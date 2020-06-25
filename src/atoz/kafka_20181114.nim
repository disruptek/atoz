
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateCluster_21626022 = ref object of OpenApiRestCall_21625435
proc url_CreateCluster_21626024(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_21626023(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626025 = header.getOrDefault("X-Amz-Date")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Date", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Security-Token", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Algorithm", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Signature")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Signature", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Credential")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Credential", valid_21626031
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

proc call*(call_21626033: Call_CreateCluster_21626022; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ## 
  let valid = call_21626033.validator(path, query, header, formData, body, _)
  let scheme = call_21626033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626033.makeUrl(scheme.get, call_21626033.host, call_21626033.base,
                               call_21626033.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626033, uri, valid, _)

proc call*(call_21626034: Call_CreateCluster_21626022; body: JsonNode): Recallable =
  ## createCluster
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ##   body: JObject (required)
  var body_21626035 = newJObject()
  if body != nil:
    body_21626035 = body
  result = call_21626034.call(nil, nil, nil, nil, body_21626035)

var createCluster* = Call_CreateCluster_21626022(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_CreateCluster_21626023, base: "/",
    makeUrl: url_CreateCluster_21626024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListClusters_21625781(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_21625780(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   clusterNameFilter: JString
  ##                    : 
  ##             <p>Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21625882 = query.getOrDefault("clusterNameFilter")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "clusterNameFilter", valid_21625882
  var valid_21625883 = query.getOrDefault("NextToken")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "NextToken", valid_21625883
  var valid_21625884 = query.getOrDefault("maxResults")
  valid_21625884 = validateParameter(valid_21625884, JInt, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "maxResults", valid_21625884
  var valid_21625885 = query.getOrDefault("nextToken")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "nextToken", valid_21625885
  var valid_21625886 = query.getOrDefault("MaxResults")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "MaxResults", valid_21625886
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
  var valid_21625887 = header.getOrDefault("X-Amz-Date")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Date", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Security-Token", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Algorithm", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Signature")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Signature", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-Credential")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-Credential", valid_21625893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625918: Call_ListClusters_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  let valid = call_21625918.validator(path, query, header, formData, body, _)
  let scheme = call_21625918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625918.makeUrl(scheme.get, call_21625918.host, call_21625918.base,
                               call_21625918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625918, uri, valid, _)

proc call*(call_21625981: Call_ListClusters_21625779;
          clusterNameFilter: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listClusters
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ##   clusterNameFilter: string
  ##                    : 
  ##             <p>Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21625983 = newJObject()
  add(query_21625983, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_21625983, "NextToken", newJString(NextToken))
  add(query_21625983, "maxResults", newJInt(maxResults))
  add(query_21625983, "nextToken", newJString(nextToken))
  add(query_21625983, "MaxResults", newJString(MaxResults))
  result = call_21625981.call(nil, query_21625983, nil, nil, nil)

var listClusters* = Call_ListClusters_21625779(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_ListClusters_21625780, base: "/", makeUrl: url_ListClusters_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_21626053 = ref object of OpenApiRestCall_21625435
proc url_CreateConfiguration_21626055(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_21626054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626056 = header.getOrDefault("X-Amz-Date")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Date", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Security-Token", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
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

proc call*(call_21626064: Call_CreateConfiguration_21626053; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ## 
  let valid = call_21626064.validator(path, query, header, formData, body, _)
  let scheme = call_21626064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626064.makeUrl(scheme.get, call_21626064.host, call_21626064.base,
                               call_21626064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626064, uri, valid, _)

proc call*(call_21626065: Call_CreateConfiguration_21626053; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ##   body: JObject (required)
  var body_21626066 = newJObject()
  if body != nil:
    body_21626066 = body
  result = call_21626065.call(nil, nil, nil, nil, body_21626066)

var createConfiguration* = Call_CreateConfiguration_21626053(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_21626054, base: "/",
    makeUrl: url_CreateConfiguration_21626055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_21626036 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurations_21626038(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_21626037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
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
  var valid_21626042 = query.getOrDefault("MaxResults")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "MaxResults", valid_21626042
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
  var valid_21626043 = header.getOrDefault("X-Amz-Date")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Date", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Security-Token", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Algorithm", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Signature")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Signature", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Credential")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Credential", valid_21626049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626050: Call_ListConfigurations_21626036; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_21626050.validator(path, query, header, formData, body, _)
  let scheme = call_21626050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626050.makeUrl(scheme.get, call_21626050.host, call_21626050.base,
                               call_21626050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626050, uri, valid, _)

proc call*(call_21626051: Call_ListConfigurations_21626036; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConfigurations
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626052 = newJObject()
  add(query_21626052, "NextToken", newJString(NextToken))
  add(query_21626052, "maxResults", newJInt(maxResults))
  add(query_21626052, "nextToken", newJString(nextToken))
  add(query_21626052, "MaxResults", newJString(MaxResults))
  result = call_21626051.call(nil, query_21626052, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_21626036(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_21626037, base: "/",
    makeUrl: url_ListConfigurations_21626038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_21626067 = ref object of OpenApiRestCall_21625435
proc url_DescribeCluster_21626069(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCluster_21626068(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626083 = path.getOrDefault("clusterArn")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "clusterArn", valid_21626083
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
  var valid_21626084 = header.getOrDefault("X-Amz-Date")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Date", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Security-Token", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Algorithm", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Signature")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Signature", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Credential")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Credential", valid_21626090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626091: Call_DescribeCluster_21626067; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  let valid = call_21626091.validator(path, query, header, formData, body, _)
  let scheme = call_21626091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626091.makeUrl(scheme.get, call_21626091.host, call_21626091.base,
                               call_21626091.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626091, uri, valid, _)

proc call*(call_21626092: Call_DescribeCluster_21626067; clusterArn: string): Recallable =
  ## describeCluster
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626093 = newJObject()
  add(path_21626093, "clusterArn", newJString(clusterArn))
  result = call_21626092.call(path_21626093, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_21626067(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_21626068,
    base: "/", makeUrl: url_DescribeCluster_21626069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_21626094 = ref object of OpenApiRestCall_21625435
proc url_DeleteCluster_21626096(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCluster_21626095(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626097 = path.getOrDefault("clusterArn")
  valid_21626097 = validateParameter(valid_21626097, JString, required = true,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "clusterArn", valid_21626097
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  section = newJObject()
  var valid_21626098 = query.getOrDefault("currentVersion")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "currentVersion", valid_21626098
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
  var valid_21626099 = header.getOrDefault("X-Amz-Date")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Date", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Security-Token", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Algorithm", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Signature")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Signature", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Credential")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Credential", valid_21626105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626106: Call_DeleteCluster_21626094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  let valid = call_21626106.validator(path, query, header, formData, body, _)
  let scheme = call_21626106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626106.makeUrl(scheme.get, call_21626106.host, call_21626106.base,
                               call_21626106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626106, uri, valid, _)

proc call*(call_21626107: Call_DeleteCluster_21626094; clusterArn: string;
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
  var path_21626108 = newJObject()
  var query_21626109 = newJObject()
  add(query_21626109, "currentVersion", newJString(currentVersion))
  add(path_21626108, "clusterArn", newJString(clusterArn))
  result = call_21626107.call(path_21626108, query_21626109, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_21626094(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_21626095,
    base: "/", makeUrl: url_DeleteCluster_21626096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_21626110 = ref object of OpenApiRestCall_21625435
proc url_DescribeClusterOperation_21626112(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeClusterOperation_21626111(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626113 = path.getOrDefault("clusterOperationArn")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "clusterOperationArn", valid_21626113
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
  var valid_21626114 = header.getOrDefault("X-Amz-Date")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Date", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Security-Token", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Algorithm", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Signature")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Signature", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Credential")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Credential", valid_21626120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626121: Call_DescribeClusterOperation_21626110;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  let valid = call_21626121.validator(path, query, header, formData, body, _)
  let scheme = call_21626121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626121.makeUrl(scheme.get, call_21626121.host, call_21626121.base,
                               call_21626121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626121, uri, valid, _)

proc call*(call_21626122: Call_DescribeClusterOperation_21626110;
          clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ##   clusterOperationArn: string (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  var path_21626123 = newJObject()
  add(path_21626123, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_21626122.call(path_21626123, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_21626110(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_21626111, base: "/",
    makeUrl: url_DescribeClusterOperation_21626112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_21626124 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfiguration_21626126(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_21626125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626127 = path.getOrDefault("arn")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "arn", valid_21626127
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
  var valid_21626128 = header.getOrDefault("X-Amz-Date")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Date", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Security-Token", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Algorithm", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Signature")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Signature", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Credential")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Credential", valid_21626134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626135: Call_DescribeConfiguration_21626124;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  let valid = call_21626135.validator(path, query, header, formData, body, _)
  let scheme = call_21626135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626135.makeUrl(scheme.get, call_21626135.host, call_21626135.base,
                               call_21626135.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626135, uri, valid, _)

proc call*(call_21626136: Call_DescribeConfiguration_21626124; arn: string): Recallable =
  ## describeConfiguration
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  var path_21626137 = newJObject()
  add(path_21626137, "arn", newJString(arn))
  result = call_21626136.call(path_21626137, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_21626124(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_21626125, base: "/",
    makeUrl: url_DescribeConfiguration_21626126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_21626138 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurationRevision_21626140(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_21626139(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626141 = path.getOrDefault("arn")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "arn", valid_21626141
  var valid_21626142 = path.getOrDefault("revision")
  valid_21626142 = validateParameter(valid_21626142, JInt, required = true,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "revision", valid_21626142
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
  var valid_21626143 = header.getOrDefault("X-Amz-Date")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Date", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Security-Token", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Algorithm", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Signature")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Signature", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Credential")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Credential", valid_21626149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626150: Call_DescribeConfigurationRevision_21626138;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  let valid = call_21626150.validator(path, query, header, formData, body, _)
  let scheme = call_21626150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626150.makeUrl(scheme.get, call_21626150.host, call_21626150.base,
                               call_21626150.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626150, uri, valid, _)

proc call*(call_21626151: Call_DescribeConfigurationRevision_21626138; arn: string;
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
  var path_21626152 = newJObject()
  add(path_21626152, "arn", newJString(arn))
  add(path_21626152, "revision", newJInt(revision))
  result = call_21626151.call(path_21626152, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_21626138(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_21626139, base: "/",
    makeUrl: url_DescribeConfigurationRevision_21626140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_21626153 = ref object of OpenApiRestCall_21625435
proc url_GetBootstrapBrokers_21626155(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBootstrapBrokers_21626154(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626156 = path.getOrDefault("clusterArn")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "clusterArn", valid_21626156
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
  var valid_21626157 = header.getOrDefault("X-Amz-Date")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Date", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Security-Token", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Algorithm", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Signature")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Signature", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Credential")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Credential", valid_21626163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626164: Call_GetBootstrapBrokers_21626153; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  let valid = call_21626164.validator(path, query, header, formData, body, _)
  let scheme = call_21626164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626164.makeUrl(scheme.get, call_21626164.host, call_21626164.base,
                               call_21626164.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626164, uri, valid, _)

proc call*(call_21626165: Call_GetBootstrapBrokers_21626153; clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626166 = newJObject()
  add(path_21626166, "clusterArn", newJString(clusterArn))
  result = call_21626165.call(path_21626166, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_21626153(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_21626154, base: "/",
    makeUrl: url_GetBootstrapBrokers_21626155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_21626167 = ref object of OpenApiRestCall_21625435
proc url_ListClusterOperations_21626169(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListClusterOperations_21626168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626170 = path.getOrDefault("clusterArn")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "clusterArn", valid_21626170
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626171 = query.getOrDefault("NextToken")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "NextToken", valid_21626171
  var valid_21626172 = query.getOrDefault("maxResults")
  valid_21626172 = validateParameter(valid_21626172, JInt, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "maxResults", valid_21626172
  var valid_21626173 = query.getOrDefault("nextToken")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "nextToken", valid_21626173
  var valid_21626174 = query.getOrDefault("MaxResults")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "MaxResults", valid_21626174
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
  if body != nil:
    result.add "body", body

proc call*(call_21626182: Call_ListClusterOperations_21626167;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  let valid = call_21626182.validator(path, query, header, formData, body, _)
  let scheme = call_21626182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626182.makeUrl(scheme.get, call_21626182.host, call_21626182.base,
                               call_21626182.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626182, uri, valid, _)

proc call*(call_21626183: Call_ListClusterOperations_21626167; clusterArn: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listClusterOperations
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626184 = newJObject()
  var query_21626185 = newJObject()
  add(query_21626185, "NextToken", newJString(NextToken))
  add(query_21626185, "maxResults", newJInt(maxResults))
  add(query_21626185, "nextToken", newJString(nextToken))
  add(path_21626184, "clusterArn", newJString(clusterArn))
  add(query_21626185, "MaxResults", newJString(MaxResults))
  result = call_21626183.call(path_21626184, query_21626185, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_21626167(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_21626168, base: "/",
    makeUrl: url_ListClusterOperations_21626169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_21626186 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurationRevisions_21626188(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_21626187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626189 = path.getOrDefault("arn")
  valid_21626189 = validateParameter(valid_21626189, JString, required = true,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "arn", valid_21626189
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626190 = query.getOrDefault("NextToken")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "NextToken", valid_21626190
  var valid_21626191 = query.getOrDefault("maxResults")
  valid_21626191 = validateParameter(valid_21626191, JInt, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "maxResults", valid_21626191
  var valid_21626192 = query.getOrDefault("nextToken")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "nextToken", valid_21626192
  var valid_21626193 = query.getOrDefault("MaxResults")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "MaxResults", valid_21626193
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
  var valid_21626194 = header.getOrDefault("X-Amz-Date")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Date", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Security-Token", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Algorithm", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Signature")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Signature", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Credential")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Credential", valid_21626200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626201: Call_ListConfigurationRevisions_21626186;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_21626201.validator(path, query, header, formData, body, _)
  let scheme = call_21626201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626201.makeUrl(scheme.get, call_21626201.host, call_21626201.base,
                               call_21626201.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626201, uri, valid, _)

proc call*(call_21626202: Call_ListConfigurationRevisions_21626186; arn: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listConfigurationRevisions
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626203 = newJObject()
  var query_21626204 = newJObject()
  add(path_21626203, "arn", newJString(arn))
  add(query_21626204, "NextToken", newJString(NextToken))
  add(query_21626204, "maxResults", newJInt(maxResults))
  add(query_21626204, "nextToken", newJString(nextToken))
  add(query_21626204, "MaxResults", newJString(MaxResults))
  result = call_21626202.call(path_21626203, query_21626204, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_21626186(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_21626187, base: "/",
    makeUrl: url_ListConfigurationRevisions_21626188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKafkaVersions_21626205 = ref object of OpenApiRestCall_21625435
proc url_ListKafkaVersions_21626207(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKafkaVersions_21626206(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626208 = query.getOrDefault("NextToken")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "NextToken", valid_21626208
  var valid_21626209 = query.getOrDefault("maxResults")
  valid_21626209 = validateParameter(valid_21626209, JInt, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "maxResults", valid_21626209
  var valid_21626210 = query.getOrDefault("nextToken")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "nextToken", valid_21626210
  var valid_21626211 = query.getOrDefault("MaxResults")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "MaxResults", valid_21626211
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_ListKafkaVersions_21626205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_ListKafkaVersions_21626205; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listKafkaVersions
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626221 = newJObject()
  add(query_21626221, "NextToken", newJString(NextToken))
  add(query_21626221, "maxResults", newJInt(maxResults))
  add(query_21626221, "nextToken", newJString(nextToken))
  add(query_21626221, "MaxResults", newJString(MaxResults))
  result = call_21626220.call(nil, query_21626221, nil, nil, nil)

var listKafkaVersions* = Call_ListKafkaVersions_21626205(name: "listKafkaVersions",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/kafka-versions", validator: validate_ListKafkaVersions_21626206,
    base: "/", makeUrl: url_ListKafkaVersions_21626207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_21626222 = ref object of OpenApiRestCall_21625435
proc url_ListNodes_21626224(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_21626223(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626225 = path.getOrDefault("clusterArn")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "clusterArn", valid_21626225
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626226 = query.getOrDefault("NextToken")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "NextToken", valid_21626226
  var valid_21626227 = query.getOrDefault("maxResults")
  valid_21626227 = validateParameter(valid_21626227, JInt, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "maxResults", valid_21626227
  var valid_21626228 = query.getOrDefault("nextToken")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "nextToken", valid_21626228
  var valid_21626229 = query.getOrDefault("MaxResults")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "MaxResults", valid_21626229
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
  var valid_21626230 = header.getOrDefault("X-Amz-Date")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Date", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Security-Token", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Algorithm", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Signature")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Signature", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Credential")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Credential", valid_21626236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626237: Call_ListNodes_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_ListNodes_21626222; clusterArn: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listNodes
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626239 = newJObject()
  var query_21626240 = newJObject()
  add(query_21626240, "NextToken", newJString(NextToken))
  add(query_21626240, "maxResults", newJInt(maxResults))
  add(query_21626240, "nextToken", newJString(nextToken))
  add(path_21626239, "clusterArn", newJString(clusterArn))
  add(query_21626240, "MaxResults", newJString(MaxResults))
  result = call_21626238.call(path_21626239, query_21626240, nil, nil, nil)

var listNodes* = Call_ListNodes_21626222(name: "listNodes", meth: HttpMethod.HttpGet,
                                      host: "kafka.amazonaws.com",
                                      route: "/v1/clusters/{clusterArn}/nodes",
                                      validator: validate_ListNodes_21626223,
                                      base: "/", makeUrl: url_ListNodes_21626224,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626255 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626257(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626258 = path.getOrDefault("resourceArn")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "resourceArn", valid_21626258
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
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Algorithm", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Signature")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Signature", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Credential")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Credential", valid_21626265
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

proc call*(call_21626267: Call_TagResource_21626255; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_TagResource_21626255; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_21626269 = newJObject()
  var body_21626270 = newJObject()
  if body != nil:
    body_21626270 = body
  add(path_21626269, "resourceArn", newJString(resourceArn))
  result = call_21626268.call(path_21626269, nil, nil, nil, body_21626270)

var tagResource* = Call_TagResource_21626255(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}", validator: validate_TagResource_21626256,
    base: "/", makeUrl: url_TagResource_21626257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626241 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626243(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626244 = path.getOrDefault("resourceArn")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "resourceArn", valid_21626244
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626252: Call_ListTagsForResource_21626241; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_ListTagsForResource_21626241; resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_21626254 = newJObject()
  add(path_21626254, "resourceArn", newJString(resourceArn))
  result = call_21626253.call(path_21626254, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626241(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626242, base: "/",
    makeUrl: url_ListTagsForResource_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626271 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626273(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21626272(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626274 = path.getOrDefault("resourceArn")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "resourceArn", valid_21626274
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
  var valid_21626275 = query.getOrDefault("tagKeys")
  valid_21626275 = validateParameter(valid_21626275, JArray, required = true,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "tagKeys", valid_21626275
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
  var valid_21626276 = header.getOrDefault("X-Amz-Date")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Date", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Security-Token", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Algorithm", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Signature")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Signature", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Credential")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Credential", valid_21626282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626283: Call_UntagResource_21626271; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_UntagResource_21626271; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
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
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_21626285 = newJObject()
  var query_21626286 = newJObject()
  if tagKeys != nil:
    query_21626286.add "tagKeys", tagKeys
  add(path_21626285, "resourceArn", newJString(resourceArn))
  result = call_21626284.call(path_21626285, query_21626286, nil, nil, nil)

var untagResource* = Call_UntagResource_21626271(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626272,
    base: "/", makeUrl: url_UntagResource_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerCount_21626287 = ref object of OpenApiRestCall_21625435
proc url_UpdateBrokerCount_21626289(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBrokerCount_21626288(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626290 = path.getOrDefault("clusterArn")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "clusterArn", valid_21626290
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
  var valid_21626291 = header.getOrDefault("X-Amz-Date")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Date", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Security-Token", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Algorithm", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Signature")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Signature", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Credential")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Credential", valid_21626297
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

proc call*(call_21626299: Call_UpdateBrokerCount_21626287; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_21626299.validator(path, query, header, formData, body, _)
  let scheme = call_21626299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626299.makeUrl(scheme.get, call_21626299.host, call_21626299.base,
                               call_21626299.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626299, uri, valid, _)

proc call*(call_21626300: Call_UpdateBrokerCount_21626287; body: JsonNode;
          clusterArn: string): Recallable =
  ## updateBrokerCount
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ##   body: JObject (required)
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626301 = newJObject()
  var body_21626302 = newJObject()
  if body != nil:
    body_21626302 = body
  add(path_21626301, "clusterArn", newJString(clusterArn))
  result = call_21626300.call(path_21626301, nil, nil, nil, body_21626302)

var updateBrokerCount* = Call_UpdateBrokerCount_21626287(name: "updateBrokerCount",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes/count",
    validator: validate_UpdateBrokerCount_21626288, base: "/",
    makeUrl: url_UpdateBrokerCount_21626289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_21626303 = ref object of OpenApiRestCall_21625435
proc url_UpdateBrokerStorage_21626305(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBrokerStorage_21626304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626306 = path.getOrDefault("clusterArn")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "clusterArn", valid_21626306
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
  var valid_21626307 = header.getOrDefault("X-Amz-Date")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Date", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Security-Token", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Algorithm", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Signature")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Signature", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Credential")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Credential", valid_21626313
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

proc call*(call_21626315: Call_UpdateBrokerStorage_21626303; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  let valid = call_21626315.validator(path, query, header, formData, body, _)
  let scheme = call_21626315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626315.makeUrl(scheme.get, call_21626315.host, call_21626315.base,
                               call_21626315.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626315, uri, valid, _)

proc call*(call_21626316: Call_UpdateBrokerStorage_21626303; body: JsonNode;
          clusterArn: string): Recallable =
  ## updateBrokerStorage
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ##   body: JObject (required)
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626317 = newJObject()
  var body_21626318 = newJObject()
  if body != nil:
    body_21626318 = body
  add(path_21626317, "clusterArn", newJString(clusterArn))
  result = call_21626316.call(path_21626317, nil, nil, nil, body_21626318)

var updateBrokerStorage* = Call_UpdateBrokerStorage_21626303(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_21626304, base: "/",
    makeUrl: url_UpdateBrokerStorage_21626305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_21626319 = ref object of OpenApiRestCall_21625435
proc url_UpdateClusterConfiguration_21626321(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterConfiguration_21626320(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626322 = path.getOrDefault("clusterArn")
  valid_21626322 = validateParameter(valid_21626322, JString, required = true,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "clusterArn", valid_21626322
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
  var valid_21626323 = header.getOrDefault("X-Amz-Date")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Date", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Security-Token", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Algorithm", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Signature")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Signature", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Credential")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Credential", valid_21626329
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

proc call*(call_21626331: Call_UpdateClusterConfiguration_21626319;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  let valid = call_21626331.validator(path, query, header, formData, body, _)
  let scheme = call_21626331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626331.makeUrl(scheme.get, call_21626331.host, call_21626331.base,
                               call_21626331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626331, uri, valid, _)

proc call*(call_21626332: Call_UpdateClusterConfiguration_21626319; body: JsonNode;
          clusterArn: string): Recallable =
  ## updateClusterConfiguration
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ##   body: JObject (required)
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626333 = newJObject()
  var body_21626334 = newJObject()
  if body != nil:
    body_21626334 = body
  add(path_21626333, "clusterArn", newJString(clusterArn))
  result = call_21626332.call(path_21626333, nil, nil, nil, body_21626334)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_21626319(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_21626320, base: "/",
    makeUrl: url_UpdateClusterConfiguration_21626321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoring_21626335 = ref object of OpenApiRestCall_21625435
proc url_UpdateMonitoring_21626337(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMonitoring_21626336(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626338 = path.getOrDefault("clusterArn")
  valid_21626338 = validateParameter(valid_21626338, JString, required = true,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "clusterArn", valid_21626338
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
  var valid_21626339 = header.getOrDefault("X-Amz-Date")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Date", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Security-Token", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Algorithm", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Signature")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Signature", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Credential")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Credential", valid_21626345
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

proc call*(call_21626347: Call_UpdateMonitoring_21626335; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ## 
  let valid = call_21626347.validator(path, query, header, formData, body, _)
  let scheme = call_21626347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626347.makeUrl(scheme.get, call_21626347.host, call_21626347.base,
                               call_21626347.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626347, uri, valid, _)

proc call*(call_21626348: Call_UpdateMonitoring_21626335; body: JsonNode;
          clusterArn: string): Recallable =
  ## updateMonitoring
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ##   body: JObject (required)
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_21626349 = newJObject()
  var body_21626350 = newJObject()
  if body != nil:
    body_21626350 = body
  add(path_21626349, "clusterArn", newJString(clusterArn))
  result = call_21626348.call(path_21626349, nil, nil, nil, body_21626350)

var updateMonitoring* = Call_UpdateMonitoring_21626335(name: "updateMonitoring",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/monitoring",
    validator: validate_UpdateMonitoring_21626336, base: "/",
    makeUrl: url_UpdateMonitoring_21626337, schemes: {Scheme.Https, Scheme.Http})
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