
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Access Manager
## version: 2018-01-04
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Use AWS Resource Access Manager to share AWS resources between AWS accounts. To share a resource, you create a resource share, associate the resource with the resource share, and specify the principals that can access the resources associated with the resource share. The following principals are supported: AWS accounts, organizational units (OU) from AWS Organizations, and organizations from AWS Organizations.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/ram/latest/userguide/">AWS Resource Access Manager User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ram/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "ram.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
                               "us-west-2": "ram.us-west-2.amazonaws.com",
                               "eu-west-2": "ram.eu-west-2.amazonaws.com", "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com", "eu-central-1": "ram.eu-central-1.amazonaws.com",
                               "us-east-2": "ram.us-east-2.amazonaws.com",
                               "us-east-1": "ram.us-east-1.amazonaws.com", "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "ram.ap-south-1.amazonaws.com",
                               "eu-north-1": "ram.eu-north-1.amazonaws.com", "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
                               "us-west-1": "ram.us-west-1.amazonaws.com", "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "ram.eu-west-3.amazonaws.com",
                               "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "ram.sa-east-1.amazonaws.com",
                               "eu-west-1": "ram.eu-west-1.amazonaws.com", "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "ram.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ram.ap-southeast-1.amazonaws.com",
      "us-west-2": "ram.us-west-2.amazonaws.com",
      "eu-west-2": "ram.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ram.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ram.eu-central-1.amazonaws.com",
      "us-east-2": "ram.us-east-2.amazonaws.com",
      "us-east-1": "ram.us-east-1.amazonaws.com",
      "cn-northwest-1": "ram.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ram.ap-south-1.amazonaws.com",
      "eu-north-1": "ram.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ram.ap-northeast-2.amazonaws.com",
      "us-west-1": "ram.us-west-1.amazonaws.com",
      "us-gov-east-1": "ram.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ram.eu-west-3.amazonaws.com",
      "cn-north-1": "ram.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ram.sa-east-1.amazonaws.com",
      "eu-west-1": "ram.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ram.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ram.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ram.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ram"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AcceptResourceShareInvitation_402656294 = ref object of OpenApiRestCall_402656044
proc url_AcceptResourceShareInvitation_402656296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptResourceShareInvitation_402656295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Accepts an invitation to a resource share from another AWS account.
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

