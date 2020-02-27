
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "kafka.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kafka.ap-southeast-1.amazonaws.com",
                           "us-west-2": "kafka.us-west-2.amazonaws.com",
                           "eu-west-2": "kafka.eu-west-2.amazonaws.com", "ap-northeast-3": "kafka.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "kafka.eu-central-1.amazonaws.com",
                           "us-east-2": "kafka.us-east-2.amazonaws.com",
                           "us-east-1": "kafka.us-east-1.amazonaws.com", "cn-northwest-1": "kafka.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "kafka.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "kafka.ap-south-1.amazonaws.com",
                           "eu-north-1": "kafka.eu-north-1.amazonaws.com",
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
      "ap-northeast-2": "kafka.ap-northeast-2.amazonaws.com",
      "ap-south-1": "kafka.ap-south-1.amazonaws.com",
      "eu-north-1": "kafka.eu-north-1.amazonaws.com",
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
  Call_CreateCluster_617468 = ref object of OpenApiRestCall_616866
proc url_CreateCluster_617470(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_617469(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617471 = header.getOrDefault("X-Amz-Date")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-Date", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Security-Token")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Security-Token", valid_617472
  var valid_617473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617473 = validateParameter(valid_617473, JString, required = false,
                                 default = nil)
  if valid_617473 != nil:
    section.add "X-Amz-Content-Sha256", valid_617473
  var valid_617474 = header.getOrDefault("X-Amz-Algorithm")
  valid_617474 = validateParameter(valid_617474, JString, required = false,
                                 default = nil)
  if valid_617474 != nil:
    section.add "X-Amz-Algorithm", valid_617474
  var valid_617475 = header.getOrDefault("X-Amz-Signature")
  valid_617475 = validateParameter(valid_617475, JString, required = false,
                                 default = nil)
  if valid_617475 != nil:
    section.add "X-Amz-Signature", valid_617475
  var valid_617476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617476 = validateParameter(valid_617476, JString, required = false,
                                 default = nil)
  if valid_617476 != nil:
    section.add "X-Amz-SignedHeaders", valid_617476
  var valid_617477 = header.getOrDefault("X-Amz-Credential")
  valid_617477 = validateParameter(valid_617477, JString, required = false,
                                 default = nil)
  if valid_617477 != nil:
    section.add "X-Amz-Credential", valid_617477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617479: Call_CreateCluster_617468; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ## 
  let valid = call_617479.validator(path, query, header, formData, body, _)
  let scheme = call_617479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617479.url(scheme.get, call_617479.host, call_617479.base,
                         call_617479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617479, url, valid, _)

proc call*(call_617480: Call_CreateCluster_617468; body: JsonNode): Recallable =
  ## createCluster
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ##   body: JObject (required)
  var body_617481 = newJObject()
  if body != nil:
    body_617481 = body
  result = call_617480.call(nil, nil, nil, nil, body_617481)

var createCluster* = Call_CreateCluster_617468(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_CreateCluster_617469, base: "/", url: url_CreateCluster_617470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_617205 = ref object of OpenApiRestCall_616866
proc url_ListClusters_617207(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_617206(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617319 = query.getOrDefault("clusterNameFilter")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "clusterNameFilter", valid_617319
  var valid_617320 = query.getOrDefault("maxResults")
  valid_617320 = validateParameter(valid_617320, JInt, required = false, default = nil)
  if valid_617320 != nil:
    section.add "maxResults", valid_617320
  var valid_617321 = query.getOrDefault("nextToken")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "nextToken", valid_617321
  var valid_617322 = query.getOrDefault("NextToken")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "NextToken", valid_617322
  var valid_617323 = query.getOrDefault("MaxResults")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "MaxResults", valid_617323
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
  var valid_617324 = header.getOrDefault("X-Amz-Date")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-Date", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-Security-Token")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Security-Token", valid_617325
  var valid_617326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617326 = validateParameter(valid_617326, JString, required = false,
                                 default = nil)
  if valid_617326 != nil:
    section.add "X-Amz-Content-Sha256", valid_617326
  var valid_617327 = header.getOrDefault("X-Amz-Algorithm")
  valid_617327 = validateParameter(valid_617327, JString, required = false,
                                 default = nil)
  if valid_617327 != nil:
    section.add "X-Amz-Algorithm", valid_617327
  var valid_617328 = header.getOrDefault("X-Amz-Signature")
  valid_617328 = validateParameter(valid_617328, JString, required = false,
                                 default = nil)
  if valid_617328 != nil:
    section.add "X-Amz-Signature", valid_617328
  var valid_617329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617329 = validateParameter(valid_617329, JString, required = false,
                                 default = nil)
  if valid_617329 != nil:
    section.add "X-Amz-SignedHeaders", valid_617329
  var valid_617330 = header.getOrDefault("X-Amz-Credential")
  valid_617330 = validateParameter(valid_617330, JString, required = false,
                                 default = nil)
  if valid_617330 != nil:
    section.add "X-Amz-Credential", valid_617330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617354: Call_ListClusters_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  let valid = call_617354.validator(path, query, header, formData, body, _)
  let scheme = call_617354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617354.url(scheme.get, call_617354.host, call_617354.base,
                         call_617354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617354, url, valid, _)

proc call*(call_617425: Call_ListClusters_617205; clusterNameFilter: string = "";
          maxResults: int = 0; nextToken: string = ""; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listClusters
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ##   clusterNameFilter: string
  ##                    : 
  ##             <p>Specify a prefix of the name of the clusters that you want to list. The service lists all the clusters whose names start with this prefix.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617426 = newJObject()
  add(query_617426, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_617426, "maxResults", newJInt(maxResults))
  add(query_617426, "nextToken", newJString(nextToken))
  add(query_617426, "NextToken", newJString(NextToken))
  add(query_617426, "MaxResults", newJString(MaxResults))
  result = call_617425.call(nil, query_617426, nil, nil, nil)

var listClusters* = Call_ListClusters_617205(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_ListClusters_617206, base: "/", url: url_ListClusters_617207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_617499 = ref object of OpenApiRestCall_616866
proc url_CreateConfiguration_617501(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_617500(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617502 = header.getOrDefault("X-Amz-Date")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Date", valid_617502
  var valid_617503 = header.getOrDefault("X-Amz-Security-Token")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-Security-Token", valid_617503
  var valid_617504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617504 = validateParameter(valid_617504, JString, required = false,
                                 default = nil)
  if valid_617504 != nil:
    section.add "X-Amz-Content-Sha256", valid_617504
  var valid_617505 = header.getOrDefault("X-Amz-Algorithm")
  valid_617505 = validateParameter(valid_617505, JString, required = false,
                                 default = nil)
  if valid_617505 != nil:
    section.add "X-Amz-Algorithm", valid_617505
  var valid_617506 = header.getOrDefault("X-Amz-Signature")
  valid_617506 = validateParameter(valid_617506, JString, required = false,
                                 default = nil)
  if valid_617506 != nil:
    section.add "X-Amz-Signature", valid_617506
  var valid_617507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617507 = validateParameter(valid_617507, JString, required = false,
                                 default = nil)
  if valid_617507 != nil:
    section.add "X-Amz-SignedHeaders", valid_617507
  var valid_617508 = header.getOrDefault("X-Amz-Credential")
  valid_617508 = validateParameter(valid_617508, JString, required = false,
                                 default = nil)
  if valid_617508 != nil:
    section.add "X-Amz-Credential", valid_617508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617510: Call_CreateConfiguration_617499; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ## 
  let valid = call_617510.validator(path, query, header, formData, body, _)
  let scheme = call_617510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617510.url(scheme.get, call_617510.host, call_617510.base,
                         call_617510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617510, url, valid, _)

proc call*(call_617511: Call_CreateConfiguration_617499; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ##   body: JObject (required)
  var body_617512 = newJObject()
  if body != nil:
    body_617512 = body
  result = call_617511.call(nil, nil, nil, nil, body_617512)

var createConfiguration* = Call_CreateConfiguration_617499(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_617500, base: "/",
    url: url_CreateConfiguration_617501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_617482 = ref object of OpenApiRestCall_616866
proc url_ListConfigurations_617484(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_617483(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617485 = query.getOrDefault("maxResults")
  valid_617485 = validateParameter(valid_617485, JInt, required = false, default = nil)
  if valid_617485 != nil:
    section.add "maxResults", valid_617485
  var valid_617486 = query.getOrDefault("nextToken")
  valid_617486 = validateParameter(valid_617486, JString, required = false,
                                 default = nil)
  if valid_617486 != nil:
    section.add "nextToken", valid_617486
  var valid_617487 = query.getOrDefault("NextToken")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "NextToken", valid_617487
  var valid_617488 = query.getOrDefault("MaxResults")
  valid_617488 = validateParameter(valid_617488, JString, required = false,
                                 default = nil)
  if valid_617488 != nil:
    section.add "MaxResults", valid_617488
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
  var valid_617489 = header.getOrDefault("X-Amz-Date")
  valid_617489 = validateParameter(valid_617489, JString, required = false,
                                 default = nil)
  if valid_617489 != nil:
    section.add "X-Amz-Date", valid_617489
  var valid_617490 = header.getOrDefault("X-Amz-Security-Token")
  valid_617490 = validateParameter(valid_617490, JString, required = false,
                                 default = nil)
  if valid_617490 != nil:
    section.add "X-Amz-Security-Token", valid_617490
  var valid_617491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617491 = validateParameter(valid_617491, JString, required = false,
                                 default = nil)
  if valid_617491 != nil:
    section.add "X-Amz-Content-Sha256", valid_617491
  var valid_617492 = header.getOrDefault("X-Amz-Algorithm")
  valid_617492 = validateParameter(valid_617492, JString, required = false,
                                 default = nil)
  if valid_617492 != nil:
    section.add "X-Amz-Algorithm", valid_617492
  var valid_617493 = header.getOrDefault("X-Amz-Signature")
  valid_617493 = validateParameter(valid_617493, JString, required = false,
                                 default = nil)
  if valid_617493 != nil:
    section.add "X-Amz-Signature", valid_617493
  var valid_617494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617494 = validateParameter(valid_617494, JString, required = false,
                                 default = nil)
  if valid_617494 != nil:
    section.add "X-Amz-SignedHeaders", valid_617494
  var valid_617495 = header.getOrDefault("X-Amz-Credential")
  valid_617495 = validateParameter(valid_617495, JString, required = false,
                                 default = nil)
  if valid_617495 != nil:
    section.add "X-Amz-Credential", valid_617495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617496: Call_ListConfigurations_617482; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_617496.validator(path, query, header, formData, body, _)
  let scheme = call_617496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617496.url(scheme.get, call_617496.host, call_617496.base,
                         call_617496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617496, url, valid, _)

proc call*(call_617497: Call_ListConfigurations_617482; maxResults: int = 0;
          nextToken: string = ""; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConfigurations
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617498 = newJObject()
  add(query_617498, "maxResults", newJInt(maxResults))
  add(query_617498, "nextToken", newJString(nextToken))
  add(query_617498, "NextToken", newJString(NextToken))
  add(query_617498, "MaxResults", newJString(MaxResults))
  result = call_617497.call(nil, query_617498, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_617482(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_617483, base: "/",
    url: url_ListConfigurations_617484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_617513 = ref object of OpenApiRestCall_616866
proc url_DescribeCluster_617515(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_617514(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617530 = path.getOrDefault("clusterArn")
  valid_617530 = validateParameter(valid_617530, JString, required = true,
                                 default = nil)
  if valid_617530 != nil:
    section.add "clusterArn", valid_617530
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
  var valid_617531 = header.getOrDefault("X-Amz-Date")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-Date", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Security-Token")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Security-Token", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-Content-Sha256", valid_617533
  var valid_617534 = header.getOrDefault("X-Amz-Algorithm")
  valid_617534 = validateParameter(valid_617534, JString, required = false,
                                 default = nil)
  if valid_617534 != nil:
    section.add "X-Amz-Algorithm", valid_617534
  var valid_617535 = header.getOrDefault("X-Amz-Signature")
  valid_617535 = validateParameter(valid_617535, JString, required = false,
                                 default = nil)
  if valid_617535 != nil:
    section.add "X-Amz-Signature", valid_617535
  var valid_617536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "X-Amz-SignedHeaders", valid_617536
  var valid_617537 = header.getOrDefault("X-Amz-Credential")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-Credential", valid_617537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617538: Call_DescribeCluster_617513; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  let valid = call_617538.validator(path, query, header, formData, body, _)
  let scheme = call_617538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617538.url(scheme.get, call_617538.host, call_617538.base,
                         call_617538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617538, url, valid, _)

proc call*(call_617539: Call_DescribeCluster_617513; clusterArn: string): Recallable =
  ## describeCluster
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_617540 = newJObject()
  add(path_617540, "clusterArn", newJString(clusterArn))
  result = call_617539.call(path_617540, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_617513(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_617514,
    base: "/", url: url_DescribeCluster_617515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_617541 = ref object of OpenApiRestCall_616866
proc url_DeleteCluster_617543(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_617542(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617544 = path.getOrDefault("clusterArn")
  valid_617544 = validateParameter(valid_617544, JString, required = true,
                                 default = nil)
  if valid_617544 != nil:
    section.add "clusterArn", valid_617544
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  section = newJObject()
  var valid_617545 = query.getOrDefault("currentVersion")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "currentVersion", valid_617545
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
  var valid_617546 = header.getOrDefault("X-Amz-Date")
  valid_617546 = validateParameter(valid_617546, JString, required = false,
                                 default = nil)
  if valid_617546 != nil:
    section.add "X-Amz-Date", valid_617546
  var valid_617547 = header.getOrDefault("X-Amz-Security-Token")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Security-Token", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617548 = validateParameter(valid_617548, JString, required = false,
                                 default = nil)
  if valid_617548 != nil:
    section.add "X-Amz-Content-Sha256", valid_617548
  var valid_617549 = header.getOrDefault("X-Amz-Algorithm")
  valid_617549 = validateParameter(valid_617549, JString, required = false,
                                 default = nil)
  if valid_617549 != nil:
    section.add "X-Amz-Algorithm", valid_617549
  var valid_617550 = header.getOrDefault("X-Amz-Signature")
  valid_617550 = validateParameter(valid_617550, JString, required = false,
                                 default = nil)
  if valid_617550 != nil:
    section.add "X-Amz-Signature", valid_617550
  var valid_617551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-SignedHeaders", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-Credential")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-Credential", valid_617552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617553: Call_DeleteCluster_617541; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  let valid = call_617553.validator(path, query, header, formData, body, _)
  let scheme = call_617553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617553.url(scheme.get, call_617553.host, call_617553.base,
                         call_617553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617553, url, valid, _)

proc call*(call_617554: Call_DeleteCluster_617541; clusterArn: string;
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
  var path_617555 = newJObject()
  var query_617556 = newJObject()
  add(query_617556, "currentVersion", newJString(currentVersion))
  add(path_617555, "clusterArn", newJString(clusterArn))
  result = call_617554.call(path_617555, query_617556, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_617541(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_617542,
    base: "/", url: url_DeleteCluster_617543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_617557 = ref object of OpenApiRestCall_616866
proc url_DescribeClusterOperation_617559(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeClusterOperation_617558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617560 = path.getOrDefault("clusterOperationArn")
  valid_617560 = validateParameter(valid_617560, JString, required = true,
                                 default = nil)
  if valid_617560 != nil:
    section.add "clusterOperationArn", valid_617560
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
  var valid_617561 = header.getOrDefault("X-Amz-Date")
  valid_617561 = validateParameter(valid_617561, JString, required = false,
                                 default = nil)
  if valid_617561 != nil:
    section.add "X-Amz-Date", valid_617561
  var valid_617562 = header.getOrDefault("X-Amz-Security-Token")
  valid_617562 = validateParameter(valid_617562, JString, required = false,
                                 default = nil)
  if valid_617562 != nil:
    section.add "X-Amz-Security-Token", valid_617562
  var valid_617563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617563 = validateParameter(valid_617563, JString, required = false,
                                 default = nil)
  if valid_617563 != nil:
    section.add "X-Amz-Content-Sha256", valid_617563
  var valid_617564 = header.getOrDefault("X-Amz-Algorithm")
  valid_617564 = validateParameter(valid_617564, JString, required = false,
                                 default = nil)
  if valid_617564 != nil:
    section.add "X-Amz-Algorithm", valid_617564
  var valid_617565 = header.getOrDefault("X-Amz-Signature")
  valid_617565 = validateParameter(valid_617565, JString, required = false,
                                 default = nil)
  if valid_617565 != nil:
    section.add "X-Amz-Signature", valid_617565
  var valid_617566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617566 = validateParameter(valid_617566, JString, required = false,
                                 default = nil)
  if valid_617566 != nil:
    section.add "X-Amz-SignedHeaders", valid_617566
  var valid_617567 = header.getOrDefault("X-Amz-Credential")
  valid_617567 = validateParameter(valid_617567, JString, required = false,
                                 default = nil)
  if valid_617567 != nil:
    section.add "X-Amz-Credential", valid_617567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617568: Call_DescribeClusterOperation_617557; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  let valid = call_617568.validator(path, query, header, formData, body, _)
  let scheme = call_617568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617568.url(scheme.get, call_617568.host, call_617568.base,
                         call_617568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617568, url, valid, _)

proc call*(call_617569: Call_DescribeClusterOperation_617557;
          clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ##   clusterOperationArn: string (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  var path_617570 = newJObject()
  add(path_617570, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_617569.call(path_617570, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_617557(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_617558, base: "/",
    url: url_DescribeClusterOperation_617559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_617571 = ref object of OpenApiRestCall_616866
proc url_DescribeConfiguration_617573(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeConfiguration_617572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617574 = path.getOrDefault("arn")
  valid_617574 = validateParameter(valid_617574, JString, required = true,
                                 default = nil)
  if valid_617574 != nil:
    section.add "arn", valid_617574
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
  var valid_617575 = header.getOrDefault("X-Amz-Date")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Date", valid_617575
  var valid_617576 = header.getOrDefault("X-Amz-Security-Token")
  valid_617576 = validateParameter(valid_617576, JString, required = false,
                                 default = nil)
  if valid_617576 != nil:
    section.add "X-Amz-Security-Token", valid_617576
  var valid_617577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617577 = validateParameter(valid_617577, JString, required = false,
                                 default = nil)
  if valid_617577 != nil:
    section.add "X-Amz-Content-Sha256", valid_617577
  var valid_617578 = header.getOrDefault("X-Amz-Algorithm")
  valid_617578 = validateParameter(valid_617578, JString, required = false,
                                 default = nil)
  if valid_617578 != nil:
    section.add "X-Amz-Algorithm", valid_617578
  var valid_617579 = header.getOrDefault("X-Amz-Signature")
  valid_617579 = validateParameter(valid_617579, JString, required = false,
                                 default = nil)
  if valid_617579 != nil:
    section.add "X-Amz-Signature", valid_617579
  var valid_617580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617580 = validateParameter(valid_617580, JString, required = false,
                                 default = nil)
  if valid_617580 != nil:
    section.add "X-Amz-SignedHeaders", valid_617580
  var valid_617581 = header.getOrDefault("X-Amz-Credential")
  valid_617581 = validateParameter(valid_617581, JString, required = false,
                                 default = nil)
  if valid_617581 != nil:
    section.add "X-Amz-Credential", valid_617581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617582: Call_DescribeConfiguration_617571; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  let valid = call_617582.validator(path, query, header, formData, body, _)
  let scheme = call_617582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617582.url(scheme.get, call_617582.host, call_617582.base,
                         call_617582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617582, url, valid, _)

proc call*(call_617583: Call_DescribeConfiguration_617571; arn: string): Recallable =
  ## describeConfiguration
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  var path_617584 = newJObject()
  add(path_617584, "arn", newJString(arn))
  result = call_617583.call(path_617584, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_617571(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_617572, base: "/",
    url: url_DescribeConfiguration_617573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_617585 = ref object of OpenApiRestCall_616866
proc url_DescribeConfigurationRevision_617587(protocol: Scheme; host: string;
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

proc validate_DescribeConfigurationRevision_617586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617588 = path.getOrDefault("arn")
  valid_617588 = validateParameter(valid_617588, JString, required = true,
                                 default = nil)
  if valid_617588 != nil:
    section.add "arn", valid_617588
  var valid_617589 = path.getOrDefault("revision")
  valid_617589 = validateParameter(valid_617589, JInt, required = true, default = nil)
  if valid_617589 != nil:
    section.add "revision", valid_617589
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
  var valid_617590 = header.getOrDefault("X-Amz-Date")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Date", valid_617590
  var valid_617591 = header.getOrDefault("X-Amz-Security-Token")
  valid_617591 = validateParameter(valid_617591, JString, required = false,
                                 default = nil)
  if valid_617591 != nil:
    section.add "X-Amz-Security-Token", valid_617591
  var valid_617592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617592 = validateParameter(valid_617592, JString, required = false,
                                 default = nil)
  if valid_617592 != nil:
    section.add "X-Amz-Content-Sha256", valid_617592
  var valid_617593 = header.getOrDefault("X-Amz-Algorithm")
  valid_617593 = validateParameter(valid_617593, JString, required = false,
                                 default = nil)
  if valid_617593 != nil:
    section.add "X-Amz-Algorithm", valid_617593
  var valid_617594 = header.getOrDefault("X-Amz-Signature")
  valid_617594 = validateParameter(valid_617594, JString, required = false,
                                 default = nil)
  if valid_617594 != nil:
    section.add "X-Amz-Signature", valid_617594
  var valid_617595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617595 = validateParameter(valid_617595, JString, required = false,
                                 default = nil)
  if valid_617595 != nil:
    section.add "X-Amz-SignedHeaders", valid_617595
  var valid_617596 = header.getOrDefault("X-Amz-Credential")
  valid_617596 = validateParameter(valid_617596, JString, required = false,
                                 default = nil)
  if valid_617596 != nil:
    section.add "X-Amz-Credential", valid_617596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617597: Call_DescribeConfigurationRevision_617585;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  let valid = call_617597.validator(path, query, header, formData, body, _)
  let scheme = call_617597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617597.url(scheme.get, call_617597.host, call_617597.base,
                         call_617597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617597, url, valid, _)

proc call*(call_617598: Call_DescribeConfigurationRevision_617585; arn: string;
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
  var path_617599 = newJObject()
  add(path_617599, "arn", newJString(arn))
  add(path_617599, "revision", newJInt(revision))
  result = call_617598.call(path_617599, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_617585(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_617586, base: "/",
    url: url_DescribeConfigurationRevision_617587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_617600 = ref object of OpenApiRestCall_616866
proc url_GetBootstrapBrokers_617602(protocol: Scheme; host: string; base: string;
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

proc validate_GetBootstrapBrokers_617601(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617603 = path.getOrDefault("clusterArn")
  valid_617603 = validateParameter(valid_617603, JString, required = true,
                                 default = nil)
  if valid_617603 != nil:
    section.add "clusterArn", valid_617603
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
  var valid_617604 = header.getOrDefault("X-Amz-Date")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Date", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-Security-Token")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-Security-Token", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "X-Amz-Content-Sha256", valid_617606
  var valid_617607 = header.getOrDefault("X-Amz-Algorithm")
  valid_617607 = validateParameter(valid_617607, JString, required = false,
                                 default = nil)
  if valid_617607 != nil:
    section.add "X-Amz-Algorithm", valid_617607
  var valid_617608 = header.getOrDefault("X-Amz-Signature")
  valid_617608 = validateParameter(valid_617608, JString, required = false,
                                 default = nil)
  if valid_617608 != nil:
    section.add "X-Amz-Signature", valid_617608
  var valid_617609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617609 = validateParameter(valid_617609, JString, required = false,
                                 default = nil)
  if valid_617609 != nil:
    section.add "X-Amz-SignedHeaders", valid_617609
  var valid_617610 = header.getOrDefault("X-Amz-Credential")
  valid_617610 = validateParameter(valid_617610, JString, required = false,
                                 default = nil)
  if valid_617610 != nil:
    section.add "X-Amz-Credential", valid_617610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617611: Call_GetBootstrapBrokers_617600; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  let valid = call_617611.validator(path, query, header, formData, body, _)
  let scheme = call_617611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617611.url(scheme.get, call_617611.host, call_617611.base,
                         call_617611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617611, url, valid, _)

proc call*(call_617612: Call_GetBootstrapBrokers_617600; clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_617613 = newJObject()
  add(path_617613, "clusterArn", newJString(clusterArn))
  result = call_617612.call(path_617613, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_617600(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_617601, base: "/",
    url: url_GetBootstrapBrokers_617602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_617614 = ref object of OpenApiRestCall_616866
proc url_ListClusterOperations_617616(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListClusterOperations_617615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617617 = path.getOrDefault("clusterArn")
  valid_617617 = validateParameter(valid_617617, JString, required = true,
                                 default = nil)
  if valid_617617 != nil:
    section.add "clusterArn", valid_617617
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617618 = query.getOrDefault("maxResults")
  valid_617618 = validateParameter(valid_617618, JInt, required = false, default = nil)
  if valid_617618 != nil:
    section.add "maxResults", valid_617618
  var valid_617619 = query.getOrDefault("nextToken")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "nextToken", valid_617619
  var valid_617620 = query.getOrDefault("NextToken")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "NextToken", valid_617620
  var valid_617621 = query.getOrDefault("MaxResults")
  valid_617621 = validateParameter(valid_617621, JString, required = false,
                                 default = nil)
  if valid_617621 != nil:
    section.add "MaxResults", valid_617621
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
  var valid_617622 = header.getOrDefault("X-Amz-Date")
  valid_617622 = validateParameter(valid_617622, JString, required = false,
                                 default = nil)
  if valid_617622 != nil:
    section.add "X-Amz-Date", valid_617622
  var valid_617623 = header.getOrDefault("X-Amz-Security-Token")
  valid_617623 = validateParameter(valid_617623, JString, required = false,
                                 default = nil)
  if valid_617623 != nil:
    section.add "X-Amz-Security-Token", valid_617623
  var valid_617624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617624 = validateParameter(valid_617624, JString, required = false,
                                 default = nil)
  if valid_617624 != nil:
    section.add "X-Amz-Content-Sha256", valid_617624
  var valid_617625 = header.getOrDefault("X-Amz-Algorithm")
  valid_617625 = validateParameter(valid_617625, JString, required = false,
                                 default = nil)
  if valid_617625 != nil:
    section.add "X-Amz-Algorithm", valid_617625
  var valid_617626 = header.getOrDefault("X-Amz-Signature")
  valid_617626 = validateParameter(valid_617626, JString, required = false,
                                 default = nil)
  if valid_617626 != nil:
    section.add "X-Amz-Signature", valid_617626
  var valid_617627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617627 = validateParameter(valid_617627, JString, required = false,
                                 default = nil)
  if valid_617627 != nil:
    section.add "X-Amz-SignedHeaders", valid_617627
  var valid_617628 = header.getOrDefault("X-Amz-Credential")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Credential", valid_617628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617629: Call_ListClusterOperations_617614; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  let valid = call_617629.validator(path, query, header, formData, body, _)
  let scheme = call_617629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617629.url(scheme.get, call_617629.host, call_617629.base,
                         call_617629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617629, url, valid, _)

proc call*(call_617630: Call_ListClusterOperations_617614; clusterArn: string;
          maxResults: int = 0; nextToken: string = ""; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listClusterOperations
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var path_617631 = newJObject()
  var query_617632 = newJObject()
  add(query_617632, "maxResults", newJInt(maxResults))
  add(query_617632, "nextToken", newJString(nextToken))
  add(query_617632, "NextToken", newJString(NextToken))
  add(path_617631, "clusterArn", newJString(clusterArn))
  add(query_617632, "MaxResults", newJString(MaxResults))
  result = call_617630.call(path_617631, query_617632, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_617614(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_617615, base: "/",
    url: url_ListClusterOperations_617616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_617633 = ref object of OpenApiRestCall_616866
proc url_ListConfigurationRevisions_617635(protocol: Scheme; host: string;
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

proc validate_ListConfigurationRevisions_617634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617636 = path.getOrDefault("arn")
  valid_617636 = validateParameter(valid_617636, JString, required = true,
                                 default = nil)
  if valid_617636 != nil:
    section.add "arn", valid_617636
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617637 = query.getOrDefault("maxResults")
  valid_617637 = validateParameter(valid_617637, JInt, required = false, default = nil)
  if valid_617637 != nil:
    section.add "maxResults", valid_617637
  var valid_617638 = query.getOrDefault("nextToken")
  valid_617638 = validateParameter(valid_617638, JString, required = false,
                                 default = nil)
  if valid_617638 != nil:
    section.add "nextToken", valid_617638
  var valid_617639 = query.getOrDefault("NextToken")
  valid_617639 = validateParameter(valid_617639, JString, required = false,
                                 default = nil)
  if valid_617639 != nil:
    section.add "NextToken", valid_617639
  var valid_617640 = query.getOrDefault("MaxResults")
  valid_617640 = validateParameter(valid_617640, JString, required = false,
                                 default = nil)
  if valid_617640 != nil:
    section.add "MaxResults", valid_617640
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
  var valid_617641 = header.getOrDefault("X-Amz-Date")
  valid_617641 = validateParameter(valid_617641, JString, required = false,
                                 default = nil)
  if valid_617641 != nil:
    section.add "X-Amz-Date", valid_617641
  var valid_617642 = header.getOrDefault("X-Amz-Security-Token")
  valid_617642 = validateParameter(valid_617642, JString, required = false,
                                 default = nil)
  if valid_617642 != nil:
    section.add "X-Amz-Security-Token", valid_617642
  var valid_617643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617643 = validateParameter(valid_617643, JString, required = false,
                                 default = nil)
  if valid_617643 != nil:
    section.add "X-Amz-Content-Sha256", valid_617643
  var valid_617644 = header.getOrDefault("X-Amz-Algorithm")
  valid_617644 = validateParameter(valid_617644, JString, required = false,
                                 default = nil)
  if valid_617644 != nil:
    section.add "X-Amz-Algorithm", valid_617644
  var valid_617645 = header.getOrDefault("X-Amz-Signature")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Signature", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-SignedHeaders", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Credential")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Credential", valid_617647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617648: Call_ListConfigurationRevisions_617633;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_617648.validator(path, query, header, formData, body, _)
  let scheme = call_617648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617648.url(scheme.get, call_617648.host, call_617648.base,
                         call_617648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617648, url, valid, _)

proc call*(call_617649: Call_ListConfigurationRevisions_617633; arn: string;
          maxResults: int = 0; nextToken: string = ""; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listConfigurationRevisions
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var path_617650 = newJObject()
  var query_617651 = newJObject()
  add(path_617650, "arn", newJString(arn))
  add(query_617651, "maxResults", newJInt(maxResults))
  add(query_617651, "nextToken", newJString(nextToken))
  add(query_617651, "NextToken", newJString(NextToken))
  add(query_617651, "MaxResults", newJString(MaxResults))
  result = call_617649.call(path_617650, query_617651, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_617633(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_617634, base: "/",
    url: url_ListConfigurationRevisions_617635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKafkaVersions_617652 = ref object of OpenApiRestCall_616866
proc url_ListKafkaVersions_617654(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKafkaVersions_617653(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617655 = query.getOrDefault("maxResults")
  valid_617655 = validateParameter(valid_617655, JInt, required = false, default = nil)
  if valid_617655 != nil:
    section.add "maxResults", valid_617655
  var valid_617656 = query.getOrDefault("nextToken")
  valid_617656 = validateParameter(valid_617656, JString, required = false,
                                 default = nil)
  if valid_617656 != nil:
    section.add "nextToken", valid_617656
  var valid_617657 = query.getOrDefault("NextToken")
  valid_617657 = validateParameter(valid_617657, JString, required = false,
                                 default = nil)
  if valid_617657 != nil:
    section.add "NextToken", valid_617657
  var valid_617658 = query.getOrDefault("MaxResults")
  valid_617658 = validateParameter(valid_617658, JString, required = false,
                                 default = nil)
  if valid_617658 != nil:
    section.add "MaxResults", valid_617658
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
  var valid_617659 = header.getOrDefault("X-Amz-Date")
  valid_617659 = validateParameter(valid_617659, JString, required = false,
                                 default = nil)
  if valid_617659 != nil:
    section.add "X-Amz-Date", valid_617659
  var valid_617660 = header.getOrDefault("X-Amz-Security-Token")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Security-Token", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Content-Sha256", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Algorithm")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Algorithm", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Signature")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Signature", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-SignedHeaders", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-Credential")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-Credential", valid_617665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617666: Call_ListKafkaVersions_617652; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ## 
  let valid = call_617666.validator(path, query, header, formData, body, _)
  let scheme = call_617666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617666.url(scheme.get, call_617666.host, call_617666.base,
                         call_617666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617666, url, valid, _)

proc call*(call_617667: Call_ListKafkaVersions_617652; maxResults: int = 0;
          nextToken: string = ""; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listKafkaVersions
  ## 
  ##             <p>Returns a list of Kafka versions.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. To get the next batch, provide this token in your next request.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617668 = newJObject()
  add(query_617668, "maxResults", newJInt(maxResults))
  add(query_617668, "nextToken", newJString(nextToken))
  add(query_617668, "NextToken", newJString(NextToken))
  add(query_617668, "MaxResults", newJString(MaxResults))
  result = call_617667.call(nil, query_617668, nil, nil, nil)

var listKafkaVersions* = Call_ListKafkaVersions_617652(name: "listKafkaVersions",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/kafka-versions", validator: validate_ListKafkaVersions_617653,
    base: "/", url: url_ListKafkaVersions_617654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_617669 = ref object of OpenApiRestCall_616866
proc url_ListNodes_617671(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodes_617670(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617672 = path.getOrDefault("clusterArn")
  valid_617672 = validateParameter(valid_617672, JString, required = true,
                                 default = nil)
  if valid_617672 != nil:
    section.add "clusterArn", valid_617672
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: JString
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617673 = query.getOrDefault("maxResults")
  valid_617673 = validateParameter(valid_617673, JInt, required = false, default = nil)
  if valid_617673 != nil:
    section.add "maxResults", valid_617673
  var valid_617674 = query.getOrDefault("nextToken")
  valid_617674 = validateParameter(valid_617674, JString, required = false,
                                 default = nil)
  if valid_617674 != nil:
    section.add "nextToken", valid_617674
  var valid_617675 = query.getOrDefault("NextToken")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "NextToken", valid_617675
  var valid_617676 = query.getOrDefault("MaxResults")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "MaxResults", valid_617676
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
  var valid_617677 = header.getOrDefault("X-Amz-Date")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Date", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Security-Token")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Security-Token", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Content-Sha256", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-Algorithm")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-Algorithm", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Signature")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Signature", valid_617681
  var valid_617682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617682 = validateParameter(valid_617682, JString, required = false,
                                 default = nil)
  if valid_617682 != nil:
    section.add "X-Amz-SignedHeaders", valid_617682
  var valid_617683 = header.getOrDefault("X-Amz-Credential")
  valid_617683 = validateParameter(valid_617683, JString, required = false,
                                 default = nil)
  if valid_617683 != nil:
    section.add "X-Amz-Credential", valid_617683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617684: Call_ListNodes_617669; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_617684.validator(path, query, header, formData, body, _)
  let scheme = call_617684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617684.url(scheme.get, call_617684.host, call_617684.base,
                         call_617684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617684, url, valid, _)

proc call*(call_617685: Call_ListNodes_617669; clusterArn: string;
          maxResults: int = 0; nextToken: string = ""; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listNodes
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ##   maxResults: int
  ##             : 
  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##          
  ##   nextToken: string
  ##            : 
  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
  ##             To get the next batch, provide this token in your next request.</p>
  ##          
  ##   NextToken: string
  ##            : Pagination token
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  ##   MaxResults: string
  ##             : Pagination limit
  var path_617686 = newJObject()
  var query_617687 = newJObject()
  add(query_617687, "maxResults", newJInt(maxResults))
  add(query_617687, "nextToken", newJString(nextToken))
  add(query_617687, "NextToken", newJString(NextToken))
  add(path_617686, "clusterArn", newJString(clusterArn))
  add(query_617687, "MaxResults", newJString(MaxResults))
  result = call_617685.call(path_617686, query_617687, nil, nil, nil)

var listNodes* = Call_ListNodes_617669(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "kafka.amazonaws.com",
                                    route: "/v1/clusters/{clusterArn}/nodes",
                                    validator: validate_ListNodes_617670,
                                    base: "/", url: url_ListNodes_617671,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617702 = ref object of OpenApiRestCall_616866
proc url_TagResource_617704(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_617703(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617705 = path.getOrDefault("resourceArn")
  valid_617705 = validateParameter(valid_617705, JString, required = true,
                                 default = nil)
  if valid_617705 != nil:
    section.add "resourceArn", valid_617705
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
  var valid_617706 = header.getOrDefault("X-Amz-Date")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Date", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Security-Token")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Security-Token", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Content-Sha256", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Algorithm")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "X-Amz-Algorithm", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-Signature")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-Signature", valid_617710
  var valid_617711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617711 = validateParameter(valid_617711, JString, required = false,
                                 default = nil)
  if valid_617711 != nil:
    section.add "X-Amz-SignedHeaders", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Credential")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Credential", valid_617712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617714: Call_TagResource_617702; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  let valid = call_617714.validator(path, query, header, formData, body, _)
  let scheme = call_617714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617714.url(scheme.get, call_617714.host, call_617714.base,
                         call_617714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617714, url, valid, _)

proc call*(call_617715: Call_TagResource_617702; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_617716 = newJObject()
  var body_617717 = newJObject()
  if body != nil:
    body_617717 = body
  add(path_617716, "resourceArn", newJString(resourceArn))
  result = call_617715.call(path_617716, nil, nil, nil, body_617717)

var tagResource* = Call_TagResource_617702(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kafka.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_617703,
                                        base: "/", url: url_TagResource_617704,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617688 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617690(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_617689(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617691 = path.getOrDefault("resourceArn")
  valid_617691 = validateParameter(valid_617691, JString, required = true,
                                 default = nil)
  if valid_617691 != nil:
    section.add "resourceArn", valid_617691
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
  var valid_617692 = header.getOrDefault("X-Amz-Date")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Date", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Security-Token")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Security-Token", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Content-Sha256", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Algorithm")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Algorithm", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-Signature")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-Signature", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-SignedHeaders", valid_617697
  var valid_617698 = header.getOrDefault("X-Amz-Credential")
  valid_617698 = validateParameter(valid_617698, JString, required = false,
                                 default = nil)
  if valid_617698 != nil:
    section.add "X-Amz-Credential", valid_617698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617699: Call_ListTagsForResource_617688; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  let valid = call_617699.validator(path, query, header, formData, body, _)
  let scheme = call_617699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617699.url(scheme.get, call_617699.host, call_617699.base,
                         call_617699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617699, url, valid, _)

proc call*(call_617700: Call_ListTagsForResource_617688; resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_617701 = newJObject()
  add(path_617701, "resourceArn", newJString(resourceArn))
  result = call_617700.call(path_617701, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_617688(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_617689, base: "/",
    url: url_ListTagsForResource_617690, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617718 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617720(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_617719(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617721 = path.getOrDefault("resourceArn")
  valid_617721 = validateParameter(valid_617721, JString, required = true,
                                 default = nil)
  if valid_617721 != nil:
    section.add "resourceArn", valid_617721
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
  var valid_617722 = query.getOrDefault("tagKeys")
  valid_617722 = validateParameter(valid_617722, JArray, required = true, default = nil)
  if valid_617722 != nil:
    section.add "tagKeys", valid_617722
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
  var valid_617723 = header.getOrDefault("X-Amz-Date")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Date", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Security-Token")
  valid_617724 = validateParameter(valid_617724, JString, required = false,
                                 default = nil)
  if valid_617724 != nil:
    section.add "X-Amz-Security-Token", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-Content-Sha256", valid_617725
  var valid_617726 = header.getOrDefault("X-Amz-Algorithm")
  valid_617726 = validateParameter(valid_617726, JString, required = false,
                                 default = nil)
  if valid_617726 != nil:
    section.add "X-Amz-Algorithm", valid_617726
  var valid_617727 = header.getOrDefault("X-Amz-Signature")
  valid_617727 = validateParameter(valid_617727, JString, required = false,
                                 default = nil)
  if valid_617727 != nil:
    section.add "X-Amz-Signature", valid_617727
  var valid_617728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617728 = validateParameter(valid_617728, JString, required = false,
                                 default = nil)
  if valid_617728 != nil:
    section.add "X-Amz-SignedHeaders", valid_617728
  var valid_617729 = header.getOrDefault("X-Amz-Credential")
  valid_617729 = validateParameter(valid_617729, JString, required = false,
                                 default = nil)
  if valid_617729 != nil:
    section.add "X-Amz-Credential", valid_617729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617730: Call_UntagResource_617718; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  let valid = call_617730.validator(path, query, header, formData, body, _)
  let scheme = call_617730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617730.url(scheme.get, call_617730.host, call_617730.base,
                         call_617730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617730, url, valid, _)

proc call*(call_617731: Call_UntagResource_617718; tagKeys: JsonNode;
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
  var path_617732 = newJObject()
  var query_617733 = newJObject()
  if tagKeys != nil:
    query_617733.add "tagKeys", tagKeys
  add(path_617732, "resourceArn", newJString(resourceArn))
  result = call_617731.call(path_617732, query_617733, nil, nil, nil)

var untagResource* = Call_UntagResource_617718(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_617719,
    base: "/", url: url_UntagResource_617720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerCount_617734 = ref object of OpenApiRestCall_616866
proc url_UpdateBrokerCount_617736(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBrokerCount_617735(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617737 = path.getOrDefault("clusterArn")
  valid_617737 = validateParameter(valid_617737, JString, required = true,
                                 default = nil)
  if valid_617737 != nil:
    section.add "clusterArn", valid_617737
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
  var valid_617738 = header.getOrDefault("X-Amz-Date")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Date", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-Security-Token")
  valid_617739 = validateParameter(valid_617739, JString, required = false,
                                 default = nil)
  if valid_617739 != nil:
    section.add "X-Amz-Security-Token", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-Content-Sha256", valid_617740
  var valid_617741 = header.getOrDefault("X-Amz-Algorithm")
  valid_617741 = validateParameter(valid_617741, JString, required = false,
                                 default = nil)
  if valid_617741 != nil:
    section.add "X-Amz-Algorithm", valid_617741
  var valid_617742 = header.getOrDefault("X-Amz-Signature")
  valid_617742 = validateParameter(valid_617742, JString, required = false,
                                 default = nil)
  if valid_617742 != nil:
    section.add "X-Amz-Signature", valid_617742
  var valid_617743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617743 = validateParameter(valid_617743, JString, required = false,
                                 default = nil)
  if valid_617743 != nil:
    section.add "X-Amz-SignedHeaders", valid_617743
  var valid_617744 = header.getOrDefault("X-Amz-Credential")
  valid_617744 = validateParameter(valid_617744, JString, required = false,
                                 default = nil)
  if valid_617744 != nil:
    section.add "X-Amz-Credential", valid_617744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617746: Call_UpdateBrokerCount_617734; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_617746.validator(path, query, header, formData, body, _)
  let scheme = call_617746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617746.url(scheme.get, call_617746.host, call_617746.base,
                         call_617746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617746, url, valid, _)

proc call*(call_617747: Call_UpdateBrokerCount_617734; body: JsonNode;
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
  var path_617748 = newJObject()
  var body_617749 = newJObject()
  if body != nil:
    body_617749 = body
  add(path_617748, "clusterArn", newJString(clusterArn))
  result = call_617747.call(path_617748, nil, nil, nil, body_617749)

var updateBrokerCount* = Call_UpdateBrokerCount_617734(name: "updateBrokerCount",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes/count",
    validator: validate_UpdateBrokerCount_617735, base: "/",
    url: url_UpdateBrokerCount_617736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_617750 = ref object of OpenApiRestCall_616866
proc url_UpdateBrokerStorage_617752(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBrokerStorage_617751(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617753 = path.getOrDefault("clusterArn")
  valid_617753 = validateParameter(valid_617753, JString, required = true,
                                 default = nil)
  if valid_617753 != nil:
    section.add "clusterArn", valid_617753
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
  var valid_617754 = header.getOrDefault("X-Amz-Date")
  valid_617754 = validateParameter(valid_617754, JString, required = false,
                                 default = nil)
  if valid_617754 != nil:
    section.add "X-Amz-Date", valid_617754
  var valid_617755 = header.getOrDefault("X-Amz-Security-Token")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "X-Amz-Security-Token", valid_617755
  var valid_617756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617756 = validateParameter(valid_617756, JString, required = false,
                                 default = nil)
  if valid_617756 != nil:
    section.add "X-Amz-Content-Sha256", valid_617756
  var valid_617757 = header.getOrDefault("X-Amz-Algorithm")
  valid_617757 = validateParameter(valid_617757, JString, required = false,
                                 default = nil)
  if valid_617757 != nil:
    section.add "X-Amz-Algorithm", valid_617757
  var valid_617758 = header.getOrDefault("X-Amz-Signature")
  valid_617758 = validateParameter(valid_617758, JString, required = false,
                                 default = nil)
  if valid_617758 != nil:
    section.add "X-Amz-Signature", valid_617758
  var valid_617759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617759 = validateParameter(valid_617759, JString, required = false,
                                 default = nil)
  if valid_617759 != nil:
    section.add "X-Amz-SignedHeaders", valid_617759
  var valid_617760 = header.getOrDefault("X-Amz-Credential")
  valid_617760 = validateParameter(valid_617760, JString, required = false,
                                 default = nil)
  if valid_617760 != nil:
    section.add "X-Amz-Credential", valid_617760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617762: Call_UpdateBrokerStorage_617750; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  let valid = call_617762.validator(path, query, header, formData, body, _)
  let scheme = call_617762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617762.url(scheme.get, call_617762.host, call_617762.base,
                         call_617762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617762, url, valid, _)

proc call*(call_617763: Call_UpdateBrokerStorage_617750; body: JsonNode;
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
  var path_617764 = newJObject()
  var body_617765 = newJObject()
  if body != nil:
    body_617765 = body
  add(path_617764, "clusterArn", newJString(clusterArn))
  result = call_617763.call(path_617764, nil, nil, nil, body_617765)

var updateBrokerStorage* = Call_UpdateBrokerStorage_617750(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_617751, base: "/",
    url: url_UpdateBrokerStorage_617752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_617766 = ref object of OpenApiRestCall_616866
proc url_UpdateClusterConfiguration_617768(protocol: Scheme; host: string;
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

proc validate_UpdateClusterConfiguration_617767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617769 = path.getOrDefault("clusterArn")
  valid_617769 = validateParameter(valid_617769, JString, required = true,
                                 default = nil)
  if valid_617769 != nil:
    section.add "clusterArn", valid_617769
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
  var valid_617770 = header.getOrDefault("X-Amz-Date")
  valid_617770 = validateParameter(valid_617770, JString, required = false,
                                 default = nil)
  if valid_617770 != nil:
    section.add "X-Amz-Date", valid_617770
  var valid_617771 = header.getOrDefault("X-Amz-Security-Token")
  valid_617771 = validateParameter(valid_617771, JString, required = false,
                                 default = nil)
  if valid_617771 != nil:
    section.add "X-Amz-Security-Token", valid_617771
  var valid_617772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617772 = validateParameter(valid_617772, JString, required = false,
                                 default = nil)
  if valid_617772 != nil:
    section.add "X-Amz-Content-Sha256", valid_617772
  var valid_617773 = header.getOrDefault("X-Amz-Algorithm")
  valid_617773 = validateParameter(valid_617773, JString, required = false,
                                 default = nil)
  if valid_617773 != nil:
    section.add "X-Amz-Algorithm", valid_617773
  var valid_617774 = header.getOrDefault("X-Amz-Signature")
  valid_617774 = validateParameter(valid_617774, JString, required = false,
                                 default = nil)
  if valid_617774 != nil:
    section.add "X-Amz-Signature", valid_617774
  var valid_617775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617775 = validateParameter(valid_617775, JString, required = false,
                                 default = nil)
  if valid_617775 != nil:
    section.add "X-Amz-SignedHeaders", valid_617775
  var valid_617776 = header.getOrDefault("X-Amz-Credential")
  valid_617776 = validateParameter(valid_617776, JString, required = false,
                                 default = nil)
  if valid_617776 != nil:
    section.add "X-Amz-Credential", valid_617776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617778: Call_UpdateClusterConfiguration_617766;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  let valid = call_617778.validator(path, query, header, formData, body, _)
  let scheme = call_617778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617778.url(scheme.get, call_617778.host, call_617778.base,
                         call_617778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617778, url, valid, _)

proc call*(call_617779: Call_UpdateClusterConfiguration_617766; body: JsonNode;
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
  var path_617780 = newJObject()
  var body_617781 = newJObject()
  if body != nil:
    body_617781 = body
  add(path_617780, "clusterArn", newJString(clusterArn))
  result = call_617779.call(path_617780, nil, nil, nil, body_617781)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_617766(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_617767, base: "/",
    url: url_UpdateClusterConfiguration_617768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoring_617782 = ref object of OpenApiRestCall_616866
proc url_UpdateMonitoring_617784(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMonitoring_617783(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617785 = path.getOrDefault("clusterArn")
  valid_617785 = validateParameter(valid_617785, JString, required = true,
                                 default = nil)
  if valid_617785 != nil:
    section.add "clusterArn", valid_617785
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
  var valid_617786 = header.getOrDefault("X-Amz-Date")
  valid_617786 = validateParameter(valid_617786, JString, required = false,
                                 default = nil)
  if valid_617786 != nil:
    section.add "X-Amz-Date", valid_617786
  var valid_617787 = header.getOrDefault("X-Amz-Security-Token")
  valid_617787 = validateParameter(valid_617787, JString, required = false,
                                 default = nil)
  if valid_617787 != nil:
    section.add "X-Amz-Security-Token", valid_617787
  var valid_617788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617788 = validateParameter(valid_617788, JString, required = false,
                                 default = nil)
  if valid_617788 != nil:
    section.add "X-Amz-Content-Sha256", valid_617788
  var valid_617789 = header.getOrDefault("X-Amz-Algorithm")
  valid_617789 = validateParameter(valid_617789, JString, required = false,
                                 default = nil)
  if valid_617789 != nil:
    section.add "X-Amz-Algorithm", valid_617789
  var valid_617790 = header.getOrDefault("X-Amz-Signature")
  valid_617790 = validateParameter(valid_617790, JString, required = false,
                                 default = nil)
  if valid_617790 != nil:
    section.add "X-Amz-Signature", valid_617790
  var valid_617791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617791 = validateParameter(valid_617791, JString, required = false,
                                 default = nil)
  if valid_617791 != nil:
    section.add "X-Amz-SignedHeaders", valid_617791
  var valid_617792 = header.getOrDefault("X-Amz-Credential")
  valid_617792 = validateParameter(valid_617792, JString, required = false,
                                 default = nil)
  if valid_617792 != nil:
    section.add "X-Amz-Credential", valid_617792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617794: Call_UpdateMonitoring_617782; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## 
  ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
  ##          
  ## 
  let valid = call_617794.validator(path, query, header, formData, body, _)
  let scheme = call_617794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617794.url(scheme.get, call_617794.host, call_617794.base,
                         call_617794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617794, url, valid, _)

proc call*(call_617795: Call_UpdateMonitoring_617782; body: JsonNode;
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
  var path_617796 = newJObject()
  var body_617797 = newJObject()
  if body != nil:
    body_617797 = body
  add(path_617796, "clusterArn", newJString(clusterArn))
  result = call_617795.call(path_617796, nil, nil, nil, body_617797)

var updateMonitoring* = Call_UpdateMonitoring_617782(name: "updateMonitoring",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/monitoring",
    validator: validate_UpdateMonitoring_617783, base: "/",
    url: url_UpdateMonitoring_617784, schemes: {Scheme.Https, Scheme.Http})
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
