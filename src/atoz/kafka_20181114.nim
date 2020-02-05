
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Managed Streaming for Kafka
## version: 2018-11-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## 
##                <p>The operations for managing an Amazon MSK cluster.</p>
##             
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/kafka/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kafka.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kafka.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kafka.us-west-2.amazonaws.com",
                           "eu-west-2": "kafka.eu-west-2.amazonaws.com", "ap-northeast-3": "kafka.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "kafka.eu-central-1.amazonaws.com",
                           "us-east-2": "kafka.us-east-2.amazonaws.com",
                           "us-east-1": "kafka.us-east-1.amazonaws.com", "cn-northwest-1": "kafka.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "kafka.ap-south-1.amazonaws.com",
                           "eu-north-1": "kafka.eu-north-1.amazonaws.com", "ap-northeast-2": "kafka.ap-northeast-2.amazonaws.com",
                           "us-west-1": "kafka.us-west-1.amazonaws.com", "us-gov-east-1": "kafka.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "kafka.eu-west-3.amazonaws.com",
                           "cn-north-1": "kafka.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "kafka.sa-east-1.amazonaws.com",
                           "eu-west-1": "kafka.eu-west-1.amazonaws.com", "us-gov-west-1": "kafka.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kafka.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "kafka.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "kafka.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "kafka.ap-southeast-1.amazonaws.com",
      "us-west-2": "kafka.us-west-2.amazonaws.com",
      "eu-west-2": "kafka.eu-west-2.amazonaws.com",
      "ap-northeast-3": "kafka.ap-northeast-3.amazonaws.com",
      "eu-central-1": "kafka.eu-central-1.amazonaws.com",
      "us-east-2": "kafka.us-east-2.amazonaws.com",
      "us-east-1": "kafka.us-east-1.amazonaws.com",
      "cn-northwest-1": "kafka.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "kafka.ap-south-1.amazonaws.com",
      "eu-north-1": "kafka.eu-north-1.amazonaws.com",
      "ap-northeast-2": "kafka.ap-northeast-2.amazonaws.com",
      "us-west-1": "kafka.us-west-1.amazonaws.com",
      "us-gov-east-1": "kafka.us-gov-east-1.amazonaws.com",
      "eu-west-3": "kafka.eu-west-3.amazonaws.com",
      "cn-north-1": "kafka.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "kafka.sa-east-1.amazonaws.com",
      "eu-west-1": "kafka.eu-west-1.amazonaws.com",
      "us-gov-west-1": "kafka.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "kafka.ap-southeast-2.amazonaws.com",
      "ca-central-1": "kafka.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "kafka"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_613256 = ref object of OpenApiRestCall_612658
