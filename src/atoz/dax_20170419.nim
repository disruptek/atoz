
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon DynamoDB Accelerator (DAX)
## version: 2017-04-19
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## DAX is a managed caching service engineered for Amazon DynamoDB. DAX dramatically speeds up database reads by caching frequently-accessed data from DynamoDB, so applications can access that data with sub-millisecond latency. You can create a DAX cluster easily, using the AWS Management Console. With a few simple modifications to your code, your application can begin taking advantage of the DAX cluster and realize significant improvements in read performance.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dax/
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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dax.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dax.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dax.us-west-2.amazonaws.com",
                           "eu-west-2": "dax.eu-west-2.amazonaws.com", "ap-northeast-3": "dax.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "dax.eu-central-1.amazonaws.com",
                           "us-east-2": "dax.us-east-2.amazonaws.com",
                           "us-east-1": "dax.us-east-1.amazonaws.com", "cn-northwest-1": "dax.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "dax.ap-south-1.amazonaws.com",
                           "eu-north-1": "dax.eu-north-1.amazonaws.com", "ap-northeast-2": "dax.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dax.us-west-1.amazonaws.com",
                           "us-gov-east-1": "dax.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dax.eu-west-3.amazonaws.com",
                           "cn-north-1": "dax.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dax.sa-east-1.amazonaws.com",
                           "eu-west-1": "dax.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "dax.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dax.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "dax.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dax.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dax.ap-southeast-1.amazonaws.com",
      "us-west-2": "dax.us-west-2.amazonaws.com",
      "eu-west-2": "dax.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dax.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dax.eu-central-1.amazonaws.com",
      "us-east-2": "dax.us-east-2.amazonaws.com",
      "us-east-1": "dax.us-east-1.amazonaws.com",
      "cn-northwest-1": "dax.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dax.ap-south-1.amazonaws.com",
      "eu-north-1": "dax.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dax.ap-northeast-2.amazonaws.com",
      "us-west-1": "dax.us-west-1.amazonaws.com",
      "us-gov-east-1": "dax.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dax.eu-west-3.amazonaws.com",
      "cn-north-1": "dax.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dax.sa-east-1.amazonaws.com",
      "eu-west-1": "dax.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dax.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dax.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dax.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dax"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_592687 = ref object of OpenApiRestCall_592348
proc url_CreateCluster_592689(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_592688(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592814 = header.getOrDefault("X-Amz-Target")
  valid_592814 = validateParameter(valid_592814, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateCluster"))
  if valid_592814 != nil:
    section.add "X-Amz-Target", valid_592814
  var valid_592815 = header.getOrDefault("X-Amz-Signature")
  valid_592815 = validateParameter(valid_592815, JString, required = false,
                                 default = nil)
  if valid_592815 != nil:
    section.add "X-Amz-Signature", valid_592815
  var valid_592816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592816 = validateParameter(valid_592816, JString, required = false,
                                 default = nil)
  if valid_592816 != nil:
    section.add "X-Amz-Content-Sha256", valid_592816
  var valid_592817 = header.getOrDefault("X-Amz-Date")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Date", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Credential")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Credential", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Security-Token")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Security-Token", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Algorithm")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Algorithm", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-SignedHeaders", valid_592821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592845: Call_CreateCluster_592687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ## 
  let valid = call_592845.validator(path, query, header, formData, body)
  let scheme = call_592845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592845.url(scheme.get, call_592845.host, call_592845.base,
                         call_592845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592845, url, valid)

proc call*(call_592916: Call_CreateCluster_592687; body: JsonNode): Recallable =
  ## createCluster
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ##   body: JObject (required)
  var body_592917 = newJObject()
  if body != nil:
    body_592917 = body
  result = call_592916.call(nil, nil, nil, nil, body_592917)