proc call*(call_402656399: Call_AcceptResourceShareInvitation_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Accepts an invitation to a resource share from another AWS account.
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

proc call*(call_402656448: Call_AcceptResourceShareInvitation_402656294;
           body: JsonNode): Recallable =
  ## acceptResourceShareInvitation
  ## Accepts an invitation to a resource share from another AWS account.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656449 = newJObject()
  if body != nil:
    body_402656449 = body
  result = call_402656448.call(nil, nil, nil, nil, body_402656449)

var acceptResourceShareInvitation* = Call_AcceptResourceShareInvitation_402656294(
    name: "acceptResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/acceptresourceshareinvitation",
    validator: validate_AcceptResourceShareInvitation_402656295, base: "/",
    makeUrl: url_AcceptResourceShareInvitation_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceShare_402656476 = ref object of OpenApiRestCall_402656044
proc url_AssociateResourceShare_402656478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateResourceShare_402656477(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified resource share with the specified principals and resources.
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

proc call*(call_402656487: Call_AssociateResourceShare_402656476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified resource share with the specified principals and resources.
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

proc call*(call_402656488: Call_AssociateResourceShare_402656476; body: JsonNode): Recallable =
  ## associateResourceShare
  ## Associates the specified resource share with the specified principals and resources.
  ##   
                                                                                         ## body: JObject (required)
  var body_402656489 = newJObject()
  if body != nil:
    body_402656489 = body
  result = call_402656488.call(nil, nil, nil, nil, body_402656489)

var associateResourceShare* = Call_AssociateResourceShare_402656476(
    name: "associateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourceshare",
    validator: validate_AssociateResourceShare_402656477, base: "/",
    makeUrl: url_AssociateResourceShare_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateResourceSharePermission_402656490 = ref object of OpenApiRestCall_402656044
proc url_AssociateResourceSharePermission_402656492(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateResourceSharePermission_402656491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates a permission with a resource share.
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

proc call*(call_402656501: Call_AssociateResourceSharePermission_402656490;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a permission with a resource share.
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

proc call*(call_402656502: Call_AssociateResourceSharePermission_402656490;
           body: JsonNode): Recallable =
  ## associateResourceSharePermission
  ## Associates a permission with a resource share.
  ##   body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var associateResourceSharePermission* = Call_AssociateResourceSharePermission_402656490(
    name: "associateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/associateresourcesharepermission",
    validator: validate_AssociateResourceSharePermission_402656491, base: "/",
    makeUrl: url_AssociateResourceSharePermission_402656492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceShare_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateResourceShare_402656506(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceShare_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a resource share.
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

proc call*(call_402656515: Call_CreateResourceShare_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a resource share.
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

proc call*(call_402656516: Call_CreateResourceShare_402656504; body: JsonNode): Recallable =
  ## createResourceShare
  ## Creates a resource share.
  ##   body: JObject (required)
  var body_402656517 = newJObject()
  if body != nil:
    body_402656517 = body
  result = call_402656516.call(nil, nil, nil, nil, body_402656517)

var createResourceShare* = Call_CreateResourceShare_402656504(
    name: "createResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/createresourceshare",
    validator: validate_CreateResourceShare_402656505, base: "/",
    makeUrl: url_CreateResourceShare_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceShare_402656518 = ref object of OpenApiRestCall_402656044
proc url_DeleteResourceShare_402656520(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceShare_402656519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified resource share.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
                                  ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   
                                                                                                              ## clientToken: JString
                                                                                                              ##              
                                                                                                              ## : 
                                                                                                              ## A 
                                                                                                              ## unique, 
                                                                                                              ## case-sensitive 
                                                                                                              ## identifier 
                                                                                                              ## that 
                                                                                                              ## you 
                                                                                                              ## provide 
                                                                                                              ## to 
                                                                                                              ## ensure 
                                                                                                              ## the 
                                                                                                              ## idempotency 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## request.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `resourceShareArn` field"
  var valid_402656521 = query.getOrDefault("resourceShareArn")
  valid_402656521 = validateParameter(valid_402656521, JString, required = true,
                                      default = nil)
  if valid_402656521 != nil:
    section.add "resourceShareArn", valid_402656521
  var valid_402656522 = query.getOrDefault("clientToken")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "clientToken", valid_402656522
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
  if body != nil:
    result.add "body", body

proc call*(call_402656530: Call_DeleteResourceShare_402656518;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified resource share.
                                                                                         ## 
  let valid = call_402656530.validator(path, query, header, formData, body, _)
  let scheme = call_402656530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656530.makeUrl(scheme.get, call_402656530.host, call_402656530.base,
                                   call_402656530.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656530, uri, valid, _)

proc call*(call_402656531: Call_DeleteResourceShare_402656518;
           resourceShareArn: string; clientToken: string = ""): Recallable =
  ## deleteResourceShare
  ## Deletes the specified resource share.
  ##   resourceShareArn: string (required)
                                          ##                   : The Amazon Resource Name (ARN) of the resource share.
  ##   
                                                                                                                      ## clientToken: string
                                                                                                                      ##              
                                                                                                                      ## : 
                                                                                                                      ## A 
                                                                                                                      ## unique, 
                                                                                                                      ## case-sensitive 
                                                                                                                      ## identifier 
                                                                                                                      ## that 
                                                                                                                      ## you 
                                                                                                                      ## provide 
                                                                                                                      ## to 
                                                                                                                      ## ensure 
                                                                                                                      ## the 
                                                                                                                      ## idempotency 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## request.
  var query_402656532 = newJObject()
  add(query_402656532, "resourceShareArn", newJString(resourceShareArn))
  add(query_402656532, "clientToken", newJString(clientToken))
  result = call_402656531.call(nil, query_402656532, nil, nil, nil)

var deleteResourceShare* = Call_DeleteResourceShare_402656518(
    name: "deleteResourceShare", meth: HttpMethod.HttpDelete,
    host: "ram.amazonaws.com", route: "/deleteresourceshare#resourceShareArn",
    validator: validate_DeleteResourceShare_402656519, base: "/",
    makeUrl: url_DeleteResourceShare_402656520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceShare_402656533 = ref object of OpenApiRestCall_402656044
proc url_DisassociateResourceShare_402656535(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateResourceShare_402656534(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the specified principals or resources from the specified resource share.
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
  var valid_402656536 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Security-Token", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Signature")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Signature", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Algorithm", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Date")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Date", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Credential")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Credential", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656542
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

proc call*(call_402656544: Call_DisassociateResourceShare_402656533;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the specified principals or resources from the specified resource share.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_DisassociateResourceShare_402656533;
           body: JsonNode): Recallable =
  ## disassociateResourceShare
  ## Disassociates the specified principals or resources from the specified resource share.
  ##   
                                                                                           ## body: JObject (required)
  var body_402656546 = newJObject()
  if body != nil:
    body_402656546 = body
  result = call_402656545.call(nil, nil, nil, nil, body_402656546)

var disassociateResourceShare* = Call_DisassociateResourceShare_402656533(
    name: "disassociateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourceshare",
    validator: validate_DisassociateResourceShare_402656534, base: "/",
    makeUrl: url_DisassociateResourceShare_402656535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateResourceSharePermission_402656547 = ref object of OpenApiRestCall_402656044
proc url_DisassociateResourceSharePermission_402656549(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateResourceSharePermission_402656548(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates an AWS RAM permission from a resource share.
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
  var valid_402656550 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Security-Token", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Signature")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Signature", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Algorithm", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Date")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Date", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Credential")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Credential", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656556
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

proc call*(call_402656558: Call_DisassociateResourceSharePermission_402656547;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates an AWS RAM permission from a resource share.
                                                                                         ## 
  let valid = call_402656558.validator(path, query, header, formData, body, _)
  let scheme = call_402656558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656558.makeUrl(scheme.get, call_402656558.host, call_402656558.base,
                                   call_402656558.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656558, uri, valid, _)

proc call*(call_402656559: Call_DisassociateResourceSharePermission_402656547;
           body: JsonNode): Recallable =
  ## disassociateResourceSharePermission
  ## Disassociates an AWS RAM permission from a resource share.
  ##   body: JObject (required)
  var body_402656560 = newJObject()
  if body != nil:
    body_402656560 = body
  result = call_402656559.call(nil, nil, nil, nil, body_402656560)

var disassociateResourceSharePermission* = Call_DisassociateResourceSharePermission_402656547(
    name: "disassociateResourceSharePermission", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/disassociateresourcesharepermission",
    validator: validate_DisassociateResourceSharePermission_402656548,
    base: "/", makeUrl: url_DisassociateResourceSharePermission_402656549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSharingWithAwsOrganization_402656561 = ref object of OpenApiRestCall_402656044
proc url_EnableSharingWithAwsOrganization_402656563(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSharingWithAwsOrganization_402656562(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
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

proc call*(call_402656571: Call_EnableSharingWithAwsOrganization_402656561;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
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

proc call*(call_402656572: Call_EnableSharingWithAwsOrganization_402656561): Recallable =
  ## enableSharingWithAwsOrganization
  ## <p>Enables resource sharing within your AWS Organization.</p> <p>The caller must be the master account for the AWS Organization.</p>
  result = call_402656572.call(nil, nil, nil, nil, nil)

var enableSharingWithAwsOrganization* = Call_EnableSharingWithAwsOrganization_402656561(
    name: "enableSharingWithAwsOrganization", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/enablesharingwithawsorganization",
    validator: validate_EnableSharingWithAwsOrganization_402656562, base: "/",
    makeUrl: url_EnableSharingWithAwsOrganization_402656563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermission_402656573 = ref object of OpenApiRestCall_402656044
proc url_GetPermission_402656575(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPermission_402656574(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the contents of an AWS RAM permission in JSON format.
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
  var valid_402656576 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Security-Token", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Signature")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Signature", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Algorithm", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Date")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Date", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Credential")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Credential", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656582
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

proc call*(call_402656584: Call_GetPermission_402656573; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the contents of an AWS RAM permission in JSON format.
                                                                                         ## 
  let valid = call_402656584.validator(path, query, header, formData, body, _)
  let scheme = call_402656584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656584.makeUrl(scheme.get, call_402656584.host, call_402656584.base,
                                   call_402656584.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656584, uri, valid, _)

proc call*(call_402656585: Call_GetPermission_402656573; body: JsonNode): Recallable =
  ## getPermission
  ## Gets the contents of an AWS RAM permission in JSON format.
  ##   body: JObject (required)
  var body_402656586 = newJObject()
  if body != nil:
    body_402656586 = body
  result = call_402656585.call(nil, nil, nil, nil, body_402656586)

var getPermission* = Call_GetPermission_402656573(name: "getPermission",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/getpermission", validator: validate_GetPermission_402656574,
    base: "/", makeUrl: url_GetPermission_402656575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicies_402656587 = ref object of OpenApiRestCall_402656044
proc url_GetResourcePolicies_402656589(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourcePolicies_402656588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the policies for the specified resources that you own and have shared.
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
  var valid_402656590 = query.getOrDefault("maxResults")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "maxResults", valid_402656590
  var valid_402656591 = query.getOrDefault("nextToken")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "nextToken", valid_402656591
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656600: Call_GetResourcePolicies_402656587;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the policies for the specified resources that you own and have shared.
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_GetResourcePolicies_402656587; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourcePolicies
  ## Gets the policies for the specified resources that you own and have shared.
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
  var query_402656602 = newJObject()
  var body_402656603 = newJObject()
  add(query_402656602, "maxResults", newJString(maxResults))
  add(query_402656602, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656603 = body
  result = call_402656601.call(nil, query_402656602, nil, nil, body_402656603)

var getResourcePolicies* = Call_GetResourcePolicies_402656587(
    name: "getResourcePolicies", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourcepolicies",
    validator: validate_GetResourcePolicies_402656588, base: "/",
    makeUrl: url_GetResourcePolicies_402656589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareAssociations_402656604 = ref object of OpenApiRestCall_402656044
proc url_GetResourceShareAssociations_402656606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShareAssociations_402656605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the resources or principals for the resource shares that you own.
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
  var valid_402656607 = query.getOrDefault("maxResults")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "maxResults", valid_402656607
  var valid_402656608 = query.getOrDefault("nextToken")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "nextToken", valid_402656608
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
  var valid_402656609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Security-Token", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Signature")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Signature", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Algorithm", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Date")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Date", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Credential")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Credential", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656615
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

proc call*(call_402656617: Call_GetResourceShareAssociations_402656604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the resources or principals for the resource shares that you own.
                                                                                         ## 
  let valid = call_402656617.validator(path, query, header, formData, body, _)
  let scheme = call_402656617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656617.makeUrl(scheme.get, call_402656617.host, call_402656617.base,
                                   call_402656617.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656617, uri, valid, _)

proc call*(call_402656618: Call_GetResourceShareAssociations_402656604;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareAssociations
  ## Gets the resources or principals for the resource shares that you own.
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
  var query_402656619 = newJObject()
  var body_402656620 = newJObject()
  add(query_402656619, "maxResults", newJString(maxResults))
  add(query_402656619, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656620 = body
  result = call_402656618.call(nil, query_402656619, nil, nil, body_402656620)

var getResourceShareAssociations* = Call_GetResourceShareAssociations_402656604(
    name: "getResourceShareAssociations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareassociations",
    validator: validate_GetResourceShareAssociations_402656605, base: "/",
    makeUrl: url_GetResourceShareAssociations_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShareInvitations_402656621 = ref object of OpenApiRestCall_402656044
proc url_GetResourceShareInvitations_402656623(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShareInvitations_402656622(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets the invitations for resource sharing that you've received.
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
  var valid_402656624 = query.getOrDefault("maxResults")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "maxResults", valid_402656624
  var valid_402656625 = query.getOrDefault("nextToken")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "nextToken", valid_402656625
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
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
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

proc call*(call_402656634: Call_GetResourceShareInvitations_402656621;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the invitations for resource sharing that you've received.
                                                                                         ## 
  let valid = call_402656634.validator(path, query, header, formData, body, _)
  let scheme = call_402656634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656634.makeUrl(scheme.get, call_402656634.host, call_402656634.base,
                                   call_402656634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656634, uri, valid, _)

proc call*(call_402656635: Call_GetResourceShareInvitations_402656621;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShareInvitations
  ## Gets the invitations for resource sharing that you've received.
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
  var query_402656636 = newJObject()
  var body_402656637 = newJObject()
  add(query_402656636, "maxResults", newJString(maxResults))
  add(query_402656636, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656637 = body
  result = call_402656635.call(nil, query_402656636, nil, nil, body_402656637)

var getResourceShareInvitations* = Call_GetResourceShareInvitations_402656621(
    name: "getResourceShareInvitations", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshareinvitations",
    validator: validate_GetResourceShareInvitations_402656622, base: "/",
    makeUrl: url_GetResourceShareInvitations_402656623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceShares_402656638 = ref object of OpenApiRestCall_402656044
proc url_GetResourceShares_402656640(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResourceShares_402656639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
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
  var valid_402656641 = query.getOrDefault("maxResults")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "maxResults", valid_402656641
  var valid_402656642 = query.getOrDefault("nextToken")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "nextToken", valid_402656642
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
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
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

proc call*(call_402656651: Call_GetResourceShares_402656638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the resource shares that you own or the resource shares that are shared with you.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_GetResourceShares_402656638; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getResourceShares
  ## Gets the resource shares that you own or the resource shares that are shared with you.
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
  var query_402656653 = newJObject()
  var body_402656654 = newJObject()
  add(query_402656653, "maxResults", newJString(maxResults))
  add(query_402656653, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656654 = body
  result = call_402656652.call(nil, query_402656653, nil, nil, body_402656654)

var getResourceShares* = Call_GetResourceShares_402656638(
    name: "getResourceShares", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/getresourceshares",
    validator: validate_GetResourceShares_402656639, base: "/",
    makeUrl: url_GetResourceShares_402656640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPendingInvitationResources_402656655 = ref object of OpenApiRestCall_402656044
proc url_ListPendingInvitationResources_402656657(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPendingInvitationResources_402656656(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
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
  var valid_402656658 = query.getOrDefault("maxResults")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "maxResults", valid_402656658
  var valid_402656659 = query.getOrDefault("nextToken")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "nextToken", valid_402656659
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
  var valid_402656660 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Security-Token", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Signature")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Signature", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Algorithm", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Date")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Date", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Credential")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Credential", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656666
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

proc call*(call_402656668: Call_ListPendingInvitationResources_402656655;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
                                                                                         ## 
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_ListPendingInvitationResources_402656655;
           body: JsonNode; maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPendingInvitationResources
  ## Lists the resources in a resource share that is shared with you but that the invitation is still pending for.
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
  var query_402656670 = newJObject()
  var body_402656671 = newJObject()
  add(query_402656670, "maxResults", newJString(maxResults))
  add(query_402656670, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656671 = body
  result = call_402656669.call(nil, query_402656670, nil, nil, body_402656671)

var listPendingInvitationResources* = Call_ListPendingInvitationResources_402656655(
    name: "listPendingInvitationResources", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listpendinginvitationresources",
    validator: validate_ListPendingInvitationResources_402656656, base: "/",
    makeUrl: url_ListPendingInvitationResources_402656657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPermissions_402656672 = ref object of OpenApiRestCall_402656044
proc url_ListPermissions_402656674(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPermissions_402656673(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the AWS RAM permissions.
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

proc call*(call_402656683: Call_ListPermissions_402656672; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS RAM permissions.
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

proc call*(call_402656684: Call_ListPermissions_402656672; body: JsonNode): Recallable =
  ## listPermissions
  ## Lists the AWS RAM permissions.
  ##   body: JObject (required)
  var body_402656685 = newJObject()
  if body != nil:
    body_402656685 = body
  result = call_402656684.call(nil, nil, nil, nil, body_402656685)

var listPermissions* = Call_ListPermissions_402656672(name: "listPermissions",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/listpermissions", validator: validate_ListPermissions_402656673,
    base: "/", makeUrl: url_ListPermissions_402656674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipals_402656686 = ref object of OpenApiRestCall_402656044
proc url_ListPrincipals_402656688(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipals_402656687(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
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
  var valid_402656689 = query.getOrDefault("maxResults")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "maxResults", valid_402656689
  var valid_402656690 = query.getOrDefault("nextToken")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "nextToken", valid_402656690
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
  var valid_402656691 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Security-Token", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Signature")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Signature", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Algorithm", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Date")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Date", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Credential")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Credential", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656697
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

proc call*(call_402656699: Call_ListPrincipals_402656686; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the principals that you have shared resources with or that have shared resources with you.
                                                                                         ## 
  let valid = call_402656699.validator(path, query, header, formData, body, _)
  let scheme = call_402656699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656699.makeUrl(scheme.get, call_402656699.host, call_402656699.base,
                                   call_402656699.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656699, uri, valid, _)

proc call*(call_402656700: Call_ListPrincipals_402656686; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPrincipals
  ## Lists the principals that you have shared resources with or that have shared resources with you.
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
  var query_402656701 = newJObject()
  var body_402656702 = newJObject()
  add(query_402656701, "maxResults", newJString(maxResults))
  add(query_402656701, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656702 = body
  result = call_402656700.call(nil, query_402656701, nil, nil, body_402656702)

var listPrincipals* = Call_ListPrincipals_402656686(name: "listPrincipals",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/listprincipals", validator: validate_ListPrincipals_402656687,
    base: "/", makeUrl: url_ListPrincipals_402656688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceSharePermissions_402656703 = ref object of OpenApiRestCall_402656044
proc url_ListResourceSharePermissions_402656705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceSharePermissions_402656704(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the AWS RAM permissions that are associated with a resource share.
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
  var valid_402656706 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Security-Token", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Signature")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Signature", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Algorithm", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Date")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Date", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Credential")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Credential", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656712
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

proc call*(call_402656714: Call_ListResourceSharePermissions_402656703;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS RAM permissions that are associated with a resource share.
                                                                                         ## 
  let valid = call_402656714.validator(path, query, header, formData, body, _)
  let scheme = call_402656714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656714.makeUrl(scheme.get, call_402656714.host, call_402656714.base,
                                   call_402656714.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656714, uri, valid, _)

proc call*(call_402656715: Call_ListResourceSharePermissions_402656703;
           body: JsonNode): Recallable =
  ## listResourceSharePermissions
  ## Lists the AWS RAM permissions that are associated with a resource share.
  ##   
                                                                             ## body: JObject (required)
  var body_402656716 = newJObject()
  if body != nil:
    body_402656716 = body
  result = call_402656715.call(nil, nil, nil, nil, body_402656716)

var listResourceSharePermissions* = Call_ListResourceSharePermissions_402656703(
    name: "listResourceSharePermissions", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/listresourcesharepermissions",
    validator: validate_ListResourceSharePermissions_402656704, base: "/",
    makeUrl: url_ListResourceSharePermissions_402656705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_402656717 = ref object of OpenApiRestCall_402656044
proc url_ListResources_402656719(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResources_402656718(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
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
  var valid_402656720 = query.getOrDefault("maxResults")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "maxResults", valid_402656720
  var valid_402656721 = query.getOrDefault("nextToken")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "nextToken", valid_402656721
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
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
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

proc call*(call_402656730: Call_ListResources_402656717; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
                                                                                         ## 
  let valid = call_402656730.validator(path, query, header, formData, body, _)
  let scheme = call_402656730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656730.makeUrl(scheme.get, call_402656730.host, call_402656730.base,
                                   call_402656730.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656730, uri, valid, _)

proc call*(call_402656731: Call_ListResources_402656717; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listResources
  ## Lists the resources that you added to a resource shares or the resources that are shared with you.
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
  var query_402656732 = newJObject()
  var body_402656733 = newJObject()
  add(query_402656732, "maxResults", newJString(maxResults))
  add(query_402656732, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656733 = body
  result = call_402656731.call(nil, query_402656732, nil, nil, body_402656733)

var listResources* = Call_ListResources_402656717(name: "listResources",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/listresources", validator: validate_ListResources_402656718,
    base: "/", makeUrl: url_ListResources_402656719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PromoteResourceShareCreatedFromPolicy_402656734 = ref object of OpenApiRestCall_402656044
proc url_PromoteResourceShareCreatedFromPolicy_402656736(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PromoteResourceShareCreatedFromPolicy_402656735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resourceShareArn: JString (required)
                                  ##                   : The ARN of the resource share to promote.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `resourceShareArn` field"
  var valid_402656737 = query.getOrDefault("resourceShareArn")
  valid_402656737 = validateParameter(valid_402656737, JString, required = true,
                                      default = nil)
  if valid_402656737 != nil:
    section.add "resourceShareArn", valid_402656737
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
  var valid_402656738 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Security-Token", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Signature")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Signature", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Algorithm", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Date")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Date", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Credential")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Credential", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656745: Call_PromoteResourceShareCreatedFromPolicy_402656734;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656745.validator(path, query, header, formData, body, _)
  let scheme = call_402656745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656745.makeUrl(scheme.get, call_402656745.host, call_402656745.base,
                                   call_402656745.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656745, uri, valid, _)

proc call*(call_402656746: Call_PromoteResourceShareCreatedFromPolicy_402656734;
           resourceShareArn: string): Recallable =
  ## promoteResourceShareCreatedFromPolicy
  ## <p>Resource shares that were created by attaching a policy to a resource are visible only to the resource share owner, and the resource share cannot be modified in AWS RAM.</p> <p>Use this API action to promote the resource share. When you promote the resource share, it becomes:</p> <ul> <li> <p>Visible to all principals that it is shared with.</p> </li> <li> <p>Modifiable in AWS RAM.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                        ## resourceShareArn: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                        ##                   
                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## ARN 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## resource 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## share 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                        ## promote.
  var query_402656747 = newJObject()
  add(query_402656747, "resourceShareArn", newJString(resourceShareArn))
  result = call_402656746.call(nil, query_402656747, nil, nil, nil)

var promoteResourceShareCreatedFromPolicy* = Call_PromoteResourceShareCreatedFromPolicy_402656734(
    name: "promoteResourceShareCreatedFromPolicy", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com",
    route: "/promoteresourcesharecreatedfrompolicy#resourceShareArn",
    validator: validate_PromoteResourceShareCreatedFromPolicy_402656735,
    base: "/", makeUrl: url_PromoteResourceShareCreatedFromPolicy_402656736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectResourceShareInvitation_402656748 = ref object of OpenApiRestCall_402656044
proc url_RejectResourceShareInvitation_402656750(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectResourceShareInvitation_402656749(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Rejects an invitation to a resource share from another AWS account.
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
  var valid_402656751 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Security-Token", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Signature")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Signature", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Algorithm", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Date")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Date", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Credential")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Credential", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656757
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

proc call*(call_402656759: Call_RejectResourceShareInvitation_402656748;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Rejects an invitation to a resource share from another AWS account.
                                                                                         ## 
  let valid = call_402656759.validator(path, query, header, formData, body, _)
  let scheme = call_402656759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656759.makeUrl(scheme.get, call_402656759.host, call_402656759.base,
                                   call_402656759.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656759, uri, valid, _)

proc call*(call_402656760: Call_RejectResourceShareInvitation_402656748;
           body: JsonNode): Recallable =
  ## rejectResourceShareInvitation
  ## Rejects an invitation to a resource share from another AWS account.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656761 = newJObject()
  if body != nil:
    body_402656761 = body
  result = call_402656760.call(nil, nil, nil, nil, body_402656761)

var rejectResourceShareInvitation* = Call_RejectResourceShareInvitation_402656748(
    name: "rejectResourceShareInvitation", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/rejectresourceshareinvitation",
    validator: validate_RejectResourceShareInvitation_402656749, base: "/",
    makeUrl: url_RejectResourceShareInvitation_402656750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656762 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656764(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656763(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds the specified tags to the specified resource share that you own.
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
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
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

proc call*(call_402656773: Call_TagResource_402656762; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds the specified tags to the specified resource share that you own.
                                                                                         ## 
  let valid = call_402656773.validator(path, query, header, formData, body, _)
  let scheme = call_402656773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656773.makeUrl(scheme.get, call_402656773.host, call_402656773.base,
                                   call_402656773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656773, uri, valid, _)

proc call*(call_402656774: Call_TagResource_402656762; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tags to the specified resource share that you own.
  ##   body: 
                                                                          ## JObject (required)
  var body_402656775 = newJObject()
  if body != nil:
    body_402656775 = body
  result = call_402656774.call(nil, nil, nil, nil, body_402656775)

var tagResource* = Call_TagResource_402656762(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com", route: "/tagresource",
    validator: validate_TagResource_402656763, base: "/",
    makeUrl: url_TagResource_402656764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656776 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656778(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656777(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the specified tags from the specified resource share that you own.
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
  var valid_402656779 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Security-Token", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Signature")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Signature", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Algorithm", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Date")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Date", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Credential")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Credential", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656785
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

proc call*(call_402656787: Call_UntagResource_402656776; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource share that you own.
                                                                                         ## 
  let valid = call_402656787.validator(path, query, header, formData, body, _)
  let scheme = call_402656787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656787.makeUrl(scheme.get, call_402656787.host, call_402656787.base,
                                   call_402656787.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656787, uri, valid, _)

proc call*(call_402656788: Call_UntagResource_402656776; body: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource share that you own.
  ##   
                                                                               ## body: JObject (required)
  var body_402656789 = newJObject()
  if body != nil:
    body_402656789 = body
  result = call_402656788.call(nil, nil, nil, nil, body_402656789)

var untagResource* = Call_UntagResource_402656776(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ram.amazonaws.com",
    route: "/untagresource", validator: validate_UntagResource_402656777,
    base: "/", makeUrl: url_UntagResource_402656778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceShare_402656790 = ref object of OpenApiRestCall_402656044
proc url_UpdateResourceShare_402656792(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceShare_402656791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the specified resource share that you own.
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
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
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

proc call*(call_402656801: Call_UpdateResourceShare_402656790;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified resource share that you own.
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_UpdateResourceShare_402656790; body: JsonNode): Recallable =
  ## updateResourceShare
  ## Updates the specified resource share that you own.
  ##   body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var updateResourceShare* = Call_UpdateResourceShare_402656790(
    name: "updateResourceShare", meth: HttpMethod.HttpPost,
    host: "ram.amazonaws.com", route: "/updateresourceshare",
    validator: validate_UpdateResourceShare_402656791, base: "/",
    makeUrl: url_UpdateResourceShare_402656792,
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