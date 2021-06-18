
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS RoboMaker
## version: 2018-06-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This section provides documentation for the AWS RoboMaker API operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/robomaker/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com", "us-west-2": "robomaker.us-west-2.amazonaws.com", "eu-west-2": "robomaker.eu-west-2.amazonaws.com", "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com", "eu-central-1": "robomaker.eu-central-1.amazonaws.com", "us-east-2": "robomaker.us-east-2.amazonaws.com", "us-east-1": "robomaker.us-east-1.amazonaws.com", "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "robomaker.ap-south-1.amazonaws.com", "eu-north-1": "robomaker.eu-north-1.amazonaws.com", "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com", "us-west-1": "robomaker.us-west-1.amazonaws.com", "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com", "eu-west-3": "robomaker.eu-west-3.amazonaws.com", "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "robomaker.sa-east-1.amazonaws.com", "eu-west-1": "robomaker.eu-west-1.amazonaws.com", "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com", "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "robomaker.us-west-2.amazonaws.com",
      "eu-west-2": "robomaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "robomaker.eu-central-1.amazonaws.com",
      "us-east-2": "robomaker.us-east-2.amazonaws.com",
      "us-east-1": "robomaker.us-east-1.amazonaws.com",
      "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "robomaker.ap-south-1.amazonaws.com",
      "eu-north-1": "robomaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "robomaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "robomaker.eu-west-3.amazonaws.com",
      "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "robomaker.sa-east-1.amazonaws.com",
      "eu-west-1": "robomaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "robomaker"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchDescribeSimulationJob_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchDescribeSimulationJob_402656296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeSimulationJob_402656295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes one or more simulation jobs.
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
  var valid_402656378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Security-Token", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Signature")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Signature", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Algorithm", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Date")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Date", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Credential")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Credential", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656384
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