var createCluster* = Call_CreateCluster_592687(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateCluster",
    validator: validate_CreateCluster_592688, base: "/", url: url_CreateCluster_592689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateParameterGroup_592956 = ref object of OpenApiRestCall_592348
proc url_CreateParameterGroup_592958(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateParameterGroup_592957(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592959 = header.getOrDefault("X-Amz-Target")
  valid_592959 = validateParameter(valid_592959, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateParameterGroup"))
  if valid_592959 != nil:
    section.add "X-Amz-Target", valid_592959
  var valid_592960 = header.getOrDefault("X-Amz-Signature")
  valid_592960 = validateParameter(valid_592960, JString, required = false,
                                 default = nil)
  if valid_592960 != nil:
    section.add "X-Amz-Signature", valid_592960
  var valid_592961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Content-Sha256", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Date")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Date", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Credential")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Credential", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Security-Token")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Security-Token", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Algorithm")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Algorithm", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-SignedHeaders", valid_592966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592968: Call_CreateParameterGroup_592956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ## 
  let valid = call_592968.validator(path, query, header, formData, body)
  let scheme = call_592968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592968.url(scheme.get, call_592968.host, call_592968.base,
                         call_592968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592968, url, valid)

proc call*(call_592969: Call_CreateParameterGroup_592956; body: JsonNode): Recallable =
  ## createParameterGroup
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ##   body: JObject (required)
  var body_592970 = newJObject()
  if body != nil:
    body_592970 = body
  result = call_592969.call(nil, nil, nil, nil, body_592970)

var createParameterGroup* = Call_CreateParameterGroup_592956(
    name: "createParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateParameterGroup",
    validator: validate_CreateParameterGroup_592957, base: "/",
    url: url_CreateParameterGroup_592958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubnetGroup_592971 = ref object of OpenApiRestCall_592348
proc url_CreateSubnetGroup_592973(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSubnetGroup_592972(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new subnet group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592974 = header.getOrDefault("X-Amz-Target")
  valid_592974 = validateParameter(valid_592974, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateSubnetGroup"))
  if valid_592974 != nil:
    section.add "X-Amz-Target", valid_592974
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_CreateSubnetGroup_592971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_CreateSubnetGroup_592971; body: JsonNode): Recallable =
  ## createSubnetGroup
  ## Creates a new subnet group.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var createSubnetGroup* = Call_CreateSubnetGroup_592971(name: "createSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateSubnetGroup",
    validator: validate_CreateSubnetGroup_592972, base: "/",
    url: url_CreateSubnetGroup_592973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseReplicationFactor_592986 = ref object of OpenApiRestCall_592348
proc url_DecreaseReplicationFactor_592988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DecreaseReplicationFactor_592987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592989 = header.getOrDefault("X-Amz-Target")
  valid_592989 = validateParameter(valid_592989, JString, required = true, default = newJString(
      "AmazonDAXV3.DecreaseReplicationFactor"))
  if valid_592989 != nil:
    section.add "X-Amz-Target", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Signature")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Signature", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Content-Sha256", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Date")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Date", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Credential")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Credential", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Security-Token")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Security-Token", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Algorithm")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Algorithm", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-SignedHeaders", valid_592996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592998: Call_DecreaseReplicationFactor_592986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_DecreaseReplicationFactor_592986; body: JsonNode): Recallable =
  ## decreaseReplicationFactor
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ##   body: JObject (required)
  var body_593000 = newJObject()
  if body != nil:
    body_593000 = body
  result = call_592999.call(nil, nil, nil, nil, body_593000)

var decreaseReplicationFactor* = Call_DecreaseReplicationFactor_592986(
    name: "decreaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DecreaseReplicationFactor",
    validator: validate_DecreaseReplicationFactor_592987, base: "/",
    url: url_DecreaseReplicationFactor_592988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_593001 = ref object of OpenApiRestCall_592348
proc url_DeleteCluster_593003(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCluster_593002(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593004 = header.getOrDefault("X-Amz-Target")
  valid_593004 = validateParameter(valid_593004, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteCluster"))
  if valid_593004 != nil:
    section.add "X-Amz-Target", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Signature")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Signature", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Content-Sha256", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Date")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Date", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Credential")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Credential", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Security-Token")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Security-Token", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Algorithm")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Algorithm", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-SignedHeaders", valid_593011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593013: Call_DeleteCluster_593001; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ## 
  let valid = call_593013.validator(path, query, header, formData, body)
  let scheme = call_593013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593013.url(scheme.get, call_593013.host, call_593013.base,
                         call_593013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593013, url, valid)

