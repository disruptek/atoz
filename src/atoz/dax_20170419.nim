
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_599689 = ref object of OpenApiRestCall_599352
proc url_CreateCluster_599691(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_599690(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599803 = header.getOrDefault("X-Amz-Date")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "X-Amz-Date", valid_599803
  var valid_599804 = header.getOrDefault("X-Amz-Security-Token")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "X-Amz-Security-Token", valid_599804
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599818 = header.getOrDefault("X-Amz-Target")
  valid_599818 = validateParameter(valid_599818, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateCluster"))
  if valid_599818 != nil:
    section.add "X-Amz-Target", valid_599818
  var valid_599819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Content-Sha256", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Algorithm")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Algorithm", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Signature")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Signature", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-SignedHeaders", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Credential")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Credential", valid_599823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599847: Call_CreateCluster_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ## 
  let valid = call_599847.validator(path, query, header, formData, body)
  let scheme = call_599847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599847.url(scheme.get, call_599847.host, call_599847.base,
                         call_599847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599847, url, valid)

proc call*(call_599918: Call_CreateCluster_599689; body: JsonNode): Recallable =
  ## createCluster
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ##   body: JObject (required)
  var body_599919 = newJObject()
  if body != nil:
    body_599919 = body
  result = call_599918.call(nil, nil, nil, nil, body_599919)

var createCluster* = Call_CreateCluster_599689(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateCluster",
    validator: validate_CreateCluster_599690, base: "/", url: url_CreateCluster_599691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateParameterGroup_599958 = ref object of OpenApiRestCall_599352
proc url_CreateParameterGroup_599960(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParameterGroup_599959(path: JsonNode; query: JsonNode;
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
  var valid_599961 = header.getOrDefault("X-Amz-Date")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "X-Amz-Date", valid_599961
  var valid_599962 = header.getOrDefault("X-Amz-Security-Token")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Security-Token", valid_599962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599963 = header.getOrDefault("X-Amz-Target")
  valid_599963 = validateParameter(valid_599963, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateParameterGroup"))
  if valid_599963 != nil:
    section.add "X-Amz-Target", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Content-Sha256", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Algorithm")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Algorithm", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Signature")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Signature", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-SignedHeaders", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Credential")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Credential", valid_599968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599970: Call_CreateParameterGroup_599958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ## 
  let valid = call_599970.validator(path, query, header, formData, body)
  let scheme = call_599970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599970.url(scheme.get, call_599970.host, call_599970.base,
                         call_599970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599970, url, valid)

proc call*(call_599971: Call_CreateParameterGroup_599958; body: JsonNode): Recallable =
  ## createParameterGroup
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ##   body: JObject (required)
  var body_599972 = newJObject()
  if body != nil:
    body_599972 = body
  result = call_599971.call(nil, nil, nil, nil, body_599972)

var createParameterGroup* = Call_CreateParameterGroup_599958(
    name: "createParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateParameterGroup",
    validator: validate_CreateParameterGroup_599959, base: "/",
    url: url_CreateParameterGroup_599960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubnetGroup_599973 = ref object of OpenApiRestCall_599352
proc url_CreateSubnetGroup_599975(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubnetGroup_599974(path: JsonNode; query: JsonNode;
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
  var valid_599976 = header.getOrDefault("X-Amz-Date")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Date", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Security-Token")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Security-Token", valid_599977
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599978 = header.getOrDefault("X-Amz-Target")
  valid_599978 = validateParameter(valid_599978, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateSubnetGroup"))
  if valid_599978 != nil:
    section.add "X-Amz-Target", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Content-Sha256", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Algorithm")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Algorithm", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Signature")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Signature", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-SignedHeaders", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Credential")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Credential", valid_599983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_CreateSubnetGroup_599973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_CreateSubnetGroup_599973; body: JsonNode): Recallable =
  ## createSubnetGroup
  ## Creates a new subnet group.
  ##   body: JObject (required)
  var body_599987 = newJObject()
  if body != nil:
    body_599987 = body
  result = call_599986.call(nil, nil, nil, nil, body_599987)

var createSubnetGroup* = Call_CreateSubnetGroup_599973(name: "createSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateSubnetGroup",
    validator: validate_CreateSubnetGroup_599974, base: "/",
    url: url_CreateSubnetGroup_599975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseReplicationFactor_599988 = ref object of OpenApiRestCall_599352
proc url_DecreaseReplicationFactor_599990(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DecreaseReplicationFactor_599989(path: JsonNode; query: JsonNode;
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
  var valid_599991 = header.getOrDefault("X-Amz-Date")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Date", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Security-Token")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Security-Token", valid_599992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599993 = header.getOrDefault("X-Amz-Target")
  valid_599993 = validateParameter(valid_599993, JString, required = true, default = newJString(
      "AmazonDAXV3.DecreaseReplicationFactor"))
  if valid_599993 != nil:
    section.add "X-Amz-Target", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Content-Sha256", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Algorithm")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Algorithm", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Signature")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Signature", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-SignedHeaders", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Credential")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Credential", valid_599998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600000: Call_DecreaseReplicationFactor_599988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ## 
  let valid = call_600000.validator(path, query, header, formData, body)
  let scheme = call_600000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600000.url(scheme.get, call_600000.host, call_600000.base,
                         call_600000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600000, url, valid)

proc call*(call_600001: Call_DecreaseReplicationFactor_599988; body: JsonNode): Recallable =
  ## decreaseReplicationFactor
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ##   body: JObject (required)
  var body_600002 = newJObject()
  if body != nil:
    body_600002 = body
  result = call_600001.call(nil, nil, nil, nil, body_600002)

var decreaseReplicationFactor* = Call_DecreaseReplicationFactor_599988(
    name: "decreaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DecreaseReplicationFactor",
    validator: validate_DecreaseReplicationFactor_599989, base: "/",
    url: url_DecreaseReplicationFactor_599990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_600003 = ref object of OpenApiRestCall_599352
proc url_DeleteCluster_600005(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCluster_600004(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600006 = header.getOrDefault("X-Amz-Date")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Date", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Security-Token")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Security-Token", valid_600007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600008 = header.getOrDefault("X-Amz-Target")
  valid_600008 = validateParameter(valid_600008, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteCluster"))
  if valid_600008 != nil:
    section.add "X-Amz-Target", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Content-Sha256", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Algorithm")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Algorithm", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Signature")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Signature", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-SignedHeaders", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Credential")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Credential", valid_600013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600015: Call_DeleteCluster_600003; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ## 
  let valid = call_600015.validator(path, query, header, formData, body)
  let scheme = call_600015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600015.url(scheme.get, call_600015.host, call_600015.base,
                         call_600015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600015, url, valid)

proc call*(call_600016: Call_DeleteCluster_600003; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ##   body: JObject (required)
  var body_600017 = newJObject()
  if body != nil:
    body_600017 = body
  result = call_600016.call(nil, nil, nil, nil, body_600017)

var deleteCluster* = Call_DeleteCluster_600003(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteCluster",
    validator: validate_DeleteCluster_600004, base: "/", url: url_DeleteCluster_600005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameterGroup_600018 = ref object of OpenApiRestCall_599352
proc url_DeleteParameterGroup_600020(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameterGroup_600019(path: JsonNode; query: JsonNode;
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
  var valid_600021 = header.getOrDefault("X-Amz-Date")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Date", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Security-Token")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Security-Token", valid_600022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600023 = header.getOrDefault("X-Amz-Target")
  valid_600023 = validateParameter(valid_600023, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteParameterGroup"))
  if valid_600023 != nil:
    section.add "X-Amz-Target", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Content-Sha256", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Algorithm")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Algorithm", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Signature")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Signature", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-SignedHeaders", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Credential")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Credential", valid_600028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600030: Call_DeleteParameterGroup_600018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ## 
  let valid = call_600030.validator(path, query, header, formData, body)
  let scheme = call_600030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600030.url(scheme.get, call_600030.host, call_600030.base,
                         call_600030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600030, url, valid)

proc call*(call_600031: Call_DeleteParameterGroup_600018; body: JsonNode): Recallable =
  ## deleteParameterGroup
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ##   body: JObject (required)
  var body_600032 = newJObject()
  if body != nil:
    body_600032 = body
  result = call_600031.call(nil, nil, nil, nil, body_600032)

var deleteParameterGroup* = Call_DeleteParameterGroup_600018(
    name: "deleteParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteParameterGroup",
    validator: validate_DeleteParameterGroup_600019, base: "/",
    url: url_DeleteParameterGroup_600020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubnetGroup_600033 = ref object of OpenApiRestCall_599352
proc url_DeleteSubnetGroup_600035(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSubnetGroup_600034(path: JsonNode; query: JsonNode;
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
  var valid_600036 = header.getOrDefault("X-Amz-Date")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Date", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Security-Token")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Security-Token", valid_600037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600038 = header.getOrDefault("X-Amz-Target")
  valid_600038 = validateParameter(valid_600038, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteSubnetGroup"))
  if valid_600038 != nil:
    section.add "X-Amz-Target", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_DeleteSubnetGroup_600033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_DeleteSubnetGroup_600033; body: JsonNode): Recallable =
  ## deleteSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ##   body: JObject (required)
  var body_600047 = newJObject()
  if body != nil:
    body_600047 = body
  result = call_600046.call(nil, nil, nil, nil, body_600047)

var deleteSubnetGroup* = Call_DeleteSubnetGroup_600033(name: "deleteSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteSubnetGroup",
    validator: validate_DeleteSubnetGroup_600034, base: "/",
    url: url_DeleteSubnetGroup_600035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_600048 = ref object of OpenApiRestCall_599352
proc url_DescribeClusters_600050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeClusters_600049(path: JsonNode; query: JsonNode;
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
  var valid_600051 = header.getOrDefault("X-Amz-Date")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Date", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Security-Token")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Security-Token", valid_600052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600053 = header.getOrDefault("X-Amz-Target")
  valid_600053 = validateParameter(valid_600053, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeClusters"))
  if valid_600053 != nil:
    section.add "X-Amz-Target", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Content-Sha256", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Algorithm")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Algorithm", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Signature")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Signature", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-SignedHeaders", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Credential")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Credential", valid_600058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600060: Call_DescribeClusters_600048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ## 
  let valid = call_600060.validator(path, query, header, formData, body)
  let scheme = call_600060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600060.url(scheme.get, call_600060.host, call_600060.base,
                         call_600060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600060, url, valid)

proc call*(call_600061: Call_DescribeClusters_600048; body: JsonNode): Recallable =
  ## describeClusters
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ##   body: JObject (required)
  var body_600062 = newJObject()
  if body != nil:
    body_600062 = body
  result = call_600061.call(nil, nil, nil, nil, body_600062)

var describeClusters* = Call_DescribeClusters_600048(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeClusters",
    validator: validate_DescribeClusters_600049, base: "/",
    url: url_DescribeClusters_600050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDefaultParameters_600063 = ref object of OpenApiRestCall_599352
proc url_DescribeDefaultParameters_600065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDefaultParameters_600064(path: JsonNode; query: JsonNode;
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
  var valid_600066 = header.getOrDefault("X-Amz-Date")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Date", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Security-Token")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Security-Token", valid_600067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600068 = header.getOrDefault("X-Amz-Target")
  valid_600068 = validateParameter(valid_600068, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeDefaultParameters"))
  if valid_600068 != nil:
    section.add "X-Amz-Target", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Content-Sha256", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Algorithm")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Algorithm", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Signature")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Signature", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-SignedHeaders", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Credential")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Credential", valid_600073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600075: Call_DescribeDefaultParameters_600063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the default system parameter information for the DAX caching software.
  ## 
  let valid = call_600075.validator(path, query, header, formData, body)
  let scheme = call_600075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600075.url(scheme.get, call_600075.host, call_600075.base,
                         call_600075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600075, url, valid)

proc call*(call_600076: Call_DescribeDefaultParameters_600063; body: JsonNode): Recallable =
  ## describeDefaultParameters
  ## Returns the default system parameter information for the DAX caching software.
  ##   body: JObject (required)
  var body_600077 = newJObject()
  if body != nil:
    body_600077 = body
  result = call_600076.call(nil, nil, nil, nil, body_600077)

var describeDefaultParameters* = Call_DescribeDefaultParameters_600063(
    name: "describeDefaultParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeDefaultParameters",
    validator: validate_DescribeDefaultParameters_600064, base: "/",
    url: url_DescribeDefaultParameters_600065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_600078 = ref object of OpenApiRestCall_599352
proc url_DescribeEvents_600080(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_600079(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
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
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600083 = header.getOrDefault("X-Amz-Target")
  valid_600083 = validateParameter(valid_600083, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeEvents"))
  if valid_600083 != nil:
    section.add "X-Amz-Target", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Content-Sha256", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Algorithm")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Algorithm", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Signature")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Signature", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-SignedHeaders", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Credential")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Credential", valid_600088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600090: Call_DescribeEvents_600078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ## 
  let valid = call_600090.validator(path, query, header, formData, body)
  let scheme = call_600090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600090.url(scheme.get, call_600090.host, call_600090.base,
                         call_600090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600090, url, valid)

proc call*(call_600091: Call_DescribeEvents_600078; body: JsonNode): Recallable =
  ## describeEvents
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ##   body: JObject (required)
  var body_600092 = newJObject()
  if body != nil:
    body_600092 = body
  result = call_600091.call(nil, nil, nil, nil, body_600092)

var describeEvents* = Call_DescribeEvents_600078(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeEvents",
    validator: validate_DescribeEvents_600079, base: "/", url: url_DescribeEvents_600080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameterGroups_600093 = ref object of OpenApiRestCall_599352
proc url_DescribeParameterGroups_600095(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameterGroups_600094(path: JsonNode; query: JsonNode;
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
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600098 = header.getOrDefault("X-Amz-Target")
  valid_600098 = validateParameter(valid_600098, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameterGroups"))
  if valid_600098 != nil:
    section.add "X-Amz-Target", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Content-Sha256", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Algorithm")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Algorithm", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Signature")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Signature", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-SignedHeaders", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Credential")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Credential", valid_600103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600105: Call_DescribeParameterGroups_600093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ## 
  let valid = call_600105.validator(path, query, header, formData, body)
  let scheme = call_600105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600105.url(scheme.get, call_600105.host, call_600105.base,
                         call_600105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600105, url, valid)

proc call*(call_600106: Call_DescribeParameterGroups_600093; body: JsonNode): Recallable =
  ## describeParameterGroups
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ##   body: JObject (required)
  var body_600107 = newJObject()
  if body != nil:
    body_600107 = body
  result = call_600106.call(nil, nil, nil, nil, body_600107)

var describeParameterGroups* = Call_DescribeParameterGroups_600093(
    name: "describeParameterGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameterGroups",
    validator: validate_DescribeParameterGroups_600094, base: "/",
    url: url_DescribeParameterGroups_600095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_600108 = ref object of OpenApiRestCall_599352
proc url_DescribeParameters_600110(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameters_600109(path: JsonNode; query: JsonNode;
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
  var valid_600111 = header.getOrDefault("X-Amz-Date")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Date", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Security-Token")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Security-Token", valid_600112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600113 = header.getOrDefault("X-Amz-Target")
  valid_600113 = validateParameter(valid_600113, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameters"))
  if valid_600113 != nil:
    section.add "X-Amz-Target", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_DescribeParameters_600108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular parameter group.
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_DescribeParameters_600108; body: JsonNode): Recallable =
  ## describeParameters
  ## Returns the detailed parameter list for a particular parameter group.
  ##   body: JObject (required)
  var body_600122 = newJObject()
  if body != nil:
    body_600122 = body
  result = call_600121.call(nil, nil, nil, nil, body_600122)

var describeParameters* = Call_DescribeParameters_600108(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameters",
    validator: validate_DescribeParameters_600109, base: "/",
    url: url_DescribeParameters_600110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubnetGroups_600123 = ref object of OpenApiRestCall_599352
proc url_DescribeSubnetGroups_600125(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubnetGroups_600124(path: JsonNode; query: JsonNode;
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
  var valid_600126 = header.getOrDefault("X-Amz-Date")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Date", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Security-Token")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Security-Token", valid_600127
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600128 = header.getOrDefault("X-Amz-Target")
  valid_600128 = validateParameter(valid_600128, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeSubnetGroups"))
  if valid_600128 != nil:
    section.add "X-Amz-Target", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Content-Sha256", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Algorithm")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Algorithm", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Signature")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Signature", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-SignedHeaders", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Credential")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Credential", valid_600133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600135: Call_DescribeSubnetGroups_600123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ## 
  let valid = call_600135.validator(path, query, header, formData, body)
  let scheme = call_600135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600135.url(scheme.get, call_600135.host, call_600135.base,
                         call_600135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600135, url, valid)

proc call*(call_600136: Call_DescribeSubnetGroups_600123; body: JsonNode): Recallable =
  ## describeSubnetGroups
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ##   body: JObject (required)
  var body_600137 = newJObject()
  if body != nil:
    body_600137 = body
  result = call_600136.call(nil, nil, nil, nil, body_600137)

var describeSubnetGroups* = Call_DescribeSubnetGroups_600123(
    name: "describeSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeSubnetGroups",
    validator: validate_DescribeSubnetGroups_600124, base: "/",
    url: url_DescribeSubnetGroups_600125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseReplicationFactor_600138 = ref object of OpenApiRestCall_599352
proc url_IncreaseReplicationFactor_600140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IncreaseReplicationFactor_600139(path: JsonNode; query: JsonNode;
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
  var valid_600141 = header.getOrDefault("X-Amz-Date")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Date", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Security-Token")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Security-Token", valid_600142
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600143 = header.getOrDefault("X-Amz-Target")
  valid_600143 = validateParameter(valid_600143, JString, required = true, default = newJString(
      "AmazonDAXV3.IncreaseReplicationFactor"))
  if valid_600143 != nil:
    section.add "X-Amz-Target", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Content-Sha256", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Algorithm")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Algorithm", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Signature")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Signature", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-SignedHeaders", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Credential")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Credential", valid_600148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600150: Call_IncreaseReplicationFactor_600138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more nodes to a DAX cluster.
  ## 
  let valid = call_600150.validator(path, query, header, formData, body)
  let scheme = call_600150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600150.url(scheme.get, call_600150.host, call_600150.base,
                         call_600150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600150, url, valid)

proc call*(call_600151: Call_IncreaseReplicationFactor_600138; body: JsonNode): Recallable =
  ## increaseReplicationFactor
  ## Adds one or more nodes to a DAX cluster.
  ##   body: JObject (required)
  var body_600152 = newJObject()
  if body != nil:
    body_600152 = body
  result = call_600151.call(nil, nil, nil, nil, body_600152)

var increaseReplicationFactor* = Call_IncreaseReplicationFactor_600138(
    name: "increaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.IncreaseReplicationFactor",
    validator: validate_IncreaseReplicationFactor_600139, base: "/",
    url: url_IncreaseReplicationFactor_600140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600153 = ref object of OpenApiRestCall_599352
proc url_ListTags_600155(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_600154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600156 = header.getOrDefault("X-Amz-Date")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Date", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Security-Token")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Security-Token", valid_600157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600158 = header.getOrDefault("X-Amz-Target")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = newJString("AmazonDAXV3.ListTags"))
  if valid_600158 != nil:
    section.add "X-Amz-Target", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600165: Call_ListTags_600153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ## 
  let valid = call_600165.validator(path, query, header, formData, body)
  let scheme = call_600165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600165.url(scheme.get, call_600165.host, call_600165.base,
                         call_600165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600165, url, valid)

proc call*(call_600166: Call_ListTags_600153; body: JsonNode): Recallable =
  ## listTags
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ##   body: JObject (required)
  var body_600167 = newJObject()
  if body != nil:
    body_600167 = body
  result = call_600166.call(nil, nil, nil, nil, body_600167)

var listTags* = Call_ListTags_600153(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "dax.amazonaws.com",
                                  route: "/#X-Amz-Target=AmazonDAXV3.ListTags",
                                  validator: validate_ListTags_600154, base: "/",
                                  url: url_ListTags_600155,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootNode_600168 = ref object of OpenApiRestCall_599352
proc url_RebootNode_600170(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootNode_600169(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
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
  var valid_600171 = header.getOrDefault("X-Amz-Date")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Date", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Security-Token")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Security-Token", valid_600172
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600173 = header.getOrDefault("X-Amz-Target")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = newJString("AmazonDAXV3.RebootNode"))
  if valid_600173 != nil:
    section.add "X-Amz-Target", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Content-Sha256", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Algorithm")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Algorithm", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Signature")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Signature", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-SignedHeaders", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Credential")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Credential", valid_600178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_RebootNode_600168; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_RebootNode_600168; body: JsonNode): Recallable =
  ## rebootNode
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
  ##   body: JObject (required)
  var body_600182 = newJObject()
  if body != nil:
    body_600182 = body
  result = call_600181.call(nil, nil, nil, nil, body_600182)

var rebootNode* = Call_RebootNode_600168(name: "rebootNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.RebootNode",
                                      validator: validate_RebootNode_600169,
                                      base: "/", url: url_RebootNode_600170,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600183 = ref object of OpenApiRestCall_599352
proc url_TagResource_600185(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600186 = header.getOrDefault("X-Amz-Date")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Date", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Security-Token")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Security-Token", valid_600187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600188 = header.getOrDefault("X-Amz-Target")
  valid_600188 = validateParameter(valid_600188, JString, required = true, default = newJString(
      "AmazonDAXV3.TagResource"))
  if valid_600188 != nil:
    section.add "X-Amz-Target", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Content-Sha256", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Algorithm")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Algorithm", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Signature")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Signature", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-SignedHeaders", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Credential")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Credential", valid_600193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600195: Call_TagResource_600183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_600195.validator(path, query, header, formData, body)
  let scheme = call_600195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600195.url(scheme.get, call_600195.host, call_600195.base,
                         call_600195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600195, url, valid)

proc call*(call_600196: Call_TagResource_600183; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_600197 = newJObject()
  if body != nil:
    body_600197 = body
  result = call_600196.call(nil, nil, nil, nil, body_600197)

var tagResource* = Call_TagResource_600183(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.TagResource",
                                        validator: validate_TagResource_600184,
                                        base: "/", url: url_TagResource_600185,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600198 = ref object of OpenApiRestCall_599352
proc url_UntagResource_600200(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600201 = header.getOrDefault("X-Amz-Date")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Date", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Security-Token")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Security-Token", valid_600202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600203 = header.getOrDefault("X-Amz-Target")
  valid_600203 = validateParameter(valid_600203, JString, required = true, default = newJString(
      "AmazonDAXV3.UntagResource"))
  if valid_600203 != nil:
    section.add "X-Amz-Target", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Content-Sha256", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Algorithm")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Algorithm", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Signature")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Signature", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-SignedHeaders", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Credential")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Credential", valid_600208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600210: Call_UntagResource_600198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_600210.validator(path, query, header, formData, body)
  let scheme = call_600210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600210.url(scheme.get, call_600210.host, call_600210.base,
                         call_600210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600210, url, valid)

proc call*(call_600211: Call_UntagResource_600198; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_600212 = newJObject()
  if body != nil:
    body_600212 = body
  result = call_600211.call(nil, nil, nil, nil, body_600212)

var untagResource* = Call_UntagResource_600198(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UntagResource",
    validator: validate_UntagResource_600199, base: "/", url: url_UntagResource_600200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_600213 = ref object of OpenApiRestCall_599352
proc url_UpdateCluster_600215(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCluster_600214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600216 = header.getOrDefault("X-Amz-Date")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Date", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Security-Token")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Security-Token", valid_600217
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600218 = header.getOrDefault("X-Amz-Target")
  valid_600218 = validateParameter(valid_600218, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateCluster"))
  if valid_600218 != nil:
    section.add "X-Amz-Target", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Content-Sha256", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Algorithm")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Algorithm", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Signature", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-SignedHeaders", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Credential")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Credential", valid_600223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600225: Call_UpdateCluster_600213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ## 
  let valid = call_600225.validator(path, query, header, formData, body)
  let scheme = call_600225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600225.url(scheme.get, call_600225.host, call_600225.base,
                         call_600225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600225, url, valid)

proc call*(call_600226: Call_UpdateCluster_600213; body: JsonNode): Recallable =
  ## updateCluster
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ##   body: JObject (required)
  var body_600227 = newJObject()
  if body != nil:
    body_600227 = body
  result = call_600226.call(nil, nil, nil, nil, body_600227)

var updateCluster* = Call_UpdateCluster_600213(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateCluster",
    validator: validate_UpdateCluster_600214, base: "/", url: url_UpdateCluster_600215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateParameterGroup_600228 = ref object of OpenApiRestCall_599352
proc url_UpdateParameterGroup_600230(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateParameterGroup_600229(path: JsonNode; query: JsonNode;
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
  var valid_600231 = header.getOrDefault("X-Amz-Date")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Date", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Security-Token")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Security-Token", valid_600232
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600233 = header.getOrDefault("X-Amz-Target")
  valid_600233 = validateParameter(valid_600233, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateParameterGroup"))
  if valid_600233 != nil:
    section.add "X-Amz-Target", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Content-Sha256", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Algorithm")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Algorithm", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Signature")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Signature", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-SignedHeaders", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Credential")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Credential", valid_600238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600240: Call_UpdateParameterGroup_600228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ## 
  let valid = call_600240.validator(path, query, header, formData, body)
  let scheme = call_600240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600240.url(scheme.get, call_600240.host, call_600240.base,
                         call_600240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600240, url, valid)

proc call*(call_600241: Call_UpdateParameterGroup_600228; body: JsonNode): Recallable =
  ## updateParameterGroup
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ##   body: JObject (required)
  var body_600242 = newJObject()
  if body != nil:
    body_600242 = body
  result = call_600241.call(nil, nil, nil, nil, body_600242)

var updateParameterGroup* = Call_UpdateParameterGroup_600228(
    name: "updateParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateParameterGroup",
    validator: validate_UpdateParameterGroup_600229, base: "/",
    url: url_UpdateParameterGroup_600230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubnetGroup_600243 = ref object of OpenApiRestCall_599352
proc url_UpdateSubnetGroup_600245(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSubnetGroup_600244(path: JsonNode; query: JsonNode;
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
  var valid_600246 = header.getOrDefault("X-Amz-Date")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Date", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Security-Token")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Security-Token", valid_600247
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600248 = header.getOrDefault("X-Amz-Target")
  valid_600248 = validateParameter(valid_600248, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateSubnetGroup"))
  if valid_600248 != nil:
    section.add "X-Amz-Target", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Content-Sha256", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Algorithm")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Algorithm", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Signature")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Signature", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-SignedHeaders", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Credential")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Credential", valid_600253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600255: Call_UpdateSubnetGroup_600243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group.
  ## 
  let valid = call_600255.validator(path, query, header, formData, body)
  let scheme = call_600255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600255.url(scheme.get, call_600255.host, call_600255.base,
                         call_600255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600255, url, valid)

proc call*(call_600256: Call_UpdateSubnetGroup_600243; body: JsonNode): Recallable =
  ## updateSubnetGroup
  ## Modifies an existing subnet group.
  ##   body: JObject (required)
  var body_600257 = newJObject()
  if body != nil:
    body_600257 = body
  result = call_600256.call(nil, nil, nil, nil, body_600257)

var updateSubnetGroup* = Call_UpdateSubnetGroup_600243(name: "updateSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateSubnetGroup",
    validator: validate_UpdateSubnetGroup_600244, base: "/",
    url: url_UpdateSubnetGroup_600245, schemes: {Scheme.Https, Scheme.Http})
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