proc call*(call_402656399: Call_BatchDescribeSimulationJob_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes one or more simulation jobs.
                                                                                         ## 
  let valid = call_402656399.validator(path, query, header, formData, body, _)
  let scheme = call_402656399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656399.makeUrl(scheme.get, call_402656399.host, call_402656399.base,
                                   call_402656399.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656399, uri, valid, _)

proc call*(call_402656448: Call_BatchDescribeSimulationJob_402656294;
           body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_402656449 = newJObject()
  if body != nil:
    body_402656449 = body
  result = call_402656448.call(nil, nil, nil, nil, body_402656449)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_402656294(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_402656295, base: "/",
    makeUrl: url_BatchDescribeSimulationJob_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_402656476 = ref object of OpenApiRestCall_402656044
proc url_CancelDeploymentJob_402656478(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelDeploymentJob_402656477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels the specified deployment job.
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
  var valid_402656479 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Security-Token", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Signature")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Signature", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Algorithm", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Date")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Date", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Credential")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Credential", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656485
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

proc call*(call_402656487: Call_CancelDeploymentJob_402656476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels the specified deployment job.
                                                                                         ## 
  let valid = call_402656487.validator(path, query, header, formData, body, _)
  let scheme = call_402656487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656487.makeUrl(scheme.get, call_402656487.host, call_402656487.base,
                                   call_402656487.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656487, uri, valid, _)

proc call*(call_402656488: Call_CancelDeploymentJob_402656476; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_402656489 = newJObject()
  if body != nil:
    body_402656489 = body
  result = call_402656488.call(nil, nil, nil, nil, body_402656489)

var cancelDeploymentJob* = Call_CancelDeploymentJob_402656476(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_402656477, base: "/",
    makeUrl: url_CancelDeploymentJob_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_402656490 = ref object of OpenApiRestCall_402656044
proc url_CancelSimulationJob_402656492(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelSimulationJob_402656491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels the specified simulation job.
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
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_CancelSimulationJob_402656490;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels the specified simulation job.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CancelSimulationJob_402656490; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var cancelSimulationJob* = Call_CancelSimulationJob_402656490(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_402656491, base: "/",
    makeUrl: url_CancelSimulationJob_402656492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJobBatch_402656504 = ref object of OpenApiRestCall_402656044
proc url_CancelSimulationJobBatch_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelSimulationJobBatch_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
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
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
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

proc call*(call_402656515: Call_CancelSimulationJobBatch_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
                                                                                         ## 
  let valid = call_402656515.validator(path, query, header, formData, body, _)
  let scheme = call_402656515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656515.makeUrl(scheme.get, call_402656515.host, call_402656515.base,
                                   call_402656515.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656515, uri, valid, _)

proc call*(call_402656516: Call_CancelSimulationJobBatch_402656504;
           body: JsonNode): Recallable =
  ## cancelSimulationJobBatch
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var body_402656517 = newJObject()
  if body != nil:
    body_402656517 = body
  result = call_402656516.call(nil, nil, nil, nil, body_402656517)

var cancelSimulationJobBatch* = Call_CancelSimulationJobBatch_402656504(
    name: "cancelSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJobBatch",
    validator: validate_CancelSimulationJobBatch_402656505, base: "/",
    makeUrl: url_CancelSimulationJobBatch_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_402656518 = ref object of OpenApiRestCall_402656044
proc url_CreateDeploymentJob_402656520(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentJob_402656519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
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
  var valid_402656521 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Security-Token", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Signature")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Signature", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Algorithm", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Date")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Date", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Credential")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Credential", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656527
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

proc call*(call_402656529: Call_CreateDeploymentJob_402656518;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
                                                                                         ## 
  let valid = call_402656529.validator(path, query, header, formData, body, _)
  let scheme = call_402656529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656529.makeUrl(scheme.get, call_402656529.host, call_402656529.base,
                                   call_402656529.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656529, uri, valid, _)

proc call*(call_402656530: Call_CreateDeploymentJob_402656518; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656531 = newJObject()
  if body != nil:
    body_402656531 = body
  result = call_402656530.call(nil, nil, nil, nil, body_402656531)

var createDeploymentJob* = Call_CreateDeploymentJob_402656518(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_402656519, base: "/",
    makeUrl: url_CreateDeploymentJob_402656520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_402656532 = ref object of OpenApiRestCall_402656044
proc url_CreateFleet_402656534(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFleet_402656533(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a fleet, a logical group of robots running the same robot application.
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
  var valid_402656535 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Security-Token", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Signature")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Signature", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Algorithm", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Date")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Date", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Credential")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Credential", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656541
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

proc call*(call_402656543: Call_CreateFleet_402656532; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
                                                                                         ## 
  let valid = call_402656543.validator(path, query, header, formData, body, _)
  let scheme = call_402656543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656543.makeUrl(scheme.get, call_402656543.host, call_402656543.base,
                                   call_402656543.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656543, uri, valid, _)

proc call*(call_402656544: Call_CreateFleet_402656532; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656545 = newJObject()
  if body != nil:
    body_402656545 = body
  result = call_402656544.call(nil, nil, nil, nil, body_402656545)

var createFleet* = Call_CreateFleet_402656532(name: "createFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/createFleet", validator: validate_CreateFleet_402656533, base: "/",
    makeUrl: url_CreateFleet_402656534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_402656546 = ref object of OpenApiRestCall_402656044
proc url_CreateRobot_402656548(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobot_402656547(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a robot.
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
  var valid_402656549 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Security-Token", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Signature")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Signature", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Algorithm", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Date")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Date", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Credential")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Credential", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656555
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

proc call*(call_402656557: Call_CreateRobot_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a robot.
                                                                                         ## 
  let valid = call_402656557.validator(path, query, header, formData, body, _)
  let scheme = call_402656557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656557.makeUrl(scheme.get, call_402656557.host, call_402656557.base,
                                   call_402656557.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656557, uri, valid, _)

proc call*(call_402656558: Call_CreateRobot_402656546; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_402656559 = newJObject()
  if body != nil:
    body_402656559 = body
  result = call_402656558.call(nil, nil, nil, nil, body_402656559)

var createRobot* = Call_CreateRobot_402656546(name: "createRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/createRobot", validator: validate_CreateRobot_402656547, base: "/",
    makeUrl: url_CreateRobot_402656548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_402656560 = ref object of OpenApiRestCall_402656044
proc url_CreateRobotApplication_402656562(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobotApplication_402656561(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a robot application. 
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
  var valid_402656563 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Security-Token", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Signature")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Signature", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Algorithm", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Date")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Date", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Credential")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Credential", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656569
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

proc call*(call_402656571: Call_CreateRobotApplication_402656560;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a robot application. 
                                                                                         ## 
  let valid = call_402656571.validator(path, query, header, formData, body, _)
  let scheme = call_402656571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656571.makeUrl(scheme.get, call_402656571.host, call_402656571.base,
                                   call_402656571.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656571, uri, valid, _)

proc call*(call_402656572: Call_CreateRobotApplication_402656560; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_402656573 = newJObject()
  if body != nil:
    body_402656573 = body
  result = call_402656572.call(nil, nil, nil, nil, body_402656573)

var createRobotApplication* = Call_CreateRobotApplication_402656560(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_402656561, base: "/",
    makeUrl: url_CreateRobotApplication_402656562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_402656574 = ref object of OpenApiRestCall_402656044
proc url_CreateRobotApplicationVersion_402656576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobotApplicationVersion_402656575(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a version of a robot application.
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
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
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

proc call*(call_402656585: Call_CreateRobotApplicationVersion_402656574;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of a robot application.
                                                                                         ## 
  let valid = call_402656585.validator(path, query, header, formData, body, _)
  let scheme = call_402656585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656585.makeUrl(scheme.get, call_402656585.host, call_402656585.base,
                                   call_402656585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656585, uri, valid, _)

proc call*(call_402656586: Call_CreateRobotApplicationVersion_402656574;
           body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_402656587 = newJObject()
  if body != nil:
    body_402656587 = body
  result = call_402656586.call(nil, nil, nil, nil, body_402656587)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_402656574(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_402656575, base: "/",
    makeUrl: url_CreateRobotApplicationVersion_402656576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_402656588 = ref object of OpenApiRestCall_402656044
proc url_CreateSimulationApplication_402656590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationApplication_402656589(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a simulation application.
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
  var valid_402656591 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Security-Token", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Signature")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Signature", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Algorithm", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Date")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Date", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Credential")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Credential", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
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

proc call*(call_402656599: Call_CreateSimulationApplication_402656588;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a simulation application.
                                                                                         ## 
  let valid = call_402656599.validator(path, query, header, formData, body, _)
  let scheme = call_402656599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656599.makeUrl(scheme.get, call_402656599.host, call_402656599.base,
                                   call_402656599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656599, uri, valid, _)

proc call*(call_402656600: Call_CreateSimulationApplication_402656588;
           body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_402656601 = newJObject()
  if body != nil:
    body_402656601 = body
  result = call_402656600.call(nil, nil, nil, nil, body_402656601)

var createSimulationApplication* = Call_CreateSimulationApplication_402656588(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_402656589, base: "/",
    makeUrl: url_CreateSimulationApplication_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_402656602 = ref object of OpenApiRestCall_402656044
proc url_CreateSimulationApplicationVersion_402656604(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationApplicationVersion_402656603(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a simulation application with a specific revision id.
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
  var valid_402656605 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Security-Token", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Signature")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Signature", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Algorithm", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Date")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Date", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Credential")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Credential", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656611
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

proc call*(call_402656613: Call_CreateSimulationApplicationVersion_402656602;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a simulation application with a specific revision id.
                                                                                         ## 
  let valid = call_402656613.validator(path, query, header, formData, body, _)
  let scheme = call_402656613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656613.makeUrl(scheme.get, call_402656613.host, call_402656613.base,
                                   call_402656613.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656613, uri, valid, _)

proc call*(call_402656614: Call_CreateSimulationApplicationVersion_402656602;
           body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_402656615 = newJObject()
  if body != nil:
    body_402656615 = body
  result = call_402656614.call(nil, nil, nil, nil, body_402656615)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_402656602(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com",
    route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_402656603, base: "/",
    makeUrl: url_CreateSimulationApplicationVersion_402656604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_402656616 = ref object of OpenApiRestCall_402656044
proc url_CreateSimulationJob_402656618(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationJob_402656617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
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

proc call*(call_402656627: Call_CreateSimulationJob_402656616;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
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

proc call*(call_402656628: Call_CreateSimulationJob_402656616; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   
                                                                                                                                                          ## body: JObject (required)
  var body_402656629 = newJObject()
  if body != nil:
    body_402656629 = body
  result = call_402656628.call(nil, nil, nil, nil, body_402656629)

var createSimulationJob* = Call_CreateSimulationJob_402656616(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_402656617, base: "/",
    makeUrl: url_CreateSimulationJob_402656618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_402656630 = ref object of OpenApiRestCall_402656044
proc url_DeleteFleet_402656632(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFleet_402656631(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a fleet.
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
  var valid_402656633 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Security-Token", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Signature")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Signature", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Algorithm", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Date")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Date", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Credential")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Credential", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656639
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

proc call*(call_402656641: Call_DeleteFleet_402656630; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a fleet.
                                                                                         ## 
  let valid = call_402656641.validator(path, query, header, formData, body, _)
  let scheme = call_402656641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656641.makeUrl(scheme.get, call_402656641.host, call_402656641.base,
                                   call_402656641.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656641, uri, valid, _)

proc call*(call_402656642: Call_DeleteFleet_402656630; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_402656643 = newJObject()
  if body != nil:
    body_402656643 = body
  result = call_402656642.call(nil, nil, nil, nil, body_402656643)

var deleteFleet* = Call_DeleteFleet_402656630(name: "deleteFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deleteFleet", validator: validate_DeleteFleet_402656631, base: "/",
    makeUrl: url_DeleteFleet_402656632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_402656644 = ref object of OpenApiRestCall_402656044
proc url_DeleteRobot_402656646(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRobot_402656645(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a robot.
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
  var valid_402656647 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Security-Token", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Signature")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Signature", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Algorithm", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Date")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Date", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Credential")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Credential", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656653
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

proc call*(call_402656655: Call_DeleteRobot_402656644; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a robot.
                                                                                         ## 
  let valid = call_402656655.validator(path, query, header, formData, body, _)
  let scheme = call_402656655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656655.makeUrl(scheme.get, call_402656655.host, call_402656655.base,
                                   call_402656655.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656655, uri, valid, _)

proc call*(call_402656656: Call_DeleteRobot_402656644; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_402656657 = newJObject()
  if body != nil:
    body_402656657 = body
  result = call_402656656.call(nil, nil, nil, nil, body_402656657)

var deleteRobot* = Call_DeleteRobot_402656644(name: "deleteRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deleteRobot", validator: validate_DeleteRobot_402656645, base: "/",
    makeUrl: url_DeleteRobot_402656646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_402656658 = ref object of OpenApiRestCall_402656044
proc url_DeleteRobotApplication_402656660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRobotApplication_402656659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a robot application.
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
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Signature")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Signature", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Algorithm", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Date")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Date", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Credential")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Credential", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656667
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

proc call*(call_402656669: Call_DeleteRobotApplication_402656658;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a robot application.
                                                                                         ## 
  let valid = call_402656669.validator(path, query, header, formData, body, _)
  let scheme = call_402656669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656669.makeUrl(scheme.get, call_402656669.host, call_402656669.base,
                                   call_402656669.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656669, uri, valid, _)

proc call*(call_402656670: Call_DeleteRobotApplication_402656658; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_402656671 = newJObject()
  if body != nil:
    body_402656671 = body
  result = call_402656670.call(nil, nil, nil, nil, body_402656671)

var deleteRobotApplication* = Call_DeleteRobotApplication_402656658(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_402656659, base: "/",
    makeUrl: url_DeleteRobotApplication_402656660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_402656672 = ref object of OpenApiRestCall_402656044
proc url_DeleteSimulationApplication_402656674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSimulationApplication_402656673(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a simulation application.
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
  var valid_402656675 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Security-Token", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Signature")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Signature", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Algorithm", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Date")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Date", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Credential")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Credential", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656681
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

proc call*(call_402656683: Call_DeleteSimulationApplication_402656672;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a simulation application.
                                                                                         ## 
  let valid = call_402656683.validator(path, query, header, formData, body, _)
  let scheme = call_402656683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656683.makeUrl(scheme.get, call_402656683.host, call_402656683.base,
                                   call_402656683.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656683, uri, valid, _)

proc call*(call_402656684: Call_DeleteSimulationApplication_402656672;
           body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_402656685 = newJObject()
  if body != nil:
    body_402656685 = body
  result = call_402656684.call(nil, nil, nil, nil, body_402656685)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_402656672(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_402656673, base: "/",
    makeUrl: url_DeleteSimulationApplication_402656674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_402656686 = ref object of OpenApiRestCall_402656044
proc url_DeregisterRobot_402656688(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterRobot_402656687(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deregisters a robot.
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
  var valid_402656689 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Security-Token", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Signature")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Signature", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Algorithm", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Date")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Date", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Credential")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Credential", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656695
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

proc call*(call_402656697: Call_DeregisterRobot_402656686; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deregisters a robot.
                                                                                         ## 
  let valid = call_402656697.validator(path, query, header, formData, body, _)
  let scheme = call_402656697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656697.makeUrl(scheme.get, call_402656697.host, call_402656697.base,
                                   call_402656697.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656697, uri, valid, _)

proc call*(call_402656698: Call_DeregisterRobot_402656686; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_402656699 = newJObject()
  if body != nil:
    body_402656699 = body
  result = call_402656698.call(nil, nil, nil, nil, body_402656699)

var deregisterRobot* = Call_DeregisterRobot_402656686(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_402656687,
    base: "/", makeUrl: url_DeregisterRobot_402656688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_402656700 = ref object of OpenApiRestCall_402656044
proc url_DescribeDeploymentJob_402656702(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeploymentJob_402656701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a deployment job.
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
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
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

proc call*(call_402656711: Call_DescribeDeploymentJob_402656700;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a deployment job.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_DescribeDeploymentJob_402656700; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var describeDeploymentJob* = Call_DescribeDeploymentJob_402656700(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_402656701, base: "/",
    makeUrl: url_DescribeDeploymentJob_402656702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_402656714 = ref object of OpenApiRestCall_402656044
proc url_DescribeFleet_402656716(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFleet_402656715(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a fleet.
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
  var valid_402656717 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Security-Token", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Signature")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Signature", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Algorithm", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Date")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Date", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Credential")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Credential", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656723
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

proc call*(call_402656725: Call_DescribeFleet_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a fleet.
                                                                                         ## 
  let valid = call_402656725.validator(path, query, header, formData, body, _)
  let scheme = call_402656725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656725.makeUrl(scheme.get, call_402656725.host, call_402656725.base,
                                   call_402656725.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656725, uri, valid, _)

proc call*(call_402656726: Call_DescribeFleet_402656714; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_402656727 = newJObject()
  if body != nil:
    body_402656727 = body
  result = call_402656726.call(nil, nil, nil, nil, body_402656727)

var describeFleet* = Call_DescribeFleet_402656714(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_402656715,
    base: "/", makeUrl: url_DescribeFleet_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_402656728 = ref object of OpenApiRestCall_402656044
proc url_DescribeRobot_402656730(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRobot_402656729(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a robot.
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
  var valid_402656731 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Security-Token", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Signature")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Signature", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Algorithm", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Date")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Date", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Credential")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Credential", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656737
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

proc call*(call_402656739: Call_DescribeRobot_402656728; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a robot.
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

proc call*(call_402656740: Call_DescribeRobot_402656728; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_402656741 = newJObject()
  if body != nil:
    body_402656741 = body
  result = call_402656740.call(nil, nil, nil, nil, body_402656741)

var describeRobot* = Call_DescribeRobot_402656728(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_402656729,
    base: "/", makeUrl: url_DescribeRobot_402656730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_402656742 = ref object of OpenApiRestCall_402656044
proc url_DescribeRobotApplication_402656744(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRobotApplication_402656743(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes a robot application.
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
  var valid_402656745 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Security-Token", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Signature")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Signature", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
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

proc call*(call_402656753: Call_DescribeRobotApplication_402656742;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a robot application.
                                                                                         ## 
  let valid = call_402656753.validator(path, query, header, formData, body, _)
  let scheme = call_402656753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656753.makeUrl(scheme.get, call_402656753.host, call_402656753.base,
                                   call_402656753.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656753, uri, valid, _)

proc call*(call_402656754: Call_DescribeRobotApplication_402656742;
           body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_402656755 = newJObject()
  if body != nil:
    body_402656755 = body
  result = call_402656754.call(nil, nil, nil, nil, body_402656755)

var describeRobotApplication* = Call_DescribeRobotApplication_402656742(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_402656743, base: "/",
    makeUrl: url_DescribeRobotApplication_402656744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_402656756 = ref object of OpenApiRestCall_402656044
proc url_DescribeSimulationApplication_402656758(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationApplication_402656757(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes a simulation application.
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
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Signature")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Signature", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Algorithm", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Date")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Date", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Credential")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Credential", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656765
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

proc call*(call_402656767: Call_DescribeSimulationApplication_402656756;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a simulation application.
                                                                                         ## 
  let valid = call_402656767.validator(path, query, header, formData, body, _)
  let scheme = call_402656767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656767.makeUrl(scheme.get, call_402656767.host, call_402656767.base,
                                   call_402656767.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656767, uri, valid, _)

proc call*(call_402656768: Call_DescribeSimulationApplication_402656756;
           body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_402656769 = newJObject()
  if body != nil:
    body_402656769 = body
  result = call_402656768.call(nil, nil, nil, nil, body_402656769)

var describeSimulationApplication* = Call_DescribeSimulationApplication_402656756(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_402656757, base: "/",
    makeUrl: url_DescribeSimulationApplication_402656758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_402656770 = ref object of OpenApiRestCall_402656044
proc url_DescribeSimulationJob_402656772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationJob_402656771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes a simulation job.
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
  var valid_402656773 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Security-Token", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Signature")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Signature", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Algorithm", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Date")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Date", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Credential")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Credential", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656779
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

proc call*(call_402656781: Call_DescribeSimulationJob_402656770;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a simulation job.
                                                                                         ## 
  let valid = call_402656781.validator(path, query, header, formData, body, _)
  let scheme = call_402656781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656781.makeUrl(scheme.get, call_402656781.host, call_402656781.base,
                                   call_402656781.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656781, uri, valid, _)

proc call*(call_402656782: Call_DescribeSimulationJob_402656770; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_402656783 = newJObject()
  if body != nil:
    body_402656783 = body
  result = call_402656782.call(nil, nil, nil, nil, body_402656783)

var describeSimulationJob* = Call_DescribeSimulationJob_402656770(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_402656771, base: "/",
    makeUrl: url_DescribeSimulationJob_402656772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJobBatch_402656784 = ref object of OpenApiRestCall_402656044
proc url_DescribeSimulationJobBatch_402656786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationJobBatch_402656785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes a simulation job batch.
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
  var valid_402656787 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Security-Token", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Signature")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Signature", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Algorithm", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Date")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Date", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Credential")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Credential", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656793
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

proc call*(call_402656795: Call_DescribeSimulationJobBatch_402656784;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a simulation job batch.
                                                                                         ## 
  let valid = call_402656795.validator(path, query, header, formData, body, _)
  let scheme = call_402656795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656795.makeUrl(scheme.get, call_402656795.host, call_402656795.base,
                                   call_402656795.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656795, uri, valid, _)

proc call*(call_402656796: Call_DescribeSimulationJobBatch_402656784;
           body: JsonNode): Recallable =
  ## describeSimulationJobBatch
  ## Describes a simulation job batch.
  ##   body: JObject (required)
  var body_402656797 = newJObject()
  if body != nil:
    body_402656797 = body
  result = call_402656796.call(nil, nil, nil, nil, body_402656797)

var describeSimulationJobBatch* = Call_DescribeSimulationJobBatch_402656784(
    name: "describeSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJobBatch",
    validator: validate_DescribeSimulationJobBatch_402656785, base: "/",
    makeUrl: url_DescribeSimulationJobBatch_402656786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_402656798 = ref object of OpenApiRestCall_402656044
proc url_ListDeploymentJobs_402656800(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentJobs_402656799(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656801 = query.getOrDefault("maxResults")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "maxResults", valid_402656801
  var valid_402656802 = query.getOrDefault("nextToken")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "nextToken", valid_402656802
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
  var valid_402656803 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Security-Token", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Signature")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Signature", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Algorithm", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Date")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Date", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Credential")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Credential", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656809
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

proc call*(call_402656811: Call_ListDeploymentJobs_402656798;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
                                                                                         ## 
  let valid = call_402656811.validator(path, query, header, formData, body, _)
  let scheme = call_402656811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656811.makeUrl(scheme.get, call_402656811.host, call_402656811.base,
                                   call_402656811.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656811, uri, valid, _)

proc call*(call_402656812: Call_ListDeploymentJobs_402656798; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listDeploymentJobs
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
  ##   
                                                                                                                             ## maxResults: string
                                                                                                                             ##             
                                                                                                                             ## : 
                                                                                                                             ## Pagination 
                                                                                                                             ## limit
  ##   
                                                                                                                                     ## nextToken: string
                                                                                                                                     ##            
                                                                                                                                     ## : 
                                                                                                                                     ## Pagination 
                                                                                                                                     ## token
  ##   
                                                                                                                                             ## body: JObject (required)
  var query_402656813 = newJObject()
  var body_402656814 = newJObject()
  add(query_402656813, "maxResults", newJString(maxResults))
  add(query_402656813, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656814 = body
  result = call_402656812.call(nil, query_402656813, nil, nil, body_402656814)

var listDeploymentJobs* = Call_ListDeploymentJobs_402656798(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_402656799, base: "/",
    makeUrl: url_ListDeploymentJobs_402656800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_402656815 = ref object of OpenApiRestCall_402656044
proc url_ListFleets_402656817(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFleets_402656816(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656818 = query.getOrDefault("maxResults")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "maxResults", valid_402656818
  var valid_402656819 = query.getOrDefault("nextToken")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "nextToken", valid_402656819
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
  var valid_402656820 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Security-Token", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Signature")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Signature", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Algorithm", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Date")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Date", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Credential")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Credential", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656826
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

proc call*(call_402656828: Call_ListFleets_402656815; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
                                                                                         ## 
  let valid = call_402656828.validator(path, query, header, formData, body, _)
  let scheme = call_402656828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656828.makeUrl(scheme.get, call_402656828.host, call_402656828.base,
                                   call_402656828.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656828, uri, valid, _)

proc call*(call_402656829: Call_ListFleets_402656815; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   
                                                                                               ## maxResults: string
                                                                                               ##             
                                                                                               ## : 
                                                                                               ## Pagination 
                                                                                               ## limit
  ##   
                                                                                                       ## nextToken: string
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Pagination 
                                                                                                       ## token
  ##   
                                                                                                               ## body: JObject (required)
  var query_402656830 = newJObject()
  var body_402656831 = newJObject()
  add(query_402656830, "maxResults", newJString(maxResults))
  add(query_402656830, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656831 = body
  result = call_402656829.call(nil, query_402656830, nil, nil, body_402656831)

var listFleets* = Call_ListFleets_402656815(name: "listFleets",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/listFleets", validator: validate_ListFleets_402656816, base: "/",
    makeUrl: url_ListFleets_402656817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_402656832 = ref object of OpenApiRestCall_402656044
proc url_ListRobotApplications_402656834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRobotApplications_402656833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656835 = query.getOrDefault("maxResults")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "maxResults", valid_402656835
  var valid_402656836 = query.getOrDefault("nextToken")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "nextToken", valid_402656836
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
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
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

proc call*(call_402656845: Call_ListRobotApplications_402656832;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
                                                                                         ## 
  let valid = call_402656845.validator(path, query, header, formData, body, _)
  let scheme = call_402656845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656845.makeUrl(scheme.get, call_402656845.host, call_402656845.base,
                                   call_402656845.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656845, uri, valid, _)

proc call*(call_402656846: Call_ListRobotApplications_402656832; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   
                                                                                                                     ## maxResults: string
                                                                                                                     ##             
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## limit
  ##   
                                                                                                                             ## nextToken: string
                                                                                                                             ##            
                                                                                                                             ## : 
                                                                                                                             ## Pagination 
                                                                                                                             ## token
  ##   
                                                                                                                                     ## body: JObject (required)
  var query_402656847 = newJObject()
  var body_402656848 = newJObject()
  add(query_402656847, "maxResults", newJString(maxResults))
  add(query_402656847, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656848 = body
  result = call_402656846.call(nil, query_402656847, nil, nil, body_402656848)

var listRobotApplications* = Call_ListRobotApplications_402656832(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_402656833, base: "/",
    makeUrl: url_ListRobotApplications_402656834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_402656849 = ref object of OpenApiRestCall_402656044
proc url_ListRobots_402656851(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRobots_402656850(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656852 = query.getOrDefault("maxResults")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "maxResults", valid_402656852
  var valid_402656853 = query.getOrDefault("nextToken")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "nextToken", valid_402656853
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
  var valid_402656854 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Security-Token", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Signature")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Signature", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Algorithm", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Date")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Date", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Credential")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Credential", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656860
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

proc call*(call_402656862: Call_ListRobots_402656849; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
                                                                                         ## 
  let valid = call_402656862.validator(path, query, header, formData, body, _)
  let scheme = call_402656862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656862.makeUrl(scheme.get, call_402656862.host, call_402656862.base,
                                   call_402656862.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656862, uri, valid, _)

proc call*(call_402656863: Call_ListRobots_402656849; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   
                                                                                              ## maxResults: string
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## Pagination 
                                                                                              ## limit
  ##   
                                                                                                      ## nextToken: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## Pagination 
                                                                                                      ## token
  ##   
                                                                                                              ## body: JObject (required)
  var query_402656864 = newJObject()
  var body_402656865 = newJObject()
  add(query_402656864, "maxResults", newJString(maxResults))
  add(query_402656864, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656865 = body
  result = call_402656863.call(nil, query_402656864, nil, nil, body_402656865)

var listRobots* = Call_ListRobots_402656849(name: "listRobots",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/listRobots", validator: validate_ListRobots_402656850, base: "/",
    makeUrl: url_ListRobots_402656851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_402656866 = ref object of OpenApiRestCall_402656044
proc url_ListSimulationApplications_402656868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationApplications_402656867(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656869 = query.getOrDefault("maxResults")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "maxResults", valid_402656869
  var valid_402656870 = query.getOrDefault("nextToken")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "nextToken", valid_402656870
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
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
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

proc call*(call_402656879: Call_ListSimulationApplications_402656866;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_ListSimulationApplications_402656866;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   
                                                                                                                                 ## maxResults: string
                                                                                                                                 ##             
                                                                                                                                 ## : 
                                                                                                                                 ## Pagination 
                                                                                                                                 ## limit
  ##   
                                                                                                                                         ## nextToken: string
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## Pagination 
                                                                                                                                         ## token
  ##   
                                                                                                                                                 ## body: JObject (required)
  var query_402656881 = newJObject()
  var body_402656882 = newJObject()
  add(query_402656881, "maxResults", newJString(maxResults))
  add(query_402656881, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656882 = body
  result = call_402656880.call(nil, query_402656881, nil, nil, body_402656882)

var listSimulationApplications* = Call_ListSimulationApplications_402656866(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_402656867, base: "/",
    makeUrl: url_ListSimulationApplications_402656868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobBatches_402656883 = ref object of OpenApiRestCall_402656044
proc url_ListSimulationJobBatches_402656885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationJobBatches_402656884(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656886 = query.getOrDefault("maxResults")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "maxResults", valid_402656886
  var valid_402656887 = query.getOrDefault("nextToken")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "nextToken", valid_402656887
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
  var valid_402656888 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Security-Token", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Signature")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Signature", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Algorithm", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Date")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Date", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Credential")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Credential", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656894
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

proc call*(call_402656896: Call_ListSimulationJobBatches_402656883;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
                                                                                         ## 
  let valid = call_402656896.validator(path, query, header, formData, body, _)
  let scheme = call_402656896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656896.makeUrl(scheme.get, call_402656896.host, call_402656896.base,
                                   call_402656896.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656896, uri, valid, _)

proc call*(call_402656897: Call_ListSimulationJobBatches_402656883;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listSimulationJobBatches
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
  ##   
                                                                                                                           ## maxResults: string
                                                                                                                           ##             
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## limit
  ##   
                                                                                                                                   ## nextToken: string
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## Pagination 
                                                                                                                                   ## token
  ##   
                                                                                                                                           ## body: JObject (required)
  var query_402656898 = newJObject()
  var body_402656899 = newJObject()
  add(query_402656898, "maxResults", newJString(maxResults))
  add(query_402656898, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656899 = body
  result = call_402656897.call(nil, query_402656898, nil, nil, body_402656899)

var listSimulationJobBatches* = Call_ListSimulationJobBatches_402656883(
    name: "listSimulationJobBatches", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobBatches",
    validator: validate_ListSimulationJobBatches_402656884, base: "/",
    makeUrl: url_ListSimulationJobBatches_402656885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_402656900 = ref object of OpenApiRestCall_402656044
proc url_ListSimulationJobs_402656902(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationJobs_402656901(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656903 = query.getOrDefault("maxResults")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "maxResults", valid_402656903
  var valid_402656904 = query.getOrDefault("nextToken")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "nextToken", valid_402656904
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
  var valid_402656905 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Security-Token", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Signature")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Signature", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Algorithm", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Date")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Date", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Credential")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Credential", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656911
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

proc call*(call_402656913: Call_ListSimulationJobs_402656900;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
                                                                                         ## 
  let valid = call_402656913.validator(path, query, header, formData, body, _)
  let scheme = call_402656913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656913.makeUrl(scheme.get, call_402656913.host, call_402656913.base,
                                   call_402656913.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656913, uri, valid, _)

proc call*(call_402656914: Call_ListSimulationJobs_402656900; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   
                                                                                                                 ## maxResults: string
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## nextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  ##   
                                                                                                                                 ## body: JObject (required)
  var query_402656915 = newJObject()
  var body_402656916 = newJObject()
  add(query_402656915, "maxResults", newJString(maxResults))
  add(query_402656915, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656916 = body
  result = call_402656914.call(nil, query_402656915, nil, nil, body_402656916)

var listSimulationJobs* = Call_ListSimulationJobs_402656900(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_402656901, base: "/",
    makeUrl: url_ListSimulationJobs_402656902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656942 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656944(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656943(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656945 = path.getOrDefault("resourceArn")
  valid_402656945 = validateParameter(valid_402656945, JString, required = true,
                                      default = nil)
  if valid_402656945 != nil:
    section.add "resourceArn", valid_402656945
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
  var valid_402656946 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Security-Token", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Signature")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Signature", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Algorithm", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Date")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Date", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Credential")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Credential", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656952
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

proc call*(call_402656954: Call_TagResource_402656942; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402656954.validator(path, query, header, formData, body, _)
  let scheme = call_402656954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656954.makeUrl(scheme.get, call_402656954.host, call_402656954.base,
                                   call_402656954.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656954, uri, valid, _)

proc call*(call_402656955: Call_TagResource_402656942; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## AWS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## RoboMaker 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## tagging.
  var path_402656956 = newJObject()
  var body_402656957 = newJObject()
  if body != nil:
    body_402656957 = body
  add(path_402656956, "resourceArn", newJString(resourceArn))
  result = call_402656955.call(path_402656956, nil, nil, nil, body_402656957)

var tagResource* = Call_TagResource_402656942(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656943,
    base: "/", makeUrl: url_TagResource_402656944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656917 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656919(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656918(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all tags on a AWS RoboMaker resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656931 = path.getOrDefault("resourceArn")
  valid_402656931 = validateParameter(valid_402656931, JString, required = true,
                                      default = nil)
  if valid_402656931 != nil:
    section.add "resourceArn", valid_402656931
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
  var valid_402656932 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Security-Token", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Signature")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Signature", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Algorithm", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Date")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Date", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Credential")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Credential", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656939: Call_ListTagsForResource_402656917;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
                                                                                         ## 
  let valid = call_402656939.validator(path, query, header, formData, body, _)
  let scheme = call_402656939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656939.makeUrl(scheme.get, call_402656939.host, call_402656939.base,
                                   call_402656939.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656939, uri, valid, _)

proc call*(call_402656940: Call_ListTagsForResource_402656917;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
                                                ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_402656941 = newJObject()
  add(path_402656941, "resourceArn", newJString(resourceArn))
  result = call_402656940.call(path_402656941, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656917(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656918, base: "/",
    makeUrl: url_ListTagsForResource_402656919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_402656958 = ref object of OpenApiRestCall_402656044
proc url_RegisterRobot_402656960(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterRobot_402656959(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Registers a robot with a fleet.
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
  var valid_402656961 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Security-Token", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Signature")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Signature", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Algorithm", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Date")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Date", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Credential")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Credential", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656967
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

proc call*(call_402656969: Call_RegisterRobot_402656958; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a robot with a fleet.
                                                                                         ## 
  let valid = call_402656969.validator(path, query, header, formData, body, _)
  let scheme = call_402656969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656969.makeUrl(scheme.get, call_402656969.host, call_402656969.base,
                                   call_402656969.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656969, uri, valid, _)

proc call*(call_402656970: Call_RegisterRobot_402656958; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_402656971 = newJObject()
  if body != nil:
    body_402656971 = body
  result = call_402656970.call(nil, nil, nil, nil, body_402656971)

var registerRobot* = Call_RegisterRobot_402656958(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_402656959,
    base: "/", makeUrl: url_RegisterRobot_402656960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_402656972 = ref object of OpenApiRestCall_402656044
proc url_RestartSimulationJob_402656974(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestartSimulationJob_402656973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Restarts a running simulation job.
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
  var valid_402656975 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Security-Token", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Signature")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Signature", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Algorithm", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Date")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Date", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Credential")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Credential", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656981
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

proc call*(call_402656983: Call_RestartSimulationJob_402656972;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Restarts a running simulation job.
                                                                                         ## 
  let valid = call_402656983.validator(path, query, header, formData, body, _)
  let scheme = call_402656983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656983.makeUrl(scheme.get, call_402656983.host, call_402656983.base,
                                   call_402656983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656983, uri, valid, _)

proc call*(call_402656984: Call_RestartSimulationJob_402656972; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_402656985 = newJObject()
  if body != nil:
    body_402656985 = body
  result = call_402656984.call(nil, nil, nil, nil, body_402656985)

var restartSimulationJob* = Call_RestartSimulationJob_402656972(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_402656973, base: "/",
    makeUrl: url_RestartSimulationJob_402656974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSimulationJobBatch_402656986 = ref object of OpenApiRestCall_402656044
proc url_StartSimulationJobBatch_402656988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSimulationJobBatch_402656987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
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
  var valid_402656989 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Security-Token", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Signature")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Signature", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Algorithm", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Date")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Date", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Credential")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Credential", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656995
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

proc call*(call_402656997: Call_StartSimulationJobBatch_402656986;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
                                                                                         ## 
  let valid = call_402656997.validator(path, query, header, formData, body, _)
  let scheme = call_402656997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656997.makeUrl(scheme.get, call_402656997.host, call_402656997.base,
                                   call_402656997.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656997, uri, valid, _)

proc call*(call_402656998: Call_StartSimulationJobBatch_402656986;
           body: JsonNode): Recallable =
  ## startSimulationJobBatch
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
  ##   
                                                                                                                          ## body: JObject (required)
  var body_402656999 = newJObject()
  if body != nil:
    body_402656999 = body
  result = call_402656998.call(nil, nil, nil, nil, body_402656999)

var startSimulationJobBatch* = Call_StartSimulationJobBatch_402656986(
    name: "startSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/startSimulationJobBatch",
    validator: validate_StartSimulationJobBatch_402656987, base: "/",
    makeUrl: url_StartSimulationJobBatch_402656988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_402657000 = ref object of OpenApiRestCall_402656044
proc url_SyncDeploymentJob_402657002(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SyncDeploymentJob_402657001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
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
  var valid_402657003 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Security-Token", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Signature")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Signature", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Algorithm", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Date")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Date", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Credential")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Credential", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657009
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

proc call*(call_402657011: Call_SyncDeploymentJob_402657000;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
                                                                                         ## 
  let valid = call_402657011.validator(path, query, header, formData, body, _)
  let scheme = call_402657011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657011.makeUrl(scheme.get, call_402657011.host, call_402657011.base,
                                   call_402657011.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657011, uri, valid, _)

proc call*(call_402657012: Call_SyncDeploymentJob_402657000; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   
                                                                                                                      ## body: JObject (required)
  var body_402657013 = newJObject()
  if body != nil:
    body_402657013 = body
  result = call_402657012.call(nil, nil, nil, nil, body_402657013)

var syncDeploymentJob* = Call_SyncDeploymentJob_402657000(
    name: "syncDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/syncDeploymentJob",
    validator: validate_SyncDeploymentJob_402657001, base: "/",
    makeUrl: url_SyncDeploymentJob_402657002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657014 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657016(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402657015(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657017 = path.getOrDefault("resourceArn")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true,
                                      default = nil)
  if valid_402657017 != nil:
    section.add "resourceArn", valid_402657017
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657018 = query.getOrDefault("tagKeys")
  valid_402657018 = validateParameter(valid_402657018, JArray, required = true,
                                      default = nil)
  if valid_402657018 != nil:
    section.add "tagKeys", valid_402657018
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
  var valid_402657019 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Security-Token", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Signature")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Signature", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Algorithm", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Date")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Date", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Credential")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Credential", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657026: Call_UntagResource_402657014; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
                                                                                         ## 
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_UntagResource_402657014; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   
                                                                                                                                                                                                                                                                                                  ## tagKeys: JArray (required)
                                                                                                                                                                                                                                                                                                  ##          
                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                  ## A 
                                                                                                                                                                                                                                                                                                  ## map 
                                                                                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                                                                                  ## contains 
                                                                                                                                                                                                                                                                                                  ## tag 
                                                                                                                                                                                                                                                                                                  ## keys 
                                                                                                                                                                                                                                                                                                  ## and 
                                                                                                                                                                                                                                                                                                  ## tag 
                                                                                                                                                                                                                                                                                                  ## values 
                                                                                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                                                                                  ## will 
                                                                                                                                                                                                                                                                                                  ## be 
                                                                                                                                                                                                                                                                                                  ## unattached 
                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                  ## resource.
  ##   
                                                                                                                                                                                                                                                                                                              ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                                              ##              
                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                              ## Amazon 
                                                                                                                                                                                                                                                                                                              ## Resource 
                                                                                                                                                                                                                                                                                                              ## Name 
                                                                                                                                                                                                                                                                                                              ## (ARN) 
                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                              ## AWS 
                                                                                                                                                                                                                                                                                                              ## RoboMaker 
                                                                                                                                                                                                                                                                                                              ## resource 
                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                              ## are 
                                                                                                                                                                                                                                                                                                              ## removing 
                                                                                                                                                                                                                                                                                                              ## tags.
  var path_402657028 = newJObject()
  var query_402657029 = newJObject()
  if tagKeys != nil:
    query_402657029.add "tagKeys", tagKeys
  add(path_402657028, "resourceArn", newJString(resourceArn))
  result = call_402657027.call(path_402657028, query_402657029, nil, nil, nil)

var untagResource* = Call_UntagResource_402657014(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402657015,
    base: "/", makeUrl: url_UntagResource_402657016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_402657030 = ref object of OpenApiRestCall_402656044
proc url_UpdateRobotApplication_402657032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRobotApplication_402657031(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a robot application.
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
  var valid_402657033 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Security-Token", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Signature")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Signature", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Algorithm", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Date")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Date", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Credential")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Credential", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657039
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

proc call*(call_402657041: Call_UpdateRobotApplication_402657030;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a robot application.
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_UpdateRobotApplication_402657030; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_402657043 = newJObject()
  if body != nil:
    body_402657043 = body
  result = call_402657042.call(nil, nil, nil, nil, body_402657043)

var updateRobotApplication* = Call_UpdateRobotApplication_402657030(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_402657031, base: "/",
    makeUrl: url_UpdateRobotApplication_402657032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_402657044 = ref object of OpenApiRestCall_402656044
proc url_UpdateSimulationApplication_402657046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSimulationApplication_402657045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates a simulation application.
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
  var valid_402657047 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Security-Token", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Signature")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Signature", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Algorithm", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Date")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Date", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Credential")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Credential", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657053
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

proc call*(call_402657055: Call_UpdateSimulationApplication_402657044;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a simulation application.
                                                                                         ## 
  let valid = call_402657055.validator(path, query, header, formData, body, _)
  let scheme = call_402657055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657055.makeUrl(scheme.get, call_402657055.host, call_402657055.base,
                                   call_402657055.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657055, uri, valid, _)

proc call*(call_402657056: Call_UpdateSimulationApplication_402657044;
           body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_402657057 = newJObject()
  if body != nil:
    body_402657057 = body
  result = call_402657056.call(nil, nil, nil, nil, body_402657057)

var updateSimulationApplication* = Call_UpdateSimulationApplication_402657044(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_402657045, base: "/",
    makeUrl: url_UpdateSimulationApplication_402657046,
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