proc call*(call_593014: Call_DeleteCluster_593001; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ##   body: JObject (required)
  var body_593015 = newJObject()
  if body != nil:
    body_593015 = body
  result = call_593014.call(nil, nil, nil, nil, body_593015)

var deleteCluster* = Call_DeleteCluster_593001(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteCluster",
    validator: validate_DeleteCluster_593002, base: "/", url: url_DeleteCluster_593003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameterGroup_593016 = ref object of OpenApiRestCall_592348
proc url_DeleteParameterGroup_593018(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameterGroup_593017(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593019 = header.getOrDefault("X-Amz-Target")
  valid_593019 = validateParameter(valid_593019, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteParameterGroup"))
  if valid_593019 != nil:
    section.add "X-Amz-Target", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Signature")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Signature", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Content-Sha256", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Date")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Date", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Credential")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Credential", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Security-Token")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Security-Token", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Algorithm")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Algorithm", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-SignedHeaders", valid_593026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593028: Call_DeleteParameterGroup_593016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ## 
  let valid = call_593028.validator(path, query, header, formData, body)
  let scheme = call_593028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593028.url(scheme.get, call_593028.host, call_593028.base,
                         call_593028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593028, url, valid)

proc call*(call_593029: Call_DeleteParameterGroup_593016; body: JsonNode): Recallable =
  ## deleteParameterGroup
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ##   body: JObject (required)
  var body_593030 = newJObject()
  if body != nil:
    body_593030 = body
  result = call_593029.call(nil, nil, nil, nil, body_593030)

var deleteParameterGroup* = Call_DeleteParameterGroup_593016(
    name: "deleteParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteParameterGroup",
    validator: validate_DeleteParameterGroup_593017, base: "/",
    url: url_DeleteParameterGroup_593018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubnetGroup_593031 = ref object of OpenApiRestCall_592348
proc url_DeleteSubnetGroup_593033(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSubnetGroup_593032(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593034 = header.getOrDefault("X-Amz-Target")
  valid_593034 = validateParameter(valid_593034, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteSubnetGroup"))
  if valid_593034 != nil:
    section.add "X-Amz-Target", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Signature")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Signature", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Content-Sha256", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Date")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Date", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Credential")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Credential", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Security-Token")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Security-Token", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Algorithm")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Algorithm", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-SignedHeaders", valid_593041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593043: Call_DeleteSubnetGroup_593031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ## 
  let valid = call_593043.validator(path, query, header, formData, body)
  let scheme = call_593043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593043.url(scheme.get, call_593043.host, call_593043.base,
                         call_593043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593043, url, valid)

proc call*(call_593044: Call_DeleteSubnetGroup_593031; body: JsonNode): Recallable =
  ## deleteSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ##   body: JObject (required)
  var body_593045 = newJObject()
  if body != nil:
    body_593045 = body
  result = call_593044.call(nil, nil, nil, nil, body_593045)

var deleteSubnetGroup* = Call_DeleteSubnetGroup_593031(name: "deleteSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteSubnetGroup",
    validator: validate_DeleteSubnetGroup_593032, base: "/",
    url: url_DeleteSubnetGroup_593033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_593046 = ref object of OpenApiRestCall_592348
proc url_DescribeClusters_593048(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeClusters_593047(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593049 = header.getOrDefault("X-Amz-Target")
  valid_593049 = validateParameter(valid_593049, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeClusters"))
  if valid_593049 != nil:
    section.add "X-Amz-Target", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Signature")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Signature", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Content-Sha256", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Date")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Date", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Credential")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Credential", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593058: Call_DescribeClusters_593046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ## 
  let valid = call_593058.validator(path, query, header, formData, body)
  let scheme = call_593058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593058.url(scheme.get, call_593058.host, call_593058.base,
                         call_593058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593058, url, valid)

proc call*(call_593059: Call_DescribeClusters_593046; body: JsonNode): Recallable =
  ## describeClusters
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ##   body: JObject (required)
  var body_593060 = newJObject()
  if body != nil:
    body_593060 = body
  result = call_593059.call(nil, nil, nil, nil, body_593060)

var describeClusters* = Call_DescribeClusters_593046(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeClusters",
    validator: validate_DescribeClusters_593047, base: "/",
    url: url_DescribeClusters_593048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDefaultParameters_593061 = ref object of OpenApiRestCall_592348
proc url_DescribeDefaultParameters_593063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDefaultParameters_593062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the default system parameter information for the DAX caching software.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593064 = header.getOrDefault("X-Amz-Target")
  valid_593064 = validateParameter(valid_593064, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeDefaultParameters"))
  if valid_593064 != nil:
    section.add "X-Amz-Target", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Signature")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Signature", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Content-Sha256", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Date")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Date", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Credential")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Credential", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Security-Token")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Security-Token", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Algorithm")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Algorithm", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-SignedHeaders", valid_593071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593073: Call_DescribeDefaultParameters_593061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the default system parameter information for the DAX caching software.
  ## 
  let valid = call_593073.validator(path, query, header, formData, body)
  let scheme = call_593073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593073.url(scheme.get, call_593073.host, call_593073.base,
                         call_593073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593073, url, valid)

proc call*(call_593074: Call_DescribeDefaultParameters_593061; body: JsonNode): Recallable =
  ## describeDefaultParameters
  ## Returns the default system parameter information for the DAX caching software.
  ##   body: JObject (required)
  var body_593075 = newJObject()
  if body != nil:
    body_593075 = body
  result = call_593074.call(nil, nil, nil, nil, body_593075)

var describeDefaultParameters* = Call_DescribeDefaultParameters_593061(
    name: "describeDefaultParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeDefaultParameters",
    validator: validate_DescribeDefaultParameters_593062, base: "/",
    url: url_DescribeDefaultParameters_593063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_593076 = ref object of OpenApiRestCall_592348
proc url_DescribeEvents_593078(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvents_593077(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593079 = header.getOrDefault("X-Amz-Target")
  valid_593079 = validateParameter(valid_593079, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeEvents"))
  if valid_593079 != nil:
    section.add "X-Amz-Target", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Signature")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Signature", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Content-Sha256", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Date")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Date", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Credential")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Credential", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Security-Token")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Security-Token", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Algorithm")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Algorithm", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-SignedHeaders", valid_593086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593088: Call_DescribeEvents_593076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ## 
  let valid = call_593088.validator(path, query, header, formData, body)
  let scheme = call_593088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593088.url(scheme.get, call_593088.host, call_593088.base,
                         call_593088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593088, url, valid)

proc call*(call_593089: Call_DescribeEvents_593076; body: JsonNode): Recallable =
  ## describeEvents
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ##   body: JObject (required)
  var body_593090 = newJObject()
  if body != nil:
    body_593090 = body
  result = call_593089.call(nil, nil, nil, nil, body_593090)

var describeEvents* = Call_DescribeEvents_593076(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeEvents",
    validator: validate_DescribeEvents_593077, base: "/", url: url_DescribeEvents_593078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameterGroups_593091 = ref object of OpenApiRestCall_592348
proc url_DescribeParameterGroups_593093(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameterGroups_593092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593094 = header.getOrDefault("X-Amz-Target")
  valid_593094 = validateParameter(valid_593094, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameterGroups"))
  if valid_593094 != nil:
    section.add "X-Amz-Target", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Signature")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Signature", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Content-Sha256", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Date")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Date", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Credential")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Credential", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Security-Token")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Security-Token", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Algorithm")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Algorithm", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-SignedHeaders", valid_593101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593103: Call_DescribeParameterGroups_593091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ## 
  let valid = call_593103.validator(path, query, header, formData, body)
  let scheme = call_593103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593103.url(scheme.get, call_593103.host, call_593103.base,
                         call_593103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593103, url, valid)

