
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "kafka.ap-northeast-1.amazonaws.com", "ap-southeast-1": "kafka.ap-southeast-1.amazonaws.com",
                               "us-west-2": "kafka.us-west-2.amazonaws.com",
                               "eu-west-2": "kafka.eu-west-2.amazonaws.com", "ap-northeast-3": "kafka.ap-northeast-3.amazonaws.com", "eu-central-1": "kafka.eu-central-1.amazonaws.com",
                               "us-east-2": "kafka.us-east-2.amazonaws.com",
                               "us-east-1": "kafka.us-east-1.amazonaws.com", "cn-northwest-1": "kafka.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "kafka.ap-south-1.amazonaws.com",
                               "eu-north-1": "kafka.eu-north-1.amazonaws.com", "ap-northeast-2": "kafka.ap-northeast-2.amazonaws.com",
                               "us-west-1": "kafka.us-west-1.amazonaws.com", "us-gov-east-1": "kafka.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "kafka.eu-west-3.amazonaws.com", "cn-north-1": "kafka.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "kafka.sa-east-1.amazonaws.com",
                               "eu-west-1": "kafka.eu-west-1.amazonaws.com", "us-gov-west-1": "kafka.us-gov-west-1.amazonaws.com", "ap-southeast-2": "kafka.ap-southeast-2.amazonaws.com", "ca-central-1": "kafka.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateCluster_402656480 = ref object of OpenApiRestCall_402656044
