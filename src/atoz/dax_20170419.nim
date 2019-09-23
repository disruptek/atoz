
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600421): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  Call_CreateCluster_600758 = ref object of OpenApiRestCall_600421
proc url_CreateCluster_600760(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_600759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600872 = header.getOrDefault("X-Amz-Date")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Date", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Security-Token")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Security-Token", valid_600873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600887 = header.getOrDefault("X-Amz-Target")
  valid_600887 = validateParameter(valid_600887, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateCluster"))
  if valid_600887 != nil:
    section.add "X-Amz-Target", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_CreateCluster_600758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600916, url, valid)

proc call*(call_600987: Call_CreateCluster_600758; body: JsonNode): Recallable =
  ## createCluster
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ##   body: JObject (required)
  var body_600988 = newJObject()
  if body != nil:
    body_600988 = body
  result = call_600987.call(nil, nil, nil, nil, body_600988)

var createCluster* = Call_CreateCluster_600758(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateCluster",
    validator: validate_CreateCluster_600759, base: "/", url: url_CreateCluster_600760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateParameterGroup_601027 = ref object of OpenApiRestCall_600421
proc url_CreateParameterGroup_601029(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateParameterGroup_601028(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601030 = header.getOrDefault("X-Amz-Date")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Date", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Security-Token")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Security-Token", valid_601031
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601032 = header.getOrDefault("X-Amz-Target")
  valid_601032 = validateParameter(valid_601032, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateParameterGroup"))
  if valid_601032 != nil:
    section.add "X-Amz-Target", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Content-Sha256", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Algorithm")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Algorithm", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Signature")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Signature", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-SignedHeaders", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Credential")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Credential", valid_601037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601039: Call_CreateParameterGroup_601027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ## 
  let valid = call_601039.validator(path, query, header, formData, body)
  let scheme = call_601039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601039.url(scheme.get, call_601039.host, call_601039.base,
                         call_601039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601039, url, valid)

proc call*(call_601040: Call_CreateParameterGroup_601027; body: JsonNode): Recallable =
  ## createParameterGroup
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ##   body: JObject (required)
  var body_601041 = newJObject()
  if body != nil:
    body_601041 = body
  result = call_601040.call(nil, nil, nil, nil, body_601041)

var createParameterGroup* = Call_CreateParameterGroup_601027(
    name: "createParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateParameterGroup",
    validator: validate_CreateParameterGroup_601028, base: "/",
    url: url_CreateParameterGroup_601029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubnetGroup_601042 = ref object of OpenApiRestCall_600421
proc url_CreateSubnetGroup_601044(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSubnetGroup_601043(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601045 = header.getOrDefault("X-Amz-Date")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Date", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Security-Token")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Security-Token", valid_601046
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601047 = header.getOrDefault("X-Amz-Target")
  valid_601047 = validateParameter(valid_601047, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateSubnetGroup"))
  if valid_601047 != nil:
    section.add "X-Amz-Target", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601054: Call_CreateSubnetGroup_601042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group.
  ## 
  let valid = call_601054.validator(path, query, header, formData, body)
  let scheme = call_601054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601054.url(scheme.get, call_601054.host, call_601054.base,
                         call_601054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601054, url, valid)

proc call*(call_601055: Call_CreateSubnetGroup_601042; body: JsonNode): Recallable =
  ## createSubnetGroup
  ## Creates a new subnet group.
  ##   body: JObject (required)
  var body_601056 = newJObject()
  if body != nil:
    body_601056 = body
  result = call_601055.call(nil, nil, nil, nil, body_601056)

var createSubnetGroup* = Call_CreateSubnetGroup_601042(name: "createSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateSubnetGroup",
    validator: validate_CreateSubnetGroup_601043, base: "/",
    url: url_CreateSubnetGroup_601044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseReplicationFactor_601057 = ref object of OpenApiRestCall_600421
proc url_DecreaseReplicationFactor_601059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DecreaseReplicationFactor_601058(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601060 = header.getOrDefault("X-Amz-Date")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Date", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Security-Token")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Security-Token", valid_601061
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601062 = header.getOrDefault("X-Amz-Target")
  valid_601062 = validateParameter(valid_601062, JString, required = true, default = newJString(
      "AmazonDAXV3.DecreaseReplicationFactor"))
  if valid_601062 != nil:
    section.add "X-Amz-Target", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_DecreaseReplicationFactor_601057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601069, url, valid)

proc call*(call_601070: Call_DecreaseReplicationFactor_601057; body: JsonNode): Recallable =
  ## decreaseReplicationFactor
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ##   body: JObject (required)
  var body_601071 = newJObject()
  if body != nil:
    body_601071 = body
  result = call_601070.call(nil, nil, nil, nil, body_601071)

var decreaseReplicationFactor* = Call_DecreaseReplicationFactor_601057(
    name: "decreaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DecreaseReplicationFactor",
    validator: validate_DecreaseReplicationFactor_601058, base: "/",
    url: url_DecreaseReplicationFactor_601059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_601072 = ref object of OpenApiRestCall_600421
proc url_DeleteCluster_601074(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCluster_601073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601075 = header.getOrDefault("X-Amz-Date")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Date", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Security-Token")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Security-Token", valid_601076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601077 = header.getOrDefault("X-Amz-Target")
  valid_601077 = validateParameter(valid_601077, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteCluster"))
  if valid_601077 != nil:
    section.add "X-Amz-Target", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Content-Sha256", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Algorithm")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Algorithm", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Signature")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Signature", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-SignedHeaders", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Credential")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Credential", valid_601082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601084: Call_DeleteCluster_601072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ## 
  let valid = call_601084.validator(path, query, header, formData, body)
  let scheme = call_601084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601084.url(scheme.get, call_601084.host, call_601084.base,
                         call_601084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601084, url, valid)

proc call*(call_601085: Call_DeleteCluster_601072; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ##   body: JObject (required)
  var body_601086 = newJObject()
  if body != nil:
    body_601086 = body
  result = call_601085.call(nil, nil, nil, nil, body_601086)

var deleteCluster* = Call_DeleteCluster_601072(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteCluster",
    validator: validate_DeleteCluster_601073, base: "/", url: url_DeleteCluster_601074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameterGroup_601087 = ref object of OpenApiRestCall_600421
proc url_DeleteParameterGroup_601089(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteParameterGroup_601088(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601090 = header.getOrDefault("X-Amz-Date")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Date", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Security-Token")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Security-Token", valid_601091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601092 = header.getOrDefault("X-Amz-Target")
  valid_601092 = validateParameter(valid_601092, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteParameterGroup"))
  if valid_601092 != nil:
    section.add "X-Amz-Target", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Content-Sha256", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Algorithm")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Algorithm", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Signature")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Signature", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-SignedHeaders", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Credential")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Credential", valid_601097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601099: Call_DeleteParameterGroup_601087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ## 
  let valid = call_601099.validator(path, query, header, formData, body)
  let scheme = call_601099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601099.url(scheme.get, call_601099.host, call_601099.base,
                         call_601099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601099, url, valid)

proc call*(call_601100: Call_DeleteParameterGroup_601087; body: JsonNode): Recallable =
  ## deleteParameterGroup
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ##   body: JObject (required)
  var body_601101 = newJObject()
  if body != nil:
    body_601101 = body
  result = call_601100.call(nil, nil, nil, nil, body_601101)

var deleteParameterGroup* = Call_DeleteParameterGroup_601087(
    name: "deleteParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteParameterGroup",
    validator: validate_DeleteParameterGroup_601088, base: "/",
    url: url_DeleteParameterGroup_601089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubnetGroup_601102 = ref object of OpenApiRestCall_600421
proc url_DeleteSubnetGroup_601104(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSubnetGroup_601103(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601105 = header.getOrDefault("X-Amz-Date")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Date", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Security-Token")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Security-Token", valid_601106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601107 = header.getOrDefault("X-Amz-Target")
  valid_601107 = validateParameter(valid_601107, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteSubnetGroup"))
  if valid_601107 != nil:
    section.add "X-Amz-Target", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Content-Sha256", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Algorithm")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Algorithm", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Signature")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Signature", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-SignedHeaders", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Credential")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Credential", valid_601112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_DeleteSubnetGroup_601102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ## 
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_DeleteSubnetGroup_601102; body: JsonNode): Recallable =
  ## deleteSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ##   body: JObject (required)
  var body_601116 = newJObject()
  if body != nil:
    body_601116 = body
  result = call_601115.call(nil, nil, nil, nil, body_601116)

var deleteSubnetGroup* = Call_DeleteSubnetGroup_601102(name: "deleteSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteSubnetGroup",
    validator: validate_DeleteSubnetGroup_601103, base: "/",
    url: url_DeleteSubnetGroup_601104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_601117 = ref object of OpenApiRestCall_600421
proc url_DescribeClusters_601119(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeClusters_601118(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601120 = header.getOrDefault("X-Amz-Date")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Date", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Security-Token")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Security-Token", valid_601121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601122 = header.getOrDefault("X-Amz-Target")
  valid_601122 = validateParameter(valid_601122, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeClusters"))
  if valid_601122 != nil:
    section.add "X-Amz-Target", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Content-Sha256", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Algorithm")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Algorithm", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Signature")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Signature", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-SignedHeaders", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Credential")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Credential", valid_601127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601129: Call_DescribeClusters_601117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ## 
  let valid = call_601129.validator(path, query, header, formData, body)
  let scheme = call_601129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601129.url(scheme.get, call_601129.host, call_601129.base,
                         call_601129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601129, url, valid)

proc call*(call_601130: Call_DescribeClusters_601117; body: JsonNode): Recallable =
  ## describeClusters
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ##   body: JObject (required)
  var body_601131 = newJObject()
  if body != nil:
    body_601131 = body
  result = call_601130.call(nil, nil, nil, nil, body_601131)

var describeClusters* = Call_DescribeClusters_601117(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeClusters",
    validator: validate_DescribeClusters_601118, base: "/",
    url: url_DescribeClusters_601119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDefaultParameters_601132 = ref object of OpenApiRestCall_600421
proc url_DescribeDefaultParameters_601134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDefaultParameters_601133(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601135 = header.getOrDefault("X-Amz-Date")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Date", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Security-Token")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Security-Token", valid_601136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601137 = header.getOrDefault("X-Amz-Target")
  valid_601137 = validateParameter(valid_601137, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeDefaultParameters"))
  if valid_601137 != nil:
    section.add "X-Amz-Target", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Content-Sha256", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Algorithm")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Algorithm", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Signature")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Signature", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-SignedHeaders", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Credential")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Credential", valid_601142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601144: Call_DescribeDefaultParameters_601132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the default system parameter information for the DAX caching software.
  ## 
  let valid = call_601144.validator(path, query, header, formData, body)
  let scheme = call_601144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601144.url(scheme.get, call_601144.host, call_601144.base,
                         call_601144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601144, url, valid)

proc call*(call_601145: Call_DescribeDefaultParameters_601132; body: JsonNode): Recallable =
  ## describeDefaultParameters
  ## Returns the default system parameter information for the DAX caching software.
  ##   body: JObject (required)
  var body_601146 = newJObject()
  if body != nil:
    body_601146 = body
  result = call_601145.call(nil, nil, nil, nil, body_601146)

var describeDefaultParameters* = Call_DescribeDefaultParameters_601132(
    name: "describeDefaultParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeDefaultParameters",
    validator: validate_DescribeDefaultParameters_601133, base: "/",
    url: url_DescribeDefaultParameters_601134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_601147 = ref object of OpenApiRestCall_600421
proc url_DescribeEvents_601149(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvents_601148(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601150 = header.getOrDefault("X-Amz-Date")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Date", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Security-Token")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Security-Token", valid_601151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601152 = header.getOrDefault("X-Amz-Target")
  valid_601152 = validateParameter(valid_601152, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeEvents"))
  if valid_601152 != nil:
    section.add "X-Amz-Target", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Content-Sha256", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Algorithm")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Algorithm", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Signature")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Signature", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-SignedHeaders", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Credential")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Credential", valid_601157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601159: Call_DescribeEvents_601147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ## 
  let valid = call_601159.validator(path, query, header, formData, body)
  let scheme = call_601159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601159.url(scheme.get, call_601159.host, call_601159.base,
                         call_601159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601159, url, valid)

proc call*(call_601160: Call_DescribeEvents_601147; body: JsonNode): Recallable =
  ## describeEvents
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last hour are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ##   body: JObject (required)
  var body_601161 = newJObject()
  if body != nil:
    body_601161 = body
  result = call_601160.call(nil, nil, nil, nil, body_601161)

var describeEvents* = Call_DescribeEvents_601147(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeEvents",
    validator: validate_DescribeEvents_601148, base: "/", url: url_DescribeEvents_601149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameterGroups_601162 = ref object of OpenApiRestCall_600421
proc url_DescribeParameterGroups_601164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameterGroups_601163(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601165 = header.getOrDefault("X-Amz-Date")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Date", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Security-Token")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Security-Token", valid_601166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601167 = header.getOrDefault("X-Amz-Target")
  valid_601167 = validateParameter(valid_601167, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameterGroups"))
  if valid_601167 != nil:
    section.add "X-Amz-Target", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_DescribeParameterGroups_601162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601174, url, valid)

proc call*(call_601175: Call_DescribeParameterGroups_601162; body: JsonNode): Recallable =
  ## describeParameterGroups
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ##   body: JObject (required)
  var body_601176 = newJObject()
  if body != nil:
    body_601176 = body
  result = call_601175.call(nil, nil, nil, nil, body_601176)

var describeParameterGroups* = Call_DescribeParameterGroups_601162(
    name: "describeParameterGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameterGroups",
    validator: validate_DescribeParameterGroups_601163, base: "/",
    url: url_DescribeParameterGroups_601164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_601177 = ref object of OpenApiRestCall_600421
proc url_DescribeParameters_601179(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeParameters_601178(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601182 = header.getOrDefault("X-Amz-Target")
  valid_601182 = validateParameter(valid_601182, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameters"))
  if valid_601182 != nil:
    section.add "X-Amz-Target", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Content-Sha256", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Algorithm")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Algorithm", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Signature")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Signature", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-SignedHeaders", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Credential")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Credential", valid_601187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601189: Call_DescribeParameters_601177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular parameter group.
  ## 
  let valid = call_601189.validator(path, query, header, formData, body)
  let scheme = call_601189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601189.url(scheme.get, call_601189.host, call_601189.base,
                         call_601189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601189, url, valid)

proc call*(call_601190: Call_DescribeParameters_601177; body: JsonNode): Recallable =
  ## describeParameters
  ## Returns the detailed parameter list for a particular parameter group.
  ##   body: JObject (required)
  var body_601191 = newJObject()
  if body != nil:
    body_601191 = body
  result = call_601190.call(nil, nil, nil, nil, body_601191)

var describeParameters* = Call_DescribeParameters_601177(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameters",
    validator: validate_DescribeParameters_601178, base: "/",
    url: url_DescribeParameters_601179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubnetGroups_601192 = ref object of OpenApiRestCall_600421
proc url_DescribeSubnetGroups_601194(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSubnetGroups_601193(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601195 = header.getOrDefault("X-Amz-Date")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Date", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Security-Token")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Security-Token", valid_601196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601197 = header.getOrDefault("X-Amz-Target")
  valid_601197 = validateParameter(valid_601197, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeSubnetGroups"))
  if valid_601197 != nil:
    section.add "X-Amz-Target", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Content-Sha256", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Algorithm")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Algorithm", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Signature")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Signature", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-SignedHeaders", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Credential")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Credential", valid_601202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601204: Call_DescribeSubnetGroups_601192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ## 
  let valid = call_601204.validator(path, query, header, formData, body)
  let scheme = call_601204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601204.url(scheme.get, call_601204.host, call_601204.base,
                         call_601204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601204, url, valid)

proc call*(call_601205: Call_DescribeSubnetGroups_601192; body: JsonNode): Recallable =
  ## describeSubnetGroups
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ##   body: JObject (required)
  var body_601206 = newJObject()
  if body != nil:
    body_601206 = body
  result = call_601205.call(nil, nil, nil, nil, body_601206)

var describeSubnetGroups* = Call_DescribeSubnetGroups_601192(
    name: "describeSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeSubnetGroups",
    validator: validate_DescribeSubnetGroups_601193, base: "/",
    url: url_DescribeSubnetGroups_601194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseReplicationFactor_601207 = ref object of OpenApiRestCall_600421
proc url_IncreaseReplicationFactor_601209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_IncreaseReplicationFactor_601208(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601210 = header.getOrDefault("X-Amz-Date")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Date", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Security-Token")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Security-Token", valid_601211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601212 = header.getOrDefault("X-Amz-Target")
  valid_601212 = validateParameter(valid_601212, JString, required = true, default = newJString(
      "AmazonDAXV3.IncreaseReplicationFactor"))
  if valid_601212 != nil:
    section.add "X-Amz-Target", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Content-Sha256", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Algorithm")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Algorithm", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Signature")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Signature", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-SignedHeaders", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Credential")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Credential", valid_601217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601219: Call_IncreaseReplicationFactor_601207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more nodes to a DAX cluster.
  ## 
  let valid = call_601219.validator(path, query, header, formData, body)
  let scheme = call_601219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601219.url(scheme.get, call_601219.host, call_601219.base,
                         call_601219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601219, url, valid)

proc call*(call_601220: Call_IncreaseReplicationFactor_601207; body: JsonNode): Recallable =
  ## increaseReplicationFactor
  ## Adds one or more nodes to a DAX cluster.
  ##   body: JObject (required)
  var body_601221 = newJObject()
  if body != nil:
    body_601221 = body
  result = call_601220.call(nil, nil, nil, nil, body_601221)

var increaseReplicationFactor* = Call_IncreaseReplicationFactor_601207(
    name: "increaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.IncreaseReplicationFactor",
    validator: validate_IncreaseReplicationFactor_601208, base: "/",
    url: url_IncreaseReplicationFactor_601209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601222 = ref object of OpenApiRestCall_600421
proc url_ListTags_601224(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_601223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601225 = header.getOrDefault("X-Amz-Date")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Date", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Security-Token")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Security-Token", valid_601226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601227 = header.getOrDefault("X-Amz-Target")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = newJString("AmazonDAXV3.ListTags"))
  if valid_601227 != nil:
    section.add "X-Amz-Target", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Content-Sha256", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Algorithm")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Algorithm", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Signature")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Signature", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-SignedHeaders", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Credential")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Credential", valid_601232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601234: Call_ListTags_601222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ## 
  let valid = call_601234.validator(path, query, header, formData, body)
  let scheme = call_601234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601234.url(scheme.get, call_601234.host, call_601234.base,
                         call_601234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601234, url, valid)

proc call*(call_601235: Call_ListTags_601222; body: JsonNode): Recallable =
  ## listTags
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ##   body: JObject (required)
  var body_601236 = newJObject()
  if body != nil:
    body_601236 = body
  result = call_601235.call(nil, nil, nil, nil, body_601236)

var listTags* = Call_ListTags_601222(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "dax.amazonaws.com",
                                  route: "/#X-Amz-Target=AmazonDAXV3.ListTags",
                                  validator: validate_ListTags_601223, base: "/",
                                  url: url_ListTags_601224,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootNode_601237 = ref object of OpenApiRestCall_600421
proc url_RebootNode_601239(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootNode_601238(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601240 = header.getOrDefault("X-Amz-Date")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Date", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Security-Token")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Security-Token", valid_601241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601242 = header.getOrDefault("X-Amz-Target")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = newJString("AmazonDAXV3.RebootNode"))
  if valid_601242 != nil:
    section.add "X-Amz-Target", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Content-Sha256", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Algorithm")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Algorithm", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Signature")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Signature", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-SignedHeaders", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Credential")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Credential", valid_601247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601249: Call_RebootNode_601237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.
  ## 
  let valid = call_601249.validator(path, query, header, formData, body)
  let scheme = call_601249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601249.url(scheme.get, call_601249.host, call_601249.base,
                         call_601249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601249, url, valid)

proc call*(call_601250: Call_RebootNode_601237; body: JsonNode): Recallable =
  ## rebootNode
  ## Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.
  ##   body: JObject (required)
  var body_601251 = newJObject()
  if body != nil:
    body_601251 = body
  result = call_601250.call(nil, nil, nil, nil, body_601251)

var rebootNode* = Call_RebootNode_601237(name: "rebootNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.RebootNode",
                                      validator: validate_RebootNode_601238,
                                      base: "/", url: url_RebootNode_601239,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601252 = ref object of OpenApiRestCall_600421
proc url_TagResource_601254(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_601253(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601255 = header.getOrDefault("X-Amz-Date")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Date", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Security-Token")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Security-Token", valid_601256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601257 = header.getOrDefault("X-Amz-Target")
  valid_601257 = validateParameter(valid_601257, JString, required = true, default = newJString(
      "AmazonDAXV3.TagResource"))
  if valid_601257 != nil:
    section.add "X-Amz-Target", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Content-Sha256", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Algorithm")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Algorithm", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Signature")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Signature", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-SignedHeaders", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Credential")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Credential", valid_601262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601264: Call_TagResource_601252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_601264.validator(path, query, header, formData, body)
  let scheme = call_601264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601264.url(scheme.get, call_601264.host, call_601264.base,
                         call_601264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601264, url, valid)

proc call*(call_601265: Call_TagResource_601252; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_601266 = newJObject()
  if body != nil:
    body_601266 = body
  result = call_601265.call(nil, nil, nil, nil, body_601266)

var tagResource* = Call_TagResource_601252(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.TagResource",
                                        validator: validate_TagResource_601253,
                                        base: "/", url: url_TagResource_601254,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601267 = ref object of OpenApiRestCall_600421
proc url_UntagResource_601269(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_601268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601270 = header.getOrDefault("X-Amz-Date")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Date", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Security-Token")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Security-Token", valid_601271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601272 = header.getOrDefault("X-Amz-Target")
  valid_601272 = validateParameter(valid_601272, JString, required = true, default = newJString(
      "AmazonDAXV3.UntagResource"))
  if valid_601272 != nil:
    section.add "X-Amz-Target", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Content-Sha256", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Algorithm")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Algorithm", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Signature")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Signature", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-SignedHeaders", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Credential")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Credential", valid_601277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601279: Call_UntagResource_601267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_601279.validator(path, query, header, formData, body)
  let scheme = call_601279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601279.url(scheme.get, call_601279.host, call_601279.base,
                         call_601279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601279, url, valid)

proc call*(call_601280: Call_UntagResource_601267; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_601281 = newJObject()
  if body != nil:
    body_601281 = body
  result = call_601280.call(nil, nil, nil, nil, body_601281)

var untagResource* = Call_UntagResource_601267(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UntagResource",
    validator: validate_UntagResource_601268, base: "/", url: url_UntagResource_601269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_601282 = ref object of OpenApiRestCall_600421
proc url_UpdateCluster_601284(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCluster_601283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601285 = header.getOrDefault("X-Amz-Date")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Date", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Security-Token")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Security-Token", valid_601286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601287 = header.getOrDefault("X-Amz-Target")
  valid_601287 = validateParameter(valid_601287, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateCluster"))
  if valid_601287 != nil:
    section.add "X-Amz-Target", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Content-Sha256", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Algorithm")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Algorithm", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Signature")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Signature", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-SignedHeaders", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Credential")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Credential", valid_601292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601294: Call_UpdateCluster_601282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ## 
  let valid = call_601294.validator(path, query, header, formData, body)
  let scheme = call_601294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601294.url(scheme.get, call_601294.host, call_601294.base,
                         call_601294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601294, url, valid)

proc call*(call_601295: Call_UpdateCluster_601282; body: JsonNode): Recallable =
  ## updateCluster
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ##   body: JObject (required)
  var body_601296 = newJObject()
  if body != nil:
    body_601296 = body
  result = call_601295.call(nil, nil, nil, nil, body_601296)

var updateCluster* = Call_UpdateCluster_601282(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateCluster",
    validator: validate_UpdateCluster_601283, base: "/", url: url_UpdateCluster_601284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateParameterGroup_601297 = ref object of OpenApiRestCall_600421
proc url_UpdateParameterGroup_601299(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateParameterGroup_601298(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601300 = header.getOrDefault("X-Amz-Date")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Date", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Security-Token")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Security-Token", valid_601301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601302 = header.getOrDefault("X-Amz-Target")
  valid_601302 = validateParameter(valid_601302, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateParameterGroup"))
  if valid_601302 != nil:
    section.add "X-Amz-Target", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Content-Sha256", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Algorithm")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Algorithm", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Signature")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Signature", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-SignedHeaders", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Credential")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Credential", valid_601307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601309: Call_UpdateParameterGroup_601297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ## 
  let valid = call_601309.validator(path, query, header, formData, body)
  let scheme = call_601309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601309.url(scheme.get, call_601309.host, call_601309.base,
                         call_601309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601309, url, valid)

proc call*(call_601310: Call_UpdateParameterGroup_601297; body: JsonNode): Recallable =
  ## updateParameterGroup
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ##   body: JObject (required)
  var body_601311 = newJObject()
  if body != nil:
    body_601311 = body
  result = call_601310.call(nil, nil, nil, nil, body_601311)

var updateParameterGroup* = Call_UpdateParameterGroup_601297(
    name: "updateParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateParameterGroup",
    validator: validate_UpdateParameterGroup_601298, base: "/",
    url: url_UpdateParameterGroup_601299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubnetGroup_601312 = ref object of OpenApiRestCall_600421
proc url_UpdateSubnetGroup_601314(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSubnetGroup_601313(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601315 = header.getOrDefault("X-Amz-Date")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Date", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Security-Token")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Security-Token", valid_601316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601317 = header.getOrDefault("X-Amz-Target")
  valid_601317 = validateParameter(valid_601317, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateSubnetGroup"))
  if valid_601317 != nil:
    section.add "X-Amz-Target", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Content-Sha256", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Algorithm")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Algorithm", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Signature", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-SignedHeaders", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Credential")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Credential", valid_601322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601324: Call_UpdateSubnetGroup_601312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group.
  ## 
  let valid = call_601324.validator(path, query, header, formData, body)
  let scheme = call_601324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601324.url(scheme.get, call_601324.host, call_601324.base,
                         call_601324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601324, url, valid)

proc call*(call_601325: Call_UpdateSubnetGroup_601312; body: JsonNode): Recallable =
  ## updateSubnetGroup
  ## Modifies an existing subnet group.
  ##   body: JObject (required)
  var body_601326 = newJObject()
  if body != nil:
    body_601326 = body
  result = call_601325.call(nil, nil, nil, nil, body_601326)

var updateSubnetGroup* = Call_UpdateSubnetGroup_601312(name: "updateSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateSubnetGroup",
    validator: validate_UpdateSubnetGroup_601313, base: "/",
    url: url_UpdateSubnetGroup_601314, schemes: {Scheme.Https, Scheme.Http})
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