proc call*(call_593104: Call_DescribeParameterGroups_593091; body: JsonNode): Recallable =
  ## describeParameterGroups
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ##   body: JObject (required)
  var body_593105 = newJObject()
  if body != nil:
    body_593105 = body
  result = call_593104.call(nil, nil, nil, nil, body_593105)

var describeParameterGroups* = Call_DescribeParameterGroups_593091(
    name: "describeParameterGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameterGroups",
    validator: validate_DescribeParameterGroups_593092, base: "/",
    url: url_DescribeParameterGroups_593093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_593106 = ref object of OpenApiRestCall_592348
proc url_DescribeParameters_593108(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameters_593107(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the detailed parameter list for a particular parameter group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593109 = header.getOrDefault("X-Amz-Target")
  valid_593109 = validateParameter(valid_593109, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameters"))
  if valid_593109 != nil:
    section.add "X-Amz-Target", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Signature")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Signature", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Content-Sha256", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Date")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Date", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Credential")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Credential", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Security-Token")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Security-Token", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Algorithm")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Algorithm", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-SignedHeaders", valid_593116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_DescribeParameters_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular parameter group.
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_DescribeParameters_593106; body: JsonNode): Recallable =
  ## describeParameters
  ## Returns the detailed parameter list for a particular parameter group.
  ##   body: JObject (required)
  var body_593120 = newJObject()
  if body != nil:
    body_593120 = body
  result = call_593119.call(nil, nil, nil, nil, body_593120)

