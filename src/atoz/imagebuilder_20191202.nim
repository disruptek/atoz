
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: EC2 Image Builder
## version: 2019-12-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## EC2 Image Builder is a fully managed AWS service that makes it easier to automate the creation, management, and deployment of customized, secure, and up-to-date “golden” server images that are pre-installed and pre-configured with software and settings to meet specific IT standards.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/imagebuilder/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com", "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com", "us-west-2": "imagebuilder.us-west-2.amazonaws.com", "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com", "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com", "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com", "us-east-2": "imagebuilder.us-east-2.amazonaws.com", "us-east-1": "imagebuilder.us-east-1.amazonaws.com", "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com", "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com", "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com", "us-west-1": "imagebuilder.us-west-1.amazonaws.com", "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com", "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com", "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn", "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com", "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com", "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com", "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com", "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "imagebuilder.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "imagebuilder.ap-southeast-1.amazonaws.com",
      "us-west-2": "imagebuilder.us-west-2.amazonaws.com",
      "eu-west-2": "imagebuilder.eu-west-2.amazonaws.com",
      "ap-northeast-3": "imagebuilder.ap-northeast-3.amazonaws.com",
      "eu-central-1": "imagebuilder.eu-central-1.amazonaws.com",
      "us-east-2": "imagebuilder.us-east-2.amazonaws.com",
      "us-east-1": "imagebuilder.us-east-1.amazonaws.com",
      "cn-northwest-1": "imagebuilder.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "imagebuilder.ap-south-1.amazonaws.com",
      "eu-north-1": "imagebuilder.eu-north-1.amazonaws.com",
      "ap-northeast-2": "imagebuilder.ap-northeast-2.amazonaws.com",
      "us-west-1": "imagebuilder.us-west-1.amazonaws.com",
      "us-gov-east-1": "imagebuilder.us-gov-east-1.amazonaws.com",
      "eu-west-3": "imagebuilder.eu-west-3.amazonaws.com",
      "cn-north-1": "imagebuilder.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "imagebuilder.sa-east-1.amazonaws.com",
      "eu-west-1": "imagebuilder.eu-west-1.amazonaws.com",
      "us-gov-west-1": "imagebuilder.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "imagebuilder.ap-southeast-2.amazonaws.com",
      "ca-central-1": "imagebuilder.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "imagebuilder"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CancelImageCreation_402656294 = ref object of OpenApiRestCall_402656044
