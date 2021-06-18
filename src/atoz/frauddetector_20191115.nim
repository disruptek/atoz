
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Fraud Detector
## version: 2019-11-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This is the Amazon Fraud Detector API Reference. This guide is for developers who need detailed information about Amazon Fraud Detector API actions, data types, and errors. For more information about Amazon Fraud Detector features, see the <a href="https://docs.aws.amazon.com/frauddetector/latest/ug/">Amazon Fraud Detector User Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/frauddetector/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "frauddetector.ap-northeast-1.amazonaws.com", "ap-southeast-1": "frauddetector.ap-southeast-1.amazonaws.com", "us-west-2": "frauddetector.us-west-2.amazonaws.com", "eu-west-2": "frauddetector.eu-west-2.amazonaws.com", "ap-northeast-3": "frauddetector.ap-northeast-3.amazonaws.com", "eu-central-1": "frauddetector.eu-central-1.amazonaws.com", "us-east-2": "frauddetector.us-east-2.amazonaws.com", "us-east-1": "frauddetector.us-east-1.amazonaws.com", "cn-northwest-1": "frauddetector.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "frauddetector.ap-south-1.amazonaws.com", "eu-north-1": "frauddetector.eu-north-1.amazonaws.com", "ap-northeast-2": "frauddetector.ap-northeast-2.amazonaws.com", "us-west-1": "frauddetector.us-west-1.amazonaws.com", "us-gov-east-1": "frauddetector.us-gov-east-1.amazonaws.com", "eu-west-3": "frauddetector.eu-west-3.amazonaws.com", "cn-north-1": "frauddetector.cn-north-1.amazonaws.com.cn", "sa-east-1": "frauddetector.sa-east-1.amazonaws.com", "eu-west-1": "frauddetector.eu-west-1.amazonaws.com", "us-gov-west-1": "frauddetector.us-gov-west-1.amazonaws.com", "ap-southeast-2": "frauddetector.ap-southeast-2.amazonaws.com", "ca-central-1": "frauddetector.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "frauddetector.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "frauddetector.ap-southeast-1.amazonaws.com",
      "us-west-2": "frauddetector.us-west-2.amazonaws.com",
      "eu-west-2": "frauddetector.eu-west-2.amazonaws.com",
      "ap-northeast-3": "frauddetector.ap-northeast-3.amazonaws.com",
      "eu-central-1": "frauddetector.eu-central-1.amazonaws.com",
      "us-east-2": "frauddetector.us-east-2.amazonaws.com",
      "us-east-1": "frauddetector.us-east-1.amazonaws.com",
      "cn-northwest-1": "frauddetector.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "frauddetector.ap-south-1.amazonaws.com",
      "eu-north-1": "frauddetector.eu-north-1.amazonaws.com",
      "ap-northeast-2": "frauddetector.ap-northeast-2.amazonaws.com",
      "us-west-1": "frauddetector.us-west-1.amazonaws.com",
      "us-gov-east-1": "frauddetector.us-gov-east-1.amazonaws.com",
      "eu-west-3": "frauddetector.eu-west-3.amazonaws.com",
      "cn-north-1": "frauddetector.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "frauddetector.sa-east-1.amazonaws.com",
      "eu-west-1": "frauddetector.eu-west-1.amazonaws.com",
      "us-gov-west-1": "frauddetector.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "frauddetector.ap-southeast-2.amazonaws.com",
      "ca-central-1": "frauddetector.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "frauddetector"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchCreateVariable_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchCreateVariable_402656296(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCreateVariable_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a batch of variables.
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
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchCreateVariable"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_BatchCreateVariable_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a batch of variables.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_BatchCreateVariable_402656294; body: JsonNode): Recallable =
  ## batchCreateVariable
  ## Creates a batch of variables.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var batchCreateVariable* = Call_BatchCreateVariable_402656294(
    name: "batchCreateVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchCreateVariable",
    validator: validate_BatchCreateVariable_402656295, base: "/",
    makeUrl: url_BatchCreateVariable_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetVariable_402656489 = ref object of OpenApiRestCall_402656044