var describeParameters* = Call_DescribeParameters_593106(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameters",
    validator: validate_DescribeParameters_593107, base: "/",
    url: url_DescribeParameters_593108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubnetGroups_593121 = ref object of OpenApiRestCall_592348
proc url_DescribeSubnetGroups_593123(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSubnetGroups_593122(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593124 = header.getOrDefault("X-Amz-Target")
  valid_593124 = validateParameter(valid_593124, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeSubnetGroups"))
  if valid_593124 != nil:
    section.add "X-Amz-Target", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Signature")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Signature", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Content-Sha256", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Date")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Date", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Credential")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Credential", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Security-Token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Security-Token", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Algorithm")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Algorithm", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-SignedHeaders", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593133: Call_DescribeSubnetGroups_593121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ## 
  let valid = call_593133.validator(path, query, header, formData, body)
  let scheme = call_593133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593133.url(scheme.get, call_593133.host, call_593133.base,
                         call_593133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593133, url, valid)

proc call*(call_593134: Call_DescribeSubnetGroups_593121; body: JsonNode): Recallable =
  ## describeSubnetGroups
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ##   body: JObject (required)
  var body_593135 = newJObject()
  if body != nil:
    body_593135 = body
  result = call_593134.call(nil, nil, nil, nil, body_593135)

var describeSubnetGroups* = Call_DescribeSubnetGroups_593121(
    name: "describeSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeSubnetGroups",
    validator: validate_DescribeSubnetGroups_593122, base: "/",
    url: url_DescribeSubnetGroups_593123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseReplicationFactor_593136 = ref object of OpenApiRestCall_592348
proc url_IncreaseReplicationFactor_593138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_IncreaseReplicationFactor_593137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more nodes to a DAX cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593139 = header.getOrDefault("X-Amz-Target")
  valid_593139 = validateParameter(valid_593139, JString, required = true, default = newJString(
      "AmazonDAXV3.IncreaseReplicationFactor"))
  if valid_593139 != nil:
    section.add "X-Amz-Target", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-Signature")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-Signature", valid_593140
  var valid_593141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Content-Sha256", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Date")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Date", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Credential")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Credential", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Security-Token")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Security-Token", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Algorithm")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Algorithm", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-SignedHeaders", valid_593146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593148: Call_IncreaseReplicationFactor_593136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more nodes to a DAX cluster.
  ## 
  let valid = call_593148.validator(path, query, header, formData, body)
  let scheme = call_593148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593148.url(scheme.get, call_593148.host, call_593148.base,
                         call_593148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593148, url, valid)

proc call*(call_593149: Call_IncreaseReplicationFactor_593136; body: JsonNode): Recallable =
  ## increaseReplicationFactor
  ## Adds one or more nodes to a DAX cluster.
  ##   body: JObject (required)
  var body_593150 = newJObject()
  if body != nil:
    body_593150 = body
  result = call_593149.call(nil, nil, nil, nil, body_593150)