proc url_CancelImageCreation_402656296(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelImageCreation_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
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

proc call*(call_402656399: Call_CancelImageCreation_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
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

proc call*(call_402656448: Call_CancelImageCreation_402656294; body: JsonNode): Recallable =
  ## cancelImageCreation
  ## CancelImageCreation cancels the creation of Image. This operation can only be used on images in a non-terminal state.
  ##   
                                                                                                                          ## body: JObject (required)
  var body_402656449 = newJObject()
  if body != nil:
    body_402656449 = body
  result = call_402656448.call(nil, nil, nil, nil, body_402656449)

var cancelImageCreation* = Call_CancelImageCreation_402656294(
    name: "cancelImageCreation", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CancelImageCreation",
    validator: validate_CancelImageCreation_402656295, base: "/",
    makeUrl: url_CancelImageCreation_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_402656476 = ref object of OpenApiRestCall_402656044
proc url_CreateComponent_402656478(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_402656477(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new component that can be used to build, validate, test, and assess your image.
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

proc call*(call_402656487: Call_CreateComponent_402656476; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new component that can be used to build, validate, test, and assess your image.
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

proc call*(call_402656488: Call_CreateComponent_402656476; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a new component that can be used to build, validate, test, and assess your image.
  ##   
                                                                                              ## body: JObject (required)
  var body_402656489 = newJObject()
  if body != nil:
    body_402656489 = body
  result = call_402656488.call(nil, nil, nil, nil, body_402656489)

var createComponent* = Call_CreateComponent_402656476(name: "createComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateComponent", validator: validate_CreateComponent_402656477,
    base: "/", makeUrl: url_CreateComponent_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionConfiguration_402656490 = ref object of OpenApiRestCall_402656044
proc url_CreateDistributionConfiguration_402656492(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionConfiguration_402656491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
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

proc call*(call_402656501: Call_CreateDistributionConfiguration_402656490;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
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

proc call*(call_402656502: Call_CreateDistributionConfiguration_402656490;
           body: JsonNode): Recallable =
  ## createDistributionConfiguration
  ## Creates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   
                                                                                                                              ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createDistributionConfiguration* = Call_CreateDistributionConfiguration_402656490(
    name: "createDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateDistributionConfiguration",
    validator: validate_CreateDistributionConfiguration_402656491, base: "/",
    makeUrl: url_CreateDistributionConfiguration_402656492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImage_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateImage_402656506(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImage_402656505(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
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

proc call*(call_402656515: Call_CreateImage_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
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

proc call*(call_402656516: Call_CreateImage_402656504; body: JsonNode): Recallable =
  ## createImage
  ##  Creates a new image. This request will create a new image along with all of the configured output resources defined in the distribution configuration. 
  ##   
                                                                                                                                                             ## body: JObject (required)
  var body_402656517 = newJObject()
  if body != nil:
    body_402656517 = body
  result = call_402656516.call(nil, nil, nil, nil, body_402656517)

var createImage* = Call_CreateImage_402656504(name: "createImage",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/CreateImage", validator: validate_CreateImage_402656505, base: "/",
    makeUrl: url_CreateImage_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImagePipeline_402656518 = ref object of OpenApiRestCall_402656044
proc url_CreateImagePipeline_402656520(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImagePipeline_402656519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
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

proc call*(call_402656529: Call_CreateImagePipeline_402656518;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
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

proc call*(call_402656530: Call_CreateImagePipeline_402656518; body: JsonNode): Recallable =
  ## createImagePipeline
  ##  Creates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   
                                                                                                                    ## body: JObject (required)
  var body_402656531 = newJObject()
  if body != nil:
    body_402656531 = body
  result = call_402656530.call(nil, nil, nil, nil, body_402656531)

var createImagePipeline* = Call_CreateImagePipeline_402656518(
    name: "createImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImagePipeline",
    validator: validate_CreateImagePipeline_402656519, base: "/",
    makeUrl: url_CreateImagePipeline_402656520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateImageRecipe_402656532 = ref object of OpenApiRestCall_402656044
proc url_CreateImageRecipe_402656534(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateImageRecipe_402656533(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
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

proc call*(call_402656543: Call_CreateImageRecipe_402656532;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
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

proc call*(call_402656544: Call_CreateImageRecipe_402656532; body: JsonNode): Recallable =
  ## createImageRecipe
  ##  Creates a new image recipe. Image recipes define how images are configured, tested, and assessed. 
  ##   
                                                                                                        ## body: JObject (required)
  var body_402656545 = newJObject()
  if body != nil:
    body_402656545 = body
  result = call_402656544.call(nil, nil, nil, nil, body_402656545)

var createImageRecipe* = Call_CreateImageRecipe_402656532(
    name: "createImageRecipe", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/CreateImageRecipe",
    validator: validate_CreateImageRecipe_402656533, base: "/",
    makeUrl: url_CreateImageRecipe_402656534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInfrastructureConfiguration_402656546 = ref object of OpenApiRestCall_402656044
proc url_CreateInfrastructureConfiguration_402656548(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInfrastructureConfiguration_402656547(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
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

proc call*(call_402656557: Call_CreateInfrastructureConfiguration_402656546;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
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

proc call*(call_402656558: Call_CreateInfrastructureConfiguration_402656546;
           body: JsonNode): Recallable =
  ## createInfrastructureConfiguration
  ##  Creates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   
                                                                                                                                                        ## body: JObject (required)
  var body_402656559 = newJObject()
  if body != nil:
    body_402656559 = body
  result = call_402656558.call(nil, nil, nil, nil, body_402656559)

var createInfrastructureConfiguration* = Call_CreateInfrastructureConfiguration_402656546(
    name: "createInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/CreateInfrastructureConfiguration",
    validator: validate_CreateInfrastructureConfiguration_402656547, base: "/",
    makeUrl: url_CreateInfrastructureConfiguration_402656548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_402656560 = ref object of OpenApiRestCall_402656044
proc url_DeleteComponent_402656562(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_402656561(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes a component build version. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
                                  ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_402656563 = query.getOrDefault("componentBuildVersionArn")
  valid_402656563 = validateParameter(valid_402656563, JString, required = true,
                                      default = nil)
  if valid_402656563 != nil:
    section.add "componentBuildVersionArn", valid_402656563
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
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656571: Call_DeleteComponent_402656560; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a component build version. 
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

proc call*(call_402656572: Call_DeleteComponent_402656560;
           componentBuildVersionArn: string): Recallable =
  ## deleteComponent
  ##  Deletes a component build version. 
  ##   componentBuildVersionArn: string (required)
                                         ##                           :  The Amazon Resource Name (ARN) of the component build version to delete. 
  var query_402656573 = newJObject()
  add(query_402656573, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_402656572.call(nil, query_402656573, nil, nil, nil)

var deleteComponent* = Call_DeleteComponent_402656560(name: "deleteComponent",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteComponent#componentBuildVersionArn",
    validator: validate_DeleteComponent_402656561, base: "/",
    makeUrl: url_DeleteComponent_402656562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistributionConfiguration_402656574 = ref object of OpenApiRestCall_402656044
proc url_DeleteDistributionConfiguration_402656576(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDistributionConfiguration_402656575(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Deletes a distribution configuration. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
                                  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_402656577 = query.getOrDefault("distributionConfigurationArn")
  valid_402656577 = validateParameter(valid_402656577, JString, required = true,
                                      default = nil)
  if valid_402656577 != nil:
    section.add "distributionConfigurationArn", valid_402656577
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
  var valid_402656578 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Security-Token", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Signature")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Signature", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Algorithm", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Date")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Date", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Credential")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Credential", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656585: Call_DeleteDistributionConfiguration_402656574;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes a distribution configuration. 
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

proc call*(call_402656586: Call_DeleteDistributionConfiguration_402656574;
           distributionConfigurationArn: string): Recallable =
  ## deleteDistributionConfiguration
  ##  Deletes a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
                                            ##                               :  The Amazon Resource Name (ARN) of the distribution configuration to delete. 
  var query_402656587 = newJObject()
  add(query_402656587, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_402656586.call(nil, query_402656587, nil, nil, nil)

var deleteDistributionConfiguration* = Call_DeleteDistributionConfiguration_402656574(
    name: "deleteDistributionConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteDistributionConfiguration#distributionConfigurationArn",
    validator: validate_DeleteDistributionConfiguration_402656575, base: "/",
    makeUrl: url_DeleteDistributionConfiguration_402656576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImage_402656588 = ref object of OpenApiRestCall_402656044
proc url_DeleteImage_402656590(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImage_402656589(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes an image. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
                                  ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_402656591 = query.getOrDefault("imageBuildVersionArn")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "imageBuildVersionArn", valid_402656591
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
  var valid_402656592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Security-Token", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Signature")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Signature", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Algorithm", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Date")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Date", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Credential")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Credential", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656599: Call_DeleteImage_402656588; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image. 
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

proc call*(call_402656600: Call_DeleteImage_402656588;
           imageBuildVersionArn: string): Recallable =
  ## deleteImage
  ##  Deletes an image. 
  ##   imageBuildVersionArn: string (required)
                        ##                       :  The Amazon Resource Name (ARN) of the image to delete. 
  var query_402656601 = newJObject()
  add(query_402656601, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_402656600.call(nil, query_402656601, nil, nil, nil)

var deleteImage* = Call_DeleteImage_402656588(name: "deleteImage",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/DeleteImage#imageBuildVersionArn", validator: validate_DeleteImage_402656589,
    base: "/", makeUrl: url_DeleteImage_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImagePipeline_402656602 = ref object of OpenApiRestCall_402656044
proc url_DeleteImagePipeline_402656604(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImagePipeline_402656603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes an image pipeline. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
                                  ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imagePipelineArn` field"
  var valid_402656605 = query.getOrDefault("imagePipelineArn")
  valid_402656605 = validateParameter(valid_402656605, JString, required = true,
                                      default = nil)
  if valid_402656605 != nil:
    section.add "imagePipelineArn", valid_402656605
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
  var valid_402656606 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Security-Token", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Signature")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Signature", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Algorithm", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Date")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Date", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Credential")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Credential", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656613: Call_DeleteImagePipeline_402656602;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image pipeline. 
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

proc call*(call_402656614: Call_DeleteImagePipeline_402656602;
           imagePipelineArn: string): Recallable =
  ## deleteImagePipeline
  ##  Deletes an image pipeline. 
  ##   imagePipelineArn: string (required)
                                 ##                   :  The Amazon Resource Name (ARN) of the image pipeline to delete. 
  var query_402656615 = newJObject()
  add(query_402656615, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_402656614.call(nil, query_402656615, nil, nil, nil)

var deleteImagePipeline* = Call_DeleteImagePipeline_402656602(
    name: "deleteImagePipeline", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImagePipeline#imagePipelineArn",
    validator: validate_DeleteImagePipeline_402656603, base: "/",
    makeUrl: url_DeleteImagePipeline_402656604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteImageRecipe_402656616 = ref object of OpenApiRestCall_402656044
proc url_DeleteImageRecipe_402656618(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteImageRecipe_402656617(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Deletes an image recipe. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
                                  ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imageRecipeArn` field"
  var valid_402656619 = query.getOrDefault("imageRecipeArn")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "imageRecipeArn", valid_402656619
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
  var valid_402656620 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Security-Token", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Signature")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Signature", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Algorithm", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Date")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Date", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Credential")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Credential", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656627: Call_DeleteImageRecipe_402656616;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an image recipe. 
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

proc call*(call_402656628: Call_DeleteImageRecipe_402656616;
           imageRecipeArn: string): Recallable =
  ## deleteImageRecipe
  ##  Deletes an image recipe. 
  ##   imageRecipeArn: string (required)
                               ##                 :  The Amazon Resource Name (ARN) of the image recipe to delete. 
  var query_402656629 = newJObject()
  add(query_402656629, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_402656628.call(nil, query_402656629, nil, nil, nil)

var deleteImageRecipe* = Call_DeleteImageRecipe_402656616(
    name: "deleteImageRecipe", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteImageRecipe#imageRecipeArn",
    validator: validate_DeleteImageRecipe_402656617, base: "/",
    makeUrl: url_DeleteImageRecipe_402656618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInfrastructureConfiguration_402656630 = ref object of OpenApiRestCall_402656044
proc url_DeleteInfrastructureConfiguration_402656632(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInfrastructureConfiguration_402656631(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Deletes an infrastructure configuration. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
                                  ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_402656633 = query.getOrDefault("infrastructureConfigurationArn")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true,
                                      default = nil)
  if valid_402656633 != nil:
    section.add "infrastructureConfigurationArn", valid_402656633
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
  if body != nil:
    result.add "body", body

proc call*(call_402656641: Call_DeleteInfrastructureConfiguration_402656630;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Deletes an infrastructure configuration. 
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

proc call*(call_402656642: Call_DeleteInfrastructureConfiguration_402656630;
           infrastructureConfigurationArn: string): Recallable =
  ## deleteInfrastructureConfiguration
  ##  Deletes an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
                                               ##                                 :  The Amazon Resource Name (ARN) of the infrastructure configuration to delete. 
  var query_402656643 = newJObject()
  add(query_402656643, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_402656642.call(nil, query_402656643, nil, nil, nil)

var deleteInfrastructureConfiguration* = Call_DeleteInfrastructureConfiguration_402656630(
    name: "deleteInfrastructureConfiguration", meth: HttpMethod.HttpDelete,
    host: "imagebuilder.amazonaws.com",
    route: "/DeleteInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_DeleteInfrastructureConfiguration_402656631, base: "/",
    makeUrl: url_DeleteInfrastructureConfiguration_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponent_402656644 = ref object of OpenApiRestCall_402656044
proc url_GetComponent_402656646(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponent_402656645(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a component object. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentBuildVersionArn: JString (required)
                                  ##                           :  The Amazon Resource Name (ARN) of the component that you want to retrieve. Regex requires "/\d+$" suffix.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `componentBuildVersionArn` field"
  var valid_402656647 = query.getOrDefault("componentBuildVersionArn")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true,
                                      default = nil)
  if valid_402656647 != nil:
    section.add "componentBuildVersionArn", valid_402656647
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
  if body != nil:
    result.add "body", body

proc call*(call_402656655: Call_GetComponent_402656644; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a component object. 
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

proc call*(call_402656656: Call_GetComponent_402656644;
           componentBuildVersionArn: string): Recallable =
  ## getComponent
  ##  Gets a component object. 
  ##   componentBuildVersionArn: string (required)
                               ##                           :  The Amazon Resource Name (ARN) of the component that you want to retrieve. Regex requires "/\d+$" suffix.
  var query_402656657 = newJObject()
  add(query_402656657, "componentBuildVersionArn",
      newJString(componentBuildVersionArn))
  result = call_402656656.call(nil, query_402656657, nil, nil, nil)

var getComponent* = Call_GetComponent_402656644(name: "getComponent",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetComponent#componentBuildVersionArn",
    validator: validate_GetComponent_402656645, base: "/",
    makeUrl: url_GetComponent_402656646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComponentPolicy_402656658 = ref object of OpenApiRestCall_402656044
proc url_GetComponentPolicy_402656660(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComponentPolicy_402656659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets a component policy. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   componentArn: JString (required)
                                  ##               :  The Amazon Resource Name (ARN) of the component whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `componentArn` field"
  var valid_402656661 = query.getOrDefault("componentArn")
  valid_402656661 = validateParameter(valid_402656661, JString, required = true,
                                      default = nil)
  if valid_402656661 != nil:
    section.add "componentArn", valid_402656661
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
  var valid_402656662 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Security-Token", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Signature")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Signature", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Algorithm", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Date")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Date", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Credential")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Credential", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656669: Call_GetComponentPolicy_402656658;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a component policy. 
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

proc call*(call_402656670: Call_GetComponentPolicy_402656658;
           componentArn: string): Recallable =
  ## getComponentPolicy
  ##  Gets a component policy. 
  ##   componentArn: string (required)
                               ##               :  The Amazon Resource Name (ARN) of the component whose policy you want to retrieve. 
  var query_402656671 = newJObject()
  add(query_402656671, "componentArn", newJString(componentArn))
  result = call_402656670.call(nil, query_402656671, nil, nil, nil)

var getComponentPolicy* = Call_GetComponentPolicy_402656658(
    name: "getComponentPolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetComponentPolicy#componentArn",
    validator: validate_GetComponentPolicy_402656659, base: "/",
    makeUrl: url_GetComponentPolicy_402656660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfiguration_402656672 = ref object of OpenApiRestCall_402656044
proc url_GetDistributionConfiguration_402656674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDistributionConfiguration_402656673(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Gets a distribution configuration. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   distributionConfigurationArn: JString (required)
                                  ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `distributionConfigurationArn` field"
  var valid_402656675 = query.getOrDefault("distributionConfigurationArn")
  valid_402656675 = validateParameter(valid_402656675, JString, required = true,
                                      default = nil)
  if valid_402656675 != nil:
    section.add "distributionConfigurationArn", valid_402656675
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
  var valid_402656676 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Security-Token", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Signature")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Signature", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Algorithm", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Date")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Date", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Credential")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Credential", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656683: Call_GetDistributionConfiguration_402656672;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets a distribution configuration. 
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

proc call*(call_402656684: Call_GetDistributionConfiguration_402656672;
           distributionConfigurationArn: string): Recallable =
  ## getDistributionConfiguration
  ##  Gets a distribution configuration. 
  ##   distributionConfigurationArn: string (required)
                                         ##                               :  The Amazon Resource Name (ARN) of the distribution configuration that you want to retrieve. 
  var query_402656685 = newJObject()
  add(query_402656685, "distributionConfigurationArn",
      newJString(distributionConfigurationArn))
  result = call_402656684.call(nil, query_402656685, nil, nil, nil)

var getDistributionConfiguration* = Call_GetDistributionConfiguration_402656672(
    name: "getDistributionConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetDistributionConfiguration#distributionConfigurationArn",
    validator: validate_GetDistributionConfiguration_402656673, base: "/",
    makeUrl: url_GetDistributionConfiguration_402656674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImage_402656686 = ref object of OpenApiRestCall_402656044
proc url_GetImage_402656688(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImage_402656687(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets an image. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageBuildVersionArn: JString (required)
                                  ##                       :  The Amazon Resource Name (ARN) of the image that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `imageBuildVersionArn` field"
  var valid_402656689 = query.getOrDefault("imageBuildVersionArn")
  valid_402656689 = validateParameter(valid_402656689, JString, required = true,
                                      default = nil)
  if valid_402656689 != nil:
    section.add "imageBuildVersionArn", valid_402656689
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
  var valid_402656690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Security-Token", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Signature")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Signature", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Algorithm", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Date")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Date", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Credential")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Credential", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656697: Call_GetImage_402656686; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image. 
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

proc call*(call_402656698: Call_GetImage_402656686; imageBuildVersionArn: string): Recallable =
  ## getImage
  ##  Gets an image. 
  ##   imageBuildVersionArn: string (required)
                     ##                       :  The Amazon Resource Name (ARN) of the image that you want to retrieve. 
  var query_402656699 = newJObject()
  add(query_402656699, "imageBuildVersionArn", newJString(imageBuildVersionArn))
  result = call_402656698.call(nil, query_402656699, nil, nil, nil)

var getImage* = Call_GetImage_402656686(name: "getImage",
                                        meth: HttpMethod.HttpGet,
                                        host: "imagebuilder.amazonaws.com", route: "/GetImage#imageBuildVersionArn",
                                        validator: validate_GetImage_402656687,
                                        base: "/", makeUrl: url_GetImage_402656688,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePipeline_402656700 = ref object of OpenApiRestCall_402656044
proc url_GetImagePipeline_402656702(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePipeline_402656701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets an image pipeline. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imagePipelineArn: JString (required)
                                  ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you want to retrieve. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imagePipelineArn` field"
  var valid_402656703 = query.getOrDefault("imagePipelineArn")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true,
                                      default = nil)
  if valid_402656703 != nil:
    section.add "imagePipelineArn", valid_402656703
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
  var valid_402656704 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Security-Token", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Signature")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Signature", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Algorithm", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Date")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Date", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Credential")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Credential", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_GetImagePipeline_402656700;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image pipeline. 
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

proc call*(call_402656712: Call_GetImagePipeline_402656700;
           imagePipelineArn: string): Recallable =
  ## getImagePipeline
  ##  Gets an image pipeline. 
  ##   imagePipelineArn: string (required)
                              ##                   :  The Amazon Resource Name (ARN) of the image pipeline that you want to retrieve. 
  var query_402656713 = newJObject()
  add(query_402656713, "imagePipelineArn", newJString(imagePipelineArn))
  result = call_402656712.call(nil, query_402656713, nil, nil, nil)

var getImagePipeline* = Call_GetImagePipeline_402656700(
    name: "getImagePipeline", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImagePipeline#imagePipelineArn",
    validator: validate_GetImagePipeline_402656701, base: "/",
    makeUrl: url_GetImagePipeline_402656702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImagePolicy_402656714 = ref object of OpenApiRestCall_402656044
proc url_GetImagePolicy_402656716(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImagePolicy_402656715(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets an image policy. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageArn: JString (required)
                                  ##           :  The Amazon Resource Name (ARN) of the image whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imageArn` field"
  var valid_402656717 = query.getOrDefault("imageArn")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "imageArn", valid_402656717
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
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656725: Call_GetImagePolicy_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image policy. 
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

proc call*(call_402656726: Call_GetImagePolicy_402656714; imageArn: string): Recallable =
  ## getImagePolicy
  ##  Gets an image policy. 
  ##   imageArn: string (required)
                            ##           :  The Amazon Resource Name (ARN) of the image whose policy you want to retrieve. 
  var query_402656727 = newJObject()
  add(query_402656727, "imageArn", newJString(imageArn))
  result = call_402656726.call(nil, query_402656727, nil, nil, nil)

var getImagePolicy* = Call_GetImagePolicy_402656714(name: "getImagePolicy",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImagePolicy#imageArn", validator: validate_GetImagePolicy_402656715,
    base: "/", makeUrl: url_GetImagePolicy_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipe_402656728 = ref object of OpenApiRestCall_402656044
proc url_GetImageRecipe_402656730(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipe_402656729(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets an image recipe. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
                                  ##                 :  The Amazon Resource Name (ARN) of the image recipe that you want to retrieve. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imageRecipeArn` field"
  var valid_402656731 = query.getOrDefault("imageRecipeArn")
  valid_402656731 = validateParameter(valid_402656731, JString, required = true,
                                      default = nil)
  if valid_402656731 != nil:
    section.add "imageRecipeArn", valid_402656731
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

proc call*(call_402656739: Call_GetImageRecipe_402656728; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image recipe. 
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

proc call*(call_402656740: Call_GetImageRecipe_402656728; imageRecipeArn: string): Recallable =
  ## getImageRecipe
  ##  Gets an image recipe. 
  ##   imageRecipeArn: string (required)
                            ##                 :  The Amazon Resource Name (ARN) of the image recipe that you want to retrieve. 
  var query_402656741 = newJObject()
  add(query_402656741, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_402656740.call(nil, query_402656741, nil, nil, nil)

var getImageRecipe* = Call_GetImageRecipe_402656728(name: "getImageRecipe",
    meth: HttpMethod.HttpGet, host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipe#imageRecipeArn", validator: validate_GetImageRecipe_402656729,
    base: "/", makeUrl: url_GetImageRecipe_402656730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImageRecipePolicy_402656742 = ref object of OpenApiRestCall_402656044
proc url_GetImageRecipePolicy_402656744(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetImageRecipePolicy_402656743(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Gets an image recipe policy. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   imageRecipeArn: JString (required)
                                  ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you want to retrieve. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `imageRecipeArn` field"
  var valid_402656745 = query.getOrDefault("imageRecipeArn")
  valid_402656745 = validateParameter(valid_402656745, JString, required = true,
                                      default = nil)
  if valid_402656745 != nil:
    section.add "imageRecipeArn", valid_402656745
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
  var valid_402656746 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Security-Token", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Signature")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Signature", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Algorithm", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Date")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Date", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Credential")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Credential", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656753: Call_GetImageRecipePolicy_402656742;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an image recipe policy. 
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

proc call*(call_402656754: Call_GetImageRecipePolicy_402656742;
           imageRecipeArn: string): Recallable =
  ## getImageRecipePolicy
  ##  Gets an image recipe policy. 
  ##   imageRecipeArn: string (required)
                                   ##                 :  The Amazon Resource Name (ARN) of the image recipe whose policy you want to retrieve. 
  var query_402656755 = newJObject()
  add(query_402656755, "imageRecipeArn", newJString(imageRecipeArn))
  result = call_402656754.call(nil, query_402656755, nil, nil, nil)

var getImageRecipePolicy* = Call_GetImageRecipePolicy_402656742(
    name: "getImageRecipePolicy", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetImageRecipePolicy#imageRecipeArn",
    validator: validate_GetImageRecipePolicy_402656743, base: "/",
    makeUrl: url_GetImageRecipePolicy_402656744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInfrastructureConfiguration_402656756 = ref object of OpenApiRestCall_402656044
proc url_GetInfrastructureConfiguration_402656758(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInfrastructureConfiguration_402656757(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Gets an infrastructure configuration. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   infrastructureConfigurationArn: JString (required)
                                  ##                                 : The Amazon Resource Name (ARN) of the infrastructure configuration that you want to retrieve. 
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `infrastructureConfigurationArn` field"
  var valid_402656759 = query.getOrDefault("infrastructureConfigurationArn")
  valid_402656759 = validateParameter(valid_402656759, JString, required = true,
                                      default = nil)
  if valid_402656759 != nil:
    section.add "infrastructureConfigurationArn", valid_402656759
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
  var valid_402656760 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Security-Token", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Signature")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Signature", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Algorithm", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Date")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Date", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Credential")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Credential", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656767: Call_GetInfrastructureConfiguration_402656756;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Gets an infrastructure configuration. 
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

proc call*(call_402656768: Call_GetInfrastructureConfiguration_402656756;
           infrastructureConfigurationArn: string): Recallable =
  ## getInfrastructureConfiguration
  ##  Gets an infrastructure configuration. 
  ##   infrastructureConfigurationArn: string (required)
                                            ##                                 : The Amazon Resource Name (ARN) of the infrastructure configuration that you want to retrieve. 
  var query_402656769 = newJObject()
  add(query_402656769, "infrastructureConfigurationArn",
      newJString(infrastructureConfigurationArn))
  result = call_402656768.call(nil, query_402656769, nil, nil, nil)

var getInfrastructureConfiguration* = Call_GetInfrastructureConfiguration_402656756(
    name: "getInfrastructureConfiguration", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com",
    route: "/GetInfrastructureConfiguration#infrastructureConfigurationArn",
    validator: validate_GetInfrastructureConfiguration_402656757, base: "/",
    makeUrl: url_GetInfrastructureConfiguration_402656758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportComponent_402656770 = ref object of OpenApiRestCall_402656044
proc url_ImportComponent_402656772(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportComponent_402656771(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Imports a component and transforms its data into a component document. 
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

proc call*(call_402656781: Call_ImportComponent_402656770; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Imports a component and transforms its data into a component document. 
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

proc call*(call_402656782: Call_ImportComponent_402656770; body: JsonNode): Recallable =
  ## importComponent
  ## Imports a component and transforms its data into a component document. 
  ##   
                                                                            ## body: JObject (required)
  var body_402656783 = newJObject()
  if body != nil:
    body_402656783 = body
  result = call_402656782.call(nil, nil, nil, nil, body_402656783)

var importComponent* = Call_ImportComponent_402656770(name: "importComponent",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/ImportComponent", validator: validate_ImportComponent_402656771,
    base: "/", makeUrl: url_ImportComponent_402656772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponentBuildVersions_402656784 = ref object of OpenApiRestCall_402656044
proc url_ListComponentBuildVersions_402656786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponentBuildVersions_402656785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Returns the list of component build versions for the specified semantic version. 
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
  var valid_402656787 = query.getOrDefault("maxResults")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "maxResults", valid_402656787
  var valid_402656788 = query.getOrDefault("nextToken")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "nextToken", valid_402656788
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
  var valid_402656789 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Security-Token", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Signature")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Signature", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Algorithm", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Date")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Date", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Credential")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Credential", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656795
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

proc call*(call_402656797: Call_ListComponentBuildVersions_402656784;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of component build versions for the specified semantic version. 
                                                                                         ## 
  let valid = call_402656797.validator(path, query, header, formData, body, _)
  let scheme = call_402656797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656797.makeUrl(scheme.get, call_402656797.host, call_402656797.base,
                                   call_402656797.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656797, uri, valid, _)

proc call*(call_402656798: Call_ListComponentBuildVersions_402656784;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listComponentBuildVersions
  ##  Returns the list of component build versions for the specified semantic version. 
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
  var query_402656799 = newJObject()
  var body_402656800 = newJObject()
  add(query_402656799, "maxResults", newJString(maxResults))
  add(query_402656799, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656800 = body
  result = call_402656798.call(nil, query_402656799, nil, nil, body_402656800)

var listComponentBuildVersions* = Call_ListComponentBuildVersions_402656784(
    name: "listComponentBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListComponentBuildVersions",
    validator: validate_ListComponentBuildVersions_402656785, base: "/",
    makeUrl: url_ListComponentBuildVersions_402656786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_402656801 = ref object of OpenApiRestCall_402656044
proc url_ListComponents_402656803(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_402656802(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the list of component build versions for the specified semantic version. 
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
  var valid_402656804 = query.getOrDefault("maxResults")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "maxResults", valid_402656804
  var valid_402656805 = query.getOrDefault("nextToken")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "nextToken", valid_402656805
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
  var valid_402656806 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Security-Token", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Signature")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Signature", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Algorithm", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Date")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Date", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Credential")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Credential", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656812
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

proc call*(call_402656814: Call_ListComponents_402656801; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the list of component build versions for the specified semantic version. 
                                                                                         ## 
  let valid = call_402656814.validator(path, query, header, formData, body, _)
  let scheme = call_402656814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656814.makeUrl(scheme.get, call_402656814.host, call_402656814.base,
                                   call_402656814.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656814, uri, valid, _)

proc call*(call_402656815: Call_ListComponents_402656801; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listComponents
  ## Returns the list of component build versions for the specified semantic version. 
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
  var query_402656816 = newJObject()
  var body_402656817 = newJObject()
  add(query_402656816, "maxResults", newJString(maxResults))
  add(query_402656816, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656817 = body
  result = call_402656815.call(nil, query_402656816, nil, nil, body_402656817)

var listComponents* = Call_ListComponents_402656801(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListComponents", validator: validate_ListComponents_402656802,
    base: "/", makeUrl: url_ListComponents_402656803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionConfigurations_402656818 = ref object of OpenApiRestCall_402656044
proc url_ListDistributionConfigurations_402656820(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributionConfigurations_402656819(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Returns a list of distribution configurations. 
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
  var valid_402656821 = query.getOrDefault("maxResults")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "maxResults", valid_402656821
  var valid_402656822 = query.getOrDefault("nextToken")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "nextToken", valid_402656822
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
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
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

proc call*(call_402656831: Call_ListDistributionConfigurations_402656818;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of distribution configurations. 
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_ListDistributionConfigurations_402656818;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listDistributionConfigurations
  ##  Returns a list of distribution configurations. 
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
  var query_402656833 = newJObject()
  var body_402656834 = newJObject()
  add(query_402656833, "maxResults", newJString(maxResults))
  add(query_402656833, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656834 = body
  result = call_402656832.call(nil, query_402656833, nil, nil, body_402656834)

var listDistributionConfigurations* = Call_ListDistributionConfigurations_402656818(
    name: "listDistributionConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListDistributionConfigurations",
    validator: validate_ListDistributionConfigurations_402656819, base: "/",
    makeUrl: url_ListDistributionConfigurations_402656820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageBuildVersions_402656835 = ref object of OpenApiRestCall_402656044
proc url_ListImageBuildVersions_402656837(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageBuildVersions_402656836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of distribution configurations. 
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
  var valid_402656838 = query.getOrDefault("maxResults")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "maxResults", valid_402656838
  var valid_402656839 = query.getOrDefault("nextToken")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "nextToken", valid_402656839
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
  var valid_402656840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Security-Token", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Signature")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Signature", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Algorithm", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Date")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Date", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Credential")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Credential", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656846
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

proc call*(call_402656848: Call_ListImageBuildVersions_402656835;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of distribution configurations. 
                                                                                         ## 
  let valid = call_402656848.validator(path, query, header, formData, body, _)
  let scheme = call_402656848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656848.makeUrl(scheme.get, call_402656848.host, call_402656848.base,
                                   call_402656848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656848, uri, valid, _)

proc call*(call_402656849: Call_ListImageBuildVersions_402656835;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImageBuildVersions
  ##  Returns a list of distribution configurations. 
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
  var query_402656850 = newJObject()
  var body_402656851 = newJObject()
  add(query_402656850, "maxResults", newJString(maxResults))
  add(query_402656850, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656851 = body
  result = call_402656849.call(nil, query_402656850, nil, nil, body_402656851)

var listImageBuildVersions* = Call_ListImageBuildVersions_402656835(
    name: "listImageBuildVersions", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageBuildVersions",
    validator: validate_ListImageBuildVersions_402656836, base: "/",
    makeUrl: url_ListImageBuildVersions_402656837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelineImages_402656852 = ref object of OpenApiRestCall_402656044
proc url_ListImagePipelineImages_402656854(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelineImages_402656853(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of images created by the specified pipeline. 
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
  var valid_402656855 = query.getOrDefault("maxResults")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "maxResults", valid_402656855
  var valid_402656856 = query.getOrDefault("nextToken")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "nextToken", valid_402656856
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
  var valid_402656857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Security-Token", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Signature")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Signature", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Algorithm", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Date")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Date", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Credential")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Credential", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656863
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

proc call*(call_402656865: Call_ListImagePipelineImages_402656852;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of images created by the specified pipeline. 
                                                                                         ## 
  let valid = call_402656865.validator(path, query, header, formData, body, _)
  let scheme = call_402656865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656865.makeUrl(scheme.get, call_402656865.host, call_402656865.base,
                                   call_402656865.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656865, uri, valid, _)

proc call*(call_402656866: Call_ListImagePipelineImages_402656852;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImagePipelineImages
  ##  Returns a list of images created by the specified pipeline. 
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
  var query_402656867 = newJObject()
  var body_402656868 = newJObject()
  add(query_402656867, "maxResults", newJString(maxResults))
  add(query_402656867, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656868 = body
  result = call_402656866.call(nil, query_402656867, nil, nil, body_402656868)

var listImagePipelineImages* = Call_ListImagePipelineImages_402656852(
    name: "listImagePipelineImages", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelineImages",
    validator: validate_ListImagePipelineImages_402656853, base: "/",
    makeUrl: url_ListImagePipelineImages_402656854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImagePipelines_402656869 = ref object of OpenApiRestCall_402656044
proc url_ListImagePipelines_402656871(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImagePipelines_402656870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of image pipelines. 
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
  var valid_402656872 = query.getOrDefault("maxResults")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "maxResults", valid_402656872
  var valid_402656873 = query.getOrDefault("nextToken")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "nextToken", valid_402656873
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

proc call*(call_402656882: Call_ListImagePipelines_402656869;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of image pipelines. 
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

proc call*(call_402656883: Call_ListImagePipelines_402656869; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImagePipelines
  ## Returns a list of image pipelines. 
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
  var query_402656884 = newJObject()
  var body_402656885 = newJObject()
  add(query_402656884, "maxResults", newJString(maxResults))
  add(query_402656884, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656885 = body
  result = call_402656883.call(nil, query_402656884, nil, nil, body_402656885)

var listImagePipelines* = Call_ListImagePipelines_402656869(
    name: "listImagePipelines", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImagePipelines",
    validator: validate_ListImagePipelines_402656870, base: "/",
    makeUrl: url_ListImagePipelines_402656871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImageRecipes_402656886 = ref object of OpenApiRestCall_402656044
proc url_ListImageRecipes_402656888(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImageRecipes_402656887(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns a list of image recipes. 
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
  var valid_402656889 = query.getOrDefault("maxResults")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "maxResults", valid_402656889
  var valid_402656890 = query.getOrDefault("nextToken")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "nextToken", valid_402656890
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
  var valid_402656891 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Security-Token", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Signature")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Signature", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Algorithm", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Date")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Date", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Credential")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Credential", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656897
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

proc call*(call_402656899: Call_ListImageRecipes_402656886;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of image recipes. 
                                                                                         ## 
  let valid = call_402656899.validator(path, query, header, formData, body, _)
  let scheme = call_402656899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656899.makeUrl(scheme.get, call_402656899.host, call_402656899.base,
                                   call_402656899.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656899, uri, valid, _)

proc call*(call_402656900: Call_ListImageRecipes_402656886; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImageRecipes
  ##  Returns a list of image recipes. 
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
  var query_402656901 = newJObject()
  var body_402656902 = newJObject()
  add(query_402656901, "maxResults", newJString(maxResults))
  add(query_402656901, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656902 = body
  result = call_402656900.call(nil, query_402656901, nil, nil, body_402656902)

var listImageRecipes* = Call_ListImageRecipes_402656886(
    name: "listImageRecipes", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com", route: "/ListImageRecipes",
    validator: validate_ListImageRecipes_402656887, base: "/",
    makeUrl: url_ListImageRecipes_402656888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_402656903 = ref object of OpenApiRestCall_402656044
proc url_ListImages_402656905(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListImages_402656904(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns the list of image build versions for the specified semantic version. 
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
  var valid_402656906 = query.getOrDefault("maxResults")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "maxResults", valid_402656906
  var valid_402656907 = query.getOrDefault("nextToken")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "nextToken", valid_402656907
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
  var valid_402656908 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Security-Token", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Signature")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Signature", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Algorithm", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Date")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Date", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Credential")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Credential", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656914
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

proc call*(call_402656916: Call_ListImages_402656903; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of image build versions for the specified semantic version. 
                                                                                         ## 
  let valid = call_402656916.validator(path, query, header, formData, body, _)
  let scheme = call_402656916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656916.makeUrl(scheme.get, call_402656916.host, call_402656916.base,
                                   call_402656916.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656916, uri, valid, _)

proc call*(call_402656917: Call_ListImages_402656903; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImages
  ##  Returns the list of image build versions for the specified semantic version. 
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
  var query_402656918 = newJObject()
  var body_402656919 = newJObject()
  add(query_402656918, "maxResults", newJString(maxResults))
  add(query_402656918, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656919 = body
  result = call_402656917.call(nil, query_402656918, nil, nil, body_402656919)

var listImages* = Call_ListImages_402656903(name: "listImages",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/ListImages", validator: validate_ListImages_402656904, base: "/",
    makeUrl: url_ListImages_402656905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInfrastructureConfigurations_402656920 = ref object of OpenApiRestCall_402656044
proc url_ListInfrastructureConfigurations_402656922(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInfrastructureConfigurations_402656921(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Returns a list of infrastructure configurations. 
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
  var valid_402656923 = query.getOrDefault("maxResults")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "maxResults", valid_402656923
  var valid_402656924 = query.getOrDefault("nextToken")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "nextToken", valid_402656924
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
  var valid_402656925 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Security-Token", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Signature")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Signature", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Algorithm", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Date")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Date", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Credential")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Credential", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656931
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

proc call*(call_402656933: Call_ListInfrastructureConfigurations_402656920;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of infrastructure configurations. 
                                                                                         ## 
  let valid = call_402656933.validator(path, query, header, formData, body, _)
  let scheme = call_402656933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656933.makeUrl(scheme.get, call_402656933.host, call_402656933.base,
                                   call_402656933.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656933, uri, valid, _)

proc call*(call_402656934: Call_ListInfrastructureConfigurations_402656920;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listInfrastructureConfigurations
  ##  Returns a list of infrastructure configurations. 
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
  var query_402656935 = newJObject()
  var body_402656936 = newJObject()
  add(query_402656935, "maxResults", newJString(maxResults))
  add(query_402656935, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656936 = body
  result = call_402656934.call(nil, query_402656935, nil, nil, body_402656936)

var listInfrastructureConfigurations* = Call_ListInfrastructureConfigurations_402656920(
    name: "listInfrastructureConfigurations", meth: HttpMethod.HttpPost,
    host: "imagebuilder.amazonaws.com",
    route: "/ListInfrastructureConfigurations",
    validator: validate_ListInfrastructureConfigurations_402656921, base: "/",
    makeUrl: url_ListInfrastructureConfigurations_402656922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656962 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656964(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656963(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Adds a tag to a resource. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  The Amazon Resource Name (ARN) of the resource that you want to tag. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656965 = path.getOrDefault("resourceArn")
  valid_402656965 = validateParameter(valid_402656965, JString, required = true,
                                      default = nil)
  if valid_402656965 != nil:
    section.add "resourceArn", valid_402656965
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
  var valid_402656966 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Security-Token", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Signature")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Signature", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Algorithm", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Date")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Date", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Credential")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Credential", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656972
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

proc call*(call_402656974: Call_TagResource_402656962; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Adds a tag to a resource. 
                                                                                         ## 
  let valid = call_402656974.validator(path, query, header, formData, body, _)
  let scheme = call_402656974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656974.makeUrl(scheme.get, call_402656974.host, call_402656974.base,
                                   call_402656974.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656974, uri, valid, _)

proc call*(call_402656975: Call_TagResource_402656962; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ##  Adds a tag to a resource. 
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              :  The Amazon Resource Name (ARN) of the resource that you want to tag. 
  var path_402656976 = newJObject()
  var body_402656977 = newJObject()
  if body != nil:
    body_402656977 = body
  add(path_402656976, "resourceArn", newJString(resourceArn))
  result = call_402656975.call(path_402656976, nil, nil, nil, body_402656977)

var tagResource* = Call_TagResource_402656962(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656963,
    base: "/", makeUrl: url_TagResource_402656964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656937 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656939(protocol: Scheme; host: string;
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

proc validate_ListTagsForResource_402656938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Returns the list of tags for the specified resource. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  The Amazon Resource Name (ARN) of the resource whose tags you want to retrieve. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656951 = path.getOrDefault("resourceArn")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "resourceArn", valid_402656951
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
  var valid_402656952 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Security-Token", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Signature")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Signature", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Algorithm", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Date")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Date", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Credential")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Credential", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656959: Call_ListTagsForResource_402656937;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns the list of tags for the specified resource. 
                                                                                         ## 
  let valid = call_402656959.validator(path, query, header, formData, body, _)
  let scheme = call_402656959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656959.makeUrl(scheme.get, call_402656959.host, call_402656959.base,
                                   call_402656959.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656959, uri, valid, _)

proc call*(call_402656960: Call_ListTagsForResource_402656937;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ##  Returns the list of tags for the specified resource. 
  ##   resourceArn: string (required)
                                                           ##              :  The Amazon Resource Name (ARN) of the resource whose tags you want to retrieve. 
  var path_402656961 = newJObject()
  add(path_402656961, "resourceArn", newJString(resourceArn))
  result = call_402656960.call(path_402656961, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656937(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "imagebuilder.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656938, base: "/",
    makeUrl: url_ListTagsForResource_402656939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComponentPolicy_402656978 = ref object of OpenApiRestCall_402656044
proc url_PutComponentPolicy_402656980(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComponentPolicy_402656979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Applies a policy to a component. 
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
  var valid_402656981 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Security-Token", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Signature")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Signature", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Algorithm", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Date")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Date", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Credential")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Credential", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656987
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

proc call*(call_402656989: Call_PutComponentPolicy_402656978;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to a component. 
                                                                                         ## 
  let valid = call_402656989.validator(path, query, header, formData, body, _)
  let scheme = call_402656989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656989.makeUrl(scheme.get, call_402656989.host, call_402656989.base,
                                   call_402656989.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656989, uri, valid, _)

proc call*(call_402656990: Call_PutComponentPolicy_402656978; body: JsonNode): Recallable =
  ## putComponentPolicy
  ##  Applies a policy to a component. 
  ##   body: JObject (required)
  var body_402656991 = newJObject()
  if body != nil:
    body_402656991 = body
  result = call_402656990.call(nil, nil, nil, nil, body_402656991)

var putComponentPolicy* = Call_PutComponentPolicy_402656978(
    name: "putComponentPolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutComponentPolicy",
    validator: validate_PutComponentPolicy_402656979, base: "/",
    makeUrl: url_PutComponentPolicy_402656980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImagePolicy_402656992 = ref object of OpenApiRestCall_402656044
proc url_PutImagePolicy_402656994(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImagePolicy_402656993(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Applies a policy to an image. 
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
  var valid_402656995 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Security-Token", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Signature")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Signature", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Algorithm", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Date")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Date", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Credential")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Credential", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657001
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

proc call*(call_402657003: Call_PutImagePolicy_402656992; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to an image. 
                                                                                         ## 
  let valid = call_402657003.validator(path, query, header, formData, body, _)
  let scheme = call_402657003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657003.makeUrl(scheme.get, call_402657003.host, call_402657003.base,
                                   call_402657003.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657003, uri, valid, _)

proc call*(call_402657004: Call_PutImagePolicy_402656992; body: JsonNode): Recallable =
  ## putImagePolicy
  ##  Applies a policy to an image. 
  ##   body: JObject (required)
  var body_402657005 = newJObject()
  if body != nil:
    body_402657005 = body
  result = call_402657004.call(nil, nil, nil, nil, body_402657005)

var putImagePolicy* = Call_PutImagePolicy_402656992(name: "putImagePolicy",
    meth: HttpMethod.HttpPut, host: "imagebuilder.amazonaws.com",
    route: "/PutImagePolicy", validator: validate_PutImagePolicy_402656993,
    base: "/", makeUrl: url_PutImagePolicy_402656994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageRecipePolicy_402657006 = ref object of OpenApiRestCall_402656044
proc url_PutImageRecipePolicy_402657008(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageRecipePolicy_402657007(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Applies a policy to an image recipe. 
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
  var valid_402657009 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Security-Token", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Signature")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Signature", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Algorithm", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Date")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Date", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Credential")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Credential", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657015
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

proc call*(call_402657017: Call_PutImageRecipePolicy_402657006;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Applies a policy to an image recipe. 
                                                                                         ## 
  let valid = call_402657017.validator(path, query, header, formData, body, _)
  let scheme = call_402657017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657017.makeUrl(scheme.get, call_402657017.host, call_402657017.base,
                                   call_402657017.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657017, uri, valid, _)

proc call*(call_402657018: Call_PutImageRecipePolicy_402657006; body: JsonNode): Recallable =
  ## putImageRecipePolicy
  ##  Applies a policy to an image recipe. 
  ##   body: JObject (required)
  var body_402657019 = newJObject()
  if body != nil:
    body_402657019 = body
  result = call_402657018.call(nil, nil, nil, nil, body_402657019)

var putImageRecipePolicy* = Call_PutImageRecipePolicy_402657006(
    name: "putImageRecipePolicy", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/PutImageRecipePolicy",
    validator: validate_PutImageRecipePolicy_402657007, base: "/",
    makeUrl: url_PutImageRecipePolicy_402657008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImagePipelineExecution_402657020 = ref object of OpenApiRestCall_402656044
proc url_StartImagePipelineExecution_402657022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImagePipelineExecution_402657021(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Manually triggers a pipeline to create an image. 
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
  var valid_402657023 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Security-Token", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Signature")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Signature", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Algorithm", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Date")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Date", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Credential")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Credential", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657029
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

proc call*(call_402657031: Call_StartImagePipelineExecution_402657020;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Manually triggers a pipeline to create an image. 
                                                                                         ## 
  let valid = call_402657031.validator(path, query, header, formData, body, _)
  let scheme = call_402657031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657031.makeUrl(scheme.get, call_402657031.host, call_402657031.base,
                                   call_402657031.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657031, uri, valid, _)

proc call*(call_402657032: Call_StartImagePipelineExecution_402657020;
           body: JsonNode): Recallable =
  ## startImagePipelineExecution
  ##  Manually triggers a pipeline to create an image. 
  ##   body: JObject (required)
  var body_402657033 = newJObject()
  if body != nil:
    body_402657033 = body
  result = call_402657032.call(nil, nil, nil, nil, body_402657033)

var startImagePipelineExecution* = Call_StartImagePipelineExecution_402657020(
    name: "startImagePipelineExecution", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/StartImagePipelineExecution",
    validator: validate_StartImagePipelineExecution_402657021, base: "/",
    makeUrl: url_StartImagePipelineExecution_402657022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657034 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657036(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402657035(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Removes a tag from a resource. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              :  The Amazon Resource Name (ARN) of the resource that you want to untag. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657037 = path.getOrDefault("resourceArn")
  valid_402657037 = validateParameter(valid_402657037, JString, required = true,
                                      default = nil)
  if valid_402657037 != nil:
    section.add "resourceArn", valid_402657037
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          :  The tag keys to remove from the resource. 
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657038 = query.getOrDefault("tagKeys")
  valid_402657038 = validateParameter(valid_402657038, JArray, required = true,
                                      default = nil)
  if valid_402657038 != nil:
    section.add "tagKeys", valid_402657038
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
  var valid_402657039 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Security-Token", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Signature")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Signature", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Algorithm", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Date")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Date", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Credential")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Credential", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657046: Call_UntagResource_402657034; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Removes a tag from a resource. 
                                                                                         ## 
  let valid = call_402657046.validator(path, query, header, formData, body, _)
  let scheme = call_402657046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657046.makeUrl(scheme.get, call_402657046.host, call_402657046.base,
                                   call_402657046.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657046, uri, valid, _)

proc call*(call_402657047: Call_UntagResource_402657034; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ##  Removes a tag from a resource. 
  ##   tagKeys: JArray (required)
                                     ##          :  The tag keys to remove from the resource. 
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
                                                                                              ## resource 
                                                                                              ## that 
                                                                                              ## you 
                                                                                              ## want 
                                                                                              ## to 
                                                                                              ## untag. 
  var path_402657048 = newJObject()
  var query_402657049 = newJObject()
  if tagKeys != nil:
    query_402657049.add "tagKeys", tagKeys
  add(path_402657048, "resourceArn", newJString(resourceArn))
  result = call_402657047.call(path_402657048, query_402657049, nil, nil, nil)

var untagResource* = Call_UntagResource_402657034(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "imagebuilder.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402657035,
    base: "/", makeUrl: url_UntagResource_402657036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistributionConfiguration_402657050 = ref object of OpenApiRestCall_402656044
proc url_UpdateDistributionConfiguration_402657052(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDistributionConfiguration_402657051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
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
  var valid_402657053 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Security-Token", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Signature")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Signature", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Algorithm", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Date")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Date", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Credential")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Credential", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657059
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

proc call*(call_402657061: Call_UpdateDistributionConfiguration_402657050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
                                                                                         ## 
  let valid = call_402657061.validator(path, query, header, formData, body, _)
  let scheme = call_402657061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657061.makeUrl(scheme.get, call_402657061.host, call_402657061.base,
                                   call_402657061.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657061, uri, valid, _)

proc call*(call_402657062: Call_UpdateDistributionConfiguration_402657050;
           body: JsonNode): Recallable =
  ## updateDistributionConfiguration
  ##  Updates a new distribution configuration. Distribution configurations define and configure the outputs of your pipeline. 
  ##   
                                                                                                                               ## body: JObject (required)
  var body_402657063 = newJObject()
  if body != nil:
    body_402657063 = body
  result = call_402657062.call(nil, nil, nil, nil, body_402657063)

var updateDistributionConfiguration* = Call_UpdateDistributionConfiguration_402657050(
    name: "updateDistributionConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateDistributionConfiguration",
    validator: validate_UpdateDistributionConfiguration_402657051, base: "/",
    makeUrl: url_UpdateDistributionConfiguration_402657052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateImagePipeline_402657064 = ref object of OpenApiRestCall_402656044
proc url_UpdateImagePipeline_402657066(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateImagePipeline_402657065(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
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
  var valid_402657067 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Security-Token", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Signature")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Signature", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Algorithm", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Date")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Date", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Credential")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Credential", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657073
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

proc call*(call_402657075: Call_UpdateImagePipeline_402657064;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
                                                                                         ## 
  let valid = call_402657075.validator(path, query, header, formData, body, _)
  let scheme = call_402657075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657075.makeUrl(scheme.get, call_402657075.host, call_402657075.base,
                                   call_402657075.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657075, uri, valid, _)

proc call*(call_402657076: Call_UpdateImagePipeline_402657064; body: JsonNode): Recallable =
  ## updateImagePipeline
  ##  Updates a new image pipeline. Image pipelines enable you to automate the creation and distribution of images. 
  ##   
                                                                                                                    ## body: JObject (required)
  var body_402657077 = newJObject()
  if body != nil:
    body_402657077 = body
  result = call_402657076.call(nil, nil, nil, nil, body_402657077)

var updateImagePipeline* = Call_UpdateImagePipeline_402657064(
    name: "updateImagePipeline", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com", route: "/UpdateImagePipeline",
    validator: validate_UpdateImagePipeline_402657065, base: "/",
    makeUrl: url_UpdateImagePipeline_402657066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInfrastructureConfiguration_402657078 = ref object of OpenApiRestCall_402656044
proc url_UpdateInfrastructureConfiguration_402657080(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateInfrastructureConfiguration_402657079(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
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
  var valid_402657081 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Security-Token", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Signature")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Signature", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Algorithm", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Date")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Date", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Credential")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Credential", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657087
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

proc call*(call_402657089: Call_UpdateInfrastructureConfiguration_402657078;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
                                                                                         ## 
  let valid = call_402657089.validator(path, query, header, formData, body, _)
  let scheme = call_402657089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657089.makeUrl(scheme.get, call_402657089.host, call_402657089.base,
                                   call_402657089.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657089, uri, valid, _)

proc call*(call_402657090: Call_UpdateInfrastructureConfiguration_402657078;
           body: JsonNode): Recallable =
  ## updateInfrastructureConfiguration
  ##  Updates a new infrastructure configuration. An infrastructure configuration defines the environment in which your image will be built and tested. 
  ##   
                                                                                                                                                        ## body: JObject (required)
  var body_402657091 = newJObject()
  if body != nil:
    body_402657091 = body
  result = call_402657090.call(nil, nil, nil, nil, body_402657091)

var updateInfrastructureConfiguration* = Call_UpdateInfrastructureConfiguration_402657078(
    name: "updateInfrastructureConfiguration", meth: HttpMethod.HttpPut,
    host: "imagebuilder.amazonaws.com",
    route: "/UpdateInfrastructureConfiguration",
    validator: validate_UpdateInfrastructureConfiguration_402657079, base: "/",
    makeUrl: url_UpdateInfrastructureConfiguration_402657080,
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