proc url_BatchGetVariable_402656491(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetVariable_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a batch of variables.
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
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.BatchGetVariable"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
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

proc call*(call_402656501: Call_BatchGetVariable_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a batch of variables.
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

proc call*(call_402656502: Call_BatchGetVariable_402656489; body: JsonNode): Recallable =
  ## batchGetVariable
  ## Gets a batch of variables.
  ##   body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var batchGetVariable* = Call_BatchGetVariable_402656489(
    name: "batchGetVariable", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.BatchGetVariable",
    validator: validate_BatchGetVariable_402656490, base: "/",
    makeUrl: url_BatchGetVariable_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetectorVersion_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateDetectorVersion_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetectorVersion_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
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
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateDetectorVersion"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_CreateDetectorVersion_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateDetectorVersion_402656504; body: JsonNode): Recallable =
  ## createDetectorVersion
  ## Creates a detector version. The detector version starts in a <code>DRAFT</code> status.
  ##   
                                                                                            ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createDetectorVersion* = Call_CreateDetectorVersion_402656504(
    name: "createDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateDetectorVersion",
    validator: validate_CreateDetectorVersion_402656505, base: "/",
    makeUrl: url_CreateDetectorVersion_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelVersion_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateModelVersion_402656521(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelVersion_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a version of the model using the specified model type. 
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
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateModelVersion"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_CreateModelVersion_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a version of the model using the specified model type. 
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateModelVersion_402656519; body: JsonNode): Recallable =
  ## createModelVersion
  ## Creates a version of the model using the specified model type. 
  ##   body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createModelVersion* = Call_CreateModelVersion_402656519(
    name: "createModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateModelVersion",
    validator: validate_CreateModelVersion_402656520, base: "/",
    makeUrl: url_CreateModelVersion_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateRule_402656536(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRule_402656535(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a rule for use with the specified detector. 
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
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateRule"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
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

proc call*(call_402656546: Call_CreateRule_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a rule for use with the specified detector. 
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateRule_402656534; body: JsonNode): Recallable =
  ## createRule
  ## Creates a rule for use with the specified detector. 
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createRule* = Call_CreateRule_402656534(name: "createRule",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateRule",
    validator: validate_CreateRule_402656535, base: "/",
    makeUrl: url_CreateRule_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVariable_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateVariable_402656551(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateVariable_402656550(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a variable.
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
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.CreateVariable"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
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

proc call*(call_402656561: Call_CreateVariable_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a variable.
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateVariable_402656549; body: JsonNode): Recallable =
  ## createVariable
  ## Creates a variable.
  ##   body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createVariable* = Call_CreateVariable_402656549(name: "createVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.CreateVariable",
    validator: validate_CreateVariable_402656550, base: "/",
    makeUrl: url_CreateVariable_402656551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetectorVersion_402656564 = ref object of OpenApiRestCall_402656044
proc url_DeleteDetectorVersion_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDetectorVersion_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the detector version.
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
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteDetectorVersion"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_DeleteDetectorVersion_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the detector version.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DeleteDetectorVersion_402656564; body: JsonNode): Recallable =
  ## deleteDetectorVersion
  ## Deletes the detector version.
  ##   body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var deleteDetectorVersion* = Call_DeleteDetectorVersion_402656564(
    name: "deleteDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteDetectorVersion",
    validator: validate_DeleteDetectorVersion_402656565, base: "/",
    makeUrl: url_DeleteDetectorVersion_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvent_402656579 = ref object of OpenApiRestCall_402656044
proc url_DeleteEvent_402656581(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvent_402656580(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified event.
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
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DeleteEvent"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_DeleteEvent_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified event.
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

proc call*(call_402656592: Call_DeleteEvent_402656579; body: JsonNode): Recallable =
  ## deleteEvent
  ## Deletes the specified event.
  ##   body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var deleteEvent* = Call_DeleteEvent_402656579(name: "deleteEvent",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DeleteEvent",
    validator: validate_DeleteEvent_402656580, base: "/",
    makeUrl: url_DeleteEvent_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDetector_402656594 = ref object of OpenApiRestCall_402656044
proc url_DescribeDetector_402656596(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDetector_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all versions for a specified detector.
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
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeDetector"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_DescribeDetector_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all versions for a specified detector.
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

proc call*(call_402656607: Call_DescribeDetector_402656594; body: JsonNode): Recallable =
  ## describeDetector
  ## Gets all versions for a specified detector.
  ##   body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var describeDetector* = Call_DescribeDetector_402656594(
    name: "describeDetector", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeDetector",
    validator: validate_DescribeDetector_402656595, base: "/",
    makeUrl: url_DescribeDetector_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelVersions_402656609 = ref object of OpenApiRestCall_402656044
proc url_DescribeModelVersions_402656611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelVersions_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
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
  var valid_402656612 = query.getOrDefault("maxResults")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "maxResults", valid_402656612
  var valid_402656613 = query.getOrDefault("nextToken")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "nextToken", valid_402656613
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
  var valid_402656614 = header.getOrDefault("X-Amz-Target")
  valid_402656614 = validateParameter(valid_402656614, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.DescribeModelVersions"))
  if valid_402656614 != nil:
    section.add "X-Amz-Target", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Security-Token", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Signature")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Signature", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Algorithm", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Date")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Date", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Credential")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Credential", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656621
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

proc call*(call_402656623: Call_DescribeModelVersions_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
                                                                                         ## 
  let valid = call_402656623.validator(path, query, header, formData, body, _)
  let scheme = call_402656623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656623.makeUrl(scheme.get, call_402656623.host, call_402656623.base,
                                   call_402656623.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656623, uri, valid, _)

proc call*(call_402656624: Call_DescribeModelVersions_402656609; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeModelVersions
  ## Gets all of the model versions for the specified model type or for the specified model type and model ID. You can also get details for a single, specified model version. 
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
  var query_402656625 = newJObject()
  var body_402656626 = newJObject()
  add(query_402656625, "maxResults", newJString(maxResults))
  add(query_402656625, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656626 = body
  result = call_402656624.call(nil, query_402656625, nil, nil, body_402656626)

var describeModelVersions* = Call_DescribeModelVersions_402656609(
    name: "describeModelVersions", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.DescribeModelVersions",
    validator: validate_DescribeModelVersions_402656610, base: "/",
    makeUrl: url_DescribeModelVersions_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectorVersion_402656627 = ref object of OpenApiRestCall_402656044
proc url_GetDetectorVersion_402656629(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectorVersion_402656628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a particular detector version. 
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
  var valid_402656630 = header.getOrDefault("X-Amz-Target")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectorVersion"))
  if valid_402656630 != nil:
    section.add "X-Amz-Target", valid_402656630
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656639: Call_GetDetectorVersion_402656627;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a particular detector version. 
                                                                                         ## 
  let valid = call_402656639.validator(path, query, header, formData, body, _)
  let scheme = call_402656639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656639.makeUrl(scheme.get, call_402656639.host, call_402656639.base,
                                   call_402656639.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656639, uri, valid, _)

proc call*(call_402656640: Call_GetDetectorVersion_402656627; body: JsonNode): Recallable =
  ## getDetectorVersion
  ## Gets a particular detector version. 
  ##   body: JObject (required)
  var body_402656641 = newJObject()
  if body != nil:
    body_402656641 = body
  result = call_402656640.call(nil, nil, nil, nil, body_402656641)

var getDetectorVersion* = Call_GetDetectorVersion_402656627(
    name: "getDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectorVersion",
    validator: validate_GetDetectorVersion_402656628, base: "/",
    makeUrl: url_GetDetectorVersion_402656629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetectors_402656642 = ref object of OpenApiRestCall_402656044
proc url_GetDetectors_402656644(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDetectors_402656643(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var valid_402656645 = query.getOrDefault("maxResults")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "maxResults", valid_402656645
  var valid_402656646 = query.getOrDefault("nextToken")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "nextToken", valid_402656646
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
  var valid_402656647 = header.getOrDefault("X-Amz-Target")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetDetectors"))
  if valid_402656647 != nil:
    section.add "X-Amz-Target", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Security-Token", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Signature")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Signature", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Algorithm", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Date")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Date", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Credential")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Credential", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656654
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

proc call*(call_402656656: Call_GetDetectors_402656642; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
                                                                                         ## 
  let valid = call_402656656.validator(path, query, header, formData, body, _)
  let scheme = call_402656656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656656.makeUrl(scheme.get, call_402656656.host, call_402656656.base,
                                   call_402656656.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656656, uri, valid, _)

proc call*(call_402656657: Call_GetDetectors_402656642; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getDetectors
  ## Gets all of detectors. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetEventTypesResponse</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var query_402656658 = newJObject()
  var body_402656659 = newJObject()
  add(query_402656658, "maxResults", newJString(maxResults))
  add(query_402656658, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656659 = body
  result = call_402656657.call(nil, query_402656658, nil, nil, body_402656659)

var getDetectors* = Call_GetDetectors_402656642(name: "getDetectors",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetDetectors",
    validator: validate_GetDetectors_402656643, base: "/",
    makeUrl: url_GetDetectors_402656644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExternalModels_402656660 = ref object of OpenApiRestCall_402656044
proc url_GetExternalModels_402656662(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExternalModels_402656661(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var valid_402656663 = query.getOrDefault("maxResults")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "maxResults", valid_402656663
  var valid_402656664 = query.getOrDefault("nextToken")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "nextToken", valid_402656664
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
  var valid_402656665 = header.getOrDefault("X-Amz-Target")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetExternalModels"))
  if valid_402656665 != nil:
    section.add "X-Amz-Target", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
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

proc call*(call_402656674: Call_GetExternalModels_402656660;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
                                                                                         ## 
  let valid = call_402656674.validator(path, query, header, formData, body, _)
  let scheme = call_402656674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656674.makeUrl(scheme.get, call_402656674.host, call_402656674.base,
                                   call_402656674.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656674, uri, valid, _)

proc call*(call_402656675: Call_GetExternalModels_402656660; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getExternalModels
  ## Gets the details for one or more Amazon SageMaker models that have been imported into the service. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 5 and 10. To get the next page results, provide the pagination token from the <code>GetExternalModelsResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var query_402656676 = newJObject()
  var body_402656677 = newJObject()
  add(query_402656676, "maxResults", newJString(maxResults))
  add(query_402656676, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656677 = body
  result = call_402656675.call(nil, query_402656676, nil, nil, body_402656677)

var getExternalModels* = Call_GetExternalModels_402656660(
    name: "getExternalModels", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetExternalModels",
    validator: validate_GetExternalModels_402656661, base: "/",
    makeUrl: url_GetExternalModels_402656662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModelVersion_402656678 = ref object of OpenApiRestCall_402656044
proc url_GetModelVersion_402656680(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModelVersion_402656679(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a model version. 
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
  var valid_402656681 = header.getOrDefault("X-Amz-Target")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModelVersion"))
  if valid_402656681 != nil:
    section.add "X-Amz-Target", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
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

proc call*(call_402656690: Call_GetModelVersion_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a model version. 
                                                                                         ## 
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_GetModelVersion_402656678; body: JsonNode): Recallable =
  ## getModelVersion
  ## Gets a model version. 
  ##   body: JObject (required)
  var body_402656692 = newJObject()
  if body != nil:
    body_402656692 = body
  result = call_402656691.call(nil, nil, nil, nil, body_402656692)

var getModelVersion* = Call_GetModelVersion_402656678(name: "getModelVersion",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModelVersion",
    validator: validate_GetModelVersion_402656679, base: "/",
    makeUrl: url_GetModelVersion_402656680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModels_402656693 = ref object of OpenApiRestCall_402656044
proc url_GetModels_402656695(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModels_402656694(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
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
  var valid_402656696 = query.getOrDefault("maxResults")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "maxResults", valid_402656696
  var valid_402656697 = query.getOrDefault("nextToken")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "nextToken", valid_402656697
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
  var valid_402656698 = header.getOrDefault("X-Amz-Target")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetModels"))
  if valid_402656698 != nil:
    section.add "X-Amz-Target", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Security-Token", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Signature")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Signature", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Algorithm", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Date")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Date", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Credential")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Credential", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656705
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

proc call*(call_402656707: Call_GetModels_402656693; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
                                                                                         ## 
  let valid = call_402656707.validator(path, query, header, formData, body, _)
  let scheme = call_402656707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656707.makeUrl(scheme.get, call_402656707.host, call_402656707.base,
                                   call_402656707.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656707, uri, valid, _)

proc call*(call_402656708: Call_GetModels_402656693; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getModels
  ## Gets all of the models for the AWS account, or the specified model type, or gets a single model for the specified model type, model ID combination. 
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
  var query_402656709 = newJObject()
  var body_402656710 = newJObject()
  add(query_402656709, "maxResults", newJString(maxResults))
  add(query_402656709, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656710 = body
  result = call_402656708.call(nil, query_402656709, nil, nil, body_402656710)

var getModels* = Call_GetModels_402656693(name: "getModels",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetModels",
    validator: validate_GetModels_402656694, base: "/", makeUrl: url_GetModels_402656695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutcomes_402656711 = ref object of OpenApiRestCall_402656044
proc url_GetOutcomes_402656713(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOutcomes_402656712(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var valid_402656714 = query.getOrDefault("maxResults")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "maxResults", valid_402656714
  var valid_402656715 = query.getOrDefault("nextToken")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "nextToken", valid_402656715
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
  var valid_402656716 = header.getOrDefault("X-Amz-Target")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetOutcomes"))
  if valid_402656716 != nil:
    section.add "X-Amz-Target", valid_402656716
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

proc call*(call_402656725: Call_GetOutcomes_402656711; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
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

proc call*(call_402656726: Call_GetOutcomes_402656711; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getOutcomes
  ## Gets one or more outcomes. This is a paginated API. If you provide a null <code>maxSizePerPage</code>, this actions retrieves a maximum of 10 records per page. If you provide a <code>maxSizePerPage</code>, the value must be between 50 and 100. To get the next page results, provide the pagination token from the <code>GetOutcomesResult</code> as part of your request. A null pagination token fetches the records from the beginning. 
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
  var query_402656727 = newJObject()
  var body_402656728 = newJObject()
  add(query_402656727, "maxResults", newJString(maxResults))
  add(query_402656727, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656728 = body
  result = call_402656726.call(nil, query_402656727, nil, nil, body_402656728)

var getOutcomes* = Call_GetOutcomes_402656711(name: "getOutcomes",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetOutcomes",
    validator: validate_GetOutcomes_402656712, base: "/",
    makeUrl: url_GetOutcomes_402656713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPrediction_402656729 = ref object of OpenApiRestCall_402656044
proc url_GetPrediction_402656731(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPrediction_402656730(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
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
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetPrediction"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_GetPrediction_402656729; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_GetPrediction_402656729; body: JsonNode): Recallable =
  ## getPrediction
  ## Evaluates an event against a detector version. If a version ID is not provided, the detector’s (<code>ACTIVE</code>) version is used. 
  ##   
                                                                                                                                             ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var getPrediction* = Call_GetPrediction_402656729(name: "getPrediction",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetPrediction",
    validator: validate_GetPrediction_402656730, base: "/",
    makeUrl: url_GetPrediction_402656731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRules_402656744 = ref object of OpenApiRestCall_402656044
proc url_GetRules_402656746(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRules_402656745(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all rules available for the specified detector.
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
  var valid_402656747 = query.getOrDefault("maxResults")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "maxResults", valid_402656747
  var valid_402656748 = query.getOrDefault("nextToken")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "nextToken", valid_402656748
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
  var valid_402656749 = header.getOrDefault("X-Amz-Target")
  valid_402656749 = validateParameter(valid_402656749, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetRules"))
  if valid_402656749 != nil:
    section.add "X-Amz-Target", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Security-Token", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Signature")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Signature", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Algorithm", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Date")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Date", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Credential")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Credential", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656756
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

proc call*(call_402656758: Call_GetRules_402656744; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all rules available for the specified detector.
                                                                                         ## 
  let valid = call_402656758.validator(path, query, header, formData, body, _)
  let scheme = call_402656758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656758.makeUrl(scheme.get, call_402656758.host, call_402656758.base,
                                   call_402656758.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656758, uri, valid, _)

proc call*(call_402656759: Call_GetRules_402656744; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getRules
  ## Gets all rules available for the specified detector.
  ##   maxResults: string
                                                         ##             : Pagination limit
  ##   
                                                                                          ## nextToken: string
                                                                                          ##            
                                                                                          ## : 
                                                                                          ## Pagination 
                                                                                          ## token
  ##   
                                                                                                  ## body: JObject (required)
  var query_402656760 = newJObject()
  var body_402656761 = newJObject()
  add(query_402656760, "maxResults", newJString(maxResults))
  add(query_402656760, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656761 = body
  result = call_402656759.call(nil, query_402656760, nil, nil, body_402656761)

var getRules* = Call_GetRules_402656744(name: "getRules",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetRules",
                                        validator: validate_GetRules_402656745,
                                        base: "/", makeUrl: url_GetRules_402656746,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetVariables_402656762 = ref object of OpenApiRestCall_402656044
proc url_GetVariables_402656764(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetVariables_402656763(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
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
  var valid_402656765 = query.getOrDefault("maxResults")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "maxResults", valid_402656765
  var valid_402656766 = query.getOrDefault("nextToken")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "nextToken", valid_402656766
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
  var valid_402656767 = header.getOrDefault("X-Amz-Target")
  valid_402656767 = validateParameter(valid_402656767, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.GetVariables"))
  if valid_402656767 != nil:
    section.add "X-Amz-Target", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Security-Token", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Signature")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Signature", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Algorithm", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Date")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Date", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Credential")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Credential", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656774
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

proc call*(call_402656776: Call_GetVariables_402656762; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
                                                                                         ## 
  let valid = call_402656776.validator(path, query, header, formData, body, _)
  let scheme = call_402656776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656776.makeUrl(scheme.get, call_402656776.host, call_402656776.base,
                                   call_402656776.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656776, uri, valid, _)

proc call*(call_402656777: Call_GetVariables_402656762; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getVariables
  ## Gets all of the variables or the specific variable. This is a paginated API. Providing null <code>maxSizePerPage</code> results in retrieving maximum of 100 records per page. If you provide <code>maxSizePerPage</code> the value must be between 50 and 100. To get the next page result, a provide a pagination token from <code>GetVariablesResult</code> as part of your request. Null pagination token fetches the records from the beginning. 
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
  var query_402656778 = newJObject()
  var body_402656779 = newJObject()
  add(query_402656778, "maxResults", newJString(maxResults))
  add(query_402656778, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656779 = body
  result = call_402656777.call(nil, query_402656778, nil, nil, body_402656779)

var getVariables* = Call_GetVariables_402656762(name: "getVariables",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.GetVariables",
    validator: validate_GetVariables_402656763, base: "/",
    makeUrl: url_GetVariables_402656764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDetector_402656780 = ref object of OpenApiRestCall_402656044
proc url_PutDetector_402656782(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDetector_402656781(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or updates a detector. 
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
  var valid_402656783 = header.getOrDefault("X-Amz-Target")
  valid_402656783 = validateParameter(valid_402656783, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutDetector"))
  if valid_402656783 != nil:
    section.add "X-Amz-Target", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Security-Token", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Signature")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Signature", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Algorithm", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Date")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Date", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Credential")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Credential", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656790
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

proc call*(call_402656792: Call_PutDetector_402656780; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates a detector. 
                                                                                         ## 
  let valid = call_402656792.validator(path, query, header, formData, body, _)
  let scheme = call_402656792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656792.makeUrl(scheme.get, call_402656792.host, call_402656792.base,
                                   call_402656792.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656792, uri, valid, _)

proc call*(call_402656793: Call_PutDetector_402656780; body: JsonNode): Recallable =
  ## putDetector
  ## Creates or updates a detector. 
  ##   body: JObject (required)
  var body_402656794 = newJObject()
  if body != nil:
    body_402656794 = body
  result = call_402656793.call(nil, nil, nil, nil, body_402656794)

var putDetector* = Call_PutDetector_402656780(name: "putDetector",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutDetector",
    validator: validate_PutDetector_402656781, base: "/",
    makeUrl: url_PutDetector_402656782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutExternalModel_402656795 = ref object of OpenApiRestCall_402656044
proc url_PutExternalModel_402656797(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutExternalModel_402656796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
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
  var valid_402656798 = header.getOrDefault("X-Amz-Target")
  valid_402656798 = validateParameter(valid_402656798, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutExternalModel"))
  if valid_402656798 != nil:
    section.add "X-Amz-Target", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Security-Token", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Signature")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Signature", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Algorithm", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Date")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Date", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Credential")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Credential", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656805
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

proc call*(call_402656807: Call_PutExternalModel_402656795;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
                                                                                         ## 
  let valid = call_402656807.validator(path, query, header, formData, body, _)
  let scheme = call_402656807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656807.makeUrl(scheme.get, call_402656807.host, call_402656807.base,
                                   call_402656807.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656807, uri, valid, _)

proc call*(call_402656808: Call_PutExternalModel_402656795; body: JsonNode): Recallable =
  ## putExternalModel
  ## Creates or updates an Amazon SageMaker model endpoint. You can also use this action to update the configuration of the model endpoint, including the IAM role and/or the mapped variables. 
  ##   
                                                                                                                                                                                                ## body: JObject (required)
  var body_402656809 = newJObject()
  if body != nil:
    body_402656809 = body
  result = call_402656808.call(nil, nil, nil, nil, body_402656809)

var putExternalModel* = Call_PutExternalModel_402656795(
    name: "putExternalModel", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutExternalModel",
    validator: validate_PutExternalModel_402656796, base: "/",
    makeUrl: url_PutExternalModel_402656797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutModel_402656810 = ref object of OpenApiRestCall_402656044
proc url_PutModel_402656812(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutModel_402656811(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or updates a model. 
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
  var valid_402656813 = header.getOrDefault("X-Amz-Target")
  valid_402656813 = validateParameter(valid_402656813, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutModel"))
  if valid_402656813 != nil:
    section.add "X-Amz-Target", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Security-Token", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Signature")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Signature", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Algorithm", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Date")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Date", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Credential")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Credential", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656820
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

proc call*(call_402656822: Call_PutModel_402656810; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates a model. 
                                                                                         ## 
  let valid = call_402656822.validator(path, query, header, formData, body, _)
  let scheme = call_402656822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656822.makeUrl(scheme.get, call_402656822.host, call_402656822.base,
                                   call_402656822.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656822, uri, valid, _)

proc call*(call_402656823: Call_PutModel_402656810; body: JsonNode): Recallable =
  ## putModel
  ## Creates or updates a model. 
  ##   body: JObject (required)
  var body_402656824 = newJObject()
  if body != nil:
    body_402656824 = body
  result = call_402656823.call(nil, nil, nil, nil, body_402656824)

var putModel* = Call_PutModel_402656810(name: "putModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutModel",
                                        validator: validate_PutModel_402656811,
                                        base: "/", makeUrl: url_PutModel_402656812,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOutcome_402656825 = ref object of OpenApiRestCall_402656044
proc url_PutOutcome_402656827(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutOutcome_402656826(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or updates an outcome. 
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
  var valid_402656828 = header.getOrDefault("X-Amz-Target")
  valid_402656828 = validateParameter(valid_402656828, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.PutOutcome"))
  if valid_402656828 != nil:
    section.add "X-Amz-Target", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Security-Token", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Signature")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Signature", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Algorithm", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Date")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Date", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Credential")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Credential", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656835
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

proc call*(call_402656837: Call_PutOutcome_402656825; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates an outcome. 
                                                                                         ## 
  let valid = call_402656837.validator(path, query, header, formData, body, _)
  let scheme = call_402656837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656837.makeUrl(scheme.get, call_402656837.host, call_402656837.base,
                                   call_402656837.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656837, uri, valid, _)

proc call*(call_402656838: Call_PutOutcome_402656825; body: JsonNode): Recallable =
  ## putOutcome
  ## Creates or updates an outcome. 
  ##   body: JObject (required)
  var body_402656839 = newJObject()
  if body != nil:
    body_402656839 = body
  result = call_402656838.call(nil, nil, nil, nil, body_402656839)

var putOutcome* = Call_PutOutcome_402656825(name: "putOutcome",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.PutOutcome",
    validator: validate_PutOutcome_402656826, base: "/",
    makeUrl: url_PutOutcome_402656827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersion_402656840 = ref object of OpenApiRestCall_402656044
proc url_UpdateDetectorVersion_402656842(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersion_402656841(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
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
  var valid_402656843 = header.getOrDefault("X-Amz-Target")
  valid_402656843 = validateParameter(valid_402656843, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersion"))
  if valid_402656843 != nil:
    section.add "X-Amz-Target", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Security-Token", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Signature")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Signature", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Algorithm", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Date")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Date", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Credential")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Credential", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656850
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

proc call*(call_402656852: Call_UpdateDetectorVersion_402656840;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
                                                                                         ## 
  let valid = call_402656852.validator(path, query, header, formData, body, _)
  let scheme = call_402656852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656852.makeUrl(scheme.get, call_402656852.host, call_402656852.base,
                                   call_402656852.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656852, uri, valid, _)

proc call*(call_402656853: Call_UpdateDetectorVersion_402656840; body: JsonNode): Recallable =
  ## updateDetectorVersion
  ##  Updates a detector version. The detector version attributes that you can update include models, external model endpoints, rules, and description. You can only update a <code>DRAFT</code> detector version.
  ##   
                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656854 = newJObject()
  if body != nil:
    body_402656854 = body
  result = call_402656853.call(nil, nil, nil, nil, body_402656854)

var updateDetectorVersion* = Call_UpdateDetectorVersion_402656840(
    name: "updateDetectorVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersion",
    validator: validate_UpdateDetectorVersion_402656841, base: "/",
    makeUrl: url_UpdateDetectorVersion_402656842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionMetadata_402656855 = ref object of OpenApiRestCall_402656044
proc url_UpdateDetectorVersionMetadata_402656857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionMetadata_402656856(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
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
  var valid_402656858 = header.getOrDefault("X-Amz-Target")
  valid_402656858 = validateParameter(valid_402656858, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata"))
  if valid_402656858 != nil:
    section.add "X-Amz-Target", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Security-Token", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Signature")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Signature", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Algorithm", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Date")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Date", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Credential")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Credential", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656865
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

proc call*(call_402656867: Call_UpdateDetectorVersionMetadata_402656855;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
                                                                                         ## 
  let valid = call_402656867.validator(path, query, header, formData, body, _)
  let scheme = call_402656867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656867.makeUrl(scheme.get, call_402656867.host, call_402656867.base,
                                   call_402656867.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656867, uri, valid, _)

proc call*(call_402656868: Call_UpdateDetectorVersionMetadata_402656855;
           body: JsonNode): Recallable =
  ## updateDetectorVersionMetadata
  ## Updates the detector version's description. You can update the metadata for any detector version (<code>DRAFT, ACTIVE,</code> or <code>INACTIVE</code>). 
  ##   
                                                                                                                                                              ## body: JObject (required)
  var body_402656869 = newJObject()
  if body != nil:
    body_402656869 = body
  result = call_402656868.call(nil, nil, nil, nil, body_402656869)

var updateDetectorVersionMetadata* = Call_UpdateDetectorVersionMetadata_402656855(
    name: "updateDetectorVersionMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionMetadata",
    validator: validate_UpdateDetectorVersionMetadata_402656856, base: "/",
    makeUrl: url_UpdateDetectorVersionMetadata_402656857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetectorVersionStatus_402656870 = ref object of OpenApiRestCall_402656044
proc url_UpdateDetectorVersionStatus_402656872(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDetectorVersionStatus_402656871(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
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
  var valid_402656873 = header.getOrDefault("X-Amz-Target")
  valid_402656873 = validateParameter(valid_402656873, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateDetectorVersionStatus"))
  if valid_402656873 != nil:
    section.add "X-Amz-Target", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Security-Token", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Signature")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Signature", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-Algorithm", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Date")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Date", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Credential")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Credential", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656880
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

proc call*(call_402656882: Call_UpdateDetectorVersionStatus_402656870;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
                                                                                         ## 
  let valid = call_402656882.validator(path, query, header, formData, body, _)
  let scheme = call_402656882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656882.makeUrl(scheme.get, call_402656882.host, call_402656882.base,
                                   call_402656882.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656882, uri, valid, _)

proc call*(call_402656883: Call_UpdateDetectorVersionStatus_402656870;
           body: JsonNode): Recallable =
  ## updateDetectorVersionStatus
  ## Updates the detector version’s status. You can perform the following promotions or demotions using <code>UpdateDetectorVersionStatus</code>: <code>DRAFT</code> to <code>ACTIVE</code>, <code>ACTIVE</code> to <code>INACTIVE</code>, and <code>INACTIVE</code> to <code>ACTIVE</code>.
  ##   
                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656884 = newJObject()
  if body != nil:
    body_402656884 = body
  result = call_402656883.call(nil, nil, nil, nil, body_402656884)

var updateDetectorVersionStatus* = Call_UpdateDetectorVersionStatus_402656870(
    name: "updateDetectorVersionStatus", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com", route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateDetectorVersionStatus",
    validator: validate_UpdateDetectorVersionStatus_402656871, base: "/",
    makeUrl: url_UpdateDetectorVersionStatus_402656872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateModelVersion_402656885 = ref object of OpenApiRestCall_402656044
proc url_UpdateModelVersion_402656887(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateModelVersion_402656886(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
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
  var valid_402656888 = header.getOrDefault("X-Amz-Target")
  valid_402656888 = validateParameter(valid_402656888, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateModelVersion"))
  if valid_402656888 != nil:
    section.add "X-Amz-Target", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Security-Token", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Signature")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Signature", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Algorithm", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Date")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Date", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Credential")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Credential", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656895
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

proc call*(call_402656897: Call_UpdateModelVersion_402656885;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
                                                                                         ## 
  let valid = call_402656897.validator(path, query, header, formData, body, _)
  let scheme = call_402656897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656897.makeUrl(scheme.get, call_402656897.host, call_402656897.base,
                                   call_402656897.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656897, uri, valid, _)

proc call*(call_402656898: Call_UpdateModelVersion_402656885; body: JsonNode): Recallable =
  ## updateModelVersion
  ## <p>Updates a model version. You can update the description and status attributes using this action. You can perform the following status updates: </p> <ol> <li> <p>Change the <code>TRAINING_COMPLETE</code> status to <code>ACTIVE</code> </p> </li> <li> <p>Change <code>ACTIVE</code> back to <code>TRAINING_COMPLETE</code> </p> </li> </ol>
  ##   
                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656899 = newJObject()
  if body != nil:
    body_402656899 = body
  result = call_402656898.call(nil, nil, nil, nil, body_402656899)

var updateModelVersion* = Call_UpdateModelVersion_402656885(
    name: "updateModelVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateModelVersion",
    validator: validate_UpdateModelVersion_402656886, base: "/",
    makeUrl: url_UpdateModelVersion_402656887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleMetadata_402656900 = ref object of OpenApiRestCall_402656044
proc url_UpdateRuleMetadata_402656902(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleMetadata_402656901(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a rule's metadata. 
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
  var valid_402656903 = header.getOrDefault("X-Amz-Target")
  valid_402656903 = validateParameter(valid_402656903, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleMetadata"))
  if valid_402656903 != nil:
    section.add "X-Amz-Target", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Security-Token", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Signature")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Signature", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Algorithm", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Date")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Date", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Credential")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Credential", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656910
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

proc call*(call_402656912: Call_UpdateRuleMetadata_402656900;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a rule's metadata. 
                                                                                         ## 
  let valid = call_402656912.validator(path, query, header, formData, body, _)
  let scheme = call_402656912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656912.makeUrl(scheme.get, call_402656912.host, call_402656912.base,
                                   call_402656912.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656912, uri, valid, _)

proc call*(call_402656913: Call_UpdateRuleMetadata_402656900; body: JsonNode): Recallable =
  ## updateRuleMetadata
  ## Updates a rule's metadata. 
  ##   body: JObject (required)
  var body_402656914 = newJObject()
  if body != nil:
    body_402656914 = body
  result = call_402656913.call(nil, nil, nil, nil, body_402656914)

var updateRuleMetadata* = Call_UpdateRuleMetadata_402656900(
    name: "updateRuleMetadata", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleMetadata",
    validator: validate_UpdateRuleMetadata_402656901, base: "/",
    makeUrl: url_UpdateRuleMetadata_402656902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleVersion_402656915 = ref object of OpenApiRestCall_402656044
proc url_UpdateRuleVersion_402656917(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleVersion_402656916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a rule version resulting in a new rule version. 
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
  var valid_402656918 = header.getOrDefault("X-Amz-Target")
  valid_402656918 = validateParameter(valid_402656918, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateRuleVersion"))
  if valid_402656918 != nil:
    section.add "X-Amz-Target", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Security-Token", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Signature")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Signature", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Algorithm", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Date")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Date", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Credential")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Credential", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656925
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

proc call*(call_402656927: Call_UpdateRuleVersion_402656915;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a rule version resulting in a new rule version. 
                                                                                         ## 
  let valid = call_402656927.validator(path, query, header, formData, body, _)
  let scheme = call_402656927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656927.makeUrl(scheme.get, call_402656927.host, call_402656927.base,
                                   call_402656927.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656927, uri, valid, _)

proc call*(call_402656928: Call_UpdateRuleVersion_402656915; body: JsonNode): Recallable =
  ## updateRuleVersion
  ## Updates a rule version resulting in a new rule version. 
  ##   body: JObject (required)
  var body_402656929 = newJObject()
  if body != nil:
    body_402656929 = body
  result = call_402656928.call(nil, nil, nil, nil, body_402656929)

var updateRuleVersion* = Call_UpdateRuleVersion_402656915(
    name: "updateRuleVersion", meth: HttpMethod.HttpPost,
    host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateRuleVersion",
    validator: validate_UpdateRuleVersion_402656916, base: "/",
    makeUrl: url_UpdateRuleVersion_402656917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateVariable_402656930 = ref object of OpenApiRestCall_402656044
proc url_UpdateVariable_402656932(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateVariable_402656931(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a variable.
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
  var valid_402656933 = header.getOrDefault("X-Amz-Target")
  valid_402656933 = validateParameter(valid_402656933, JString, required = true, default = newJString(
      "AWSHawksNestServiceFacade.UpdateVariable"))
  if valid_402656933 != nil:
    section.add "X-Amz-Target", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Security-Token", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Signature")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Signature", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Algorithm", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Date")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Date", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Credential")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Credential", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656940
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

proc call*(call_402656942: Call_UpdateVariable_402656930; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a variable.
                                                                                         ## 
  let valid = call_402656942.validator(path, query, header, formData, body, _)
  let scheme = call_402656942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656942.makeUrl(scheme.get, call_402656942.host, call_402656942.base,
                                   call_402656942.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656942, uri, valid, _)

proc call*(call_402656943: Call_UpdateVariable_402656930; body: JsonNode): Recallable =
  ## updateVariable
  ## Updates a variable.
  ##   body: JObject (required)
  var body_402656944 = newJObject()
  if body != nil:
    body_402656944 = body
  result = call_402656943.call(nil, nil, nil, nil, body_402656944)

var updateVariable* = Call_UpdateVariable_402656930(name: "updateVariable",
    meth: HttpMethod.HttpPost, host: "frauddetector.amazonaws.com",
    route: "/#X-Amz-Target=AWSHawksNestServiceFacade.UpdateVariable",
    validator: validate_UpdateVariable_402656931, base: "/",
    makeUrl: url_UpdateVariable_402656932, schemes: {Scheme.Https, Scheme.Http})
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