var increaseReplicationFactor* = Call_IncreaseReplicationFactor_593136(
    name: "increaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.IncreaseReplicationFactor",
    validator: validate_IncreaseReplicationFactor_593137, base: "/",
    url: url_IncreaseReplicationFactor_593138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_593151 = ref object of OpenApiRestCall_592348
proc url_ListTags_593153(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_593152(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593154 = header.getOrDefault("X-Amz-Target")
  valid_593154 = validateParameter(valid_593154, JString, required = true,
                                 default = newJString("AmazonDAXV3.ListTags"))
  if valid_593154 != nil:
    section.add "X-Amz-Target", valid_593154
  var valid_593155 = header.getOrDefault("X-Amz-Signature")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Signature", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Content-Sha256", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Date")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Date", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Credential")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Credential", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Security-Token")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Security-Token", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Algorithm")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Algorithm", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-SignedHeaders", valid_593161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593163: Call_ListTags_593151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ## 
  let valid = call_593163.validator(path, query, header, formData, body)
  let scheme = call_593163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593163.url(scheme.get, call_593163.host, call_593163.base,
                         call_593163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593163, url, valid)

proc call*(call_593164: Call_ListTags_593151; body: JsonNode): Recallable =
  ## listTags
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ##   body: JObject (required)
  var body_593165 = newJObject()
  if body != nil:
    body_593165 = body
  result = call_593164.call(nil, nil, nil, nil, body_593165)

var listTags* = Call_ListTags_593151(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "dax.amazonaws.com",
                                  route: "/#X-Amz-Target=AmazonDAXV3.ListTags",
                                  validator: validate_ListTags_593152, base: "/",
                                  url: url_ListTags_593153,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootNode_593166 = ref object of OpenApiRestCall_592348
proc url_RebootNode_593168(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootNode_593167(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593169 = header.getOrDefault("X-Amz-Target")
  valid_593169 = validateParameter(valid_593169, JString, required = true,
                                 default = newJString("AmazonDAXV3.RebootNode"))
  if valid_593169 != nil:
    section.add "X-Amz-Target", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Signature")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Signature", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Content-Sha256", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Date")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Date", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Credential")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Credential", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Security-Token")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Security-Token", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Algorithm")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Algorithm", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-SignedHeaders", valid_593176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593178: Call_RebootNode_593166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.
  ## 
  let valid = call_593178.validator(path, query, header, formData, body)
  let scheme = call_593178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593178.url(scheme.get, call_593178.host, call_593178.base,
                         call_593178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593178, url, valid)

proc call*(call_593179: Call_RebootNode_593166; body: JsonNode): Recallable =
  ## rebootNode
  ## Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.
  ##   body: JObject (required)
  var body_593180 = newJObject()
  if body != nil:
    body_593180 = body
  result = call_593179.call(nil, nil, nil, nil, body_593180)

var rebootNode* = Call_RebootNode_593166(name: "rebootNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.RebootNode",
                                      validator: validate_RebootNode_593167,
                                      base: "/", url: url_RebootNode_593168,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593181 = ref object of OpenApiRestCall_592348
proc url_TagResource_593183(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593182(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593184 = header.getOrDefault("X-Amz-Target")
  valid_593184 = validateParameter(valid_593184, JString, required = true, default = newJString(
      "AmazonDAXV3.TagResource"))
  if valid_593184 != nil:
    section.add "X-Amz-Target", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Signature")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Signature", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Content-Sha256", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Date")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Date", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Credential")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Credential", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Security-Token")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Security-Token", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Algorithm")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Algorithm", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-SignedHeaders", valid_593191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593193: Call_TagResource_593181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_593193.validator(path, query, header, formData, body)
  let scheme = call_593193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593193.url(scheme.get, call_593193.host, call_593193.base,
                         call_593193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593193, url, valid)

proc call*(call_593194: Call_TagResource_593181; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_593195 = newJObject()
  if body != nil:
    body_593195 = body
  result = call_593194.call(nil, nil, nil, nil, body_593195)

var tagResource* = Call_TagResource_593181(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.TagResource",
                                        validator: validate_TagResource_593182,
                                        base: "/", url: url_TagResource_593183,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593196 = ref object of OpenApiRestCall_592348
proc url_UntagResource_593198(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593197(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593199 = header.getOrDefault("X-Amz-Target")
  valid_593199 = validateParameter(valid_593199, JString, required = true, default = newJString(
      "AmazonDAXV3.UntagResource"))
  if valid_593199 != nil:
    section.add "X-Amz-Target", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Signature")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Signature", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Content-Sha256", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Date")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Date", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Credential")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Credential", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Security-Token")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Security-Token", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Algorithm")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Algorithm", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-SignedHeaders", valid_593206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593208: Call_UntagResource_593196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_593208.validator(path, query, header, formData, body)
  let scheme = call_593208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593208.url(scheme.get, call_593208.host, call_593208.base,
                         call_593208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593208, url, valid)

proc call*(call_593209: Call_UntagResource_593196; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_593210 = newJObject()
  if body != nil:
    body_593210 = body
  result = call_593209.call(nil, nil, nil, nil, body_593210)

var untagResource* = Call_UntagResource_593196(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UntagResource",
    validator: validate_UntagResource_593197, base: "/", url: url_UntagResource_593198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_593211 = ref object of OpenApiRestCall_592348
proc url_UpdateCluster_593213(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCluster_593212(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593214 = header.getOrDefault("X-Amz-Target")
  valid_593214 = validateParameter(valid_593214, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateCluster"))
  if valid_593214 != nil:
    section.add "X-Amz-Target", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Signature")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Signature", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Content-Sha256", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Date")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Date", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Credential")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Credential", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Security-Token")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Security-Token", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Algorithm")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Algorithm", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-SignedHeaders", valid_593221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593223: Call_UpdateCluster_593211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ## 
  let valid = call_593223.validator(path, query, header, formData, body)
  let scheme = call_593223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593223.url(scheme.get, call_593223.host, call_593223.base,
                         call_593223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593223, url, valid)

proc call*(call_593224: Call_UpdateCluster_593211; body: JsonNode): Recallable =
  ## updateCluster
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ##   body: JObject (required)
  var body_593225 = newJObject()
  if body != nil:
    body_593225 = body
  result = call_593224.call(nil, nil, nil, nil, body_593225)

var updateCluster* = Call_UpdateCluster_593211(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateCluster",
    validator: validate_UpdateCluster_593212, base: "/", url: url_UpdateCluster_593213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateParameterGroup_593226 = ref object of OpenApiRestCall_592348
proc url_UpdateParameterGroup_593228(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateParameterGroup_593227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593229 = header.getOrDefault("X-Amz-Target")
  valid_593229 = validateParameter(valid_593229, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateParameterGroup"))
  if valid_593229 != nil:
    section.add "X-Amz-Target", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Signature")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Signature", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Content-Sha256", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Date")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Date", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Credential")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Credential", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Security-Token")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Security-Token", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Algorithm")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Algorithm", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-SignedHeaders", valid_593236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593238: Call_UpdateParameterGroup_593226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ## 
  let valid = call_593238.validator(path, query, header, formData, body)
  let scheme = call_593238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593238.url(scheme.get, call_593238.host, call_593238.base,
                         call_593238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593238, url, valid)

proc call*(call_593239: Call_UpdateParameterGroup_593226; body: JsonNode): Recallable =
  ## updateParameterGroup
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ##   body: JObject (required)
  var body_593240 = newJObject()
  if body != nil:
    body_593240 = body
  result = call_593239.call(nil, nil, nil, nil, body_593240)

var updateParameterGroup* = Call_UpdateParameterGroup_593226(
    name: "updateParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateParameterGroup",
    validator: validate_UpdateParameterGroup_593227, base: "/",
    url: url_UpdateParameterGroup_593228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubnetGroup_593241 = ref object of OpenApiRestCall_592348
proc url_UpdateSubnetGroup_593243(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSubnetGroup_593242(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Modifies an existing subnet group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593244 = header.getOrDefault("X-Amz-Target")
  valid_593244 = validateParameter(valid_593244, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateSubnetGroup"))
  if valid_593244 != nil:
    section.add "X-Amz-Target", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Signature")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Signature", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Content-Sha256", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Date")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Date", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Credential")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Credential", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Security-Token")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Security-Token", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Algorithm")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Algorithm", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-SignedHeaders", valid_593251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593253: Call_UpdateSubnetGroup_593241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group.
  ## 
  let valid = call_593253.validator(path, query, header, formData, body)
  let scheme = call_593253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593253.url(scheme.get, call_593253.host, call_593253.base,
                         call_593253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593253, url, valid)

proc call*(call_593254: Call_UpdateSubnetGroup_593241; body: JsonNode): Recallable =
  ## updateSubnetGroup
  ## Modifies an existing subnet group.
  ##   body: JObject (required)
  var body_593255 = newJObject()
  if body != nil:
    body_593255 = body
  result = call_593254.call(nil, nil, nil, nil, body_593255)

var updateSubnetGroup* = Call_UpdateSubnetGroup_593241(name: "updateSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateSubnetGroup",
    validator: validate_UpdateSubnetGroup_593242, base: "/",
    url: url_UpdateSubnetGroup_593243, schemes: {Scheme.Https, Scheme.Http})
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
