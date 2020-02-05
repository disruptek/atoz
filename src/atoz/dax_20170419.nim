
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  Call_CreateCluster_612980 = ref object of OpenApiRestCall_612642
proc url_CreateCluster_612982(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_612981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613107 = header.getOrDefault("X-Amz-Target")
  valid_613107 = validateParameter(valid_613107, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateCluster"))
  if valid_613107 != nil:
    section.add "X-Amz-Target", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Signature")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Signature", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Content-Sha256", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Date")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Date", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Credential")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Credential", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Security-Token")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Security-Token", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Algorithm")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Algorithm", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-SignedHeaders", valid_613114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613138: Call_CreateCluster_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ## 
  let valid = call_613138.validator(path, query, header, formData, body)
  let scheme = call_613138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613138.url(scheme.get, call_613138.host, call_613138.base,
                         call_613138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613138, url, valid)

proc call*(call_613209: Call_CreateCluster_612980; body: JsonNode): Recallable =
  ## createCluster
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ##   body: JObject (required)
  var body_613210 = newJObject()
  if body != nil:
    body_613210 = body
  result = call_613209.call(nil, nil, nil, nil, body_613210)

var createCluster* = Call_CreateCluster_612980(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateCluster",
    validator: validate_CreateCluster_612981, base: "/", url: url_CreateCluster_612982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateParameterGroup_613249 = ref object of OpenApiRestCall_612642
proc url_CreateParameterGroup_613251(protocol: Scheme; host: string; base: string;
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

proc validate_CreateParameterGroup_613250(path: JsonNode; query: JsonNode;
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
  var valid_613252 = header.getOrDefault("X-Amz-Target")
  valid_613252 = validateParameter(valid_613252, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateParameterGroup"))
  if valid_613252 != nil:
    section.add "X-Amz-Target", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Signature", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Content-Sha256", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Date")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Date", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Credential")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Credential", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Security-Token")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Security-Token", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Algorithm")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Algorithm", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-SignedHeaders", valid_613259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613261: Call_CreateParameterGroup_613249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ## 
  let valid = call_613261.validator(path, query, header, formData, body)
  let scheme = call_613261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613261.url(scheme.get, call_613261.host, call_613261.base,
                         call_613261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613261, url, valid)

proc call*(call_613262: Call_CreateParameterGroup_613249; body: JsonNode): Recallable =
  ## createParameterGroup
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ##   body: JObject (required)
  var body_613263 = newJObject()
  if body != nil:
    body_613263 = body
  result = call_613262.call(nil, nil, nil, nil, body_613263)

var createParameterGroup* = Call_CreateParameterGroup_613249(
    name: "createParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateParameterGroup",
    validator: validate_CreateParameterGroup_613250, base: "/",
    url: url_CreateParameterGroup_613251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubnetGroup_613264 = ref object of OpenApiRestCall_612642
proc url_CreateSubnetGroup_613266(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSubnetGroup_613265(path: JsonNode; query: JsonNode;
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
  var valid_613267 = header.getOrDefault("X-Amz-Target")
  valid_613267 = validateParameter(valid_613267, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateSubnetGroup"))
  if valid_613267 != nil:
    section.add "X-Amz-Target", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_CreateSubnetGroup_613264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new subnet group.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_CreateSubnetGroup_613264; body: JsonNode): Recallable =
  ## createSubnetGroup
  ## Creates a new subnet group.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var createSubnetGroup* = Call_CreateSubnetGroup_613264(name: "createSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateSubnetGroup",
    validator: validate_CreateSubnetGroup_613265, base: "/",
    url: url_CreateSubnetGroup_613266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseReplicationFactor_613279 = ref object of OpenApiRestCall_612642
proc url_DecreaseReplicationFactor_613281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DecreaseReplicationFactor_613280(path: JsonNode; query: JsonNode;
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
  var valid_613282 = header.getOrDefault("X-Amz-Target")
  valid_613282 = validateParameter(valid_613282, JString, required = true, default = newJString(
      "AmazonDAXV3.DecreaseReplicationFactor"))
  if valid_613282 != nil:
    section.add "X-Amz-Target", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Signature")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Signature", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Content-Sha256", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Date")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Date", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Credential")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Credential", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Security-Token")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Security-Token", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Algorithm")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Algorithm", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-SignedHeaders", valid_613289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613291: Call_DecreaseReplicationFactor_613279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ## 
  let valid = call_613291.validator(path, query, header, formData, body)
  let scheme = call_613291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613291.url(scheme.get, call_613291.host, call_613291.base,
                         call_613291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613291, url, valid)

proc call*(call_613292: Call_DecreaseReplicationFactor_613279; body: JsonNode): Recallable =
  ## decreaseReplicationFactor
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ##   body: JObject (required)
  var body_613293 = newJObject()
  if body != nil:
    body_613293 = body
  result = call_613292.call(nil, nil, nil, nil, body_613293)

var decreaseReplicationFactor* = Call_DecreaseReplicationFactor_613279(
    name: "decreaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DecreaseReplicationFactor",
    validator: validate_DecreaseReplicationFactor_613280, base: "/",
    url: url_DecreaseReplicationFactor_613281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_613294 = ref object of OpenApiRestCall_612642
proc url_DeleteCluster_613296(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_613295(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613297 = header.getOrDefault("X-Amz-Target")
  valid_613297 = validateParameter(valid_613297, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteCluster"))
  if valid_613297 != nil:
    section.add "X-Amz-Target", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613306: Call_DeleteCluster_613294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ## 
  let valid = call_613306.validator(path, query, header, formData, body)
  let scheme = call_613306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613306.url(scheme.get, call_613306.host, call_613306.base,
                         call_613306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613306, url, valid)

proc call*(call_613307: Call_DeleteCluster_613294; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ##   body: JObject (required)
  var body_613308 = newJObject()
  if body != nil:
    body_613308 = body
  result = call_613307.call(nil, nil, nil, nil, body_613308)

var deleteCluster* = Call_DeleteCluster_613294(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteCluster",
    validator: validate_DeleteCluster_613295, base: "/", url: url_DeleteCluster_613296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameterGroup_613309 = ref object of OpenApiRestCall_612642
proc url_DeleteParameterGroup_613311(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteParameterGroup_613310(path: JsonNode; query: JsonNode;
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
  var valid_613312 = header.getOrDefault("X-Amz-Target")
  valid_613312 = validateParameter(valid_613312, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteParameterGroup"))
  if valid_613312 != nil:
    section.add "X-Amz-Target", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613321: Call_DeleteParameterGroup_613309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ## 
  let valid = call_613321.validator(path, query, header, formData, body)
  let scheme = call_613321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613321.url(scheme.get, call_613321.host, call_613321.base,
                         call_613321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613321, url, valid)

proc call*(call_613322: Call_DeleteParameterGroup_613309; body: JsonNode): Recallable =
  ## deleteParameterGroup
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ##   body: JObject (required)
  var body_613323 = newJObject()
  if body != nil:
    body_613323 = body
  result = call_613322.call(nil, nil, nil, nil, body_613323)

var deleteParameterGroup* = Call_DeleteParameterGroup_613309(
    name: "deleteParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteParameterGroup",
    validator: validate_DeleteParameterGroup_613310, base: "/",
    url: url_DeleteParameterGroup_613311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubnetGroup_613324 = ref object of OpenApiRestCall_612642
proc url_DeleteSubnetGroup_613326(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSubnetGroup_613325(path: JsonNode; query: JsonNode;
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
  var valid_613327 = header.getOrDefault("X-Amz-Target")
  valid_613327 = validateParameter(valid_613327, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteSubnetGroup"))
  if valid_613327 != nil:
    section.add "X-Amz-Target", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Signature")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Signature", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Content-Sha256", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Date")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Date", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Credential")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Credential", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Security-Token")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Security-Token", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Algorithm")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Algorithm", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-SignedHeaders", valid_613334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613336: Call_DeleteSubnetGroup_613324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ## 
  let valid = call_613336.validator(path, query, header, formData, body)
  let scheme = call_613336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613336.url(scheme.get, call_613336.host, call_613336.base,
                         call_613336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613336, url, valid)

proc call*(call_613337: Call_DeleteSubnetGroup_613324; body: JsonNode): Recallable =
  ## deleteSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ##   body: JObject (required)
  var body_613338 = newJObject()
  if body != nil:
    body_613338 = body
  result = call_613337.call(nil, nil, nil, nil, body_613338)

var deleteSubnetGroup* = Call_DeleteSubnetGroup_613324(name: "deleteSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteSubnetGroup",
    validator: validate_DeleteSubnetGroup_613325, base: "/",
    url: url_DeleteSubnetGroup_613326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_613339 = ref object of OpenApiRestCall_612642
proc url_DescribeClusters_613341(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeClusters_613340(path: JsonNode; query: JsonNode;
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
  var valid_613342 = header.getOrDefault("X-Amz-Target")
  valid_613342 = validateParameter(valid_613342, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeClusters"))
  if valid_613342 != nil:
    section.add "X-Amz-Target", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_DescribeClusters_613339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_DescribeClusters_613339; body: JsonNode): Recallable =
  ## describeClusters
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ##   body: JObject (required)
  var body_613353 = newJObject()
  if body != nil:
    body_613353 = body
  result = call_613352.call(nil, nil, nil, nil, body_613353)

var describeClusters* = Call_DescribeClusters_613339(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeClusters",
    validator: validate_DescribeClusters_613340, base: "/",
    url: url_DescribeClusters_613341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDefaultParameters_613354 = ref object of OpenApiRestCall_612642
proc url_DescribeDefaultParameters_613356(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDefaultParameters_613355(path: JsonNode; query: JsonNode;
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
  var valid_613357 = header.getOrDefault("X-Amz-Target")
  valid_613357 = validateParameter(valid_613357, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeDefaultParameters"))
  if valid_613357 != nil:
    section.add "X-Amz-Target", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Signature")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Signature", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Content-Sha256", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Date")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Date", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Credential")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Credential", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Security-Token")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Security-Token", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Algorithm")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Algorithm", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-SignedHeaders", valid_613364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613366: Call_DescribeDefaultParameters_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the default system parameter information for the DAX caching software.
  ## 
  let valid = call_613366.validator(path, query, header, formData, body)
  let scheme = call_613366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613366.url(scheme.get, call_613366.host, call_613366.base,
                         call_613366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613366, url, valid)

proc call*(call_613367: Call_DescribeDefaultParameters_613354; body: JsonNode): Recallable =
  ## describeDefaultParameters
  ## Returns the default system parameter information for the DAX caching software.
  ##   body: JObject (required)
  var body_613368 = newJObject()
  if body != nil:
    body_613368 = body
  result = call_613367.call(nil, nil, nil, nil, body_613368)

var describeDefaultParameters* = Call_DescribeDefaultParameters_613354(
    name: "describeDefaultParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeDefaultParameters",
    validator: validate_DescribeDefaultParameters_613355, base: "/",
    url: url_DescribeDefaultParameters_613356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_613369 = ref object of OpenApiRestCall_612642
proc url_DescribeEvents_613371(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEvents_613370(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613372 = header.getOrDefault("X-Amz-Target")
  valid_613372 = validateParameter(valid_613372, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeEvents"))
  if valid_613372 != nil:
    section.add "X-Amz-Target", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Signature")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Signature", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Content-Sha256", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Date")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Date", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Credential")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Credential", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Security-Token")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Security-Token", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Algorithm")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Algorithm", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-SignedHeaders", valid_613379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_DescribeEvents_613369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ## 
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_DescribeEvents_613369; body: JsonNode): Recallable =
  ## describeEvents
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ##   body: JObject (required)
  var body_613383 = newJObject()
  if body != nil:
    body_613383 = body
  result = call_613382.call(nil, nil, nil, nil, body_613383)

var describeEvents* = Call_DescribeEvents_613369(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeEvents",
    validator: validate_DescribeEvents_613370, base: "/", url: url_DescribeEvents_613371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameterGroups_613384 = ref object of OpenApiRestCall_612642
proc url_DescribeParameterGroups_613386(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameterGroups_613385(path: JsonNode; query: JsonNode;
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
  var valid_613387 = header.getOrDefault("X-Amz-Target")
  valid_613387 = validateParameter(valid_613387, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameterGroups"))
  if valid_613387 != nil:
    section.add "X-Amz-Target", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613396: Call_DescribeParameterGroups_613384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ## 
  let valid = call_613396.validator(path, query, header, formData, body)
  let scheme = call_613396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613396.url(scheme.get, call_613396.host, call_613396.base,
                         call_613396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613396, url, valid)

proc call*(call_613397: Call_DescribeParameterGroups_613384; body: JsonNode): Recallable =
  ## describeParameterGroups
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ##   body: JObject (required)
  var body_613398 = newJObject()
  if body != nil:
    body_613398 = body
  result = call_613397.call(nil, nil, nil, nil, body_613398)

var describeParameterGroups* = Call_DescribeParameterGroups_613384(
    name: "describeParameterGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameterGroups",
    validator: validate_DescribeParameterGroups_613385, base: "/",
    url: url_DescribeParameterGroups_613386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_613399 = ref object of OpenApiRestCall_612642
proc url_DescribeParameters_613401(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeParameters_613400(path: JsonNode; query: JsonNode;
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
  var valid_613402 = header.getOrDefault("X-Amz-Target")
  valid_613402 = validateParameter(valid_613402, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameters"))
  if valid_613402 != nil:
    section.add "X-Amz-Target", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_DescribeParameters_613399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the detailed parameter list for a particular parameter group.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_DescribeParameters_613399; body: JsonNode): Recallable =
  ## describeParameters
  ## Returns the detailed parameter list for a particular parameter group.
  ##   body: JObject (required)
  var body_613413 = newJObject()
  if body != nil:
    body_613413 = body
  result = call_613412.call(nil, nil, nil, nil, body_613413)

var describeParameters* = Call_DescribeParameters_613399(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameters",
    validator: validate_DescribeParameters_613400, base: "/",
    url: url_DescribeParameters_613401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubnetGroups_613414 = ref object of OpenApiRestCall_612642
proc url_DescribeSubnetGroups_613416(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSubnetGroups_613415(path: JsonNode; query: JsonNode;
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
  var valid_613417 = header.getOrDefault("X-Amz-Target")
  valid_613417 = validateParameter(valid_613417, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeSubnetGroups"))
  if valid_613417 != nil:
    section.add "X-Amz-Target", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_DescribeSubnetGroups_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_DescribeSubnetGroups_613414; body: JsonNode): Recallable =
  ## describeSubnetGroups
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ##   body: JObject (required)
  var body_613428 = newJObject()
  if body != nil:
    body_613428 = body
  result = call_613427.call(nil, nil, nil, nil, body_613428)

var describeSubnetGroups* = Call_DescribeSubnetGroups_613414(
    name: "describeSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeSubnetGroups",
    validator: validate_DescribeSubnetGroups_613415, base: "/",
    url: url_DescribeSubnetGroups_613416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseReplicationFactor_613429 = ref object of OpenApiRestCall_612642
proc url_IncreaseReplicationFactor_613431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IncreaseReplicationFactor_613430(path: JsonNode; query: JsonNode;
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
  var valid_613432 = header.getOrDefault("X-Amz-Target")
  valid_613432 = validateParameter(valid_613432, JString, required = true, default = newJString(
      "AmazonDAXV3.IncreaseReplicationFactor"))
  if valid_613432 != nil:
    section.add "X-Amz-Target", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Security-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Security-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Algorithm")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Algorithm", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-SignedHeaders", valid_613439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613441: Call_IncreaseReplicationFactor_613429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more nodes to a DAX cluster.
  ## 
  let valid = call_613441.validator(path, query, header, formData, body)
  let scheme = call_613441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613441.url(scheme.get, call_613441.host, call_613441.base,
                         call_613441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613441, url, valid)

proc call*(call_613442: Call_IncreaseReplicationFactor_613429; body: JsonNode): Recallable =
  ## increaseReplicationFactor
  ## Adds one or more nodes to a DAX cluster.
  ##   body: JObject (required)
  var body_613443 = newJObject()
  if body != nil:
    body_613443 = body
  result = call_613442.call(nil, nil, nil, nil, body_613443)

var increaseReplicationFactor* = Call_IncreaseReplicationFactor_613429(
    name: "increaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.IncreaseReplicationFactor",
    validator: validate_IncreaseReplicationFactor_613430, base: "/",
    url: url_IncreaseReplicationFactor_613431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_613444 = ref object of OpenApiRestCall_612642
proc url_ListTags_613446(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_613445(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613447 = header.getOrDefault("X-Amz-Target")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = newJString("AmazonDAXV3.ListTags"))
  if valid_613447 != nil:
    section.add "X-Amz-Target", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Signature")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Signature", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Content-Sha256", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Date")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Date", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Credential")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Credential", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Security-Token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Security-Token", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Algorithm")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Algorithm", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-SignedHeaders", valid_613454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613456: Call_ListTags_613444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ## 
  let valid = call_613456.validator(path, query, header, formData, body)
  let scheme = call_613456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613456.url(scheme.get, call_613456.host, call_613456.base,
                         call_613456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613456, url, valid)

proc call*(call_613457: Call_ListTags_613444; body: JsonNode): Recallable =
  ## listTags
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ##   body: JObject (required)
  var body_613458 = newJObject()
  if body != nil:
    body_613458 = body
  result = call_613457.call(nil, nil, nil, nil, body_613458)

var listTags* = Call_ListTags_613444(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "dax.amazonaws.com",
                                  route: "/#X-Amz-Target=AmazonDAXV3.ListTags",
                                  validator: validate_ListTags_613445, base: "/",
                                  url: url_ListTags_613446,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootNode_613459 = ref object of OpenApiRestCall_612642
proc url_RebootNode_613461(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootNode_613460(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613462 = header.getOrDefault("X-Amz-Target")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = newJString("AmazonDAXV3.RebootNode"))
  if valid_613462 != nil:
    section.add "X-Amz-Target", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_RebootNode_613459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_RebootNode_613459; body: JsonNode): Recallable =
  ## rebootNode
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
  ##   body: JObject (required)
  var body_613473 = newJObject()
  if body != nil:
    body_613473 = body
  result = call_613472.call(nil, nil, nil, nil, body_613473)

var rebootNode* = Call_RebootNode_613459(name: "rebootNode",
                                      meth: HttpMethod.HttpPost,
                                      host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.RebootNode",
                                      validator: validate_RebootNode_613460,
                                      base: "/", url: url_RebootNode_613461,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613474 = ref object of OpenApiRestCall_612642
proc url_TagResource_613476(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613477 = header.getOrDefault("X-Amz-Target")
  valid_613477 = validateParameter(valid_613477, JString, required = true, default = newJString(
      "AmazonDAXV3.TagResource"))
  if valid_613477 != nil:
    section.add "X-Amz-Target", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Signature")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Signature", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Content-Sha256", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Date")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Date", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Credential")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Credential", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Security-Token")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Security-Token", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Algorithm")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Algorithm", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-SignedHeaders", valid_613484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613486: Call_TagResource_613474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_613486.validator(path, query, header, formData, body)
  let scheme = call_613486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613486.url(scheme.get, call_613486.host, call_613486.base,
                         call_613486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613486, url, valid)

proc call*(call_613487: Call_TagResource_613474; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_613488 = newJObject()
  if body != nil:
    body_613488 = body
  result = call_613487.call(nil, nil, nil, nil, body_613488)

var tagResource* = Call_TagResource_613474(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.TagResource",
                                        validator: validate_TagResource_613475,
                                        base: "/", url: url_TagResource_613476,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613489 = ref object of OpenApiRestCall_612642
proc url_UntagResource_613491(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613490(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613492 = header.getOrDefault("X-Amz-Target")
  valid_613492 = validateParameter(valid_613492, JString, required = true, default = newJString(
      "AmazonDAXV3.UntagResource"))
  if valid_613492 != nil:
    section.add "X-Amz-Target", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Signature")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Signature", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Content-Sha256", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Date")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Date", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Credential")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Credential", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Security-Token")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Security-Token", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Algorithm")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Algorithm", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-SignedHeaders", valid_613499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_UntagResource_613489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ## 
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_UntagResource_613489; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ##   body: JObject (required)
  var body_613503 = newJObject()
  if body != nil:
    body_613503 = body
  result = call_613502.call(nil, nil, nil, nil, body_613503)

var untagResource* = Call_UntagResource_613489(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UntagResource",
    validator: validate_UntagResource_613490, base: "/", url: url_UntagResource_613491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_613504 = ref object of OpenApiRestCall_612642
proc url_UpdateCluster_613506(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCluster_613505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613507 = header.getOrDefault("X-Amz-Target")
  valid_613507 = validateParameter(valid_613507, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateCluster"))
  if valid_613507 != nil:
    section.add "X-Amz-Target", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Signature")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Signature", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Content-Sha256", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Date")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Date", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Credential")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Credential", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Security-Token")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Security-Token", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Algorithm")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Algorithm", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-SignedHeaders", valid_613514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613516: Call_UpdateCluster_613504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ## 
  let valid = call_613516.validator(path, query, header, formData, body)
  let scheme = call_613516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613516.url(scheme.get, call_613516.host, call_613516.base,
                         call_613516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613516, url, valid)

proc call*(call_613517: Call_UpdateCluster_613504; body: JsonNode): Recallable =
  ## updateCluster
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ##   body: JObject (required)
  var body_613518 = newJObject()
  if body != nil:
    body_613518 = body
  result = call_613517.call(nil, nil, nil, nil, body_613518)

var updateCluster* = Call_UpdateCluster_613504(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateCluster",
    validator: validate_UpdateCluster_613505, base: "/", url: url_UpdateCluster_613506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateParameterGroup_613519 = ref object of OpenApiRestCall_612642
proc url_UpdateParameterGroup_613521(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateParameterGroup_613520(path: JsonNode; query: JsonNode;
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
  var valid_613522 = header.getOrDefault("X-Amz-Target")
  valid_613522 = validateParameter(valid_613522, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateParameterGroup"))
  if valid_613522 != nil:
    section.add "X-Amz-Target", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Signature")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Signature", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Content-Sha256", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Date")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Date", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Credential")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Credential", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Security-Token")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Security-Token", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Algorithm")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Algorithm", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-SignedHeaders", valid_613529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613531: Call_UpdateParameterGroup_613519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ## 
  let valid = call_613531.validator(path, query, header, formData, body)
  let scheme = call_613531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613531.url(scheme.get, call_613531.host, call_613531.base,
                         call_613531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613531, url, valid)

proc call*(call_613532: Call_UpdateParameterGroup_613519; body: JsonNode): Recallable =
  ## updateParameterGroup
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ##   body: JObject (required)
  var body_613533 = newJObject()
  if body != nil:
    body_613533 = body
  result = call_613532.call(nil, nil, nil, nil, body_613533)

var updateParameterGroup* = Call_UpdateParameterGroup_613519(
    name: "updateParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateParameterGroup",
    validator: validate_UpdateParameterGroup_613520, base: "/",
    url: url_UpdateParameterGroup_613521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubnetGroup_613534 = ref object of OpenApiRestCall_612642
proc url_UpdateSubnetGroup_613536(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSubnetGroup_613535(path: JsonNode; query: JsonNode;
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
  var valid_613537 = header.getOrDefault("X-Amz-Target")
  valid_613537 = validateParameter(valid_613537, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateSubnetGroup"))
  if valid_613537 != nil:
    section.add "X-Amz-Target", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Signature")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Signature", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Content-Sha256", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Date")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Date", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Credential")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Credential", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Security-Token")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Security-Token", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Algorithm")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Algorithm", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-SignedHeaders", valid_613544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613546: Call_UpdateSubnetGroup_613534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing subnet group.
  ## 
  let valid = call_613546.validator(path, query, header, formData, body)
  let scheme = call_613546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613546.url(scheme.get, call_613546.host, call_613546.base,
                         call_613546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613546, url, valid)

proc call*(call_613547: Call_UpdateSubnetGroup_613534; body: JsonNode): Recallable =
  ## updateSubnetGroup
  ## Modifies an existing subnet group.
  ##   body: JObject (required)
  var body_613548 = newJObject()
  if body != nil:
    body_613548 = body
  result = call_613547.call(nil, nil, nil, nil, body_613548)

var updateSubnetGroup* = Call_UpdateSubnetGroup_613534(name: "updateSubnetGroup",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateSubnetGroup",
    validator: validate_UpdateSubnetGroup_613535, base: "/",
    url: url_UpdateSubnetGroup_613536, schemes: {Scheme.Https, Scheme.Http})
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
