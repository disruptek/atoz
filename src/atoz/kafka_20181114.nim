
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_590963 = ref object of OpenApiRestCall_590364
proc url_CreateCluster_590965(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_590964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590966 = header.getOrDefault("X-Amz-Signature")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Signature", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-Content-Sha256", valid_590967
  var valid_590968 = header.getOrDefault("X-Amz-Date")
  valid_590968 = validateParameter(valid_590968, JString, required = false,
                                 default = nil)
  if valid_590968 != nil:
    section.add "X-Amz-Date", valid_590968
  var valid_590969 = header.getOrDefault("X-Amz-Credential")
  valid_590969 = validateParameter(valid_590969, JString, required = false,
                                 default = nil)
  if valid_590969 != nil:
    section.add "X-Amz-Credential", valid_590969
  var valid_590970 = header.getOrDefault("X-Amz-Security-Token")
  valid_590970 = validateParameter(valid_590970, JString, required = false,
                                 default = nil)
  if valid_590970 != nil:
    section.add "X-Amz-Security-Token", valid_590970
  var valid_590971 = header.getOrDefault("X-Amz-Algorithm")
  valid_590971 = validateParameter(valid_590971, JString, required = false,
                                 default = nil)
  if valid_590971 != nil:
    section.add "X-Amz-Algorithm", valid_590971
  var valid_590972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590972 = validateParameter(valid_590972, JString, required = false,
                                 default = nil)
  if valid_590972 != nil:
    section.add "X-Amz-SignedHeaders", valid_590972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590974: Call_CreateCluster_590963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ## 
  let valid = call_590974.validator(path, query, header, formData, body)
  let scheme = call_590974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590974.url(scheme.get, call_590974.host, call_590974.base,
                         call_590974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590974, url, valid)

proc call*(call_590975: Call_CreateCluster_590963; body: JsonNode): Recallable =
  ## createCluster
  ## 
  ##             <p>Creates a new MSK cluster.</p>
  ##          
  ##   body: JObject (required)
  var body_590976 = newJObject()
  if body != nil:
    body_590976 = body
  result = call_590975.call(nil, nil, nil, nil, body_590976)

var createCluster* = Call_CreateCluster_590963(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_CreateCluster_590964, base: "/", url: url_CreateCluster_590965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_590703 = ref object of OpenApiRestCall_590364
proc url_ListClusters_590705(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusters_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590817 = query.getOrDefault("nextToken")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "nextToken", valid_590817
  var valid_590818 = query.getOrDefault("MaxResults")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "MaxResults", valid_590818
  var valid_590819 = query.getOrDefault("NextToken")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "NextToken", valid_590819
  var valid_590820 = query.getOrDefault("clusterNameFilter")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "clusterNameFilter", valid_590820
  var valid_590821 = query.getOrDefault("maxResults")
  valid_590821 = validateParameter(valid_590821, JInt, required = false, default = nil)
  if valid_590821 != nil:
    section.add "maxResults", valid_590821
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
  var valid_590822 = header.getOrDefault("X-Amz-Signature")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Signature", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-Content-Sha256", valid_590823
  var valid_590824 = header.getOrDefault("X-Amz-Date")
  valid_590824 = validateParameter(valid_590824, JString, required = false,
                                 default = nil)
  if valid_590824 != nil:
    section.add "X-Amz-Date", valid_590824
  var valid_590825 = header.getOrDefault("X-Amz-Credential")
  valid_590825 = validateParameter(valid_590825, JString, required = false,
                                 default = nil)
  if valid_590825 != nil:
    section.add "X-Amz-Credential", valid_590825
  var valid_590826 = header.getOrDefault("X-Amz-Security-Token")
  valid_590826 = validateParameter(valid_590826, JString, required = false,
                                 default = nil)
  if valid_590826 != nil:
    section.add "X-Amz-Security-Token", valid_590826
  var valid_590827 = header.getOrDefault("X-Amz-Algorithm")
  valid_590827 = validateParameter(valid_590827, JString, required = false,
                                 default = nil)
  if valid_590827 != nil:
    section.add "X-Amz-Algorithm", valid_590827
  var valid_590828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590828 = validateParameter(valid_590828, JString, required = false,
                                 default = nil)
  if valid_590828 != nil:
    section.add "X-Amz-SignedHeaders", valid_590828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590851: Call_ListClusters_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK clusters in the current Region.</p>
  ##          
  ## 
  let valid = call_590851.validator(path, query, header, formData, body)
  let scheme = call_590851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590851.url(scheme.get, call_590851.host, call_590851.base,
                         call_590851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590851, url, valid)

proc call*(call_590922: Call_ListClusters_590703; nextToken: string = "";
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
  var query_590923 = newJObject()
  add(query_590923, "nextToken", newJString(nextToken))
  add(query_590923, "MaxResults", newJString(MaxResults))
  add(query_590923, "NextToken", newJString(NextToken))
  add(query_590923, "clusterNameFilter", newJString(clusterNameFilter))
  add(query_590923, "maxResults", newJInt(maxResults))
  result = call_590922.call(nil, query_590923, nil, nil, nil)

var listClusters* = Call_ListClusters_590703(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com", route: "/v1/clusters",
    validator: validate_ListClusters_590704, base: "/", url: url_ListClusters_590705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfiguration_590994 = ref object of OpenApiRestCall_590364
proc url_CreateConfiguration_590996(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfiguration_590995(path: JsonNode; query: JsonNode;
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
  var valid_590997 = header.getOrDefault("X-Amz-Signature")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Signature", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Content-Sha256", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-Date")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-Date", valid_590999
  var valid_591000 = header.getOrDefault("X-Amz-Credential")
  valid_591000 = validateParameter(valid_591000, JString, required = false,
                                 default = nil)
  if valid_591000 != nil:
    section.add "X-Amz-Credential", valid_591000
  var valid_591001 = header.getOrDefault("X-Amz-Security-Token")
  valid_591001 = validateParameter(valid_591001, JString, required = false,
                                 default = nil)
  if valid_591001 != nil:
    section.add "X-Amz-Security-Token", valid_591001
  var valid_591002 = header.getOrDefault("X-Amz-Algorithm")
  valid_591002 = validateParameter(valid_591002, JString, required = false,
                                 default = nil)
  if valid_591002 != nil:
    section.add "X-Amz-Algorithm", valid_591002
  var valid_591003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591003 = validateParameter(valid_591003, JString, required = false,
                                 default = nil)
  if valid_591003 != nil:
    section.add "X-Amz-SignedHeaders", valid_591003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591005: Call_CreateConfiguration_590994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ## 
  let valid = call_591005.validator(path, query, header, formData, body)
  let scheme = call_591005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591005.url(scheme.get, call_591005.host, call_591005.base,
                         call_591005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591005, url, valid)

proc call*(call_591006: Call_CreateConfiguration_590994; body: JsonNode): Recallable =
  ## createConfiguration
  ## 
  ##             <p>Creates a new MSK configuration.</p>
  ##          
  ##   body: JObject (required)
  var body_591007 = newJObject()
  if body != nil:
    body_591007 = body
  result = call_591006.call(nil, nil, nil, nil, body_591007)

var createConfiguration* = Call_CreateConfiguration_590994(
    name: "createConfiguration", meth: HttpMethod.HttpPost,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_CreateConfiguration_590995, base: "/",
    url: url_CreateConfiguration_590996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_590977 = ref object of OpenApiRestCall_590364
proc url_ListConfigurations_590979(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurations_590978(path: JsonNode; query: JsonNode;
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
  var valid_590980 = query.getOrDefault("nextToken")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "nextToken", valid_590980
  var valid_590981 = query.getOrDefault("MaxResults")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "MaxResults", valid_590981
  var valid_590982 = query.getOrDefault("NextToken")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "NextToken", valid_590982
  var valid_590983 = query.getOrDefault("maxResults")
  valid_590983 = validateParameter(valid_590983, JInt, required = false, default = nil)
  if valid_590983 != nil:
    section.add "maxResults", valid_590983
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
  var valid_590984 = header.getOrDefault("X-Amz-Signature")
  valid_590984 = validateParameter(valid_590984, JString, required = false,
                                 default = nil)
  if valid_590984 != nil:
    section.add "X-Amz-Signature", valid_590984
  var valid_590985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590985 = validateParameter(valid_590985, JString, required = false,
                                 default = nil)
  if valid_590985 != nil:
    section.add "X-Amz-Content-Sha256", valid_590985
  var valid_590986 = header.getOrDefault("X-Amz-Date")
  valid_590986 = validateParameter(valid_590986, JString, required = false,
                                 default = nil)
  if valid_590986 != nil:
    section.add "X-Amz-Date", valid_590986
  var valid_590987 = header.getOrDefault("X-Amz-Credential")
  valid_590987 = validateParameter(valid_590987, JString, required = false,
                                 default = nil)
  if valid_590987 != nil:
    section.add "X-Amz-Credential", valid_590987
  var valid_590988 = header.getOrDefault("X-Amz-Security-Token")
  valid_590988 = validateParameter(valid_590988, JString, required = false,
                                 default = nil)
  if valid_590988 != nil:
    section.add "X-Amz-Security-Token", valid_590988
  var valid_590989 = header.getOrDefault("X-Amz-Algorithm")
  valid_590989 = validateParameter(valid_590989, JString, required = false,
                                 default = nil)
  if valid_590989 != nil:
    section.add "X-Amz-Algorithm", valid_590989
  var valid_590990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590990 = validateParameter(valid_590990, JString, required = false,
                                 default = nil)
  if valid_590990 != nil:
    section.add "X-Amz-SignedHeaders", valid_590990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590991: Call_ListConfigurations_590977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_590991.validator(path, query, header, formData, body)
  let scheme = call_590991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590991.url(scheme.get, call_590991.host, call_590991.base,
                         call_590991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590991, url, valid)

proc call*(call_590992: Call_ListConfigurations_590977; nextToken: string = "";
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
  var query_590993 = newJObject()
  add(query_590993, "nextToken", newJString(nextToken))
  add(query_590993, "MaxResults", newJString(MaxResults))
  add(query_590993, "NextToken", newJString(NextToken))
  add(query_590993, "maxResults", newJInt(maxResults))
  result = call_590992.call(nil, query_590993, nil, nil, nil)

var listConfigurations* = Call_ListConfigurations_590977(
    name: "listConfigurations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations",
    validator: validate_ListConfigurations_590978, base: "/",
    url: url_ListConfigurations_590979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_591008 = ref object of OpenApiRestCall_590364
proc url_DescribeCluster_591010(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_591009(path: JsonNode; query: JsonNode;
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
  var valid_591025 = path.getOrDefault("clusterArn")
  valid_591025 = validateParameter(valid_591025, JString, required = true,
                                 default = nil)
  if valid_591025 != nil:
    section.add "clusterArn", valid_591025
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
  var valid_591026 = header.getOrDefault("X-Amz-Signature")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Signature", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Content-Sha256", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-Date")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-Date", valid_591028
  var valid_591029 = header.getOrDefault("X-Amz-Credential")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-Credential", valid_591029
  var valid_591030 = header.getOrDefault("X-Amz-Security-Token")
  valid_591030 = validateParameter(valid_591030, JString, required = false,
                                 default = nil)
  if valid_591030 != nil:
    section.add "X-Amz-Security-Token", valid_591030
  var valid_591031 = header.getOrDefault("X-Amz-Algorithm")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "X-Amz-Algorithm", valid_591031
  var valid_591032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "X-Amz-SignedHeaders", valid_591032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591033: Call_DescribeCluster_591008; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ## 
  let valid = call_591033.validator(path, query, header, formData, body)
  let scheme = call_591033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591033.url(scheme.get, call_591033.host, call_591033.base,
                         call_591033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591033, url, valid)

proc call*(call_591034: Call_DescribeCluster_591008; clusterArn: string): Recallable =
  ## describeCluster
  ## 
  ##             <p>Returns a description of the MSK cluster whose Amazon Resource Name (ARN) is specified in the request.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_591035 = newJObject()
  add(path_591035, "clusterArn", newJString(clusterArn))
  result = call_591034.call(path_591035, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_591008(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DescribeCluster_591009,
    base: "/", url: url_DescribeCluster_591010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_591036 = ref object of OpenApiRestCall_590364
proc url_DeleteCluster_591038(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_591037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591039 = path.getOrDefault("clusterArn")
  valid_591039 = validateParameter(valid_591039, JString, required = true,
                                 default = nil)
  if valid_591039 != nil:
    section.add "clusterArn", valid_591039
  result.add "path", section
  ## parameters in `query` object:
  ##   currentVersion: JString
  ##                 : 
  ##             <p>The current version of the MSK cluster.</p>
  ##          
  section = newJObject()
  var valid_591040 = query.getOrDefault("currentVersion")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "currentVersion", valid_591040
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
  var valid_591041 = header.getOrDefault("X-Amz-Signature")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Signature", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Content-Sha256", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-Date")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-Date", valid_591043
  var valid_591044 = header.getOrDefault("X-Amz-Credential")
  valid_591044 = validateParameter(valid_591044, JString, required = false,
                                 default = nil)
  if valid_591044 != nil:
    section.add "X-Amz-Credential", valid_591044
  var valid_591045 = header.getOrDefault("X-Amz-Security-Token")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-Security-Token", valid_591045
  var valid_591046 = header.getOrDefault("X-Amz-Algorithm")
  valid_591046 = validateParameter(valid_591046, JString, required = false,
                                 default = nil)
  if valid_591046 != nil:
    section.add "X-Amz-Algorithm", valid_591046
  var valid_591047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591047 = validateParameter(valid_591047, JString, required = false,
                                 default = nil)
  if valid_591047 != nil:
    section.add "X-Amz-SignedHeaders", valid_591047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591048: Call_DeleteCluster_591036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Deletes the MSK cluster specified by the Amazon Resource Name (ARN) in the request.</p>
  ##          
  ## 
  let valid = call_591048.validator(path, query, header, formData, body)
  let scheme = call_591048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591048.url(scheme.get, call_591048.host, call_591048.base,
                         call_591048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591048, url, valid)

proc call*(call_591049: Call_DeleteCluster_591036; clusterArn: string;
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
  var path_591050 = newJObject()
  var query_591051 = newJObject()
  add(query_591051, "currentVersion", newJString(currentVersion))
  add(path_591050, "clusterArn", newJString(clusterArn))
  result = call_591049.call(path_591050, query_591051, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_591036(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}", validator: validate_DeleteCluster_591037,
    base: "/", url: url_DeleteCluster_591038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusterOperation_591052 = ref object of OpenApiRestCall_590364
proc url_DescribeClusterOperation_591054(protocol: Scheme; host: string;
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

proc validate_DescribeClusterOperation_591053(path: JsonNode; query: JsonNode;
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
  var valid_591055 = path.getOrDefault("clusterOperationArn")
  valid_591055 = validateParameter(valid_591055, JString, required = true,
                                 default = nil)
  if valid_591055 != nil:
    section.add "clusterOperationArn", valid_591055
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
  var valid_591056 = header.getOrDefault("X-Amz-Signature")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Signature", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Content-Sha256", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-Date")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Date", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-Credential")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-Credential", valid_591059
  var valid_591060 = header.getOrDefault("X-Amz-Security-Token")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "X-Amz-Security-Token", valid_591060
  var valid_591061 = header.getOrDefault("X-Amz-Algorithm")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-Algorithm", valid_591061
  var valid_591062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591062 = validateParameter(valid_591062, JString, required = false,
                                 default = nil)
  if valid_591062 != nil:
    section.add "X-Amz-SignedHeaders", valid_591062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591063: Call_DescribeClusterOperation_591052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ## 
  let valid = call_591063.validator(path, query, header, formData, body)
  let scheme = call_591063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591063.url(scheme.get, call_591063.host, call_591063.base,
                         call_591063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591063, url, valid)

proc call*(call_591064: Call_DescribeClusterOperation_591052;
          clusterOperationArn: string): Recallable =
  ## describeClusterOperation
  ## 
  ##             <p>Returns a description of the cluster operation specified by the ARN.</p>
  ##          
  ##   clusterOperationArn: string (required)
  ##                      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the MSK cluster operation.</p>
  ##          
  var path_591065 = newJObject()
  add(path_591065, "clusterOperationArn", newJString(clusterOperationArn))
  result = call_591064.call(path_591065, nil, nil, nil, nil)

var describeClusterOperation* = Call_DescribeClusterOperation_591052(
    name: "describeClusterOperation", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/operations/{clusterOperationArn}",
    validator: validate_DescribeClusterOperation_591053, base: "/",
    url: url_DescribeClusterOperation_591054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfiguration_591066 = ref object of OpenApiRestCall_590364
proc url_DescribeConfiguration_591068(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConfiguration_591067(path: JsonNode; query: JsonNode;
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
  var valid_591069 = path.getOrDefault("arn")
  valid_591069 = validateParameter(valid_591069, JString, required = true,
                                 default = nil)
  if valid_591069 != nil:
    section.add "arn", valid_591069
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
  var valid_591070 = header.getOrDefault("X-Amz-Signature")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Signature", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Content-Sha256", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Date")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Date", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Credential")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Credential", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Security-Token")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Security-Token", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Algorithm")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Algorithm", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-SignedHeaders", valid_591076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591077: Call_DescribeConfiguration_591066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ## 
  let valid = call_591077.validator(path, query, header, formData, body)
  let scheme = call_591077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591077.url(scheme.get, call_591077.host, call_591077.base,
                         call_591077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591077, url, valid)

proc call*(call_591078: Call_DescribeConfiguration_591066; arn: string): Recallable =
  ## describeConfiguration
  ## 
  ##             <p>Returns a description of this MSK configuration.</p>
  ##          
  ##   arn: string (required)
  ##      : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies an MSK configuration and all of its revisions.</p>
  ##          
  var path_591079 = newJObject()
  add(path_591079, "arn", newJString(arn))
  result = call_591078.call(path_591079, nil, nil, nil, nil)

var describeConfiguration* = Call_DescribeConfiguration_591066(
    name: "describeConfiguration", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}",
    validator: validate_DescribeConfiguration_591067, base: "/",
    url: url_DescribeConfiguration_591068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRevision_591080 = ref object of OpenApiRestCall_590364
proc url_DescribeConfigurationRevision_591082(protocol: Scheme; host: string;
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

proc validate_DescribeConfigurationRevision_591081(path: JsonNode; query: JsonNode;
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
  var valid_591083 = path.getOrDefault("arn")
  valid_591083 = validateParameter(valid_591083, JString, required = true,
                                 default = nil)
  if valid_591083 != nil:
    section.add "arn", valid_591083
  var valid_591084 = path.getOrDefault("revision")
  valid_591084 = validateParameter(valid_591084, JInt, required = true, default = nil)
  if valid_591084 != nil:
    section.add "revision", valid_591084
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
  var valid_591085 = header.getOrDefault("X-Amz-Signature")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Signature", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Content-Sha256", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Date")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Date", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Credential")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Credential", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-Security-Token")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Security-Token", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Algorithm")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Algorithm", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-SignedHeaders", valid_591091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591092: Call_DescribeConfigurationRevision_591080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a description of this revision of the configuration.</p>
  ##          
  ## 
  let valid = call_591092.validator(path, query, header, formData, body)
  let scheme = call_591092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591092.url(scheme.get, call_591092.host, call_591092.base,
                         call_591092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591092, url, valid)

proc call*(call_591093: Call_DescribeConfigurationRevision_591080; arn: string;
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
  var path_591094 = newJObject()
  add(path_591094, "arn", newJString(arn))
  add(path_591094, "revision", newJInt(revision))
  result = call_591093.call(path_591094, nil, nil, nil, nil)

var describeConfigurationRevision* = Call_DescribeConfigurationRevision_591080(
    name: "describeConfigurationRevision", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/configurations/{arn}/revisions/{revision}",
    validator: validate_DescribeConfigurationRevision_591081, base: "/",
    url: url_DescribeConfigurationRevision_591082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBootstrapBrokers_591095 = ref object of OpenApiRestCall_590364
proc url_GetBootstrapBrokers_591097(protocol: Scheme; host: string; base: string;
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

proc validate_GetBootstrapBrokers_591096(path: JsonNode; query: JsonNode;
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
  var valid_591098 = path.getOrDefault("clusterArn")
  valid_591098 = validateParameter(valid_591098, JString, required = true,
                                 default = nil)
  if valid_591098 != nil:
    section.add "clusterArn", valid_591098
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
  var valid_591099 = header.getOrDefault("X-Amz-Signature")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Signature", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Content-Sha256", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Date")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Date", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Credential")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Credential", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-Security-Token")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-Security-Token", valid_591103
  var valid_591104 = header.getOrDefault("X-Amz-Algorithm")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Algorithm", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-SignedHeaders", valid_591105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591106: Call_GetBootstrapBrokers_591095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ## 
  let valid = call_591106.validator(path, query, header, formData, body)
  let scheme = call_591106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591106.url(scheme.get, call_591106.host, call_591106.base,
                         call_591106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591106, url, valid)

proc call*(call_591107: Call_GetBootstrapBrokers_591095; clusterArn: string): Recallable =
  ## getBootstrapBrokers
  ## 
  ##             <p>A list of brokers that a client application can use to bootstrap.</p>
  ##          
  ##   clusterArn: string (required)
  ##             : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the cluster.</p>
  ##          
  var path_591108 = newJObject()
  add(path_591108, "clusterArn", newJString(clusterArn))
  result = call_591107.call(path_591108, nil, nil, nil, nil)

var getBootstrapBrokers* = Call_GetBootstrapBrokers_591095(
    name: "getBootstrapBrokers", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/bootstrap-brokers",
    validator: validate_GetBootstrapBrokers_591096, base: "/",
    url: url_GetBootstrapBrokers_591097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterOperations_591109 = ref object of OpenApiRestCall_590364
proc url_ListClusterOperations_591111(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusterOperations_591110(path: JsonNode; query: JsonNode;
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
  var valid_591112 = path.getOrDefault("clusterArn")
  valid_591112 = validateParameter(valid_591112, JString, required = true,
                                 default = nil)
  if valid_591112 != nil:
    section.add "clusterArn", valid_591112
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
  var valid_591113 = query.getOrDefault("nextToken")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "nextToken", valid_591113
  var valid_591114 = query.getOrDefault("MaxResults")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "MaxResults", valid_591114
  var valid_591115 = query.getOrDefault("NextToken")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "NextToken", valid_591115
  var valid_591116 = query.getOrDefault("maxResults")
  valid_591116 = validateParameter(valid_591116, JInt, required = false, default = nil)
  if valid_591116 != nil:
    section.add "maxResults", valid_591116
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
  var valid_591117 = header.getOrDefault("X-Amz-Signature")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-Signature", valid_591117
  var valid_591118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591118 = validateParameter(valid_591118, JString, required = false,
                                 default = nil)
  if valid_591118 != nil:
    section.add "X-Amz-Content-Sha256", valid_591118
  var valid_591119 = header.getOrDefault("X-Amz-Date")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Date", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Credential")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Credential", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-Security-Token")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-Security-Token", valid_591121
  var valid_591122 = header.getOrDefault("X-Amz-Algorithm")
  valid_591122 = validateParameter(valid_591122, JString, required = false,
                                 default = nil)
  if valid_591122 != nil:
    section.add "X-Amz-Algorithm", valid_591122
  var valid_591123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591123 = validateParameter(valid_591123, JString, required = false,
                                 default = nil)
  if valid_591123 != nil:
    section.add "X-Amz-SignedHeaders", valid_591123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591124: Call_ListClusterOperations_591109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the operations that have been performed on the specified MSK cluster.</p>
  ##          
  ## 
  let valid = call_591124.validator(path, query, header, formData, body)
  let scheme = call_591124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591124.url(scheme.get, call_591124.host, call_591124.base,
                         call_591124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591124, url, valid)

proc call*(call_591125: Call_ListClusterOperations_591109; clusterArn: string;
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
  var path_591126 = newJObject()
  var query_591127 = newJObject()
  add(query_591127, "nextToken", newJString(nextToken))
  add(query_591127, "MaxResults", newJString(MaxResults))
  add(query_591127, "NextToken", newJString(NextToken))
  add(path_591126, "clusterArn", newJString(clusterArn))
  add(query_591127, "maxResults", newJInt(maxResults))
  result = call_591125.call(path_591126, query_591127, nil, nil, nil)

var listClusterOperations* = Call_ListClusterOperations_591109(
    name: "listClusterOperations", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/operations",
    validator: validate_ListClusterOperations_591110, base: "/",
    url: url_ListClusterOperations_591111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationRevisions_591128 = ref object of OpenApiRestCall_590364
proc url_ListConfigurationRevisions_591130(protocol: Scheme; host: string;
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

proc validate_ListConfigurationRevisions_591129(path: JsonNode; query: JsonNode;
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
  var valid_591131 = path.getOrDefault("arn")
  valid_591131 = validateParameter(valid_591131, JString, required = true,
                                 default = nil)
  if valid_591131 != nil:
    section.add "arn", valid_591131
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
  var valid_591132 = query.getOrDefault("nextToken")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "nextToken", valid_591132
  var valid_591133 = query.getOrDefault("MaxResults")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "MaxResults", valid_591133
  var valid_591134 = query.getOrDefault("NextToken")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "NextToken", valid_591134
  var valid_591135 = query.getOrDefault("maxResults")
  valid_591135 = validateParameter(valid_591135, JInt, required = false, default = nil)
  if valid_591135 != nil:
    section.add "maxResults", valid_591135
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
  var valid_591136 = header.getOrDefault("X-Amz-Signature")
  valid_591136 = validateParameter(valid_591136, JString, required = false,
                                 default = nil)
  if valid_591136 != nil:
    section.add "X-Amz-Signature", valid_591136
  var valid_591137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591137 = validateParameter(valid_591137, JString, required = false,
                                 default = nil)
  if valid_591137 != nil:
    section.add "X-Amz-Content-Sha256", valid_591137
  var valid_591138 = header.getOrDefault("X-Amz-Date")
  valid_591138 = validateParameter(valid_591138, JString, required = false,
                                 default = nil)
  if valid_591138 != nil:
    section.add "X-Amz-Date", valid_591138
  var valid_591139 = header.getOrDefault("X-Amz-Credential")
  valid_591139 = validateParameter(valid_591139, JString, required = false,
                                 default = nil)
  if valid_591139 != nil:
    section.add "X-Amz-Credential", valid_591139
  var valid_591140 = header.getOrDefault("X-Amz-Security-Token")
  valid_591140 = validateParameter(valid_591140, JString, required = false,
                                 default = nil)
  if valid_591140 != nil:
    section.add "X-Amz-Security-Token", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Algorithm")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Algorithm", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-SignedHeaders", valid_591142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591143: Call_ListConfigurationRevisions_591128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of all the MSK configurations in this Region.</p>
  ##          
  ## 
  let valid = call_591143.validator(path, query, header, formData, body)
  let scheme = call_591143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591143.url(scheme.get, call_591143.host, call_591143.base,
                         call_591143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591143, url, valid)

proc call*(call_591144: Call_ListConfigurationRevisions_591128; arn: string;
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
  var path_591145 = newJObject()
  var query_591146 = newJObject()
  add(query_591146, "nextToken", newJString(nextToken))
  add(path_591145, "arn", newJString(arn))
  add(query_591146, "MaxResults", newJString(MaxResults))
  add(query_591146, "NextToken", newJString(NextToken))
  add(query_591146, "maxResults", newJInt(maxResults))
  result = call_591144.call(path_591145, query_591146, nil, nil, nil)

var listConfigurationRevisions* = Call_ListConfigurationRevisions_591128(
    name: "listConfigurationRevisions", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/configurations/{arn}/revisions",
    validator: validate_ListConfigurationRevisions_591129, base: "/",
    url: url_ListConfigurationRevisions_591130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodes_591147 = ref object of OpenApiRestCall_590364
proc url_ListNodes_591149(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListNodes_591148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591150 = path.getOrDefault("clusterArn")
  valid_591150 = validateParameter(valid_591150, JString, required = true,
                                 default = nil)
  if valid_591150 != nil:
    section.add "clusterArn", valid_591150
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
  var valid_591151 = query.getOrDefault("nextToken")
  valid_591151 = validateParameter(valid_591151, JString, required = false,
                                 default = nil)
  if valid_591151 != nil:
    section.add "nextToken", valid_591151
  var valid_591152 = query.getOrDefault("MaxResults")
  valid_591152 = validateParameter(valid_591152, JString, required = false,
                                 default = nil)
  if valid_591152 != nil:
    section.add "MaxResults", valid_591152
  var valid_591153 = query.getOrDefault("NextToken")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = nil)
  if valid_591153 != nil:
    section.add "NextToken", valid_591153
  var valid_591154 = query.getOrDefault("maxResults")
  valid_591154 = validateParameter(valid_591154, JInt, required = false, default = nil)
  if valid_591154 != nil:
    section.add "maxResults", valid_591154
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
  var valid_591155 = header.getOrDefault("X-Amz-Signature")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Signature", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Content-Sha256", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Date")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Date", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Credential")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Credential", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Security-Token")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Security-Token", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Algorithm")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Algorithm", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-SignedHeaders", valid_591161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591162: Call_ListNodes_591147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_591162.validator(path, query, header, formData, body)
  let scheme = call_591162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591162.url(scheme.get, call_591162.host, call_591162.base,
                         call_591162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591162, url, valid)

proc call*(call_591163: Call_ListNodes_591147; clusterArn: string;
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
  var path_591164 = newJObject()
  var query_591165 = newJObject()
  add(query_591165, "nextToken", newJString(nextToken))
  add(query_591165, "MaxResults", newJString(MaxResults))
  add(query_591165, "NextToken", newJString(NextToken))
  add(path_591164, "clusterArn", newJString(clusterArn))
  add(query_591165, "maxResults", newJInt(maxResults))
  result = call_591163.call(path_591164, query_591165, nil, nil, nil)

var listNodes* = Call_ListNodes_591147(name: "listNodes", meth: HttpMethod.HttpGet,
                                    host: "kafka.amazonaws.com",
                                    route: "/v1/clusters/{clusterArn}/nodes",
                                    validator: validate_ListNodes_591148,
                                    base: "/", url: url_ListNodes_591149,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591180 = ref object of OpenApiRestCall_590364
proc url_TagResource_591182(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_591181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591183 = path.getOrDefault("resourceArn")
  valid_591183 = validateParameter(valid_591183, JString, required = true,
                                 default = nil)
  if valid_591183 != nil:
    section.add "resourceArn", valid_591183
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
  var valid_591184 = header.getOrDefault("X-Amz-Signature")
  valid_591184 = validateParameter(valid_591184, JString, required = false,
                                 default = nil)
  if valid_591184 != nil:
    section.add "X-Amz-Signature", valid_591184
  var valid_591185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Content-Sha256", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Date")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Date", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Credential")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Credential", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Security-Token")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Security-Token", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Algorithm")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Algorithm", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-SignedHeaders", valid_591190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591192: Call_TagResource_591180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ## 
  let valid = call_591192.validator(path, query, header, formData, body)
  let scheme = call_591192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591192.url(scheme.get, call_591192.host, call_591192.base,
                         call_591192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591192, url, valid)

proc call*(call_591193: Call_TagResource_591180; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## 
  ##             <p>Adds tags to the specified MSK resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  ##   body: JObject (required)
  var path_591194 = newJObject()
  var body_591195 = newJObject()
  add(path_591194, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_591195 = body
  result = call_591193.call(path_591194, nil, nil, nil, body_591195)

var tagResource* = Call_TagResource_591180(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "kafka.amazonaws.com",
                                        route: "/v1/tags/{resourceArn}",
                                        validator: validate_TagResource_591181,
                                        base: "/", url: url_TagResource_591182,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591166 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591168(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_591167(path: JsonNode; query: JsonNode;
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
  var valid_591169 = path.getOrDefault("resourceArn")
  valid_591169 = validateParameter(valid_591169, JString, required = true,
                                 default = nil)
  if valid_591169 != nil:
    section.add "resourceArn", valid_591169
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
  var valid_591170 = header.getOrDefault("X-Amz-Signature")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Signature", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Content-Sha256", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Date")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Date", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Credential")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Credential", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Security-Token")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Security-Token", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Algorithm")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Algorithm", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-SignedHeaders", valid_591176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591177: Call_ListTagsForResource_591166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ## 
  let valid = call_591177.validator(path, query, header, formData, body)
  let scheme = call_591177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591177.url(scheme.get, call_591177.host, call_591177.base,
                         call_591177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591177, url, valid)

proc call*(call_591178: Call_ListTagsForResource_591166; resourceArn: string): Recallable =
  ## listTagsForResource
  ## 
  ##             <p>Returns a list of the tags associated with the specified resource.</p>
  ##          
  ##   resourceArn: string (required)
  ##              : 
  ##             <p>The Amazon Resource Name (ARN) that uniquely identifies the resource that's associated with the tags.</p>
  ##          
  var path_591179 = newJObject()
  add(path_591179, "resourceArn", newJString(resourceArn))
  result = call_591178.call(path_591179, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591166(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "kafka.amazonaws.com", route: "/v1/tags/{resourceArn}",
    validator: validate_ListTagsForResource_591167, base: "/",
    url: url_ListTagsForResource_591168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591196 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591198(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_591197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591199 = path.getOrDefault("resourceArn")
  valid_591199 = validateParameter(valid_591199, JString, required = true,
                                 default = nil)
  if valid_591199 != nil:
    section.add "resourceArn", valid_591199
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
  var valid_591200 = query.getOrDefault("tagKeys")
  valid_591200 = validateParameter(valid_591200, JArray, required = true, default = nil)
  if valid_591200 != nil:
    section.add "tagKeys", valid_591200
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
  var valid_591201 = header.getOrDefault("X-Amz-Signature")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Signature", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Content-Sha256", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Date")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Date", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Credential")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Credential", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Security-Token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Security-Token", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Algorithm")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Algorithm", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-SignedHeaders", valid_591207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591208: Call_UntagResource_591196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Removes the tags associated with the keys that are provided in the query.</p>
  ##          
  ## 
  let valid = call_591208.validator(path, query, header, formData, body)
  let scheme = call_591208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591208.url(scheme.get, call_591208.host, call_591208.base,
                         call_591208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591208, url, valid)

proc call*(call_591209: Call_UntagResource_591196; resourceArn: string;
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
  var path_591210 = newJObject()
  var query_591211 = newJObject()
  add(path_591210, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_591211.add "tagKeys", tagKeys
  result = call_591209.call(path_591210, query_591211, nil, nil, nil)

var untagResource* = Call_UntagResource_591196(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "kafka.amazonaws.com",
    route: "/v1/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_591197,
    base: "/", url: url_UntagResource_591198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerCount_591212 = ref object of OpenApiRestCall_590364
proc url_UpdateBrokerCount_591214(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateBrokerCount_591213(path: JsonNode; query: JsonNode;
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
  var valid_591215 = path.getOrDefault("clusterArn")
  valid_591215 = validateParameter(valid_591215, JString, required = true,
                                 default = nil)
  if valid_591215 != nil:
    section.add "clusterArn", valid_591215
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
  var valid_591216 = header.getOrDefault("X-Amz-Signature")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Signature", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Content-Sha256", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Date")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Date", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Credential")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Credential", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Security-Token")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Security-Token", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Algorithm")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Algorithm", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-SignedHeaders", valid_591222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591224: Call_UpdateBrokerCount_591212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the number of broker nodes in the cluster.</p>
  ##          
  ## 
  let valid = call_591224.validator(path, query, header, formData, body)
  let scheme = call_591224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591224.url(scheme.get, call_591224.host, call_591224.base,
                         call_591224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591224, url, valid)

proc call*(call_591225: Call_UpdateBrokerCount_591212; clusterArn: string;
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
  var path_591226 = newJObject()
  var body_591227 = newJObject()
  add(path_591226, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_591227 = body
  result = call_591225.call(path_591226, nil, nil, nil, body_591227)

var updateBrokerCount* = Call_UpdateBrokerCount_591212(name: "updateBrokerCount",
    meth: HttpMethod.HttpPut, host: "kafka.amazonaws.com",
    route: "/v1/clusters/{clusterArn}/nodes/count",
    validator: validate_UpdateBrokerCount_591213, base: "/",
    url: url_UpdateBrokerCount_591214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBrokerStorage_591228 = ref object of OpenApiRestCall_590364
proc url_UpdateBrokerStorage_591230(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBrokerStorage_591229(path: JsonNode; query: JsonNode;
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
  var valid_591231 = path.getOrDefault("clusterArn")
  valid_591231 = validateParameter(valid_591231, JString, required = true,
                                 default = nil)
  if valid_591231 != nil:
    section.add "clusterArn", valid_591231
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
  var valid_591232 = header.getOrDefault("X-Amz-Signature")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Signature", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Content-Sha256", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-Date")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-Date", valid_591234
  var valid_591235 = header.getOrDefault("X-Amz-Credential")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "X-Amz-Credential", valid_591235
  var valid_591236 = header.getOrDefault("X-Amz-Security-Token")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-Security-Token", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-Algorithm")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-Algorithm", valid_591237
  var valid_591238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-SignedHeaders", valid_591238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591240: Call_UpdateBrokerStorage_591228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the EBS storage associated with MSK brokers.</p>
  ##          
  ## 
  let valid = call_591240.validator(path, query, header, formData, body)
  let scheme = call_591240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591240.url(scheme.get, call_591240.host, call_591240.base,
                         call_591240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591240, url, valid)

proc call*(call_591241: Call_UpdateBrokerStorage_591228; clusterArn: string;
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
  var path_591242 = newJObject()
  var body_591243 = newJObject()
  add(path_591242, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_591243 = body
  result = call_591241.call(path_591242, nil, nil, nil, body_591243)

var updateBrokerStorage* = Call_UpdateBrokerStorage_591228(
    name: "updateBrokerStorage", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/nodes/storage",
    validator: validate_UpdateBrokerStorage_591229, base: "/",
    url: url_UpdateBrokerStorage_591230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfiguration_591244 = ref object of OpenApiRestCall_590364
proc url_UpdateClusterConfiguration_591246(protocol: Scheme; host: string;
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

proc validate_UpdateClusterConfiguration_591245(path: JsonNode; query: JsonNode;
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
  var valid_591247 = path.getOrDefault("clusterArn")
  valid_591247 = validateParameter(valid_591247, JString, required = true,
                                 default = nil)
  if valid_591247 != nil:
    section.add "clusterArn", valid_591247
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
  var valid_591248 = header.getOrDefault("X-Amz-Signature")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Signature", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Content-Sha256", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Date")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Date", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Credential")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Credential", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-Security-Token")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-Security-Token", valid_591252
  var valid_591253 = header.getOrDefault("X-Amz-Algorithm")
  valid_591253 = validateParameter(valid_591253, JString, required = false,
                                 default = nil)
  if valid_591253 != nil:
    section.add "X-Amz-Algorithm", valid_591253
  var valid_591254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591254 = validateParameter(valid_591254, JString, required = false,
                                 default = nil)
  if valid_591254 != nil:
    section.add "X-Amz-SignedHeaders", valid_591254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591256: Call_UpdateClusterConfiguration_591244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## 
  ##             <p>Updates the cluster with the configuration that is specified in the request body.</p>
  ##          
  ## 
  let valid = call_591256.validator(path, query, header, formData, body)
  let scheme = call_591256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591256.url(scheme.get, call_591256.host, call_591256.base,
                         call_591256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591256, url, valid)

proc call*(call_591257: Call_UpdateClusterConfiguration_591244; clusterArn: string;
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
  var path_591258 = newJObject()
  var body_591259 = newJObject()
  add(path_591258, "clusterArn", newJString(clusterArn))
  if body != nil:
    body_591259 = body
  result = call_591257.call(path_591258, nil, nil, nil, body_591259)

var updateClusterConfiguration* = Call_UpdateClusterConfiguration_591244(
    name: "updateClusterConfiguration", meth: HttpMethod.HttpPut,
    host: "kafka.amazonaws.com", route: "/v1/clusters/{clusterArn}/configuration",
    validator: validate_UpdateClusterConfiguration_591245, base: "/",
    url: url_UpdateClusterConfiguration_591246,
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
