
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_594034 = ref object of OpenApiRestCall_593437
proc url_CreateCluster_594036(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_594035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594037 = header.getOrDefault("X-Amz-Date")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Date", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Security-Token")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Security-Token", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Content-Sha256", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Algorithm")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Algorithm", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-Signature")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-Signature", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-SignedHeaders", valid_594042
  var valid_594043 = header.getOrDefault("X-Amz-Credential")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "X-Amz-Credential", valid_594043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594045: Call_CreateCluster_594034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ## 
  let valid = call_594045.validator(path, query, header, formData, body)
  let scheme = call_594045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594045.url(scheme.get, call_594045.host, call_594045.base,
                         call_594045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594045, url, valid)

proc call*(call_594046: Call_CreateCluster_594034; body: JsonNode): Recallable =
  ## createCluster
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ##   body: JObject (required)
  var body_594047 = newJObject()
  if body != nil:
    body_594047 = body
  result = call_594046.call(nil, nil, nil, nil, body_594047)

var createCluster* = Call_CreateCluster_594034(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_CreateCluster_594035, base: "/", url: url_CreateCluster_594036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_593774 = ref object of OpenApiRestCall_593437
proc url_ListClusters_593776(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusters_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593888 = query.getOrDefault("clusterNameFilter")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "clusterNameFilter", valid_593888
  var valid_593889 = query.getOrDefault("NextToken")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "NextToken", valid_593889
  var valid_593890 = query.getOrDefault("maxResults")
  valid_593890 = validateParameter(valid_593890, JInt, required = false, default = nil)
  if valid_593890 != nil:
    section.add "maxResults", valid_593890
  var valid_593891 = query.getOrDefault("nextToken")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "nextToken", valid_593891
  var valid_593892 = query.getOrDefault("MaxResults")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "MaxResults", valid_593892
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
  var valid_593893 = header.getOrDefault("X-Amz-Date")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Date", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Security-Token")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Security-Token", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Content-Sha256", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Algorithm")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Algorithm", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-Signature")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-Signature", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-SignedHeaders", valid_593898
  var valid_593899 = header.getOrDefault("X-Amz-Credential")
  valid_593899 = validateParameter(valid_593899, JString, required = false,
                                 default = nil)
  if valid_593899 != nil:
    section.add "X-Amz-Credential", valid_593899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593922: Call_ListClusters_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  let valid = call_593922.validator(path, query, header, formData, body)
  let scheme = call_593922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593922.url(scheme.get, call_593922.host, call_593922.base,
                         call_593922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593922, url, valid)

proc call*(call_593993: Call_ListClusters_593774; clusterNameFilter: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
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
  var query_593994 = newJObject()
  add(query_593994, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_593994, "NextToken", newJString(NextToken))
  add(query_593994, "maxResults", newJInt(maxResults))
  add(query_593994, "nextToken", newJString(nextToken))
  add(query_593994, "MaxResults", newJString(MaxResults))
  result = call_593993.call(nil, query_593994, nil, nil, nil)

var listClusters* = Call_ListClusters_593774(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_ListClusters_593775, base: "/", url: url_ListClusters_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_594065 = ref object of OpenApiRestCall_593437
proc url_CreateConfiguration_594067(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfiguration_594066(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594068 = header.getOrDefault("X-Amz-Date")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Date", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Security-Token")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Security-Token", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Content-Sha256", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Algorithm")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Algorithm", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Signature")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Signature", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-SignedHeaders", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Credential")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Credential", valid_594074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594076: Call_CreateConfiguration_594065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ## 
  let valid = call_594076.validator(path, query, header, formData, body)
  let scheme = call_594076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594076.url(scheme.get, call_594076.host, call_594076.base,
                         call_594076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594076, url, valid)

proc call*(call_594077: Call_CreateConfiguration_594065; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ##   body: JObject (required)
  var body_594078 = newJObject()
  if body != nil:
    body_594078 = body
  result = call_594077.call(nil, nil, nil, nil, body_594078)

var createConfiguration* = Call_CreateConfiguration_594065(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_594066, base: "/",
    url: url_CreateConfiguration_594067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_594048 = ref object of OpenApiRestCall_593437
proc url_ListConfigurations_594050(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurations_594049(path: JsonNode; query: JsonNode;
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
  var valid_594051 = query.getOrDefault("NextToken")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "NextToken", valid_594051
  var valid_594052 = query.getOrDefault("maxResults")
  valid_594052 = validateParameter(valid_594052, JInt, required = false, default = nil)
  if valid_594052 != nil:
    section.add "maxResults", valid_594052
  var valid_594053 = query.getOrDefault("nextToken")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "nextToken", valid_594053
  var valid_594054 = query.getOrDefault("MaxResults")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "MaxResults", valid_594054
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
  var valid_594055 = header.getOrDefault("X-Amz-Date")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Date", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Security-Token")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Security-Token", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Content-Sha256", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Algorithm")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Algorithm", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-SignedHeaders", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Credential")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Credential", valid_594061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594062: Call_ListConfigurations_594048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_594062.validator(path, query, header, formData, body)
  let scheme = call_594062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594062.url(scheme.get, call_594062.host, call_594062.base,
                         call_594062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594062, url, valid)

proc call*(call_594063: Call_ListConfigurations_594048; NextToken: string = "";
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
  var query_594064 = newJObject()
  add(query_594064, "NextToken", newJString(NextToken))
  add(query_594064, "maxResults", newJInt(maxResults))
  add(query_594064, "nextToken", newJString(nextToken))
  add(query_594064, "MaxResults", newJString(MaxResults))
  result = call_594063.call(nil, query_594064, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_594048(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_594049, base: "/",
    url: url_ListConfigurations_594050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_594079 = ref object of OpenApiRestCall_593437
proc url_DescribeCluster_594081(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeCluster_594080(path: JsonNode; query: JsonNode;
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
  var valid_594096 = path.getOrDefault("clusterArn")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "clusterArn", valid_594096
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
  var valid_594097 = header.getOrDefault("X-Amz-Date")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Date", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Security-Token")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Security-Token", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Content-Sha256", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Algorithm")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Algorithm", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Signature")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Signature", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-SignedHeaders", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Credential")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Credential", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594104: Call_DescribeCluster_594079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  let valid = call_594104.validator(path, query, header, formData, body)
  let scheme = call_594104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594104.url(scheme.get, call_594104.host, call_594104.base,
                         call_594104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594104, url, valid)

proc call*(call_594105: Call_DescribeCluster_594079; clusterArn: string): Recallable =
  ## describeCluster
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_594106 = newJObject()
  add(path_594106, "clusterArn", newJString(clusterArn))
  result = call_594105.call(path_594106, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_594079(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_594080,
    base: "/", url: url_DescribeCluster_594081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_594107 = ref object of OpenApiRestCall_593437
proc url_DeleteCluster_594109(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteCluster_594108(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594110 = path.getOrDefault("clusterArn")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = nil)
  if valid_594110 != nil:
    section.add "clusterArn", valid_594110
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  section = newJObject()
  var valid_594111 = query.getOrDefault("currentVersion")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "currentVersion", valid_594111
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
  var valid_594112 = header.getOrDefault("X-Amz-Date")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Date", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Security-Token")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Security-Token", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Content-Sha256", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Algorithm")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Algorithm", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Signature")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Signature", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-SignedHeaders", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Credential")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Credential", valid_594118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594119: Call_DeleteCluster_594107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  let valid = call_594119.validator(path, query, header, formData, body)
  let scheme = call_594119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594119.url(scheme.get, call_594119.host, call_594119.base,
                         call_594119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594119, url, valid)

proc call*(call_594120: Call_DeleteCluster_594107; clusterArn: string;
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
  var path_594121 = newJObject()
  var query_594122 = newJObject()
  add(query_594122, "currentVersion", newJString(currentVersion))
  add(path_594121, "clusterArn", newJString(clusterArn))
  result = call_594120.call(path_594121, query_594122, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_594107(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_594108,
    base: "/", url: url_DeleteCluster_594109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_594123 = ref object of OpenApiRestCall_593437
proc url_DescribeClusterOperation_594125(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeClusterOperation_594124(path: JsonNode; query: JsonNode;
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
  var valid_594126 = path.getOrDefault("clusterOperationArn")
  valid_594126 = validateParameter(valid_594126, JString, required = true,
                                 default = nil)
  if valid_594126 != nil:
    section.add "clusterOperationArn", valid_594126
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
  var valid_594127 = header.getOrDefault("X-Amz-Date")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Date", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Security-Token")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Security-Token", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Content-Sha256", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Algorithm")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Algorithm", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Signature")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Signature", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-SignedHeaders", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Credential")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Credential", valid_594133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_DescribeClusterOperation_594123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_DescribeClusterOperation_594123;
          clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ##   clusterOperationArn: string (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  var path_594136 = newJObject()
  add(path_594136, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_594135.call(path_594136, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_594123(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_594124, base: "/",
    url: url_DescribeClusterOperation_594125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_594137 = ref object of OpenApiRestCall_593437
proc url_DescribeConfiguration_594139(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeConfiguration_594138(path: JsonNode; query: JsonNode;
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
  var valid_594140 = path.getOrDefault("arn")
  valid_594140 = validateParameter(valid_594140, JString, required = true,
                                 default = nil)
  if valid_594140 != nil:
    section.add "arn", valid_594140
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
  var valid_594141 = header.getOrDefault("X-Amz-Date")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Date", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-Security-Token")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-Security-Token", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Content-Sha256", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Algorithm")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Algorithm", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Signature")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Signature", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-SignedHeaders", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594148: Call_DescribeConfiguration_594137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  let valid = call_594148.validator(path, query, header, formData, body)
  let scheme = call_594148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594148.url(scheme.get, call_594148.host, call_594148.base,
                         call_594148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594148, url, valid)

proc call*(call_594149: Call_DescribeConfiguration_594137; arn: string): Recallable =
  ## describeConfiguration
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  var path_594150 = newJObject()
  add(path_594150, "arn", newJString(arn))
  result = call_594149.call(path_594150, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_594137(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_594138, base: "/",
    url: url_DescribeConfiguration_594139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_594151 = ref object of OpenApiRestCall_593437
proc url_DescribeConfigurationRevision_594153(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeConfigurationRevision_594152(path: JsonNode; query: JsonNode;
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
  var valid_594154 = path.getOrDefault("arn")
  valid_594154 = validateParameter(valid_594154, JString, required = true,
                                 default = nil)
  if valid_594154 != nil:
    section.add "arn", valid_594154
  var valid_594155 = path.getOrDefault("revision")
  valid_594155 = validateParameter(valid_594155, JInt, required = true, default = nil)
  if valid_594155 != nil:
    section.add "revision", valid_594155
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
  var valid_594156 = header.getOrDefault("X-Amz-Date")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Date", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-Security-Token")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-Security-Token", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Content-Sha256", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Algorithm")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Algorithm", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Signature")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Signature", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-SignedHeaders", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Credential")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Credential", valid_594162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594163: Call_DescribeConfigurationRevision_594151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  let valid = call_594163.validator(path, query, header, formData, body)
  let scheme = call_594163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594163.url(scheme.get, call_594163.host, call_594163.base,
                         call_594163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594163, url, valid)

proc call*(call_594164: Call_DescribeConfigurationRevision_594151; arn: string;
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
  var path_594165 = newJObject()
  add(path_594165, "arn", newJString(arn))
  add(path_594165, "revision", newJInt(revision))
  result = call_594164.call(path_594165, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_594151(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_594152, base: "/",
    url: url_DescribeConfigurationRevision_594153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_594166 = ref object of OpenApiRestCall_593437
proc url_GetBootstrapBrokers_594168(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetBootstrapBrokers_594167(path: JsonNode; query: JsonNode;
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
  var valid_594169 = path.getOrDefault("clusterArn")
  valid_594169 = validateParameter(valid_594169, JString, required = true,
                                 default = nil)
  if valid_594169 != nil:
    section.add "clusterArn", valid_594169
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
  var valid_594170 = header.getOrDefault("X-Amz-Date")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Date", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Security-Token")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Security-Token", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-Content-Sha256", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Algorithm")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Algorithm", valid_594173
  var valid_594174 = header.getOrDefault("X-Amz-Signature")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "X-Amz-Signature", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-SignedHeaders", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Credential")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Credential", valid_594176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594177: Call_GetBootstrapBrokers_594166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  let valid = call_594177.validator(path, query, header, formData, body)
  let scheme = call_594177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594177.url(scheme.get, call_594177.host, call_594177.base,
                         call_594177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594177, url, valid)

proc call*(call_594178: Call_GetBootstrapBrokers_594166; clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_594179 = newJObject()
  add(path_594179, "clusterArn", newJString(clusterArn))
  result = call_594178.call(path_594179, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_594166(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_594167, base: "/",
    url: url_GetBootstrapBrokers_594168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_594180 = ref object of OpenApiRestCall_593437
proc url_ListClusterOperations_594182(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListClusterOperations_594181(path: JsonNode; query: JsonNode;
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
  var valid_594183 = path.getOrDefault("clusterArn")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = nil)
  if valid_594183 != nil:
    section.add "clusterArn", valid_594183
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
  var valid_594184 = query.getOrDefault("NextToken")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "NextToken", valid_594184
  var valid_594185 = query.getOrDefault("maxResults")
  valid_594185 = validateParameter(valid_594185, JInt, required = false, default = nil)
  if valid_594185 != nil:
    section.add "maxResults", valid_594185
  var valid_594186 = query.getOrDefault("nextToken")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "nextToken", valid_594186
  var valid_594187 = query.getOrDefault("MaxResults")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "MaxResults", valid_594187
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
  var valid_594188 = header.getOrDefault("X-Amz-Date")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Date", valid_594188
  var valid_594189 = header.getOrDefault("X-Amz-Security-Token")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Security-Token", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Content-Sha256", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Algorithm")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Algorithm", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Signature")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Signature", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-SignedHeaders", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Credential")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Credential", valid_594194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594195: Call_ListClusterOperations_594180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  let valid = call_594195.validator(path, query, header, formData, body)
  let scheme = call_594195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594195.url(scheme.get, call_594195.host, call_594195.base,
                         call_594195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594195, url, valid)

proc call*(call_594196: Call_ListClusterOperations_594180; clusterArn: string;
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
  var path_594197 = newJObject()
  var query_594198 = newJObject()
  add(query_594198, "NextToken", newJString(NextToken))
  add(query_594198, "maxResults", newJInt(maxResults))
  add(query_594198, "nextToken", newJString(nextToken))
  add(path_594197, "clusterArn", newJString(clusterArn))
  add(query_594198, "MaxResults", newJString(MaxResults))
  result = call_594196.call(path_594197, query_594198, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_594180(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_594181, base: "/",
    url: url_ListClusterOperations_594182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_594199 = ref object of OpenApiRestCall_593437
proc url_ListConfigurationRevisions_594201(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListConfigurationRevisions_594200(path: JsonNode; query: JsonNode;
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
  var valid_594202 = path.getOrDefault("arn")
  valid_594202 = validateParameter(valid_594202, JString, required = true,
                                 default = nil)
  if valid_594202 != nil:
    section.add "arn", valid_594202
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
  var valid_594203 = query.getOrDefault("NextToken")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "NextToken", valid_594203
  var valid_594204 = query.getOrDefault("maxResults")
  valid_594204 = validateParameter(valid_594204, JInt, required = false, default = nil)
  if valid_594204 != nil:
    section.add "maxResults", valid_594204
  var valid_594205 = query.getOrDefault("nextToken")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "nextToken", valid_594205
  var valid_594206 = query.getOrDefault("MaxResults")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "MaxResults", valid_594206
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
  var valid_594207 = header.getOrDefault("X-Amz-Date")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Date", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Security-Token")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Security-Token", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Content-Sha256", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Algorithm")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Algorithm", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Signature")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Signature", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-SignedHeaders", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Credential")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Credential", valid_594213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594214: Call_ListConfigurationRevisions_594199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_594214.validator(path, query, header, formData, body)
  let scheme = call_594214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594214.url(scheme.get, call_594214.host, call_594214.base,
                         call_594214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594214, url, valid)

proc call*(call_594215: Call_ListConfigurationRevisions_594199; arn: string;
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
  var path_594216 = newJObject()
  var query_594217 = newJObject()
  add(path_594216, "arn", newJString(arn))
  add(query_594217, "NextToken", newJString(NextToken))
  add(query_594217, "maxResults", newJInt(maxResults))
  add(query_594217, "nextToken", newJString(nextToken))
  add(query_594217, "MaxResults", newJString(MaxResults))
  result = call_594215.call(path_594216, query_594217, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_594199(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_594200, base: "/",
    url: url_ListConfigurationRevisions_594201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_594218 = ref object of OpenApiRestCall_593437
proc url_ListNodes_594220(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ListNodes_594219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594221 = path.getOrDefault("clusterArn")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "clusterArn", valid_594221
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
  var valid_594222 = query.getOrDefault("NextToken")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "NextToken", valid_594222
  var valid_594223 = query.getOrDefault("maxResults")
  valid_594223 = validateParameter(valid_594223, JInt, required = false, default = nil)
  if valid_594223 != nil:
    section.add "maxResults", valid_594223
  var valid_594224 = query.getOrDefault("nextToken")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "nextToken", valid_594224
  var valid_594225 = query.getOrDefault("MaxResults")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "MaxResults", valid_594225
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Content-Sha256", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Algorithm")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Algorithm", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Signature")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Signature", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-SignedHeaders", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Credential")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Credential", valid_594232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594233: Call_ListNodes_594218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_594233.validator(path, query, header, formData, body)
  let scheme = call_594233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594233.url(scheme.get, call_594233.host, call_594233.base,
                         call_594233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594233, url, valid)

proc call*(call_594234: Call_ListNodes_594218; clusterArn: string;
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
  var path_594235 = newJObject()
  var query_594236 = newJObject()
  add(query_594236, "NextToken", newJString(NextToken))
  add(query_594236, "maxResults", newJInt(maxResults))
  add(query_594236, "nextToken", newJString(nextToken))
  add(path_594235, "clusterArn", newJString(clusterArn))
  add(query_594236, "MaxResults", newJString(MaxResults))
  result = call_594234.call(path_594235, query_594236, nil, nil, nil)

var listNodes* = Call_ListNodes_594218(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "kafka.amazonaws.com",
                                    route: "/v1/clusters/{clusterArn}/nodes",
                                    validator: validate_ListNodes_594219,
                                    base: "/", url: url_ListNodes_594220,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594251 = ref object of OpenApiRestCall_593437
proc url_TagResource_594253(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_594252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594254 = path.getOrDefault("resourceArn")
  valid_594254 = validateParameter(valid_594254, JString, required = true,
                                 default = nil)
  if valid_594254 != nil:
    section.add "resourceArn", valid_594254
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
  var valid_594255 = header.getOrDefault("X-Amz-Date")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Date", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Security-Token")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Security-Token", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Content-Sha256", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Algorithm")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Algorithm", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Signature")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Signature", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-SignedHeaders", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Credential")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Credential", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_TagResource_594251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_TagResource_594251; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_594265 = newJObject()
  var body_594266 = newJObject()
  if body != nil:
    body_594266 = body
  add(path_594265, "resourceArn", newJString(resourceArn))
  result = call_594264.call(path_594265, nil, nil, nil, body_594266)

var tagResource* = Call_TagResource_594251(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kafka.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_594252,
                                        base: "/", url: url_TagResource_594253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594237 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594239(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594238(path: JsonNode; query: JsonNode;
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
  var valid_594240 = path.getOrDefault("resourceArn")
  valid_594240 = validateParameter(valid_594240, JString, required = true,
                                 default = nil)
  if valid_594240 != nil:
    section.add "resourceArn", valid_594240
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
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Content-Sha256", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Algorithm")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Algorithm", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Signature")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Signature", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-SignedHeaders", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Credential")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Credential", valid_594247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594248: Call_ListTagsForResource_594237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  let valid = call_594248.validator(path, query, header, formData, body)
  let scheme = call_594248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594248.url(scheme.get, call_594248.host, call_594248.base,
                         call_594248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594248, url, valid)

proc call*(call_594249: Call_ListTagsForResource_594237; resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_594250 = newJObject()
  add(path_594250, "resourceArn", newJString(resourceArn))
  result = call_594249.call(path_594250, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594237(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594238, base: "/",
    url: url_ListTagsForResource_594239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594267 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594269(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_594268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594270 = path.getOrDefault("resourceArn")
  valid_594270 = validateParameter(valid_594270, JString, required = true,
                                 default = nil)
  if valid_594270 != nil:
    section.add "resourceArn", valid_594270
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
  var valid_594271 = query.getOrDefault("tagKeys")
  valid_594271 = validateParameter(valid_594271, JArray, required = true, default = nil)
  if valid_594271 != nil:
    section.add "tagKeys", valid_594271
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
  var valid_594272 = header.getOrDefault("X-Amz-Date")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Date", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Security-Token")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Security-Token", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594279: Call_UntagResource_594267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  let valid = call_594279.validator(path, query, header, formData, body)
  let scheme = call_594279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594279.url(scheme.get, call_594279.host, call_594279.base,
                         call_594279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594279, url, valid)

proc call*(call_594280: Call_UntagResource_594267; tagKeys: JsonNode;
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
  var path_594281 = newJObject()
  var query_594282 = newJObject()
  if tagKeys != nil:
    query_594282.add "tagKeys", tagKeys
  add(path_594281, "resourceArn", newJString(resourceArn))
  result = call_594280.call(path_594281, query_594282, nil, nil, nil)

var untagResource* = Call_UntagResource_594267(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594268,
    base: "/", url: url_UntagResource_594269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_594283 = ref object of OpenApiRestCall_593437
proc url_UpdateBrokerStorage_594285(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBrokerStorage_594284(path: JsonNode; query: JsonNode;
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
  var valid_594286 = path.getOrDefault("clusterArn")
  valid_594286 = validateParameter(valid_594286, JString, required = true,
                                 default = nil)
  if valid_594286 != nil:
    section.add "clusterArn", valid_594286
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
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Security-Token")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Security-Token", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_UpdateBrokerStorage_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_UpdateBrokerStorage_594283; body: JsonNode;
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
  var path_594297 = newJObject()
  var body_594298 = newJObject()
  if body != nil:
    body_594298 = body
  add(path_594297, "clusterArn", newJString(clusterArn))
  result = call_594296.call(path_594297, nil, nil, nil, body_594298)

var updateBrokerStorage* = Call_UpdateBrokerStorage_594283(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_594284, base: "/",
    url: url_UpdateBrokerStorage_594285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_594299 = ref object of OpenApiRestCall_593437
proc url_UpdateClusterConfiguration_594301(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateClusterConfiguration_594300(path: JsonNode; query: JsonNode;
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
  var valid_594302 = path.getOrDefault("clusterArn")
  valid_594302 = validateParameter(valid_594302, JString, required = true,
                                 default = nil)
  if valid_594302 != nil:
    section.add "clusterArn", valid_594302
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
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Security-Token")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Security-Token", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Content-Sha256", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Signature")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Signature", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-SignedHeaders", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Credential")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Credential", valid_594309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594311: Call_UpdateClusterConfiguration_594299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  let valid = call_594311.validator(path, query, header, formData, body)
  let scheme = call_594311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594311.url(scheme.get, call_594311.host, call_594311.base,
                         call_594311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594311, url, valid)

proc call*(call_594312: Call_UpdateClusterConfiguration_594299; body: JsonNode;
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
  var path_594313 = newJObject()
  var body_594314 = newJObject()
  if body != nil:
    body_594314 = body
  add(path_594313, "clusterArn", newJString(clusterArn))
  result = call_594312.call(path_594313, nil, nil, nil, body_594314)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_594299(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_594300, base: "/",
    url: url_UpdateClusterConfiguration_594301,
    schemes: {Scheme.Https, Scheme.Http})
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