proc url_CreateCluster_402656482(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_402656481(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Security-Token", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Signature")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Signature", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Algorithm", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Date")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Date", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Credential")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Credential", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656489
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

proc call*(call_402656491: Call_CreateCluster_402656480; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Creates a new MSK cluster.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656491.validator(path, query, header, formData, body, _)
  let scheme = call_402656491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656491.makeUrl(scheme.get, call_402656491.host, call_402656491.base,
                                   call_402656491.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656491, uri, valid, _)

proc call*(call_402656492: Call_CreateCluster_402656480; body: JsonNode): Recallable =
  ## createCluster
  ## 
                  ##             <p>Creates a new MSK cluster.</p>
                  ##          
  ##   body: JObject (required)
  var body_402656493 = newJObject()
  if body != nil:
    body_402656493 = body
  result = call_402656492.call(nil, nil, nil, nil, body_402656493)

var createCluster* = Call_CreateCluster_402656480(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com",
    route: "/v1/clusters", validator: validate_CreateCluster_402656481,
    base: "/", makeUrl: url_CreateCluster_402656482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListClusters_402656296(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_402656295(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
                                                          ##             <p>The 
                                                          ## paginated 
                                                          ## results marker. When the result of the operation is 
                                                          ## truncated, 
                                                          ## the call returns 
                                                          ## NextToken in 
                                                          ## the 
                                                          ## response. 
                                                          ##             To get the next batch, provide this token in your next 
                                                          ## request.</p>
                                                          ##          
  ##   
                                                                      ## MaxResults: JString
                                                                      ##             
                                                                      ## : 
                                                                      ## Pagination limit
  ##   
                                                                                         ## NextToken: JString
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Pagination 
                                                                                         ## token
  section = newJObject()
  var valid_402656378 = query.getOrDefault("clusterNameFilter")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "clusterNameFilter", valid_402656378
  var valid_402656379 = query.getOrDefault("maxResults")
  valid_402656379 = validateParameter(valid_402656379, JInt, required = false,
                                      default = nil)
  if valid_402656379 != nil:
    section.add "maxResults", valid_402656379
  var valid_402656380 = query.getOrDefault("nextToken")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "nextToken", valid_402656380
  var valid_402656381 = query.getOrDefault("MaxResults")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "MaxResults", valid_402656381
  var valid_402656382 = query.getOrDefault("NextToken")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "NextToken", valid_402656382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656383 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Security-Token", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Signature")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Signature", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Algorithm", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Date")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Date", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Credential")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Credential", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656403: Call_ListClusters_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656403.validator(path, query, header, formData, body, _)
  let scheme = call_402656403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656403.makeUrl(scheme.get, call_402656403.host, call_402656403.base,
                                   call_402656403.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656403, uri, valid, _)

proc call*(call_402656452: Call_ListClusters_402656294;
           clusterNameFilter: string = ""; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
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
                                                     ##             
                                                     ## To get the next batch, provide this token in your next request.</p>
                                                     ##          
  ##   MaxResults: string
                                                                 ##             : Pagination limit
  ##   
                                                                                                  ## NextToken: string
                                                                                                  ##            
                                                                                                  ## : 
                                                                                                  ## Pagination 
                                                                                                  ## token
  var query_402656453 = newJObject()
  add(query_402656453, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_402656453, "maxResults", newJInt(maxResults))
  add(query_402656453, "nextToken", newJString(nextToken))
  add(query_402656453, "MaxResults", newJString(MaxResults))
  add(query_402656453, "NextToken", newJString(NextToken))
  result = call_402656452.call(nil, query_402656453, nil, nil, nil)

var listClusters* = Call_ListClusters_402656294(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters", validator: validate_ListClusters_402656295,
    base: "/", makeUrl: url_ListClusters_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_402656511 = ref object of OpenApiRestCall_402656044
proc url_CreateConfiguration_402656513(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfiguration_402656512(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
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

proc call*(call_402656522: Call_CreateConfiguration_402656511;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Creates a new MSK configuration.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_CreateConfiguration_402656511; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
                        ##             <p>Creates a new MSK configuration.</p>
                        ##          
  ##   body: JObject (required)
  var body_402656524 = newJObject()
  if body != nil:
    body_402656524 = body
  result = call_402656523.call(nil, nil, nil, nil, body_402656524)

var createConfiguration* = Call_CreateConfiguration_402656511(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_402656512, base: "/",
    makeUrl: url_CreateConfiguration_402656513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_402656494 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurations_402656496(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_402656495(path: JsonNode; query: JsonNode;
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
  ##   maxResults: JInt
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                  ##          
  ##   nextToken: JString
                                              ##            : 
                                              ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
                                              ##             
                                              ## To get the next batch, provide this token in your next request.</p>
                                              ##          
  ##   MaxResults: JString
                                                          ##             : Pagination limit
  ##   
                                                                                           ## NextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  section = newJObject()
  var valid_402656497 = query.getOrDefault("maxResults")
  valid_402656497 = validateParameter(valid_402656497, JInt, required = false,
                                      default = nil)
  if valid_402656497 != nil:
    section.add "maxResults", valid_402656497
  var valid_402656498 = query.getOrDefault("nextToken")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "nextToken", valid_402656498
  var valid_402656499 = query.getOrDefault("MaxResults")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "MaxResults", valid_402656499
  var valid_402656500 = query.getOrDefault("NextToken")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "NextToken", valid_402656500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Security-Token", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Signature")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Signature", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Algorithm", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Date")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Date", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Credential")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Credential", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656508: Call_ListConfigurations_402656494;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of all the MSK configurations in this Region.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656508.validator(path, query, header, formData, body, _)
  let scheme = call_402656508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656508.makeUrl(scheme.get, call_402656508.host, call_402656508.base,
                                   call_402656508.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656508, uri, valid, _)

proc call*(call_402656509: Call_ListConfigurations_402656494;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
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
                                               ##             
                                               ## To get the next batch, provide this token in your next request.</p>
                                               ##          
  ##   MaxResults: string
                                                           ##             : Pagination limit
  ##   
                                                                                            ## NextToken: string
                                                                                            ##            
                                                                                            ## : 
                                                                                            ## Pagination 
                                                                                            ## token
  var query_402656510 = newJObject()
  add(query_402656510, "maxResults", newJInt(maxResults))
  add(query_402656510, "nextToken", newJString(nextToken))
  add(query_402656510, "MaxResults", newJString(MaxResults))
  add(query_402656510, "NextToken", newJString(NextToken))
  result = call_402656509.call(nil, query_402656510, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_402656494(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_402656495, base: "/",
    makeUrl: url_ListConfigurations_402656496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_402656525 = ref object of OpenApiRestCall_402656044
proc url_DescribeCluster_402656527(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
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

proc validate_DescribeCluster_402656526(path: JsonNode; query: JsonNode;
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
  var valid_402656539 = path.getOrDefault("clusterArn")
  valid_402656539 = validateParameter(valid_402656539, JString, required = true,
                                      default = nil)
  if valid_402656539 != nil:
    section.add "clusterArn", valid_402656539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656547: Call_DescribeCluster_402656525; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656547.validator(path, query, header, formData, body, _)
  let scheme = call_402656547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656547.makeUrl(scheme.get, call_402656547.host, call_402656547.base,
                                   call_402656547.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656547, uri, valid, _)

proc call*(call_402656548: Call_DescribeCluster_402656525; clusterArn: string): Recallable =
  ## describeCluster
  ## 
                    ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
                    ##          
  ##   clusterArn: string (required)
                                ##             : 
                                ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                ##          
  var path_402656549 = newJObject()
  add(path_402656549, "clusterArn", newJString(clusterArn))
  result = call_402656548.call(path_402656549, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_402656525(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_402656526,
    base: "/", makeUrl: url_DescribeCluster_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_402656550 = ref object of OpenApiRestCall_402656044
proc url_DeleteCluster_402656552(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_402656551(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656553 = path.getOrDefault("clusterArn")
  valid_402656553 = validateParameter(valid_402656553, JString, required = true,
                                      default = nil)
  if valid_402656553 != nil:
    section.add "clusterArn", valid_402656553
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
                                  ##                 : 
                                  ##             <p>The current version of the MSK cluster.</p>
                                  ##          
  section = newJObject()
  var valid_402656554 = query.getOrDefault("currentVersion")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "currentVersion", valid_402656554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656555 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Security-Token", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Signature")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Signature", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Algorithm", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Date")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Date", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Credential")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Credential", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656562: Call_DeleteCluster_402656550; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656562.validator(path, query, header, formData, body, _)
  let scheme = call_402656562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656562.makeUrl(scheme.get, call_402656562.host, call_402656562.base,
                                   call_402656562.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656562, uri, valid, _)

proc call*(call_402656563: Call_DeleteCluster_402656550; clusterArn: string;
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
  var path_402656564 = newJObject()
  var query_402656565 = newJObject()
  add(query_402656565, "currentVersion", newJString(currentVersion))
  add(path_402656564, "clusterArn", newJString(clusterArn))
  result = call_402656563.call(path_402656564, query_402656565, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_402656550(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_402656551,
    base: "/", makeUrl: url_DeleteCluster_402656552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_402656566 = ref object of OpenApiRestCall_402656044
proc url_DescribeClusterOperation_402656568(protocol: Scheme; host: string;
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

proc validate_DescribeClusterOperation_402656567(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656569 = path.getOrDefault("clusterOperationArn")
  valid_402656569 = validateParameter(valid_402656569, JString, required = true,
                                      default = nil)
  if valid_402656569 != nil:
    section.add "clusterOperationArn", valid_402656569
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656570 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Security-Token", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Signature")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Signature", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Algorithm", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Date")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Date", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Credential")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Credential", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656577: Call_DescribeClusterOperation_402656566;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656577.validator(path, query, header, formData, body, _)
  let scheme = call_402656577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656577.makeUrl(scheme.get, call_402656577.host, call_402656577.base,
                                   call_402656577.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656577, uri, valid, _)

proc call*(call_402656578: Call_DescribeClusterOperation_402656566;
           clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
                             ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
                             ##          
  ##   clusterOperationArn: string (required)
                                         ##                      : 
                                         ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster 
                                         ## operation.</p>
                                         ##          
  var path_402656579 = newJObject()
  add(path_402656579, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_402656578.call(path_402656579, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_402656566(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_402656567, base: "/",
    makeUrl: url_DescribeClusterOperation_402656568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_402656580 = ref object of OpenApiRestCall_402656044
proc url_DescribeConfiguration_402656582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeConfiguration_402656581(path: JsonNode; query: JsonNode;
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
  var valid_402656583 = path.getOrDefault("arn")
  valid_402656583 = validateParameter(valid_402656583, JString, required = true,
                                      default = nil)
  if valid_402656583 != nil:
    section.add "arn", valid_402656583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656584 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Security-Token", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Signature")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Signature", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Algorithm", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Date")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Date", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Credential")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Credential", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_DescribeConfiguration_402656580;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a description of this MSK configuration.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DescribeConfiguration_402656580; arn: string): Recallable =
  ## describeConfiguration
  ## 
                          ##             <p>Returns a description of this MSK configuration.</p>
                          ##          
  ##   arn: string (required)
                                      ##      : 
                                      ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
                                      ##          
  var path_402656593 = newJObject()
  add(path_402656593, "arn", newJString(arn))
  result = call_402656592.call(path_402656593, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_402656580(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_402656581, base: "/",
    makeUrl: url_DescribeConfiguration_402656582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_402656594 = ref object of OpenApiRestCall_402656044
proc url_DescribeConfigurationRevision_402656596(protocol: Scheme; host: string;
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

proc validate_DescribeConfigurationRevision_402656595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## 
                                            ##             <p>Returns a description of this revision of the configuration.</p>
                                            ##          
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   revision: JInt (required)
                                 ##           : 
                                 ##             <p>A string that uniquely identifies a revision of an MSK configuration.</p>
                                 ##          
  ##   arn: JString (required)
                                             ##      : 
                                             ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
                                             ##          
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `revision` field"
  var valid_402656597 = path.getOrDefault("revision")
  valid_402656597 = validateParameter(valid_402656597, JInt, required = true,
                                      default = nil)
  if valid_402656597 != nil:
    section.add "revision", valid_402656597
  var valid_402656598 = path.getOrDefault("arn")
  valid_402656598 = validateParameter(valid_402656598, JString, required = true,
                                      default = nil)
  if valid_402656598 != nil:
    section.add "arn", valid_402656598
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656599 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Security-Token", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Signature")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Signature", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Algorithm", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Date")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Date", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Credential")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Credential", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_DescribeConfigurationRevision_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a description of this revision of the configuration.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DescribeConfigurationRevision_402656594;
           revision: int; arn: string): Recallable =
  ## describeConfigurationRevision
  ## 
                                  ##             <p>Returns a description of this revision of the configuration.</p>
                                  ##          
  ##   revision: int (required)
                                              ##           : 
                                              ##             <p>A string that uniquely identifies a revision of an MSK configuration.</p>
                                              ##          
  ##   arn: string (required)
                                                          ##      : 
                                                          ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK 
                                                          ## configuration 
                                                          ## and all of its 
                                                          ## revisions.</p>
                                                          ##          
  var path_402656608 = newJObject()
  add(path_402656608, "revision", newJInt(revision))
  add(path_402656608, "arn", newJString(arn))
  result = call_402656607.call(path_402656608, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_402656594(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_402656595, base: "/",
    makeUrl: url_DescribeConfigurationRevision_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_402656609 = ref object of OpenApiRestCall_402656044
proc url_GetBootstrapBrokers_402656611(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetBootstrapBrokers_402656610(path: JsonNode; query: JsonNode;
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
  var valid_402656612 = path.getOrDefault("clusterArn")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true,
                                      default = nil)
  if valid_402656612 != nil:
    section.add "clusterArn", valid_402656612
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656620: Call_GetBootstrapBrokers_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>A list of brokers that a client application can use to bootstrap.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656620.validator(path, query, header, formData, body, _)
  let scheme = call_402656620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656620.makeUrl(scheme.get, call_402656620.host, call_402656620.base,
                                   call_402656620.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656620, uri, valid, _)

proc call*(call_402656621: Call_GetBootstrapBrokers_402656609;
           clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
                        ##             <p>A list of brokers that a client application can use to bootstrap.</p>
                        ##          
  ##   clusterArn: string (required)
                                    ##             : 
                                    ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                    ##          
  var path_402656622 = newJObject()
  add(path_402656622, "clusterArn", newJString(clusterArn))
  result = call_402656621.call(path_402656622, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_402656609(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_402656610, base: "/",
    makeUrl: url_GetBootstrapBrokers_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_402656623 = ref object of OpenApiRestCall_402656044
proc url_ListClusterOperations_402656625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListClusterOperations_402656624(path: JsonNode; query: JsonNode;
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
  var valid_402656626 = path.getOrDefault("clusterArn")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true,
                                      default = nil)
  if valid_402656626 != nil:
    section.add "clusterArn", valid_402656626
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                  ##          
  ##   nextToken: JString
                                              ##            : 
                                              ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
                                              ##             
                                              ## To get the next batch, provide this token in your next request.</p>
                                              ##          
  ##   MaxResults: JString
                                                          ##             : Pagination limit
  ##   
                                                                                           ## NextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  section = newJObject()
  var valid_402656627 = query.getOrDefault("maxResults")
  valid_402656627 = validateParameter(valid_402656627, JInt, required = false,
                                      default = nil)
  if valid_402656627 != nil:
    section.add "maxResults", valid_402656627
  var valid_402656628 = query.getOrDefault("nextToken")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "nextToken", valid_402656628
  var valid_402656629 = query.getOrDefault("MaxResults")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "MaxResults", valid_402656629
  var valid_402656630 = query.getOrDefault("NextToken")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "NextToken", valid_402656630
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656638: Call_ListClusterOperations_402656623;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656638.validator(path, query, header, formData, body, _)
  let scheme = call_402656638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656638.makeUrl(scheme.get, call_402656638.host, call_402656638.base,
                                   call_402656638.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656638, uri, valid, _)

proc call*(call_402656639: Call_ListClusterOperations_402656623;
           clusterArn: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listClusterOperations
  ## 
                          ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
                          ##          
  ##   maxResults: int
                                      ##             : 
                                      ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                      ##          
  ##   clusterArn: string (required)
                                                  ##             : 
                                                  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                                  ##          
  ##   nextToken: string
                                                              ##            : 
                                                              ##             
                                                              ## <p>The 
                                                              ## paginated results marker. When the result of the 
                                                              ## operation 
                                                              ## is 
                                                              ## truncated, the call returns NextToken in the response. 
                                                              ##             
                                                              ## To get the 
                                                              ## next 
                                                              ## batch, provide this token in your next 
                                                              ## request.</p>
                                                              ##          
  ##   
                                                                          ## MaxResults: string
                                                                          ##             
                                                                          ## : 
                                                                          ## Pagination 
                                                                          ## limit
  ##   
                                                                                  ## NextToken: string
                                                                                  ##            
                                                                                  ## : 
                                                                                  ## Pagination 
                                                                                  ## token
  var path_402656640 = newJObject()
  var query_402656641 = newJObject()
  add(query_402656641, "maxResults", newJInt(maxResults))
  add(path_402656640, "clusterArn", newJString(clusterArn))
  add(query_402656641, "nextToken", newJString(nextToken))
  add(query_402656641, "MaxResults", newJString(MaxResults))
  add(query_402656641, "NextToken", newJString(NextToken))
  result = call_402656639.call(path_402656640, query_402656641, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_402656623(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_402656624, base: "/",
    makeUrl: url_ListClusterOperations_402656625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_402656642 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurationRevisions_402656644(protocol: Scheme; host: string;
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

proc validate_ListConfigurationRevisions_402656643(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656645 = path.getOrDefault("arn")
  valid_402656645 = validateParameter(valid_402656645, JString, required = true,
                                      default = nil)
  if valid_402656645 != nil:
    section.add "arn", valid_402656645
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                  ##          
  ##   nextToken: JString
                                              ##            : 
                                              ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
                                              ##             
                                              ## To get the next batch, provide this token in your next request.</p>
                                              ##          
  ##   MaxResults: JString
                                                          ##             : Pagination limit
  ##   
                                                                                           ## NextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  section = newJObject()
  var valid_402656646 = query.getOrDefault("maxResults")
  valid_402656646 = validateParameter(valid_402656646, JInt, required = false,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "maxResults", valid_402656646
  var valid_402656647 = query.getOrDefault("nextToken")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "nextToken", valid_402656647
  var valid_402656648 = query.getOrDefault("MaxResults")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "MaxResults", valid_402656648
  var valid_402656649 = query.getOrDefault("NextToken")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "NextToken", valid_402656649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656650 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Security-Token", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Signature")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Signature", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Algorithm", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Date")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Date", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Credential")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Credential", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656657: Call_ListConfigurationRevisions_402656642;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of all the MSK configurations in this Region.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656657.validator(path, query, header, formData, body, _)
  let scheme = call_402656657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656657.makeUrl(scheme.get, call_402656657.host, call_402656657.base,
                                   call_402656657.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656657, uri, valid, _)

proc call*(call_402656658: Call_ListConfigurationRevisions_402656642;
           arn: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConfigurationRevisions
  ## 
                               ##             <p>Returns a list of all the MSK configurations in this Region.</p>
                               ##          
  ##   maxResults: int
                                           ##             : 
                                           ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                           ##          
  ##   nextToken: string
                                                       ##            : 
                                                       ##             <p>The paginated results marker. When the result of the operation is 
                                                       ## truncated, 
                                                       ## the call returns NextToken in the response. 
                                                       ##             
                                                       ## To get the next batch, provide this token in your next 
                                                       ## request.</p>
                                                       ##          
  ##   MaxResults: string
                                                                   ##             : Pagination limit
  ##   
                                                                                                    ## NextToken: string
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## Pagination 
                                                                                                    ## token
  ##   
                                                                                                            ## arn: string (required)
                                                                                                            ##      
                                                                                                            ## : 
                                                                                                            ##             
                                                                                                            ## <p>The 
                                                                                                            ## Amazon 
                                                                                                            ## Resource 
                                                                                                            ## Name 
                                                                                                            ## (ARN) 
                                                                                                            ## that 
                                                                                                            ## uniquely 
                                                                                                            ## identifies 
                                                                                                            ## an 
                                                                                                            ## MSK 
                                                                                                            ## configuration 
                                                                                                            ## and 
                                                                                                            ## all 
                                                                                                            ## of 
                                                                                                            ## its 
                                                                                                            ## revisions.</p>
                                                                                                            ##          
  var path_402656659 = newJObject()
  var query_402656660 = newJObject()
  add(query_402656660, "maxResults", newJInt(maxResults))
  add(query_402656660, "nextToken", newJString(nextToken))
  add(query_402656660, "MaxResults", newJString(MaxResults))
  add(query_402656660, "NextToken", newJString(NextToken))
  add(path_402656659, "arn", newJString(arn))
  result = call_402656658.call(path_402656659, query_402656660, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_402656642(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_402656643, base: "/",
    makeUrl: url_ListConfigurationRevisions_402656644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListKafkaVersions_402656661 = ref object of OpenApiRestCall_402656044
proc url_ListKafkaVersions_402656663(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListKafkaVersions_402656662(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   maxResults: JInt
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   
                                                                                                                                                                                        ## nextToken: JString
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ##             
                                                                                                                                                                                        ## <p>The 
                                                                                                                                                                                        ## paginated 
                                                                                                                                                                                        ## results 
                                                                                                                                                                                        ## marker. 
                                                                                                                                                                                        ## When 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## result 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## operation 
                                                                                                                                                                                        ## is 
                                                                                                                                                                                        ## truncated, 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## call 
                                                                                                                                                                                        ## returns 
                                                                                                                                                                                        ## NextToken 
                                                                                                                                                                                        ## in 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## response. 
                                                                                                                                                                                        ## To 
                                                                                                                                                                                        ## get 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## batch, 
                                                                                                                                                                                        ## provide 
                                                                                                                                                                                        ## this 
                                                                                                                                                                                        ## token 
                                                                                                                                                                                        ## in 
                                                                                                                                                                                        ## your 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## request.</p>
  ##   
                                                                                                                                                                                                       ## MaxResults: JString
                                                                                                                                                                                                       ##             
                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                               ## NextToken: JString
                                                                                                                                                                                                               ##            
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                               ## token
  section = newJObject()
  var valid_402656664 = query.getOrDefault("maxResults")
  valid_402656664 = validateParameter(valid_402656664, JInt, required = false,
                                      default = nil)
  if valid_402656664 != nil:
    section.add "maxResults", valid_402656664
  var valid_402656665 = query.getOrDefault("nextToken")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "nextToken", valid_402656665
  var valid_402656666 = query.getOrDefault("MaxResults")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "MaxResults", valid_402656666
  var valid_402656667 = query.getOrDefault("NextToken")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "NextToken", valid_402656667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656675: Call_ListKafkaVersions_402656661;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of Kafka versions.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_ListKafkaVersions_402656661;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listKafkaVersions
  ## 
                      ##             <p>Returns a list of Kafka versions.</p>
                      ##          
  ##   maxResults: int
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
  ##   
                                                                                                                                                                                        ## nextToken: string
                                                                                                                                                                                        ##            
                                                                                                                                                                                        ## : 
                                                                                                                                                                                        ##             
                                                                                                                                                                                        ## <p>The 
                                                                                                                                                                                        ## paginated 
                                                                                                                                                                                        ## results 
                                                                                                                                                                                        ## marker. 
                                                                                                                                                                                        ## When 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## result 
                                                                                                                                                                                        ## of 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## operation 
                                                                                                                                                                                        ## is 
                                                                                                                                                                                        ## truncated, 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## call 
                                                                                                                                                                                        ## returns 
                                                                                                                                                                                        ## NextToken 
                                                                                                                                                                                        ## in 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## response. 
                                                                                                                                                                                        ## To 
                                                                                                                                                                                        ## get 
                                                                                                                                                                                        ## the 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## batch, 
                                                                                                                                                                                        ## provide 
                                                                                                                                                                                        ## this 
                                                                                                                                                                                        ## token 
                                                                                                                                                                                        ## in 
                                                                                                                                                                                        ## your 
                                                                                                                                                                                        ## next 
                                                                                                                                                                                        ## request.</p>
  ##   
                                                                                                                                                                                                       ## MaxResults: string
                                                                                                                                                                                                       ##             
                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                               ##            
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                               ## token
  var query_402656677 = newJObject()
  add(query_402656677, "maxResults", newJInt(maxResults))
  add(query_402656677, "nextToken", newJString(nextToken))
  add(query_402656677, "MaxResults", newJString(MaxResults))
  add(query_402656677, "NextToken", newJString(NextToken))
  result = call_402656676.call(nil, query_402656677, nil, nil, nil)

var listKafkaVersions* = Call_ListKafkaVersions_402656661(
    name: "listKafkaVersions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/kafka-versions",
    validator: validate_ListKafkaVersions_402656662, base: "/",
    makeUrl: url_ListKafkaVersions_402656663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_402656678 = ref object of OpenApiRestCall_402656044
proc url_ListNodes_402656680(protocol: Scheme; host: string; base: string;
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

proc validate_ListNodes_402656679(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656681 = path.getOrDefault("clusterArn")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "clusterArn", valid_402656681
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : 
                                  ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                                  ##          
  ##   nextToken: JString
                                              ##            : 
                                              ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
                                              ##             
                                              ## To get the next batch, provide this token in your next request.</p>
                                              ##          
  ##   MaxResults: JString
                                                          ##             : Pagination limit
  ##   
                                                                                           ## NextToken: JString
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  section = newJObject()
  var valid_402656682 = query.getOrDefault("maxResults")
  valid_402656682 = validateParameter(valid_402656682, JInt, required = false,
                                      default = nil)
  if valid_402656682 != nil:
    section.add "maxResults", valid_402656682
  var valid_402656683 = query.getOrDefault("nextToken")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "nextToken", valid_402656683
  var valid_402656684 = query.getOrDefault("MaxResults")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "MaxResults", valid_402656684
  var valid_402656685 = query.getOrDefault("NextToken")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "NextToken", valid_402656685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656686 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Security-Token", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Signature")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Signature", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Algorithm", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Date")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Date", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Credential")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Credential", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656693: Call_ListNodes_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of the broker nodes in the cluster.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656693.validator(path, query, header, formData, body, _)
  let scheme = call_402656693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656693.makeUrl(scheme.get, call_402656693.host, call_402656693.base,
                                   call_402656693.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656693, uri, valid, _)

proc call*(call_402656694: Call_ListNodes_402656678; clusterArn: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listNodes
  ## 
              ##             <p>Returns a list of the broker nodes in the cluster.</p>
              ##          
  ##   maxResults: int
                          ##             : 
                          ##             <p>The maximum number of results to return in the response. If there are more results, the response includes a NextToken parameter.</p>
                          ##          
  ##   clusterArn: string (required)
                                      ##             : 
                                      ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                      ##          
  ##   nextToken: string
                                                  ##            : 
                                                  ##             <p>The paginated results marker. When the result of the operation is truncated, the call returns NextToken in the response. 
                                                  ##             
                                                  ## To get the next batch, provide this token in your next request.</p>
                                                  ##          
  ##   MaxResults: string
                                                              ##             : Pagination limit
  ##   
                                                                                               ## NextToken: string
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## Pagination 
                                                                                               ## token
  var path_402656695 = newJObject()
  var query_402656696 = newJObject()
  add(query_402656696, "maxResults", newJInt(maxResults))
  add(path_402656695, "clusterArn", newJString(clusterArn))
  add(query_402656696, "nextToken", newJString(nextToken))
  add(query_402656696, "MaxResults", newJString(MaxResults))
  add(query_402656696, "NextToken", newJString(NextToken))
  result = call_402656694.call(path_402656695, query_402656696, nil, nil, nil)

var listNodes* = Call_ListNodes_402656678(name: "listNodes",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes", validator: validate_ListNodes_402656679,
    base: "/", makeUrl: url_ListNodes_402656680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656711 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656713(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656712(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656714 = path.getOrDefault("resourceArn")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true,
                                      default = nil)
  if valid_402656714 != nil:
    section.add "resourceArn", valid_402656714
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Algorithm", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Date")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Date", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Credential")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Credential", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656721
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

proc call*(call_402656723: Call_TagResource_402656711; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Adds tags to the specified MSK resource.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656723.validator(path, query, header, formData, body, _)
  let scheme = call_402656723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656723.makeUrl(scheme.get, call_402656723.host, call_402656723.base,
                                   call_402656723.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656723, uri, valid, _)

proc call*(call_402656724: Call_TagResource_402656711; body: JsonNode;
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
  var path_402656725 = newJObject()
  var body_402656726 = newJObject()
  if body != nil:
    body_402656726 = body
  add(path_402656725, "resourceArn", newJString(resourceArn))
  result = call_402656724.call(path_402656725, nil, nil, nil, body_402656726)

var tagResource* = Call_TagResource_402656711(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}", validator: validate_TagResource_402656712,
    base: "/", makeUrl: url_TagResource_402656713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656697 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656699(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402656698(path: JsonNode; query: JsonNode;
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
  var valid_402656700 = path.getOrDefault("resourceArn")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "resourceArn", valid_402656700
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656701 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Security-Token", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Signature")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Signature", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Algorithm", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Date")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Date", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Credential")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Credential", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656708: Call_ListTagsForResource_402656697;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Returns a list of the tags associated with the specified resource.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656708.validator(path, query, header, formData, body, _)
  let scheme = call_402656708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656708.makeUrl(scheme.get, call_402656708.host, call_402656708.base,
                                   call_402656708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656708, uri, valid, _)

proc call*(call_402656709: Call_ListTagsForResource_402656697;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
                        ##             <p>Returns a list of the tags associated with the specified resource.</p>
                        ##          
  ##   resourceArn: string (required)
                                    ##              : 
                                    ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
                                    ##          
  var path_402656710 = newJObject()
  add(path_402656710, "resourceArn", newJString(resourceArn))
  result = call_402656709.call(path_402656710, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656697(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656698, base: "/",
    makeUrl: url_ListTagsForResource_402656699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656727 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656729(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402656728(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656730 = path.getOrDefault("resourceArn")
  valid_402656730 = validateParameter(valid_402656730, JString, required = true,
                                      default = nil)
  if valid_402656730 != nil:
    section.add "resourceArn", valid_402656730
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : 
                                  ##             <p>Tag keys must be unique for a given cluster. In addition, the following restrictions apply:</p>
                                  ##             
                                  ## <ul>
                                  ##                <li>
                                  ##                   <p>Each tag key must be unique. If you add a tag with a key that's already in
                                  ##                   
                                  ## use, your new tag overwrites the existing key-value pair. </p>
                                  ##                
                                  ## </li>
                                  ##                <li>
                                  ##                   <p>You can't start a tag key with aws: because this prefix is reserved for use
                                  ##                   
                                  ## by  AWS.  AWS creates tags that begin with this prefix on your behalf, but
                                  ##                   
                                  ## you can't edit or delete them.</p>
                                  ##                </li>
                                  ##                <li>
                                  ##                   <p>Tag keys must be between 1 and 128 Unicode characters in length.</p>
                                  ##                
                                  ## </li>
                                  ##                <li>
                                  ##                   <p>Tag keys must consist of the following characters: Unicode letters, digits,
                                  ##                   
                                  ## white space, and the following special characters: _ . / = + -
                                  ##                      
                                  ## @.</p>
                                  ##                </li>
                                  ##             </ul>
                                  ##          
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656731 = query.getOrDefault("tagKeys")
  valid_402656731 = validateParameter(valid_402656731, JArray, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "tagKeys", valid_402656731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Security-Token", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Signature")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Signature", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Algorithm", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Date")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Date", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Credential")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Credential", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656739: Call_UntagResource_402656727; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656739.validator(path, query, header, formData, body, _)
  let scheme = call_402656739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656739.makeUrl(scheme.get, call_402656739.host, call_402656739.base,
                                   call_402656739.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656739, uri, valid, _)

proc call*(call_402656740: Call_UntagResource_402656727; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## 
                  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
                  ##          
  ##   tagKeys: JArray (required)
                              ##          : 
                              ##             <p>Tag keys must be unique for a given cluster. In addition, the following restrictions apply:</p>
                              ##             
                              ## <ul>
                              ##                <li>
                              ##                   <p>Each tag key must be unique. If you add a tag with a key that's already in
                              ##                   
                              ## use, your new tag overwrites the existing key-value pair. </p>
                              ##                
                              ## </li>
                              ##                <li>
                              ##                   <p>You can't start a tag key with aws: because this prefix is reserved for use
                              ##                   
                              ## by  AWS.  AWS creates tags that begin with this prefix on your behalf, but
                              ##                   
                              ## you can't edit or delete them.</p>
                              ##                </li>
                              ##                <li>
                              ##                   <p>Tag keys must be between 1 and 128 Unicode characters in length.</p>
                              ##                
                              ## </li>
                              ##                <li>
                              ##                   <p>Tag keys must consist of the following characters: Unicode letters, digits,
                              ##                   
                              ## white space, and the following special characters: _ . / = + -
                              ##                      
                              ## @.</p>
                              ##                </li>
                              ##             </ul>
                              ##          
  ##   resourceArn: string (required)
                                          ##              : 
                                          ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
                                          ##          
  var path_402656741 = newJObject()
  var query_402656742 = newJObject()
  if tagKeys != nil:
    query_402656742.add "tagKeys", tagKeys
  add(path_402656741, "resourceArn", newJString(resourceArn))
  result = call_402656740.call(path_402656741, query_402656742, nil, nil, nil)

var untagResource* = Call_UntagResource_402656727(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656728,
    base: "/", makeUrl: url_UntagResource_402656729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerCount_402656743 = ref object of OpenApiRestCall_402656044
proc url_UpdateBrokerCount_402656745(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateBrokerCount_402656744(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656746 = path.getOrDefault("clusterArn")
  valid_402656746 = validateParameter(valid_402656746, JString, required = true,
                                      default = nil)
  if valid_402656746 != nil:
    section.add "clusterArn", valid_402656746
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Security-Token", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Signature")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Signature", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Algorithm", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Date")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Date", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Credential")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Credential", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656753
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

proc call*(call_402656755: Call_UpdateBrokerCount_402656743;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Updates the number of broker nodes in the cluster.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656755.validator(path, query, header, formData, body, _)
  let scheme = call_402656755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656755.makeUrl(scheme.get, call_402656755.host, call_402656755.base,
                                   call_402656755.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656755, uri, valid, _)

proc call*(call_402656756: Call_UpdateBrokerCount_402656743; clusterArn: string;
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
  var path_402656757 = newJObject()
  var body_402656758 = newJObject()
  add(path_402656757, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_402656758 = body
  result = call_402656756.call(path_402656757, nil, nil, nil, body_402656758)

var updateBrokerCount* = Call_UpdateBrokerCount_402656743(
    name: "updateBrokerCount", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/count",
    validator: validate_UpdateBrokerCount_402656744, base: "/",
    makeUrl: url_UpdateBrokerCount_402656745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_402656759 = ref object of OpenApiRestCall_402656044
proc url_UpdateBrokerStorage_402656761(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateBrokerStorage_402656760(path: JsonNode; query: JsonNode;
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
  var valid_402656762 = path.getOrDefault("clusterArn")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true,
                                      default = nil)
  if valid_402656762 != nil:
    section.add "clusterArn", valid_402656762
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
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

proc call*(call_402656771: Call_UpdateBrokerStorage_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Updates the EBS storage associated with MSK brokers.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_UpdateBrokerStorage_402656759;
           clusterArn: string; body: JsonNode): Recallable =
  ## updateBrokerStorage
  ## 
                        ##             <p>Updates the EBS storage associated with MSK brokers.</p>
                        ##          
  ##   clusterArn: string (required)
                                    ##             : 
                                    ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                    ##          
  ##   body: JObject (required)
  var path_402656773 = newJObject()
  var body_402656774 = newJObject()
  add(path_402656773, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_402656774 = body
  result = call_402656772.call(path_402656773, nil, nil, nil, body_402656774)

var updateBrokerStorage* = Call_UpdateBrokerStorage_402656759(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_402656760, base: "/",
    makeUrl: url_UpdateBrokerStorage_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_402656775 = ref object of OpenApiRestCall_402656044
proc url_UpdateClusterConfiguration_402656777(protocol: Scheme; host: string;
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

proc validate_UpdateClusterConfiguration_402656776(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656778 = path.getOrDefault("clusterArn")
  valid_402656778 = validateParameter(valid_402656778, JString, required = true,
                                      default = nil)
  if valid_402656778 != nil:
    section.add "clusterArn", valid_402656778
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656779 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Security-Token", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Signature")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Signature", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Algorithm", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Date")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Date", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Credential")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Credential", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656785
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

proc call*(call_402656787: Call_UpdateClusterConfiguration_402656775;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656787.validator(path, query, header, formData, body, _)
  let scheme = call_402656787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656787.makeUrl(scheme.get, call_402656787.host, call_402656787.base,
                                   call_402656787.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656787, uri, valid, _)

proc call*(call_402656788: Call_UpdateClusterConfiguration_402656775;
           clusterArn: string; body: JsonNode): Recallable =
  ## updateClusterConfiguration
  ## 
                               ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
                               ##          
  ##   clusterArn: string (required)
                                           ##             : 
                                           ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
                                           ##          
  ##   body: JObject (required)
  var path_402656789 = newJObject()
  var body_402656790 = newJObject()
  add(path_402656789, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_402656790 = body
  result = call_402656788.call(path_402656789, nil, nil, nil, body_402656790)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_402656775(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_402656776, base: "/",
    makeUrl: url_UpdateClusterConfiguration_402656777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoring_402656791 = ref object of OpenApiRestCall_402656044
proc url_UpdateMonitoring_402656793(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_UpdateMonitoring_402656792(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656794 = path.getOrDefault("clusterArn")
  valid_402656794 = validateParameter(valid_402656794, JString, required = true,
                                      default = nil)
  if valid_402656794 != nil:
    section.add "clusterArn", valid_402656794
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656795 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Security-Token", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Signature")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Signature", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Algorithm", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Date")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Date", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Credential")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Credential", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656801
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

proc call*(call_402656803: Call_UpdateMonitoring_402656791;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ##             <p>Updates the monitoring settings for the cluster. You can use this operation to specify which Apache Kafka metrics you want Amazon MSK to send to Amazon CloudWatch. You can also specify settings for open monitoring with Prometheus.</p>
                                                                                         ##          
                                                                                         ## 
  let valid = call_402656803.validator(path, query, header, formData, body, _)
  let scheme = call_402656803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656803.makeUrl(scheme.get, call_402656803.host, call_402656803.base,
                                   call_402656803.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656803, uri, valid, _)

proc call*(call_402656804: Call_UpdateMonitoring_402656791; clusterArn: string;
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
  var path_402656805 = newJObject()
  var body_402656806 = newJObject()
  add(path_402656805, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_402656806 = body
  result = call_402656804.call(path_402656805, nil, nil, nil, body_402656806)

var updateMonitoring* = Call_UpdateMonitoring_402656791(
    name: "updateMonitoring", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/monitoring",
    validator: validate_UpdateMonitoring_402656792, base: "/",
    makeUrl: url_UpdateMonitoring_402656793,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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