
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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

  OpenApiRestCall_402656035 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656035](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656035): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "dax.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dax.ap-southeast-1.amazonaws.com",
                               "us-west-2": "dax.us-west-2.amazonaws.com",
                               "eu-west-2": "dax.eu-west-2.amazonaws.com", "ap-northeast-3": "dax.ap-northeast-3.amazonaws.com", "eu-central-1": "dax.eu-central-1.amazonaws.com",
                               "us-east-2": "dax.us-east-2.amazonaws.com",
                               "us-east-1": "dax.us-east-1.amazonaws.com", "cn-northwest-1": "dax.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "dax.ap-south-1.amazonaws.com",
                               "eu-north-1": "dax.eu-north-1.amazonaws.com", "ap-northeast-2": "dax.ap-northeast-2.amazonaws.com",
                               "us-west-1": "dax.us-west-1.amazonaws.com", "us-gov-east-1": "dax.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "dax.eu-west-3.amazonaws.com",
                               "cn-north-1": "dax.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "dax.sa-east-1.amazonaws.com",
                               "eu-west-1": "dax.eu-west-1.amazonaws.com", "us-gov-west-1": "dax.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dax.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "dax.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateCluster_402656285 = ref object of OpenApiRestCall_402656035
proc url_CreateCluster_402656287(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_402656286(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Target")
  valid_402656381 = validateParameter(valid_402656381, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateCluster"))
  if valid_402656381 != nil:
    section.add "X-Amz-Target", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Security-Token", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Signature")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Signature", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Algorithm", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Date")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Date", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Credential")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Credential", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656388
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

proc call*(call_402656403: Call_CreateCluster_402656285; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
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

proc call*(call_402656452: Call_CreateCluster_402656285; body: JsonNode): Recallable =
  ## createCluster
  ## Creates a DAX cluster. All nodes in the cluster run the same DAX caching software.
  ##   
                                                                                       ## body: JObject (required)
  var body_402656453 = newJObject()
  if body != nil:
    body_402656453 = body
  result = call_402656452.call(nil, nil, nil, nil, body_402656453)

var createCluster* = Call_CreateCluster_402656285(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateCluster",
    validator: validate_CreateCluster_402656286, base: "/",
    makeUrl: url_CreateCluster_402656287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateParameterGroup_402656480 = ref object of OpenApiRestCall_402656035
proc url_CreateParameterGroup_402656482(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParameterGroup_402656481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656483 = header.getOrDefault("X-Amz-Target")
  valid_402656483 = validateParameter(valid_402656483, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateParameterGroup"))
  if valid_402656483 != nil:
    section.add "X-Amz-Target", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Security-Token", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Signature")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Signature", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Algorithm", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Date")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Date", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Credential")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Credential", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656490
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

proc call*(call_402656492: Call_CreateParameterGroup_402656480;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_CreateParameterGroup_402656480; body: JsonNode): Recallable =
  ## createParameterGroup
  ## Creates a new parameter group. A parameter group is a collection of parameters that you apply to all of the nodes in a DAX cluster.
  ##   
                                                                                                                                        ## body: JObject (required)
  var body_402656494 = newJObject()
  if body != nil:
    body_402656494 = body
  result = call_402656493.call(nil, nil, nil, nil, body_402656494)

var createParameterGroup* = Call_CreateParameterGroup_402656480(
    name: "createParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateParameterGroup",
    validator: validate_CreateParameterGroup_402656481, base: "/",
    makeUrl: url_CreateParameterGroup_402656482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSubnetGroup_402656495 = ref object of OpenApiRestCall_402656035
proc url_CreateSubnetGroup_402656497(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSubnetGroup_402656496(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656498 = header.getOrDefault("X-Amz-Target")
  valid_402656498 = validateParameter(valid_402656498, JString, required = true, default = newJString(
      "AmazonDAXV3.CreateSubnetGroup"))
  if valid_402656498 != nil:
    section.add "X-Amz-Target", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Security-Token", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Signature")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Signature", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Algorithm", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Date")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Date", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Credential")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Credential", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656505
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

proc call*(call_402656507: Call_CreateSubnetGroup_402656495;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new subnet group.
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_CreateSubnetGroup_402656495; body: JsonNode): Recallable =
  ## createSubnetGroup
  ## Creates a new subnet group.
  ##   body: JObject (required)
  var body_402656509 = newJObject()
  if body != nil:
    body_402656509 = body
  result = call_402656508.call(nil, nil, nil, nil, body_402656509)

var createSubnetGroup* = Call_CreateSubnetGroup_402656495(
    name: "createSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.CreateSubnetGroup",
    validator: validate_CreateSubnetGroup_402656496, base: "/",
    makeUrl: url_CreateSubnetGroup_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DecreaseReplicationFactor_402656510 = ref object of OpenApiRestCall_402656035
proc url_DecreaseReplicationFactor_402656512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DecreaseReplicationFactor_402656511(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656513 = header.getOrDefault("X-Amz-Target")
  valid_402656513 = validateParameter(valid_402656513, JString, required = true, default = newJString(
      "AmazonDAXV3.DecreaseReplicationFactor"))
  if valid_402656513 != nil:
    section.add "X-Amz-Target", valid_402656513
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

proc call*(call_402656522: Call_DecreaseReplicationFactor_402656510;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
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

proc call*(call_402656523: Call_DecreaseReplicationFactor_402656510;
           body: JsonNode): Recallable =
  ## decreaseReplicationFactor
  ## <p>Removes one or more nodes from a DAX cluster.</p> <note> <p>You cannot use <code>DecreaseReplicationFactor</code> to remove the last node in a DAX cluster. If you need to do this, use <code>DeleteCluster</code> instead.</p> </note>
  ##   
                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656524 = newJObject()
  if body != nil:
    body_402656524 = body
  result = call_402656523.call(nil, nil, nil, nil, body_402656524)

var decreaseReplicationFactor* = Call_DecreaseReplicationFactor_402656510(
    name: "decreaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DecreaseReplicationFactor",
    validator: validate_DecreaseReplicationFactor_402656511, base: "/",
    makeUrl: url_DecreaseReplicationFactor_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_402656525 = ref object of OpenApiRestCall_402656035
proc url_DeleteCluster_402656527(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCluster_402656526(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656528 = header.getOrDefault("X-Amz-Target")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteCluster"))
  if valid_402656528 != nil:
    section.add "X-Amz-Target", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
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

proc call*(call_402656537: Call_DeleteCluster_402656525; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
                                                                                         ## 
  let valid = call_402656537.validator(path, query, header, formData, body, _)
  let scheme = call_402656537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656537.makeUrl(scheme.get, call_402656537.host, call_402656537.base,
                                   call_402656537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656537, uri, valid, _)

proc call*(call_402656538: Call_DeleteCluster_402656525; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes a previously provisioned DAX cluster. <i>DeleteCluster</i> deletes all associated nodes, node endpoints and the DAX cluster itself. When you receive a successful response from this action, DAX immediately begins deleting the cluster; you cannot cancel or revert this action.
  ##   
                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656539 = newJObject()
  if body != nil:
    body_402656539 = body
  result = call_402656538.call(nil, nil, nil, nil, body_402656539)

var deleteCluster* = Call_DeleteCluster_402656525(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteCluster",
    validator: validate_DeleteCluster_402656526, base: "/",
    makeUrl: url_DeleteCluster_402656527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameterGroup_402656540 = ref object of OpenApiRestCall_402656035
proc url_DeleteParameterGroup_402656542(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameterGroup_402656541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656543 = header.getOrDefault("X-Amz-Target")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteParameterGroup"))
  if valid_402656543 != nil:
    section.add "X-Amz-Target", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
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

proc call*(call_402656552: Call_DeleteParameterGroup_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
                                                                                         ## 
  let valid = call_402656552.validator(path, query, header, formData, body, _)
  let scheme = call_402656552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656552.makeUrl(scheme.get, call_402656552.host, call_402656552.base,
                                   call_402656552.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656552, uri, valid, _)

proc call*(call_402656553: Call_DeleteParameterGroup_402656540; body: JsonNode): Recallable =
  ## deleteParameterGroup
  ## Deletes the specified parameter group. You cannot delete a parameter group if it is associated with any DAX clusters.
  ##   
                                                                                                                          ## body: JObject (required)
  var body_402656554 = newJObject()
  if body != nil:
    body_402656554 = body
  result = call_402656553.call(nil, nil, nil, nil, body_402656554)

var deleteParameterGroup* = Call_DeleteParameterGroup_402656540(
    name: "deleteParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteParameterGroup",
    validator: validate_DeleteParameterGroup_402656541, base: "/",
    makeUrl: url_DeleteParameterGroup_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSubnetGroup_402656555 = ref object of OpenApiRestCall_402656035
proc url_DeleteSubnetGroup_402656557(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSubnetGroup_402656556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Target")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true, default = newJString(
      "AmazonDAXV3.DeleteSubnetGroup"))
  if valid_402656558 != nil:
    section.add "X-Amz-Target", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
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

proc call*(call_402656567: Call_DeleteSubnetGroup_402656555;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
                                                                                         ## 
  let valid = call_402656567.validator(path, query, header, formData, body, _)
  let scheme = call_402656567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656567.makeUrl(scheme.get, call_402656567.host, call_402656567.base,
                                   call_402656567.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656567, uri, valid, _)

proc call*(call_402656568: Call_DeleteSubnetGroup_402656555; body: JsonNode): Recallable =
  ## deleteSubnetGroup
  ## <p>Deletes a subnet group.</p> <note> <p>You cannot delete a subnet group if it is associated with any DAX clusters.</p> </note>
  ##   
                                                                                                                                     ## body: JObject (required)
  var body_402656569 = newJObject()
  if body != nil:
    body_402656569 = body
  result = call_402656568.call(nil, nil, nil, nil, body_402656569)

var deleteSubnetGroup* = Call_DeleteSubnetGroup_402656555(
    name: "deleteSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DeleteSubnetGroup",
    validator: validate_DeleteSubnetGroup_402656556, base: "/",
    makeUrl: url_DeleteSubnetGroup_402656557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_402656570 = ref object of OpenApiRestCall_402656035
proc url_DescribeClusters_402656572(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeClusters_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Target")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeClusters"))
  if valid_402656573 != nil:
    section.add "X-Amz-Target", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
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

proc call*(call_402656582: Call_DescribeClusters_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
                                                                                         ## 
  let valid = call_402656582.validator(path, query, header, formData, body, _)
  let scheme = call_402656582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656582.makeUrl(scheme.get, call_402656582.host, call_402656582.base,
                                   call_402656582.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656582, uri, valid, _)

proc call*(call_402656583: Call_DescribeClusters_402656570; body: JsonNode): Recallable =
  ## describeClusters
  ## <p>Returns information about all provisioned DAX clusters if no cluster identifier is specified, or about a specific DAX cluster if a cluster identifier is supplied.</p> <p>If the cluster is in the CREATING state, only cluster level information will be displayed until all of the nodes are successfully provisioned.</p> <p>If the cluster is in the DELETING state, only cluster level information will be displayed.</p> <p>If nodes are currently being added to the DAX cluster, node endpoint information and creation time for the additional nodes will not be displayed until they are completely provisioned. When the DAX cluster state is <i>available</i>, the cluster is ready for use.</p> <p>If nodes are currently being removed from the DAX cluster, no endpoint information for the removed nodes is displayed.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656584 = newJObject()
  if body != nil:
    body_402656584 = body
  result = call_402656583.call(nil, nil, nil, nil, body_402656584)

var describeClusters* = Call_DescribeClusters_402656570(
    name: "describeClusters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeClusters",
    validator: validate_DescribeClusters_402656571, base: "/",
    makeUrl: url_DescribeClusters_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDefaultParameters_402656585 = ref object of OpenApiRestCall_402656035
proc url_DescribeDefaultParameters_402656587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDefaultParameters_402656586(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656588 = header.getOrDefault("X-Amz-Target")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeDefaultParameters"))
  if valid_402656588 != nil:
    section.add "X-Amz-Target", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Security-Token", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Signature")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Signature", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Algorithm", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Date")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Date", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Credential")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Credential", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656595
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

proc call*(call_402656597: Call_DescribeDefaultParameters_402656585;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the default system parameter information for the DAX caching software.
                                                                                         ## 
  let valid = call_402656597.validator(path, query, header, formData, body, _)
  let scheme = call_402656597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656597.makeUrl(scheme.get, call_402656597.host, call_402656597.base,
                                   call_402656597.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656597, uri, valid, _)

proc call*(call_402656598: Call_DescribeDefaultParameters_402656585;
           body: JsonNode): Recallable =
  ## describeDefaultParameters
  ## Returns the default system parameter information for the DAX caching software.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656599 = newJObject()
  if body != nil:
    body_402656599 = body
  result = call_402656598.call(nil, nil, nil, nil, body_402656599)

var describeDefaultParameters* = Call_DescribeDefaultParameters_402656585(
    name: "describeDefaultParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeDefaultParameters",
    validator: validate_DescribeDefaultParameters_402656586, base: "/",
    makeUrl: url_DescribeDefaultParameters_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_402656600 = ref object of OpenApiRestCall_402656035
proc url_DescribeEvents_402656602(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_402656601(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656603 = header.getOrDefault("X-Amz-Target")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeEvents"))
  if valid_402656603 != nil:
    section.add "X-Amz-Target", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_DescribeEvents_402656600; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_DescribeEvents_402656600; body: JsonNode): Recallable =
  ## describeEvents
  ## <p>Returns events related to DAX clusters and parameter groups. You can obtain events specific to a particular DAX cluster or parameter group by providing the name as a parameter.</p> <p>By default, only the events occurring within the last 24 hours are returned; however, you can retrieve up to 14 days' worth of events if necessary.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  result = call_402656613.call(nil, nil, nil, nil, body_402656614)

var describeEvents* = Call_DescribeEvents_402656600(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeEvents",
    validator: validate_DescribeEvents_402656601, base: "/",
    makeUrl: url_DescribeEvents_402656602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameterGroups_402656615 = ref object of OpenApiRestCall_402656035
proc url_DescribeParameterGroups_402656617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameterGroups_402656616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656618 = header.getOrDefault("X-Amz-Target")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameterGroups"))
  if valid_402656618 != nil:
    section.add "X-Amz-Target", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Security-Token", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Signature")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Signature", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Algorithm", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Date")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Date", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Credential")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Credential", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656625
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

proc call*(call_402656627: Call_DescribeParameterGroups_402656615;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
                                                                                         ## 
  let valid = call_402656627.validator(path, query, header, formData, body, _)
  let scheme = call_402656627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656627.makeUrl(scheme.get, call_402656627.host, call_402656627.base,
                                   call_402656627.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656627, uri, valid, _)

proc call*(call_402656628: Call_DescribeParameterGroups_402656615;
           body: JsonNode): Recallable =
  ## describeParameterGroups
  ## Returns a list of parameter group descriptions. If a parameter group name is specified, the list will contain only the descriptions for that group.
  ##   
                                                                                                                                                        ## body: JObject (required)
  var body_402656629 = newJObject()
  if body != nil:
    body_402656629 = body
  result = call_402656628.call(nil, nil, nil, nil, body_402656629)

var describeParameterGroups* = Call_DescribeParameterGroups_402656615(
    name: "describeParameterGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameterGroups",
    validator: validate_DescribeParameterGroups_402656616, base: "/",
    makeUrl: url_DescribeParameterGroups_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_402656630 = ref object of OpenApiRestCall_402656035
proc url_DescribeParameters_402656632(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameters_402656631(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656633 = header.getOrDefault("X-Amz-Target")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeParameters"))
  if valid_402656633 != nil:
    section.add "X-Amz-Target", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Security-Token", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Signature")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Signature", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Algorithm", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Date")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Date", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Credential")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Credential", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656640
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

proc call*(call_402656642: Call_DescribeParameters_402656630;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the detailed parameter list for a particular parameter group.
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_DescribeParameters_402656630; body: JsonNode): Recallable =
  ## describeParameters
  ## Returns the detailed parameter list for a particular parameter group.
  ##   body: 
                                                                          ## JObject (required)
  var body_402656644 = newJObject()
  if body != nil:
    body_402656644 = body
  result = call_402656643.call(nil, nil, nil, nil, body_402656644)

var describeParameters* = Call_DescribeParameters_402656630(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeParameters",
    validator: validate_DescribeParameters_402656631, base: "/",
    makeUrl: url_DescribeParameters_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubnetGroups_402656645 = ref object of OpenApiRestCall_402656035
proc url_DescribeSubnetGroups_402656647(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubnetGroups_402656646(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656648 = header.getOrDefault("X-Amz-Target")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true, default = newJString(
      "AmazonDAXV3.DescribeSubnetGroups"))
  if valid_402656648 != nil:
    section.add "X-Amz-Target", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Security-Token", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Signature")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Signature", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Algorithm", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Date")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Date", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Credential")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Credential", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656655
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

proc call*(call_402656657: Call_DescribeSubnetGroups_402656645;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
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

proc call*(call_402656658: Call_DescribeSubnetGroups_402656645; body: JsonNode): Recallable =
  ## describeSubnetGroups
  ## Returns a list of subnet group descriptions. If a subnet group name is specified, the list will contain only the description of that group.
  ##   
                                                                                                                                                ## body: JObject (required)
  var body_402656659 = newJObject()
  if body != nil:
    body_402656659 = body
  result = call_402656658.call(nil, nil, nil, nil, body_402656659)

var describeSubnetGroups* = Call_DescribeSubnetGroups_402656645(
    name: "describeSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.DescribeSubnetGroups",
    validator: validate_DescribeSubnetGroups_402656646, base: "/",
    makeUrl: url_DescribeSubnetGroups_402656647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_IncreaseReplicationFactor_402656660 = ref object of OpenApiRestCall_402656035
proc url_IncreaseReplicationFactor_402656662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IncreaseReplicationFactor_402656661(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656663 = header.getOrDefault("X-Amz-Target")
  valid_402656663 = validateParameter(valid_402656663, JString, required = true, default = newJString(
      "AmazonDAXV3.IncreaseReplicationFactor"))
  if valid_402656663 != nil:
    section.add "X-Amz-Target", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Security-Token", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Signature")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Signature", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Algorithm", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Date")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Date", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Credential")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Credential", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656670
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

proc call*(call_402656672: Call_IncreaseReplicationFactor_402656660;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds one or more nodes to a DAX cluster.
                                                                                         ## 
  let valid = call_402656672.validator(path, query, header, formData, body, _)
  let scheme = call_402656672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656672.makeUrl(scheme.get, call_402656672.host, call_402656672.base,
                                   call_402656672.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656672, uri, valid, _)

proc call*(call_402656673: Call_IncreaseReplicationFactor_402656660;
           body: JsonNode): Recallable =
  ## increaseReplicationFactor
  ## Adds one or more nodes to a DAX cluster.
  ##   body: JObject (required)
  var body_402656674 = newJObject()
  if body != nil:
    body_402656674 = body
  result = call_402656673.call(nil, nil, nil, nil, body_402656674)

var increaseReplicationFactor* = Call_IncreaseReplicationFactor_402656660(
    name: "increaseReplicationFactor", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.IncreaseReplicationFactor",
    validator: validate_IncreaseReplicationFactor_402656661, base: "/",
    makeUrl: url_IncreaseReplicationFactor_402656662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_402656675 = ref object of OpenApiRestCall_402656035
proc url_ListTags_402656677(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_402656676(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656678 = header.getOrDefault("X-Amz-Target")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true, default = newJString(
      "AmazonDAXV3.ListTags"))
  if valid_402656678 != nil:
    section.add "X-Amz-Target", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Security-Token", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Signature")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Signature", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Algorithm", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Date")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Date", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Credential")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Credential", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656685
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

proc call*(call_402656687: Call_ListTags_402656675; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
                                                                                         ## 
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_ListTags_402656675; body: JsonNode): Recallable =
  ## listTags
  ## List all of the tags for a DAX cluster. You can call <code>ListTags</code> up to 10 times per second, per account.
  ##   
                                                                                                                       ## body: JObject (required)
  var body_402656689 = newJObject()
  if body != nil:
    body_402656689 = body
  result = call_402656688.call(nil, nil, nil, nil, body_402656689)

var listTags* = Call_ListTags_402656675(name: "listTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "dax.amazonaws.com", route: "/#X-Amz-Target=AmazonDAXV3.ListTags",
                                        validator: validate_ListTags_402656676,
                                        base: "/", makeUrl: url_ListTags_402656677,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootNode_402656690 = ref object of OpenApiRestCall_402656035
proc url_RebootNode_402656692(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootNode_402656691(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656693 = header.getOrDefault("X-Amz-Target")
  valid_402656693 = validateParameter(valid_402656693, JString, required = true, default = newJString(
      "AmazonDAXV3.RebootNode"))
  if valid_402656693 != nil:
    section.add "X-Amz-Target", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Security-Token", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Signature")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Signature", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Algorithm", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Date")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Date", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Credential")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Credential", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656700
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

proc call*(call_402656702: Call_RebootNode_402656690; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
                                                                                         ## 
  let valid = call_402656702.validator(path, query, header, formData, body, _)
  let scheme = call_402656702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656702.makeUrl(scheme.get, call_402656702.host, call_402656702.base,
                                   call_402656702.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656702, uri, valid, _)

proc call*(call_402656703: Call_RebootNode_402656690; body: JsonNode): Recallable =
  ## rebootNode
  ## <p>Reboots a single node of a DAX cluster. The reboot action takes place as soon as possible. During the reboot, the node status is set to REBOOTING.</p> <note> <p> <code>RebootNode</code> restarts the DAX engine process and does not remove the contents of the cache. </p> </note>
  ##   
                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656704 = newJObject()
  if body != nil:
    body_402656704 = body
  result = call_402656703.call(nil, nil, nil, nil, body_402656704)

var rebootNode* = Call_RebootNode_402656690(name: "rebootNode",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.RebootNode",
    validator: validate_RebootNode_402656691, base: "/",
    makeUrl: url_RebootNode_402656692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656705 = ref object of OpenApiRestCall_402656035
proc url_TagResource_402656707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656706(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656708 = header.getOrDefault("X-Amz-Target")
  valid_402656708 = validateParameter(valid_402656708, JString, required = true, default = newJString(
      "AmazonDAXV3.TagResource"))
  if valid_402656708 != nil:
    section.add "X-Amz-Target", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Security-Token", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Signature")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Signature", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Algorithm", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Date")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Date", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Credential")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Credential", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656715
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

proc call*(call_402656717: Call_TagResource_402656705; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
                                                                                         ## 
  let valid = call_402656717.validator(path, query, header, formData, body, _)
  let scheme = call_402656717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656717.makeUrl(scheme.get, call_402656717.host, call_402656717.base,
                                   call_402656717.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656717, uri, valid, _)

proc call*(call_402656718: Call_TagResource_402656705; body: JsonNode): Recallable =
  ## tagResource
  ## Associates a set of tags with a DAX resource. You can call <code>TagResource</code> up to 5 times per second, per account. 
  ##   
                                                                                                                                ## body: JObject (required)
  var body_402656719 = newJObject()
  if body != nil:
    body_402656719 = body
  result = call_402656718.call(nil, nil, nil, nil, body_402656719)

var tagResource* = Call_TagResource_402656705(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.TagResource",
    validator: validate_TagResource_402656706, base: "/",
    makeUrl: url_TagResource_402656707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656720 = ref object of OpenApiRestCall_402656035
proc url_UntagResource_402656722(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656721(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656723 = header.getOrDefault("X-Amz-Target")
  valid_402656723 = validateParameter(valid_402656723, JString, required = true, default = newJString(
      "AmazonDAXV3.UntagResource"))
  if valid_402656723 != nil:
    section.add "X-Amz-Target", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Security-Token", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Signature")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Signature", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Algorithm", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Date")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Date", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Credential")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Credential", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656730
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

proc call*(call_402656732: Call_UntagResource_402656720; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
                                                                                         ## 
  let valid = call_402656732.validator(path, query, header, formData, body, _)
  let scheme = call_402656732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656732.makeUrl(scheme.get, call_402656732.host, call_402656732.base,
                                   call_402656732.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656732, uri, valid, _)

proc call*(call_402656733: Call_UntagResource_402656720; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the association of tags from a DAX resource. You can call <code>UntagResource</code> up to 5 times per second, per account. 
  ##   
                                                                                                                                         ## body: JObject (required)
  var body_402656734 = newJObject()
  if body != nil:
    body_402656734 = body
  result = call_402656733.call(nil, nil, nil, nil, body_402656734)

var untagResource* = Call_UntagResource_402656720(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UntagResource",
    validator: validate_UntagResource_402656721, base: "/",
    makeUrl: url_UntagResource_402656722, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_402656735 = ref object of OpenApiRestCall_402656035
proc url_UpdateCluster_402656737(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCluster_402656736(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656738 = header.getOrDefault("X-Amz-Target")
  valid_402656738 = validateParameter(valid_402656738, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateCluster"))
  if valid_402656738 != nil:
    section.add "X-Amz-Target", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Security-Token", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Signature")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Signature", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Algorithm", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Date")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Date", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Credential")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Credential", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656745
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

proc call*(call_402656747: Call_UpdateCluster_402656735; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
                                                                                         ## 
  let valid = call_402656747.validator(path, query, header, formData, body, _)
  let scheme = call_402656747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656747.makeUrl(scheme.get, call_402656747.host, call_402656747.base,
                                   call_402656747.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656747, uri, valid, _)

proc call*(call_402656748: Call_UpdateCluster_402656735; body: JsonNode): Recallable =
  ## updateCluster
  ## Modifies the settings for a DAX cluster. You can use this action to change one or more cluster configuration parameters by specifying the parameters and the new values.
  ##   
                                                                                                                                                                             ## body: JObject (required)
  var body_402656749 = newJObject()
  if body != nil:
    body_402656749 = body
  result = call_402656748.call(nil, nil, nil, nil, body_402656749)

var updateCluster* = Call_UpdateCluster_402656735(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateCluster",
    validator: validate_UpdateCluster_402656736, base: "/",
    makeUrl: url_UpdateCluster_402656737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateParameterGroup_402656750 = ref object of OpenApiRestCall_402656035
proc url_UpdateParameterGroup_402656752(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateParameterGroup_402656751(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656753 = header.getOrDefault("X-Amz-Target")
  valid_402656753 = validateParameter(valid_402656753, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateParameterGroup"))
  if valid_402656753 != nil:
    section.add "X-Amz-Target", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Security-Token", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Signature")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Signature", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Algorithm", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Date")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Date", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Credential")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Credential", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656760
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

proc call*(call_402656762: Call_UpdateParameterGroup_402656750;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
                                                                                         ## 
  let valid = call_402656762.validator(path, query, header, formData, body, _)
  let scheme = call_402656762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656762.makeUrl(scheme.get, call_402656762.host, call_402656762.base,
                                   call_402656762.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656762, uri, valid, _)

proc call*(call_402656763: Call_UpdateParameterGroup_402656750; body: JsonNode): Recallable =
  ## updateParameterGroup
  ## Modifies the parameters of a parameter group. You can modify up to 20 parameters in a single request by submitting a list parameter name and value pairs.
  ##   
                                                                                                                                                              ## body: JObject (required)
  var body_402656764 = newJObject()
  if body != nil:
    body_402656764 = body
  result = call_402656763.call(nil, nil, nil, nil, body_402656764)

var updateParameterGroup* = Call_UpdateParameterGroup_402656750(
    name: "updateParameterGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateParameterGroup",
    validator: validate_UpdateParameterGroup_402656751, base: "/",
    makeUrl: url_UpdateParameterGroup_402656752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSubnetGroup_402656765 = ref object of OpenApiRestCall_402656035
proc url_UpdateSubnetGroup_402656767(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSubnetGroup_402656766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656768 = header.getOrDefault("X-Amz-Target")
  valid_402656768 = validateParameter(valid_402656768, JString, required = true, default = newJString(
      "AmazonDAXV3.UpdateSubnetGroup"))
  if valid_402656768 != nil:
    section.add "X-Amz-Target", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Security-Token", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Signature")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Signature", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Algorithm", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Date")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Date", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Credential")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Credential", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656775
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

proc call*(call_402656777: Call_UpdateSubnetGroup_402656765;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies an existing subnet group.
                                                                                         ## 
  let valid = call_402656777.validator(path, query, header, formData, body, _)
  let scheme = call_402656777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656777.makeUrl(scheme.get, call_402656777.host, call_402656777.base,
                                   call_402656777.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656777, uri, valid, _)

proc call*(call_402656778: Call_UpdateSubnetGroup_402656765; body: JsonNode): Recallable =
  ## updateSubnetGroup
  ## Modifies an existing subnet group.
  ##   body: JObject (required)
  var body_402656779 = newJObject()
  if body != nil:
    body_402656779 = body
  result = call_402656778.call(nil, nil, nil, nil, body_402656779)

var updateSubnetGroup* = Call_UpdateSubnetGroup_402656765(
    name: "updateSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dax.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDAXV3.UpdateSubnetGroup",
    validator: validate_UpdateSubnetGroup_402656766, base: "/",
    makeUrl: url_UpdateSubnetGroup_402656767,
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