proc url_CreateCluster_613258(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_613257(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
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
  var valid_613259 = header.getOrDefault("X-Amz-Signature")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Signature", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Content-Sha256", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Date")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Date", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Credential")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Credential", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Security-Token")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Security-Token", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Algorithm")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Algorithm", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-SignedHeaders", valid_613265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613267: Call_CreateCluster_613256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ## 
  let valid = call_613267.validator(path, query, header, formData, body)
  let scheme = call_613267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613267.url(scheme.get, call_613267.host, call_613267.base,
                         call_613267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613267, url, valid)

proc call*(call_613268: Call_CreateCluster_613256; body: JsonNode): Recallable =
  ## createCluster
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ##   body: JObject (required)
  var body_613269 = newJObject()
  if body != nil:
    body_613269 = body
  result = call_613268.call(nil, nil, nil, nil, body_613269)

var createCluster* = Call_CreateCluster_613256(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_CreateCluster_613257, base: "/", url: url_CreateCluster_613258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_612996 = ref object of OpenApiRestCall_612658
proc url_ListClusters_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_612997(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   clusterNameFilter: JString
  ##                    : 
  ##             <p>Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.</p>
  ##          
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  section = newJObject()
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("MaxResults")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "MaxResults", valid_613111
  var valid_613112 = query.getOrDefault("NextToken")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "NextToken", valid_613112
  var valid_613113 = query.getOrDefault("clusterNameFilter")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "clusterNameFilter", valid_613113
  var valid_613114 = query.getOrDefault("maxResults")
  valid_613114 = validateParameter(valid_613114, JInt, required = false, default = nil)
  if valid_613114 != nil:
    section.add "maxResults", valid_613114
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
  var valid_613115 = header.getOrDefault("X-Amz-Signature")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Signature", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Content-Sha256", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Date")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Date", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Credential")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Credential", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Security-Token")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Security-Token", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Algorithm")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Algorithm", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-SignedHeaders", valid_613121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613144: Call_ListClusters_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  let valid = call_613144.validator(path, query, header, formData, body)
  let scheme = call_613144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613144.url(scheme.get, call_613144.host, call_613144.base,
                         call_613144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613144, url, valid)

proc call*(call_613215: Call_ListClusters_612996; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = "";
          clusterNameFilter: string = ""; maxResults: int = 0): Recallable =
  ## listClusters
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   clusterNameFilter: string
  ##                    : 
  ##             <p>Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  var query_613216 = newJObject()
  add(query_613216, "nextToken", newJString(nextToken))
  add(query_613216, "MaxResults", newJString(MaxResults))
  add(query_613216, "NextToken", newJString(NextToken))
  add(query_613216, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_613216, "maxResults", newJInt(maxResults))
  result = call_613215.call(nil, query_613216, nil, nil, nil)

var listClusters* = Call_ListClusters_612996(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_ListClusters_612997, base: "/", url: url_ListClusters_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_613287 = ref object of OpenApiRestCall_612658
proc url_CreateConfiguration_613289(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfiguration_613288(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
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
  var valid_613290 = header.getOrDefault("X-Amz-Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Signature", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Content-Sha256", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Date")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Date", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Credential")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Credential", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Security-Token")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Security-Token", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Algorithm")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Algorithm", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-SignedHeaders", valid_613296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_CreateConfiguration_613287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_CreateConfiguration_613287; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ##   body: JObject (required)
  var body_613300 = newJObject()
  if body != nil:
    body_613300 = body
  result = call_613299.call(nil, nil, nil, nil, body_613300)

var createConfiguration* = Call_CreateConfiguration_613287(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_613288, base: "/",
    url: url_CreateConfiguration_613289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_613270 = ref object of OpenApiRestCall_612658
proc url_ListConfigurations_613272(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigurations_613271(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  section = newJObject()
  var valid_613273 = query.getOrDefault("nextToken")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "nextToken", valid_613273
  var valid_613274 = query.getOrDefault("MaxResults")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "MaxResults", valid_613274
  var valid_613275 = query.getOrDefault("NextToken")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "NextToken", valid_613275
  var valid_613276 = query.getOrDefault("maxResults")
  valid_613276 = validateParameter(valid_613276, JInt, required = false, default = nil)
  if valid_613276 != nil:
    section.add "maxResults", valid_613276
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
  var valid_613277 = header.getOrDefault("X-Amz-Signature")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Signature", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Content-Sha256", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Date")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Date", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Credential")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Credential", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Security-Token")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Security-Token", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Algorithm")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Algorithm", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-SignedHeaders", valid_613283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_ListConfigurations_613270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_ListConfigurations_613270; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listConfigurations
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  var query_613286 = newJObject()
  add(query_613286, "nextToken", newJString(nextToken))
  add(query_613286, "MaxResults", newJString(MaxResults))
  add(query_613286, "NextToken", newJString(NextToken))
  add(query_613286, "maxResults", newJInt(maxResults))
  result = call_613285.call(nil, query_613286, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_613270(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_613271, base: "/",
    url: url_ListConfigurations_613272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_613301 = ref object of OpenApiRestCall_612658
proc url_DescribeCluster_613303(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCluster_613302(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613318 = path.getOrDefault("clusterArn")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "clusterArn", valid_613318
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
  var valid_613319 = header.getOrDefault("X-Amz-Signature")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Signature", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Content-Sha256", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Date")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Date", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Credential")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Credential", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Security-Token")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Security-Token", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Algorithm")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Algorithm", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-SignedHeaders", valid_613325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613326: Call_DescribeCluster_613301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  let valid = call_613326.validator(path, query, header, formData, body)
  let scheme = call_613326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613326.url(scheme.get, call_613326.host, call_613326.base,
                         call_613326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613326, url, valid)

proc call*(call_613327: Call_DescribeCluster_613301; clusterArn: string): Recallable =
  ## describeCluster
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_613328 = newJObject()
  add(path_613328, "clusterArn", newJString(clusterArn))
  result = call_613327.call(path_613328, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_613301(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_613302,
    base: "/", url: url_DescribeCluster_613303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_613329 = ref object of OpenApiRestCall_612658
proc url_DeleteCluster_613331(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCluster_613330(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613332 = path.getOrDefault("clusterArn")
  valid_613332 = validateParameter(valid_613332, JString, required = true,
                                 default = nil)
  if valid_613332 != nil:
    section.add "clusterArn", valid_613332
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  section = newJObject()
  var valid_613333 = query.getOrDefault("currentVersion")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "currentVersion", valid_613333
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
  var valid_613334 = header.getOrDefault("X-Amz-Signature")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Signature", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Content-Sha256", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Date")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Date", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Credential")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Credential", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Security-Token")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Security-Token", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Algorithm")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Algorithm", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-SignedHeaders", valid_613340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613341: Call_DeleteCluster_613329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  let valid = call_613341.validator(path, query, header, formData, body)
  let scheme = call_613341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613341.url(scheme.get, call_613341.host, call_613341.base,
                         call_613341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613341, url, valid)

proc call*(call_613342: Call_DeleteCluster_613329; clusterArn: string;
          currentVersion: string = ""): Recallable =
  ## deleteCluster
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ##   currentVersion: string
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_613343 = newJObject()
  var query_613344 = newJObject()
  add(query_613344, "currentVersion", newJString(currentVersion))
  add(path_613343, "clusterArn", newJString(clusterArn))
  result = call_613342.call(path_613343, query_613344, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_613329(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_613330,
    base: "/", url: url_DeleteCluster_613331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_613345 = ref object of OpenApiRestCall_612658
proc url_DescribeClusterOperation_613347(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterOperationArn" in path,
        "`clusterOperationArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/operations/"),
               (kind: VariableSegment, value: "clusterOperationArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeClusterOperation_613346(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterOperationArn: JString (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `clusterOperationArn` field"
  var valid_613348 = path.getOrDefault("clusterOperationArn")
  valid_613348 = validateParameter(valid_613348, JString, required = true,
                                 default = nil)
  if valid_613348 != nil:
    section.add "clusterOperationArn", valid_613348
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
  var valid_613349 = header.getOrDefault("X-Amz-Signature")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Signature", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Content-Sha256", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Date")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Date", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Credential")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Credential", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Security-Token")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Security-Token", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Algorithm")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Algorithm", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-SignedHeaders", valid_613355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613356: Call_DescribeClusterOperation_613345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  let valid = call_613356.validator(path, query, header, formData, body)
  let scheme = call_613356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613356.url(scheme.get, call_613356.host, call_613356.base,
                         call_613356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613356, url, valid)

proc call*(call_613357: Call_DescribeClusterOperation_613345;
          clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ##   clusterOperationArn: string (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  var path_613358 = newJObject()
  add(path_613358, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_613357.call(path_613358, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_613345(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_613346, base: "/",
    url: url_DescribeClusterOperation_613347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_613359 = ref object of OpenApiRestCall_612658
proc url_DescribeConfiguration_613361(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_613360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_613362 = path.getOrDefault("arn")
  valid_613362 = validateParameter(valid_613362, JString, required = true,
                                 default = nil)
  if valid_613362 != nil:
    section.add "arn", valid_613362
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
  var valid_613363 = header.getOrDefault("X-Amz-Signature")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Signature", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Content-Sha256", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Date")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Date", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Credential")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Credential", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Security-Token")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Security-Token", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Algorithm")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Algorithm", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-SignedHeaders", valid_613369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613370: Call_DescribeConfiguration_613359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  let valid = call_613370.validator(path, query, header, formData, body)
  let scheme = call_613370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613370.url(scheme.get, call_613370.host, call_613370.base,
                         call_613370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613370, url, valid)

proc call*(call_613371: Call_DescribeConfiguration_613359; arn: string): Recallable =
  ## describeConfiguration
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  var path_613372 = newJObject()
  add(path_613372, "arn", newJString(arn))
  result = call_613371.call(path_613372, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_613359(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_613360, base: "/",
    url: url_DescribeConfiguration_613361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_613373 = ref object of OpenApiRestCall_612658
proc url_DescribeConfigurationRevision_613375(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  assert "revision" in path, "`revision` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "arn"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_613374(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  ##   revision: JInt (required)
  ##           : 
  ##             <p>A string that uniquely identifies a revision of an MSK configuration.</p>
  ##          
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_613376 = path.getOrDefault("arn")
  valid_613376 = validateParameter(valid_613376, JString, required = true,
                                 default = nil)
  if valid_613376 != nil:
    section.add "arn", valid_613376
  var valid_613377 = path.getOrDefault("revision")
  valid_613377 = validateParameter(valid_613377, JInt, required = true, default = nil)
  if valid_613377 != nil:
    section.add "revision", valid_613377
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
  var valid_613378 = header.getOrDefault("X-Amz-Signature")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Signature", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Content-Sha256", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Date")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Date", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Credential")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Credential", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Security-Token")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Security-Token", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Algorithm")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Algorithm", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-SignedHeaders", valid_613384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613385: Call_DescribeConfigurationRevision_613373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  let valid = call_613385.validator(path, query, header, formData, body)
  let scheme = call_613385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613385.url(scheme.get, call_613385.host, call_613385.base,
                         call_613385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613385, url, valid)

proc call*(call_613386: Call_DescribeConfigurationRevision_613373; arn: string;
          revision: int): Recallable =
  ## describeConfigurationRevision
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  ##   revision: int (required)
  ##           : 
  ##             <p>A string that uniquely identifies a revision of an MSK configuration.</p>
  ##          
  var path_613387 = newJObject()
  add(path_613387, "arn", newJString(arn))
  add(path_613387, "revision", newJInt(revision))
  result = call_613386.call(path_613387, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_613373(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_613374, base: "/",
    url: url_DescribeConfigurationRevision_613375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_613388 = ref object of OpenApiRestCall_612658
proc url_GetBootstrapBrokers_613390(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/bootstrap-brokers")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBootstrapBrokers_613389(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613391 = path.getOrDefault("clusterArn")
  valid_613391 = validateParameter(valid_613391, JString, required = true,
                                 default = nil)
  if valid_613391 != nil:
    section.add "clusterArn", valid_613391
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
  var valid_613392 = header.getOrDefault("X-Amz-Signature")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Signature", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Content-Sha256", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Date")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Date", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Credential")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Credential", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613399: Call_GetBootstrapBrokers_613388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  let valid = call_613399.validator(path, query, header, formData, body)
  let scheme = call_613399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613399.url(scheme.get, call_613399.host, call_613399.base,
                         call_613399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613399, url, valid)

proc call*(call_613400: Call_GetBootstrapBrokers_613388; clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_613401 = newJObject()
  add(path_613401, "clusterArn", newJString(clusterArn))
  result = call_613400.call(path_613401, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_613388(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_613389, base: "/",
    url: url_GetBootstrapBrokers_613390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_613402 = ref object of OpenApiRestCall_612658
proc url_ListClusterOperations_613404(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/operations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListClusterOperations_613403(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613405 = path.getOrDefault("clusterArn")
  valid_613405 = validateParameter(valid_613405, JString, required = true,
                                 default = nil)
  if valid_613405 != nil:
    section.add "clusterArn", valid_613405
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  section = newJObject()
  var valid_613406 = query.getOrDefault("nextToken")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "nextToken", valid_613406
  var valid_613407 = query.getOrDefault("MaxResults")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "MaxResults", valid_613407
  var valid_613408 = query.getOrDefault("NextToken")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "NextToken", valid_613408
  var valid_613409 = query.getOrDefault("maxResults")
  valid_613409 = validateParameter(valid_613409, JInt, required = false, default = nil)
  if valid_613409 != nil:
    section.add "maxResults", valid_613409
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
  var valid_613410 = header.getOrDefault("X-Amz-Signature")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Signature", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Content-Sha256", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Date")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Date", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Credential")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Credential", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Security-Token")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Security-Token", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Algorithm")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Algorithm", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-SignedHeaders", valid_613416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613417: Call_ListClusterOperations_613402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  let valid = call_613417.validator(path, query, header, formData, body)
  let scheme = call_613417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613417.url(scheme.get, call_613417.host, call_613417.base,
                         call_613417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613417, url, valid)

proc call*(call_613418: Call_ListClusterOperations_613402; clusterArn: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listClusterOperations
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  var path_613419 = newJObject()
  var query_613420 = newJObject()
  add(query_613420, "nextToken", newJString(nextToken))
  add(query_613420, "MaxResults", newJString(MaxResults))
  add(query_613420, "NextToken", newJString(NextToken))
  add(path_613419, "clusterArn", newJString(clusterArn))
  add(query_613420, "maxResults", newJInt(maxResults))
  result = call_613418.call(path_613419, query_613420, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_613402(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_613403, base: "/",
    url: url_ListClusterOperations_613404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_613421 = ref object of OpenApiRestCall_612658
proc url_ListConfigurationRevisions_613423(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "arn" in path, "`arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/configurations/"),
               (kind: VariableSegment, value: "arn"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_613422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   arn: JString (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `arn` field"
  var valid_613424 = path.getOrDefault("arn")
  valid_613424 = validateParameter(valid_613424, JString, required = true,
                                 default = nil)
  if valid_613424 != nil:
    section.add "arn", valid_613424
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  section = newJObject()
  var valid_613425 = query.getOrDefault("nextToken")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "nextToken", valid_613425
  var valid_613426 = query.getOrDefault("MaxResults")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "MaxResults", valid_613426
  var valid_613427 = query.getOrDefault("NextToken")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "NextToken", valid_613427
  var valid_613428 = query.getOrDefault("maxResults")
  valid_613428 = validateParameter(valid_613428, JInt, required = false, default = nil)
  if valid_613428 != nil:
    section.add "maxResults", valid_613428
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
  var valid_613429 = header.getOrDefault("X-Amz-Signature")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Signature", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Content-Sha256", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Date")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Date", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Credential")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Credential", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Security-Token")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Security-Token", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Algorithm")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Algorithm", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-SignedHeaders", valid_613435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613436: Call_ListConfigurationRevisions_613421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_613436.validator(path, query, header, formData, body)
  let scheme = call_613436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613436.url(scheme.get, call_613436.host, call_613436.base,
                         call_613436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613436, url, valid)

proc call*(call_613437: Call_ListConfigurationRevisions_613421; arn: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listConfigurationRevisions
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  var path_613438 = newJObject()
  var query_613439 = newJObject()
  add(query_613439, "nextToken", newJString(nextToken))
  add(path_613438, "arn", newJString(arn))
  add(query_613439, "MaxResults", newJString(MaxResults))
  add(query_613439, "NextToken", newJString(NextToken))
  add(query_613439, "maxResults", newJInt(maxResults))
  result = call_613437.call(path_613438, query_613439, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_613421(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_613422, base: "/",
    url: url_ListConfigurationRevisions_613423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKafkaVersions_613440 = ref object of OpenApiRestCall_612658
proc url_ListKafkaVersions_613442(protocol: Scheme; host: string; base: string;
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

proc validate_ListKafkaVersions_613441(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  section = newJObject()
  var valid_613443 = query.getOrDefault("nextToken")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "nextToken", valid_613443
  var valid_613444 = query.getOrDefault("MaxResults")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "MaxResults", valid_613444
  var valid_613445 = query.getOrDefault("NextToken")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "NextToken", valid_613445
  var valid_613446 = query.getOrDefault("maxResults")
  valid_613446 = validateParameter(valid_613446, JInt, required = false, default = nil)
  if valid_613446 != nil:
    section.add "maxResults", valid_613446
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
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613454: Call_ListKafkaVersions_613440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  let valid = call_613454.validator(path, query, header, formData, body)
  let scheme = call_613454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613454.url(scheme.get, call_613454.host, call_613454.base,
                         call_613454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613454, url, valid)

proc call*(call_613455: Call_ListKafkaVersions_613440; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listKafkaVersions
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  var query_613456 = newJObject()
  add(query_613456, "nextToken", newJString(nextToken))
  add(query_613456, "MaxResults", newJString(MaxResults))
  add(query_613456, "NextToken", newJString(NextToken))
  add(query_613456, "maxResults", newJInt(maxResults))
  result = call_613455.call(nil, query_613456, nil, nil, nil)

var listKafkaVersions* = Call_ListKafkaVersions_613440(name: "listKafkaVersions",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/kafka-versions", validator: validate_ListKafkaVersions_613441,
    base: "/", url: url_ListKafkaVersions_613442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_613457 = ref object of OpenApiRestCall_612658
proc url_ListNodes_613459(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/nodes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_613458(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613460 = path.getOrDefault("clusterArn")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "clusterArn", valid_613460
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  section = newJObject()
  var valid_613461 = query.getOrDefault("nextToken")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "nextToken", valid_613461
  var valid_613462 = query.getOrDefault("MaxResults")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "MaxResults", valid_613462
  var valid_613463 = query.getOrDefault("NextToken")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "NextToken", valid_613463
  var valid_613464 = query.getOrDefault("maxResults")
  valid_613464 = validateParameter(valid_613464, JInt, required = false, default = nil)
  if valid_613464 != nil:
    section.add "maxResults", valid_613464
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
  var valid_613465 = header.getOrDefault("X-Amz-Signature")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Signature", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Content-Sha256", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Date")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Date", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Credential")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Credential", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Security-Token")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Security-Token", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Algorithm")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Algorithm", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-SignedHeaders", valid_613471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_ListNodes_613457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_ListNodes_613457; clusterArn: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listNodes
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  var path_613474 = newJObject()
  var query_613475 = newJObject()
  add(query_613475, "nextToken", newJString(nextToken))
  add(query_613475, "MaxResults", newJString(MaxResults))
  add(query_613475, "NextToken", newJString(NextToken))
  add(path_613474, "clusterArn", newJString(clusterArn))
  add(query_613475, "maxResults", newJInt(maxResults))
  result = call_613473.call(path_613474, query_613475, nil, nil, nil)

var listNodes* = Call_ListNodes_613457(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "kafka.amazonaws.com",
                                    route: "/v1/clusters/{clusterArn}/nodes",
                                    validator: validate_ListNodes_613458,
                                    base: "/", url: url_ListNodes_613459,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613490 = ref object of OpenApiRestCall_612658
proc url_TagResource_613492(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613491(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613493 = path.getOrDefault("resourceArn")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "resourceArn", valid_613493
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_TagResource_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_TagResource_613490; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  ##   body: JObject (required)
  var path_613504 = newJObject()
  var body_613505 = newJObject()
  add(path_613504, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613505 = body
  result = call_613503.call(path_613504, nil, nil, nil, body_613505)

var tagResource* = Call_TagResource_613490(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kafka.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_613491,
                                        base: "/", url: url_TagResource_613492,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613476 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613478(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613477(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613479 = path.getOrDefault("resourceArn")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "resourceArn", valid_613479
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
  var valid_613480 = header.getOrDefault("X-Amz-Signature")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Signature", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Content-Sha256", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Date")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Date", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Credential")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Credential", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Security-Token")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Security-Token", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Algorithm")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Algorithm", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-SignedHeaders", valid_613486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_ListTagsForResource_613476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_ListTagsForResource_613476; resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_613489 = newJObject()
  add(path_613489, "resourceArn", newJString(resourceArn))
  result = call_613488.call(path_613489, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613476(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613477, base: "/",
    url: url_ListTagsForResource_613478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613506 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613508(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
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

proc validate_UntagResource_613507(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613509 = path.getOrDefault("resourceArn")
  valid_613509 = validateParameter(valid_613509, JString, required = true,
                                 default = nil)
  if valid_613509 != nil:
    section.add "resourceArn", valid_613509
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>Tag keys must be unique for a given cluster. In addition, the following restrictions apply:</p>
  ##             <ul>
  ##                <li>
  ##                   <p>Each tag key must be unique. If you add a tag with a key that's already in
  ##                   use, your new tag overwrites the existing key-value pair. </p>
  ##                </li>
  ##                <li>
  ##                   <p>You can't start a tag key with aws: because this prefix is reserved for use
  ##                   by  AWS.  AWS creates tags that begin with this prefix on your behalf, but
  ##                   you can't edit or delete them.</p>
  ##                </li>
  ##                <li>
  ##                   <p>Tag keys must be between 1 and 128 Unicode characters in length.</p>
  ##                </li>
  ##                <li>
  ##                   <p>Tag keys must consist of the following characters: Unicode letters, digits,
  ##                   white space, and the following special characters: _ . / = + -
  ##                      @.</p>
  ##                </li>
  ##             </ul>
  ##          
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613510 = query.getOrDefault("tagKeys")
  valid_613510 = validateParameter(valid_613510, JArray, required = true, default = nil)
  if valid_613510 != nil:
    section.add "tagKeys", valid_613510
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
  var valid_613511 = header.getOrDefault("X-Amz-Signature")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Signature", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Content-Sha256", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Date")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Date", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Credential")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Credential", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Security-Token")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Security-Token", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Algorithm")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Algorithm", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-SignedHeaders", valid_613517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613518: Call_UntagResource_613506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  let valid = call_613518.validator(path, query, header, formData, body)
  let scheme = call_613518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613518.url(scheme.get, call_613518.host, call_613518.base,
                         call_613518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613518, url, valid)

proc call*(call_613519: Call_UntagResource_613506; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  ##   tagKeys: JArray (required)
  ##          : 
  ##             <p>Tag keys must be unique for a given cluster. In addition, the following restrictions apply:</p>
  ##             <ul>
  ##                <li>
  ##                   <p>Each tag key must be unique. If you add a tag with a key that's already in
  ##                   use, your new tag overwrites the existing key-value pair. </p>
  ##                </li>
  ##                <li>
  ##                   <p>You can't start a tag key with aws: because this prefix is reserved for use
  ##                   by  AWS.  AWS creates tags that begin with this prefix on your behalf, but
  ##                   you can't edit or delete them.</p>
  ##                </li>
  ##                <li>
  ##                   <p>Tag keys must be between 1 and 128 Unicode characters in length.</p>
  ##                </li>
  ##                <li>
  ##                   <p>Tag keys must consist of the following characters: Unicode letters, digits,
  ##                   white space, and the following special characters: _ . / = + -
  ##                      @.</p>
  ##                </li>
  ##             </ul>
  ##          
  var path_613520 = newJObject()
  var query_613521 = newJObject()
  add(path_613520, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613521.add "tagKeys", tagKeys
  result = call_613519.call(path_613520, query_613521, nil, nil, nil)

var untagResource* = Call_UntagResource_613506(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613507,
    base: "/", url: url_UntagResource_613508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerCount_613522 = ref object of OpenApiRestCall_612658
proc url_UpdateBrokerCount_613524(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/nodes/count")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBrokerCount_613523(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613525 = path.getOrDefault("clusterArn")
  valid_613525 = validateParameter(valid_613525, JString, required = true,
                                 default = nil)
  if valid_613525 != nil:
    section.add "clusterArn", valid_613525
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
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613534: Call_UpdateBrokerCount_613522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_613534.validator(path, query, header, formData, body)
  let scheme = call_613534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613534.url(scheme.get, call_613534.host, call_613534.base,
                         call_613534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613534, url, valid)

proc call*(call_613535: Call_UpdateBrokerCount_613522; clusterArn: string;
          body: JsonNode): Recallable =
  ## updateBrokerCount
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   body: JObject (required)
  var path_613536 = newJObject()
  var body_613537 = newJObject()
  add(path_613536, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_613537 = body
  result = call_613535.call(path_613536, nil, nil, nil, body_613537)

var updateBrokerCount* = Call_UpdateBrokerCount_613522(name: "updateBrokerCount",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes/count",
    validator: validate_UpdateBrokerCount_613523, base: "/",
    url: url_UpdateBrokerCount_613524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_613538 = ref object of OpenApiRestCall_612658
proc url_UpdateBrokerStorage_613540(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/nodes/storage")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBrokerStorage_613539(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613541 = path.getOrDefault("clusterArn")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "clusterArn", valid_613541
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
  var valid_613542 = header.getOrDefault("X-Amz-Signature")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Signature", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Content-Sha256", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Date")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Date", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Credential")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Credential", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Security-Token")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Security-Token", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Algorithm")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Algorithm", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-SignedHeaders", valid_613548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613550: Call_UpdateBrokerStorage_613538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  let valid = call_613550.validator(path, query, header, formData, body)
  let scheme = call_613550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613550.url(scheme.get, call_613550.host, call_613550.base,
                         call_613550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613550, url, valid)

proc call*(call_613551: Call_UpdateBrokerStorage_613538; clusterArn: string;
          body: JsonNode): Recallable =
  ## updateBrokerStorage
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   body: JObject (required)
  var path_613552 = newJObject()
  var body_613553 = newJObject()
  add(path_613552, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_613553 = body
  result = call_613551.call(path_613552, nil, nil, nil, body_613553)

var updateBrokerStorage* = Call_UpdateBrokerStorage_613538(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_613539, base: "/",
    url: url_UpdateBrokerStorage_613540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_613554 = ref object of OpenApiRestCall_612658
proc url_UpdateClusterConfiguration_613556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterConfiguration_613555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613557 = path.getOrDefault("clusterArn")
  valid_613557 = validateParameter(valid_613557, JString, required = true,
                                 default = nil)
  if valid_613557 != nil:
    section.add "clusterArn", valid_613557
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
  var valid_613558 = header.getOrDefault("X-Amz-Signature")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Signature", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Content-Sha256", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Date")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Date", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Credential")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Credential", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Security-Token")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Security-Token", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Algorithm")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Algorithm", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-SignedHeaders", valid_613564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613566: Call_UpdateClusterConfiguration_613554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  let valid = call_613566.validator(path, query, header, formData, body)
  let scheme = call_613566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613566.url(scheme.get, call_613566.host, call_613566.base,
                         call_613566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613566, url, valid)

proc call*(call_613567: Call_UpdateClusterConfiguration_613554; clusterArn: string;
          body: JsonNode): Recallable =
  ## updateClusterConfiguration
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   body: JObject (required)
  var path_613568 = newJObject()
  var body_613569 = newJObject()
  add(path_613568, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_613569 = body
  result = call_613567.call(path_613568, nil, nil, nil, body_613569)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_613554(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_613555, base: "/",
    url: url_UpdateClusterConfiguration_613556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoring_613570 = ref object of OpenApiRestCall_612658
proc url_UpdateMonitoring_613572(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "clusterArn" in path, "`clusterArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/clusters/"),
               (kind: VariableSegment, value: "clusterArn"),
               (kind: ConstantSegment, value: "/monitoring")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMonitoring_613571(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   clusterArn: JString (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `clusterArn` field"
  var valid_613573 = path.getOrDefault("clusterArn")
  valid_613573 = validateParameter(valid_613573, JString, required = true,
                                 default = nil)
  if valid_613573 != nil:
    section.add "clusterArn", valid_613573
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
  var valid_613574 = header.getOrDefault("X-Amz-Signature")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Signature", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Content-Sha256", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Date")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Date", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Credential")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Credential", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Security-Token")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Security-Token", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Algorithm")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Algorithm", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-SignedHeaders", valid_613580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613582: Call_UpdateMonitoring_613570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ## 
  let valid = call_613582.validator(path, query, header, formData, body)
  let scheme = call_613582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613582.url(scheme.get, call_613582.host, call_613582.base,
                         call_613582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613582, url, valid)

proc call*(call_613583: Call_UpdateMonitoring_613570; clusterArn: string;
          body: JsonNode): Recallable =
  ## updateMonitoring
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   body: JObject (required)
  var path_613584 = newJObject()
  var body_613585 = newJObject()
  add(path_613584, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_613585 = body
  result = call_613583.call(path_613584, nil, nil, nil, body_613585)

var updateMonitoring* = Call_UpdateMonitoring_613570(name: "updateMonitoring",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/monitoring",
    validator: validate_UpdateMonitoring_613571, base: "/",
    url: url_UpdateMonitoring_613572, schemes: {Scheme.Https, Scheme.Http})
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
