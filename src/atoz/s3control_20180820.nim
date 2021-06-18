
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS S3 Control
## version: 2018-08-20
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS S3 Control provides access to Amazon S3 control plane operations. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3-control/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com", "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com", "us-west-2": "s3-control.us-west-2.amazonaws.com", "eu-west-2": "s3-control.eu-west-2.amazonaws.com", "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com", "eu-central-1": "s3-control.eu-central-1.amazonaws.com", "us-east-2": "s3-control.us-east-2.amazonaws.com", "us-east-1": "s3-control.us-east-1.amazonaws.com", "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "s3-control.ap-south-1.amazonaws.com", "eu-north-1": "s3-control.eu-north-1.amazonaws.com", "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com", "us-west-1": "s3-control.us-west-1.amazonaws.com", "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com", "eu-west-3": "s3-control.eu-west-3.amazonaws.com", "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn", "sa-east-1": "s3-control.sa-east-1.amazonaws.com", "eu-west-1": "s3-control.eu-west-1.amazonaws.com", "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com", "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com", "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-control.us-west-2.amazonaws.com",
      "eu-west-2": "s3-control.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
      "us-east-2": "s3-control.us-east-2.amazonaws.com",
      "us-east-1": "s3-control.us-east-1.amazonaws.com",
      "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
      "eu-north-1": "s3-control.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-control.us-west-1.amazonaws.com",
      "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3-control.eu-west-3.amazonaws.com",
      "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
      "eu-west-1": "s3-control.eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3control"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateAccessPoint_402656488 = ref object of OpenApiRestCall_402656044
proc url_CreateAccessPoint_402656490(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAccessPoint_402656489(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an access point and associates it with the specified bucket.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name you want to assign to this access point.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656491 = path.getOrDefault("name")
  valid_402656491 = validateParameter(valid_402656491, JString, required = true,
                                      default = nil)
  if valid_402656491 != nil:
    section.add "name", valid_402656491
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The AWS account ID for the owner of the bucket for which you want to create an access point.
  ##   
                                                                                                                                                   ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Security-Token", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Signature")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Signature", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Algorithm", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Date")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Date", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Credential")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Credential", valid_402656497
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656498 = header.getOrDefault("x-amz-account-id")
  valid_402656498 = validateParameter(valid_402656498, JString, required = true,
                                      default = nil)
  if valid_402656498 != nil:
    section.add "x-amz-account-id", valid_402656498
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

proc call*(call_402656501: Call_CreateAccessPoint_402656488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an access point and associates it with the specified bucket.
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

proc call*(call_402656502: Call_CreateAccessPoint_402656488; name: string;
           body: JsonNode): Recallable =
  ## createAccessPoint
  ## Creates an access point and associates it with the specified bucket.
  ##   name: string 
                                                                         ## (required)
                                                                         ##       
                                                                         ## : 
                                                                         ## The 
                                                                         ## name 
                                                                         ## you 
                                                                         ## want 
                                                                         ## to 
                                                                         ## assign 
                                                                         ## to 
                                                                         ## this 
                                                                         ## access 
                                                                         ## point.
  ##   
                                                                                  ## body: JObject (required)
  var path_402656503 = newJObject()
  var body_402656504 = newJObject()
  add(path_402656503, "name", newJString(name))
  if body != nil:
    body_402656504 = body
  result = call_402656502.call(path_402656503, nil, nil, nil, body_402656504)

var createAccessPoint* = Call_CreateAccessPoint_402656488(
    name: "createAccessPoint", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_CreateAccessPoint_402656489, base: "/",
    makeUrl: url_CreateAccessPoint_402656490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPoint_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetAccessPoint_402656296(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPoint_402656295(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns configuration information about the specified access point.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point whose configuration information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656386 = path.getOrDefault("name")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "name", valid_402656386
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the account that owns the specified access point.
  ##   
                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656393 = header.getOrDefault("x-amz-account-id")
  valid_402656393 = validateParameter(valid_402656393, JString, required = true,
                                      default = nil)
  if valid_402656393 != nil:
    section.add "x-amz-account-id", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656408: Call_GetAccessPoint_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns configuration information about the specified access point.
                                                                                         ## 
  let valid = call_402656408.validator(path, query, header, formData, body, _)
  let scheme = call_402656408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656408.makeUrl(scheme.get, call_402656408.host, call_402656408.base,
                                   call_402656408.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656408, uri, valid, _)

proc call*(call_402656457: Call_GetAccessPoint_402656294; name: string): Recallable =
  ## getAccessPoint
  ## Returns configuration information about the specified access point.
  ##   name: string 
                                                                        ## (required)
                                                                        ##       
                                                                        ## : 
                                                                        ## The 
                                                                        ## name 
                                                                        ## of 
                                                                        ## the 
                                                                        ## access 
                                                                        ## point 
                                                                        ## whose 
                                                                        ## configuration 
                                                                        ## information 
                                                                        ## you 
                                                                        ## want 
                                                                        ## to 
                                                                        ## retrieve.
  var path_402656458 = newJObject()
  add(path_402656458, "name", newJString(name))
  result = call_402656457.call(path_402656458, nil, nil, nil, nil)

var getAccessPoint* = Call_GetAccessPoint_402656294(name: "getAccessPoint",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_GetAccessPoint_402656295, base: "/",
    makeUrl: url_GetAccessPoint_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_402656505 = ref object of OpenApiRestCall_402656044
proc url_DeleteAccessPoint_402656507(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_402656506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified access point.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656508 = path.getOrDefault("name")
  valid_402656508 = validateParameter(valid_402656508, JString, required = true,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "name", valid_402656508
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the account that owns the specified access point.
  ##   
                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656515 = header.getOrDefault("x-amz-account-id")
  valid_402656515 = validateParameter(valid_402656515, JString, required = true,
                                      default = nil)
  if valid_402656515 != nil:
    section.add "x-amz-account-id", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656517: Call_DeleteAccessPoint_402656505;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified access point.
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_DeleteAccessPoint_402656505; name: string): Recallable =
  ## deleteAccessPoint
  ## Deletes the specified access point.
  ##   name: string (required)
                                        ##       : The name of the access point you want to delete.
  var path_402656519 = newJObject()
  add(path_402656519, "name", newJString(name))
  result = call_402656518.call(path_402656519, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_402656505(
    name: "deleteAccessPoint", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_DeleteAccessPoint_402656506, base: "/",
    makeUrl: url_DeleteAccessPoint_402656507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_402656539 = ref object of OpenApiRestCall_402656044
proc url_CreateJob_402656541(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_402656540(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Amazon S3 batch operations job.
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
  ##   x-amz-account-id: JString (required)
                                ##                   : <p/>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656542 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Security-Token", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Signature")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Signature", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Algorithm", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Date")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Date", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Credential")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Credential", valid_402656547
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656548 = header.getOrDefault("x-amz-account-id")
  valid_402656548 = validateParameter(valid_402656548, JString, required = true,
                                      default = nil)
  if valid_402656548 != nil:
    section.add "x-amz-account-id", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656549
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

proc call*(call_402656551: Call_CreateJob_402656539; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Amazon S3 batch operations job.
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_CreateJob_402656539; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_402656553 = newJObject()
  if body != nil:
    body_402656553 = body
  result = call_402656552.call(nil, nil, nil, nil, body_402656553)

var createJob* = Call_CreateJob_402656539(name: "createJob",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs#x-amz-account-id", validator: validate_CreateJob_402656540,
    base: "/", makeUrl: url_CreateJob_402656541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_402656520 = ref object of OpenApiRestCall_402656044
proc url_ListJobs_402656522(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_402656521(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   jobStatuses: JArray
                                  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   
                                                                                                                                                   ## maxResults: JInt
                                                                                                                                                   ##             
                                                                                                                                                   ## : 
                                                                                                                                                   ## The 
                                                                                                                                                   ## maximum 
                                                                                                                                                   ## number 
                                                                                                                                                   ## of 
                                                                                                                                                   ## jobs 
                                                                                                                                                   ## that 
                                                                                                                                                   ## Amazon 
                                                                                                                                                   ## S3 
                                                                                                                                                   ## will 
                                                                                                                                                   ## include 
                                                                                                                                                   ## in 
                                                                                                                                                   ## the 
                                                                                                                                                   ## <code>List 
                                                                                                                                                   ## Jobs</code> 
                                                                                                                                                   ## response. 
                                                                                                                                                   ## If 
                                                                                                                                                   ## there 
                                                                                                                                                   ## are 
                                                                                                                                                   ## more 
                                                                                                                                                   ## jobs 
                                                                                                                                                   ## than 
                                                                                                                                                   ## this 
                                                                                                                                                   ## number, 
                                                                                                                                                   ## the 
                                                                                                                                                   ## response 
                                                                                                                                                   ## will 
                                                                                                                                                   ## include 
                                                                                                                                                   ## a 
                                                                                                                                                   ## pagination 
                                                                                                                                                   ## token 
                                                                                                                                                   ## in 
                                                                                                                                                   ## the 
                                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                                   ## field 
                                                                                                                                                   ## to 
                                                                                                                                                   ## enable 
                                                                                                                                                   ## you 
                                                                                                                                                   ## to 
                                                                                                                                                   ## retrieve 
                                                                                                                                                   ## the 
                                                                                                                                                   ## next 
                                                                                                                                                   ## page 
                                                                                                                                                   ## of 
                                                                                                                                                   ## results.
  ##   
                                                                                                                                                              ## nextToken: JString
                                                                                                                                                              ##            
                                                                                                                                                              ## : 
                                                                                                                                                              ## A 
                                                                                                                                                              ## pagination 
                                                                                                                                                              ## token 
                                                                                                                                                              ## to 
                                                                                                                                                              ## request 
                                                                                                                                                              ## the 
                                                                                                                                                              ## next 
                                                                                                                                                              ## page 
                                                                                                                                                              ## of 
                                                                                                                                                              ## results. 
                                                                                                                                                              ## Use 
                                                                                                                                                              ## the 
                                                                                                                                                              ## token 
                                                                                                                                                              ## that 
                                                                                                                                                              ## Amazon 
                                                                                                                                                              ## S3 
                                                                                                                                                              ## returned 
                                                                                                                                                              ## in 
                                                                                                                                                              ## the 
                                                                                                                                                              ## <code>NextToken</code> 
                                                                                                                                                              ## element 
                                                                                                                                                              ## of 
                                                                                                                                                              ## the 
                                                                                                                                                              ## <code>ListJobsResult</code> 
                                                                                                                                                              ## from 
                                                                                                                                                              ## the 
                                                                                                                                                              ## previous 
                                                                                                                                                              ## <code>List 
                                                                                                                                                              ## Jobs</code> 
                                                                                                                                                              ## request.
  ##   
                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                         ##             
                                                                                                                                                                         ## : 
                                                                                                                                                                         ## Pagination 
                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                 ##            
                                                                                                                                                                                 ## : 
                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656523 = query.getOrDefault("jobStatuses")
  valid_402656523 = validateParameter(valid_402656523, JArray, required = false,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "jobStatuses", valid_402656523
  var valid_402656524 = query.getOrDefault("maxResults")
  valid_402656524 = validateParameter(valid_402656524, JInt, required = false,
                                      default = nil)
  if valid_402656524 != nil:
    section.add "maxResults", valid_402656524
  var valid_402656525 = query.getOrDefault("nextToken")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "nextToken", valid_402656525
  var valid_402656526 = query.getOrDefault("MaxResults")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "MaxResults", valid_402656526
  var valid_402656527 = query.getOrDefault("NextToken")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "NextToken", valid_402656527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
                                ##                   : <p/>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Security-Token", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Signature")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Signature", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Algorithm", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Date")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Date", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Credential")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Credential", valid_402656533
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656534 = header.getOrDefault("x-amz-account-id")
  valid_402656534 = validateParameter(valid_402656534, JString, required = true,
                                      default = nil)
  if valid_402656534 != nil:
    section.add "x-amz-account-id", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656536: Call_ListJobs_402656520; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_ListJobs_402656520; jobStatuses: JsonNode = nil;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   
                                                                                                                ## jobStatuses: JArray
                                                                                                                ##              
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## <code>List 
                                                                                                                ## Jobs</code> 
                                                                                                                ## request 
                                                                                                                ## returns 
                                                                                                                ## jobs 
                                                                                                                ## that 
                                                                                                                ## match 
                                                                                                                ## the 
                                                                                                                ## statuses 
                                                                                                                ## listed 
                                                                                                                ## in 
                                                                                                                ## this 
                                                                                                                ## element.
  ##   
                                                                                                                           ## maxResults: int
                                                                                                                           ##             
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## maximum 
                                                                                                                           ## number 
                                                                                                                           ## of 
                                                                                                                           ## jobs 
                                                                                                                           ## that 
                                                                                                                           ## Amazon 
                                                                                                                           ## S3 
                                                                                                                           ## will 
                                                                                                                           ## include 
                                                                                                                           ## in 
                                                                                                                           ## the 
                                                                                                                           ## <code>List 
                                                                                                                           ## Jobs</code> 
                                                                                                                           ## response. 
                                                                                                                           ## If 
                                                                                                                           ## there 
                                                                                                                           ## are 
                                                                                                                           ## more 
                                                                                                                           ## jobs 
                                                                                                                           ## than 
                                                                                                                           ## this 
                                                                                                                           ## number, 
                                                                                                                           ## the 
                                                                                                                           ## response 
                                                                                                                           ## will 
                                                                                                                           ## include 
                                                                                                                           ## a 
                                                                                                                           ## pagination 
                                                                                                                           ## token 
                                                                                                                           ## in 
                                                                                                                           ## the 
                                                                                                                           ## <code>NextToken</code> 
                                                                                                                           ## field 
                                                                                                                           ## to 
                                                                                                                           ## enable 
                                                                                                                           ## you 
                                                                                                                           ## to 
                                                                                                                           ## retrieve 
                                                                                                                           ## the 
                                                                                                                           ## next 
                                                                                                                           ## page 
                                                                                                                           ## of 
                                                                                                                           ## results.
  ##   
                                                                                                                                      ## nextToken: string
                                                                                                                                      ##            
                                                                                                                                      ## : 
                                                                                                                                      ## A 
                                                                                                                                      ## pagination 
                                                                                                                                      ## token 
                                                                                                                                      ## to 
                                                                                                                                      ## request 
                                                                                                                                      ## the 
                                                                                                                                      ## next 
                                                                                                                                      ## page 
                                                                                                                                      ## of 
                                                                                                                                      ## results. 
                                                                                                                                      ## Use 
                                                                                                                                      ## the 
                                                                                                                                      ## token 
                                                                                                                                      ## that 
                                                                                                                                      ## Amazon 
                                                                                                                                      ## S3 
                                                                                                                                      ## returned 
                                                                                                                                      ## in 
                                                                                                                                      ## the 
                                                                                                                                      ## <code>NextToken</code> 
                                                                                                                                      ## element 
                                                                                                                                      ## of 
                                                                                                                                      ## the 
                                                                                                                                      ## <code>ListJobsResult</code> 
                                                                                                                                      ## from 
                                                                                                                                      ## the 
                                                                                                                                      ## previous 
                                                                                                                                      ## <code>List 
                                                                                                                                      ## Jobs</code> 
                                                                                                                                      ## request.
  ##   
                                                                                                                                                 ## MaxResults: string
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## Pagination 
                                                                                                                                                 ## limit
  ##   
                                                                                                                                                         ## NextToken: string
                                                                                                                                                         ##            
                                                                                                                                                         ## : 
                                                                                                                                                         ## Pagination 
                                                                                                                                                         ## token
  var query_402656538 = newJObject()
  if jobStatuses != nil:
    query_402656538.add "jobStatuses", jobStatuses
  add(query_402656538, "maxResults", newJInt(maxResults))
  add(query_402656538, "nextToken", newJString(nextToken))
  add(query_402656538, "MaxResults", newJString(MaxResults))
  add(query_402656538, "NextToken", newJString(NextToken))
  result = call_402656537.call(nil, query_402656538, nil, nil, nil)

var listJobs* = Call_ListJobs_402656520(name: "listJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "s3-control.amazonaws.com", route: "/v20180820/jobs#x-amz-account-id",
                                        validator: validate_ListJobs_402656521,
                                        base: "/", makeUrl: url_ListJobs_402656522,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccessPointPolicy_402656569 = ref object of OpenApiRestCall_402656044
proc url_PutAccessPointPolicy_402656571(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutAccessPointPolicy_402656570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point that you want to associate with the specified policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656572 = path.getOrDefault("name")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "name", valid_402656572
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The AWS account ID for owner of the bucket associated with the specified access point.
  ##   
                                                                                                                                             ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656579 = header.getOrDefault("x-amz-account-id")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "x-amz-account-id", valid_402656579
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

proc call*(call_402656582: Call_PutAccessPointPolicy_402656569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
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

proc call*(call_402656583: Call_PutAccessPointPolicy_402656569; name: string;
           body: JsonNode): Recallable =
  ## putAccessPointPolicy
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ##   
                                                                                                                                                                                                                    ## name: string (required)
                                                                                                                                                                                                                    ##       
                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                    ## name 
                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## access 
                                                                                                                                                                                                                    ## point 
                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                    ## want 
                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                    ## associate 
                                                                                                                                                                                                                    ## with 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## specified 
                                                                                                                                                                                                                    ## policy.
  ##   
                                                                                                                                                                                                                              ## body: JObject (required)
  var path_402656584 = newJObject()
  var body_402656585 = newJObject()
  add(path_402656584, "name", newJString(name))
  if body != nil:
    body_402656585 = body
  result = call_402656583.call(path_402656584, nil, nil, nil, body_402656585)

var putAccessPointPolicy* = Call_PutAccessPointPolicy_402656569(
    name: "putAccessPointPolicy", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_PutAccessPointPolicy_402656570, base: "/",
    makeUrl: url_PutAccessPointPolicy_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicy_402656554 = ref object of OpenApiRestCall_402656044
proc url_GetAccessPointPolicy_402656556(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicy_402656555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the access point policy associated with the specified access point.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point whose policy you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656557 = path.getOrDefault("name")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "name", valid_402656557
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the account that owns the specified access point.
  ##   
                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656564 = header.getOrDefault("x-amz-account-id")
  valid_402656564 = validateParameter(valid_402656564, JString, required = true,
                                      default = nil)
  if valid_402656564 != nil:
    section.add "x-amz-account-id", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_GetAccessPointPolicy_402656554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the access point policy associated with the specified access point.
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_GetAccessPointPolicy_402656554; name: string): Recallable =
  ## getAccessPointPolicy
  ## Returns the access point policy associated with the specified access point.
  ##   
                                                                                ## name: string (required)
                                                                                ##       
                                                                                ## : 
                                                                                ## The 
                                                                                ## name 
                                                                                ## of 
                                                                                ## the 
                                                                                ## access 
                                                                                ## point 
                                                                                ## whose 
                                                                                ## policy 
                                                                                ## you 
                                                                                ## want 
                                                                                ## to 
                                                                                ## retrieve.
  var path_402656568 = newJObject()
  add(path_402656568, "name", newJString(name))
  result = call_402656567.call(path_402656568, nil, nil, nil, nil)

var getAccessPointPolicy* = Call_GetAccessPointPolicy_402656554(
    name: "getAccessPointPolicy", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_GetAccessPointPolicy_402656555, base: "/",
    makeUrl: url_GetAccessPointPolicy_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPointPolicy_402656586 = ref object of OpenApiRestCall_402656044
proc url_DeleteAccessPointPolicy_402656588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPointPolicy_402656587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the access point policy for the specified access point.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point whose policy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656589 = path.getOrDefault("name")
  valid_402656589 = validateParameter(valid_402656589, JString, required = true,
                                      default = nil)
  if valid_402656589 != nil:
    section.add "name", valid_402656589
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the account that owns the specified access point.
  ##   
                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656590 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Security-Token", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Signature")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Signature", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Algorithm", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Date")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Date", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Credential")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Credential", valid_402656595
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656596 = header.getOrDefault("x-amz-account-id")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = nil)
  if valid_402656596 != nil:
    section.add "x-amz-account-id", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656598: Call_DeleteAccessPointPolicy_402656586;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the access point policy for the specified access point.
                                                                                         ## 
  let valid = call_402656598.validator(path, query, header, formData, body, _)
  let scheme = call_402656598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656598.makeUrl(scheme.get, call_402656598.host, call_402656598.base,
                                   call_402656598.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656598, uri, valid, _)

proc call*(call_402656599: Call_DeleteAccessPointPolicy_402656586; name: string): Recallable =
  ## deleteAccessPointPolicy
  ## Deletes the access point policy for the specified access point.
  ##   name: string (required)
                                                                    ##       : The name of the access point whose policy you want to delete.
  var path_402656600 = newJObject()
  add(path_402656600, "name", newJString(name))
  result = call_402656599.call(path_402656600, nil, nil, nil, nil)

var deleteAccessPointPolicy* = Call_DeleteAccessPointPolicy_402656586(
    name: "deleteAccessPointPolicy", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_DeleteAccessPointPolicy_402656587, base: "/",
    makeUrl: url_DeleteAccessPointPolicy_402656588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_402656614 = ref object of OpenApiRestCall_402656044
proc url_PutPublicAccessBlock_402656616(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPublicAccessBlock_402656615(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to set.
  ##   
                                                                                                                                                                             ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656623 = header.getOrDefault("x-amz-account-id")
  valid_402656623 = validateParameter(valid_402656623, JString, required = true,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "x-amz-account-id", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656624
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

proc call*(call_402656626: Call_PutPublicAccessBlock_402656614;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
                                                                                         ## 
  let valid = call_402656626.validator(path, query, header, formData, body, _)
  let scheme = call_402656626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656626.makeUrl(scheme.get, call_402656626.host, call_402656626.base,
                                   call_402656626.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656626, uri, valid, _)

proc call*(call_402656627: Call_PutPublicAccessBlock_402656614; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ##   
                                                                                                             ## body: JObject (required)
  var body_402656628 = newJObject()
  if body != nil:
    body_402656628 = body
  result = call_402656627.call(nil, nil, nil, nil, body_402656628)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_402656614(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_402656615, base: "/",
    makeUrl: url_PutPublicAccessBlock_402656616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_402656601 = ref object of OpenApiRestCall_402656044
proc url_GetPublicAccessBlock_402656603(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicAccessBlock_402656602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to retrieve.
  ##   
                                                                                                                                                                                  ## X-Amz-SignedHeaders: JString
  section = newJObject()
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
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656610 = header.getOrDefault("x-amz-account-id")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = nil)
  if valid_402656610 != nil:
    section.add "x-amz-account-id", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656612: Call_GetPublicAccessBlock_402656601;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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

proc call*(call_402656613: Call_GetPublicAccessBlock_402656601): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_402656613.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_402656601(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_402656602, base: "/",
    makeUrl: url_GetPublicAccessBlock_402656603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_402656629 = ref object of OpenApiRestCall_402656044
proc url_DeletePublicAccessBlock_402656631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePublicAccessBlock_402656630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to remove.
  ##   
                                                                                                                                                                                ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656632 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Security-Token", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Signature")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Signature", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Algorithm", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Date")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Date", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Credential")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Credential", valid_402656637
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656638 = header.getOrDefault("x-amz-account-id")
  valid_402656638 = validateParameter(valid_402656638, JString, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "x-amz-account-id", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656640: Call_DeletePublicAccessBlock_402656629;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
                                                                                         ## 
  let valid = call_402656640.validator(path, query, header, formData, body, _)
  let scheme = call_402656640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656640.makeUrl(scheme.get, call_402656640.host, call_402656640.base,
                                   call_402656640.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656640, uri, valid, _)

proc call*(call_402656641: Call_DeletePublicAccessBlock_402656629): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_402656641.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_402656629(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_402656630, base: "/",
    makeUrl: url_DeletePublicAccessBlock_402656631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_402656642 = ref object of OpenApiRestCall_402656044
proc url_DescribeJob_402656644(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
                 (kind: VariableSegment, value: "id"),
                 (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJob_402656643(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the configuration parameters and status for a batch operations job.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID for the job whose information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656645 = path.getOrDefault("id")
  valid_402656645 = validateParameter(valid_402656645, JString, required = true,
                                      default = nil)
  if valid_402656645 != nil:
    section.add "id", valid_402656645
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
  ##   x-amz-account-id: JString (required)
                                ##                   : <p/>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656646 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Security-Token", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Signature")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Signature", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Algorithm", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Date")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Date", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Credential")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Credential", valid_402656651
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656652 = header.getOrDefault("x-amz-account-id")
  valid_402656652 = validateParameter(valid_402656652, JString, required = true,
                                      default = nil)
  if valid_402656652 != nil:
    section.add "x-amz-account-id", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656654: Call_DescribeJob_402656642; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
                                                                                         ## 
  let valid = call_402656654.validator(path, query, header, formData, body, _)
  let scheme = call_402656654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656654.makeUrl(scheme.get, call_402656654.host, call_402656654.base,
                                   call_402656654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656654, uri, valid, _)

proc call*(call_402656655: Call_DescribeJob_402656642; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   
                                                                                  ## id: string (required)
                                                                                  ##     
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## ID 
                                                                                  ## for 
                                                                                  ## the 
                                                                                  ## job 
                                                                                  ## whose 
                                                                                  ## information 
                                                                                  ## you 
                                                                                  ## want 
                                                                                  ## to 
                                                                                  ## retrieve.
  var path_402656656 = newJObject()
  add(path_402656656, "id", newJString(id))
  result = call_402656655.call(path_402656656, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_402656642(name: "describeJob",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}#x-amz-account-id",
    validator: validate_DescribeJob_402656643, base: "/",
    makeUrl: url_DescribeJob_402656644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicyStatus_402656657 = ref object of OpenApiRestCall_402656044
proc url_GetAccessPointPolicyStatus_402656659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
                 (kind: VariableSegment, value: "name"), (kind: ConstantSegment,
        value: "/policyStatus#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicyStatus_402656658(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the access point whose policy status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656660 = path.getOrDefault("name")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "name", valid_402656660
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
  ##   x-amz-account-id: JString (required)
                                ##                   : The account ID for the account that owns the specified access point.
  ##   
                                                                                                                           ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656667 = header.getOrDefault("x-amz-account-id")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "x-amz-account-id", valid_402656667
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

proc call*(call_402656669: Call_GetAccessPointPolicyStatus_402656657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
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

proc call*(call_402656670: Call_GetAccessPointPolicyStatus_402656657;
           name: string): Recallable =
  ## getAccessPointPolicyStatus
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                       ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                       ##       
                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                       ## access 
                                                                                                                                                                                                                                                                                                                                                                       ## point 
                                                                                                                                                                                                                                                                                                                                                                       ## whose 
                                                                                                                                                                                                                                                                                                                                                                       ## policy 
                                                                                                                                                                                                                                                                                                                                                                       ## status 
                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                       ## retrieve.
  var path_402656671 = newJObject()
  add(path_402656671, "name", newJString(name))
  result = call_402656670.call(path_402656671, nil, nil, nil, nil)

var getAccessPointPolicyStatus* = Call_GetAccessPointPolicyStatus_402656657(
    name: "getAccessPointPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policyStatus#x-amz-account-id",
    validator: validate_GetAccessPointPolicyStatus_402656658, base: "/",
    makeUrl: url_GetAccessPointPolicyStatus_402656659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccessPoints_402656672 = ref object of OpenApiRestCall_402656044
proc url_ListAccessPoints_402656674(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccessPoints_402656673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the <code>NextToken</code> field that you can use to retrieve the next page of access points.
  ##   
                                                                                                                                                                                                                                                                                                                                                     ## bucket: JString
                                                                                                                                                                                                                                                                                                                                                     ##         
                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                     ## bucket 
                                                                                                                                                                                                                                                                                                                                                     ## whose 
                                                                                                                                                                                                                                                                                                                                                     ## associated 
                                                                                                                                                                                                                                                                                                                                                     ## access 
                                                                                                                                                                                                                                                                                                                                                     ## points 
                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                     ## want 
                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                     ## list.
  ##   
                                                                                                                                                                                                                                                                                                                                                             ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                             ## A 
                                                                                                                                                                                                                                                                                                                                                             ## continuation 
                                                                                                                                                                                                                                                                                                                                                             ## token. 
                                                                                                                                                                                                                                                                                                                                                             ## If 
                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                             ## previous 
                                                                                                                                                                                                                                                                                                                                                             ## call 
                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                             ## <code>ListAccessPoints</code> 
                                                                                                                                                                                                                                                                                                                                                             ## returned 
                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                             ## continuation 
                                                                                                                                                                                                                                                                                                                                                             ## token 
                                                                                                                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                             ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                             ## field, 
                                                                                                                                                                                                                                                                                                                                                             ## then 
                                                                                                                                                                                                                                                                                                                                                             ## providing 
                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                             ## value 
                                                                                                                                                                                                                                                                                                                                                             ## here 
                                                                                                                                                                                                                                                                                                                                                             ## causes 
                                                                                                                                                                                                                                                                                                                                                             ## Amazon 
                                                                                                                                                                                                                                                                                                                                                             ## S3 
                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                             ## retrieve 
                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                             ## next 
                                                                                                                                                                                                                                                                                                                                                             ## page 
                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                             ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                        ## MaxResults: JString
                                                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                        ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                ## token
  section = newJObject()
  var valid_402656675 = query.getOrDefault("maxResults")
  valid_402656675 = validateParameter(valid_402656675, JInt, required = false,
                                      default = nil)
  if valid_402656675 != nil:
    section.add "maxResults", valid_402656675
  var valid_402656676 = query.getOrDefault("bucket")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "bucket", valid_402656676
  var valid_402656677 = query.getOrDefault("nextToken")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "nextToken", valid_402656677
  var valid_402656678 = query.getOrDefault("MaxResults")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "MaxResults", valid_402656678
  var valid_402656679 = query.getOrDefault("NextToken")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "NextToken", valid_402656679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
                                ##                   : The AWS account ID for owner of the bucket whose access points you want to list.
  ##   
                                                                                                                                       ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656680 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Security-Token", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Signature")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Signature", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Algorithm", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Date")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Date", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Credential")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Credential", valid_402656685
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656686 = header.getOrDefault("x-amz-account-id")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "x-amz-account-id", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656688: Call_ListAccessPoints_402656672;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
                                                                                         ## 
  let valid = call_402656688.validator(path, query, header, formData, body, _)
  let scheme = call_402656688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656688.makeUrl(scheme.get, call_402656688.host, call_402656688.base,
                                   call_402656688.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656688, uri, valid, _)

proc call*(call_402656689: Call_ListAccessPoints_402656672; maxResults: int = 0;
           bucket: string = ""; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listAccessPoints
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                         ## maxResults: int
                                                                                                                                                                                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                         ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                         ## access 
                                                                                                                                                                                                                                                                                                                                                                                         ## points 
                                                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                         ## include 
                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                         ## list. 
                                                                                                                                                                                                                                                                                                                                                                                         ## If 
                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                         ## specified 
                                                                                                                                                                                                                                                                                                                                                                                         ## bucket 
                                                                                                                                                                                                                                                                                                                                                                                         ## has 
                                                                                                                                                                                                                                                                                                                                                                                         ## more 
                                                                                                                                                                                                                                                                                                                                                                                         ## than 
                                                                                                                                                                                                                                                                                                                                                                                         ## this 
                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                         ## access 
                                                                                                                                                                                                                                                                                                                                                                                         ## points, 
                                                                                                                                                                                                                                                                                                                                                                                         ## then 
                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                         ## response 
                                                                                                                                                                                                                                                                                                                                                                                         ## will 
                                                                                                                                                                                                                                                                                                                                                                                         ## include 
                                                                                                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                                                                                                         ## continuation 
                                                                                                                                                                                                                                                                                                                                                                                         ## token 
                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                         ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                         ## field 
                                                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                         ## can 
                                                                                                                                                                                                                                                                                                                                                                                         ## use 
                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                         ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                         ## next 
                                                                                                                                                                                                                                                                                                                                                                                         ## page 
                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                         ## access 
                                                                                                                                                                                                                                                                                                                                                                                         ## points.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                   ## bucket: string
                                                                                                                                                                                                                                                                                                                                                                                                   ##         
                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                   ## bucket 
                                                                                                                                                                                                                                                                                                                                                                                                   ## whose 
                                                                                                                                                                                                                                                                                                                                                                                                   ## associated 
                                                                                                                                                                                                                                                                                                                                                                                                   ## access 
                                                                                                                                                                                                                                                                                                                                                                                                   ## points 
                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                   ## list.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                           ## nextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                           ## A 
                                                                                                                                                                                                                                                                                                                                                                                                           ## continuation 
                                                                                                                                                                                                                                                                                                                                                                                                           ## token. 
                                                                                                                                                                                                                                                                                                                                                                                                           ## If 
                                                                                                                                                                                                                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                                                                                                                                                                                                                           ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                           ## call 
                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                           ## <code>ListAccessPoints</code> 
                                                                                                                                                                                                                                                                                                                                                                                                           ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                                                                                                                                                                                                                           ## continuation 
                                                                                                                                                                                                                                                                                                                                                                                                           ## token 
                                                                                                                                                                                                                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                           ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                           ## field, 
                                                                                                                                                                                                                                                                                                                                                                                                           ## then 
                                                                                                                                                                                                                                                                                                                                                                                                           ## providing 
                                                                                                                                                                                                                                                                                                                                                                                                           ## that 
                                                                                                                                                                                                                                                                                                                                                                                                           ## value 
                                                                                                                                                                                                                                                                                                                                                                                                           ## here 
                                                                                                                                                                                                                                                                                                                                                                                                           ## causes 
                                                                                                                                                                                                                                                                                                                                                                                                           ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                           ## S3 
                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                           ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                           ## next 
                                                                                                                                                                                                                                                                                                                                                                                                           ## page 
                                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                                           ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                              ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                              ##            
                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                              ## token
  var query_402656690 = newJObject()
  add(query_402656690, "maxResults", newJInt(maxResults))
  add(query_402656690, "bucket", newJString(bucket))
  add(query_402656690, "nextToken", newJString(nextToken))
  add(query_402656690, "MaxResults", newJString(MaxResults))
  add(query_402656690, "NextToken", newJString(NextToken))
  result = call_402656689.call(nil, query_402656690, nil, nil, nil)

var listAccessPoints* = Call_ListAccessPoints_402656672(
    name: "listAccessPoints", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint#x-amz-account-id",
    validator: validate_ListAccessPoints_402656673, base: "/",
    makeUrl: url_ListAccessPoints_402656674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_402656691 = ref object of OpenApiRestCall_402656044
proc url_UpdateJobPriority_402656693(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
                 (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/priority#x-amz-account-id&priority")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobPriority_402656692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing job's priority.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID for the job whose priority you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656694 = path.getOrDefault("id")
  valid_402656694 = validateParameter(valid_402656694, JString, required = true,
                                      default = nil)
  if valid_402656694 != nil:
    section.add "id", valid_402656694
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
                                  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `priority` field"
  var valid_402656695 = query.getOrDefault("priority")
  valid_402656695 = validateParameter(valid_402656695, JInt, required = true,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "priority", valid_402656695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
                                ##                   : <p/>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656696 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Security-Token", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Signature")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Signature", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Algorithm", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Date")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Date", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Credential")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Credential", valid_402656701
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656702 = header.getOrDefault("x-amz-account-id")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true,
                                      default = nil)
  if valid_402656702 != nil:
    section.add "x-amz-account-id", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656704: Call_UpdateJobPriority_402656691;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing job's priority.
                                                                                         ## 
  let valid = call_402656704.validator(path, query, header, formData, body, _)
  let scheme = call_402656704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656704.makeUrl(scheme.get, call_402656704.host, call_402656704.base,
                                   call_402656704.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656704, uri, valid, _)

proc call*(call_402656705: Call_UpdateJobPriority_402656691; id: string;
           priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
                                        ##     : The ID for the job whose priority you want to update.
  ##   
                                                                                                      ## priority: int (required)
                                                                                                      ##           
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## priority 
                                                                                                      ## you 
                                                                                                      ## want 
                                                                                                      ## to 
                                                                                                      ## assign 
                                                                                                      ## to 
                                                                                                      ## this 
                                                                                                      ## job.
  var path_402656706 = newJObject()
  var query_402656707 = newJObject()
  add(path_402656706, "id", newJString(id))
  add(query_402656707, "priority", newJInt(priority))
  result = call_402656705.call(path_402656706, query_402656707, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_402656691(
    name: "updateJobPriority", meth: HttpMethod.HttpPost,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_402656692, base: "/",
    makeUrl: url_UpdateJobPriority_402656693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_402656708 = ref object of OpenApiRestCall_402656044
proc url_UpdateJobStatus_402656710(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
                 (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/status#x-amz-account-id&requestedJobStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobStatus_402656709(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
                                 ##     : The ID of the job whose status you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_402656711 = path.getOrDefault("id")
  valid_402656711 = validateParameter(valid_402656711, JString, required = true,
                                      default = nil)
  if valid_402656711 != nil:
    section.add "id", valid_402656711
  result.add "path", section
  ## parameters in `query` object:
  ##   statusUpdateReason: JString
                                  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  ##   
                                                                                                                                                                                                ## requestedJobStatus: JString (required)
                                                                                                                                                                                                ##                     
                                                                                                                                                                                                ## : 
                                                                                                                                                                                                ## The 
                                                                                                                                                                                                ## status 
                                                                                                                                                                                                ## that 
                                                                                                                                                                                                ## you 
                                                                                                                                                                                                ## want 
                                                                                                                                                                                                ## to 
                                                                                                                                                                                                ## move 
                                                                                                                                                                                                ## the 
                                                                                                                                                                                                ## specified 
                                                                                                                                                                                                ## job 
                                                                                                                                                                                                ## to.
  section = newJObject()
  var valid_402656712 = query.getOrDefault("statusUpdateReason")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "statusUpdateReason", valid_402656712
  var valid_402656725 = query.getOrDefault("requestedJobStatus")
  valid_402656725 = validateParameter(valid_402656725, JString, required = true,
                                      default = newJString("Cancelled"))
  if valid_402656725 != nil:
    section.add "requestedJobStatus", valid_402656725
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
                                ##                   : <p/>
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656726 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Security-Token", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Signature")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Signature", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Algorithm", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Date")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Date", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Credential")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Credential", valid_402656731
  assert header != nil, "header argument is necessary due to required `x-amz-account-id` field"
  var valid_402656732 = header.getOrDefault("x-amz-account-id")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "x-amz-account-id", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656734: Call_UpdateJobStatus_402656708; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
                                                                                         ## 
  let valid = call_402656734.validator(path, query, header, formData, body, _)
  let scheme = call_402656734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656734.makeUrl(scheme.get, call_402656734.host, call_402656734.base,
                                   call_402656734.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656734, uri, valid, _)

proc call*(call_402656735: Call_UpdateJobStatus_402656708; id: string;
           statusUpdateReason: string = "";
           requestedJobStatus: string = "Cancelled"): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   
                                                                                                                                     ## statusUpdateReason: string
                                                                                                                                     ##                     
                                                                                                                                     ## : 
                                                                                                                                     ## A 
                                                                                                                                     ## description 
                                                                                                                                     ## of 
                                                                                                                                     ## the 
                                                                                                                                     ## reason 
                                                                                                                                     ## why 
                                                                                                                                     ## you 
                                                                                                                                     ## want 
                                                                                                                                     ## to 
                                                                                                                                     ## change 
                                                                                                                                     ## the 
                                                                                                                                     ## specified 
                                                                                                                                     ## job's 
                                                                                                                                     ## status. 
                                                                                                                                     ## This 
                                                                                                                                     ## field 
                                                                                                                                     ## can 
                                                                                                                                     ## be 
                                                                                                                                     ## any 
                                                                                                                                     ## string 
                                                                                                                                     ## up 
                                                                                                                                     ## to 
                                                                                                                                     ## the 
                                                                                                                                     ## maximum 
                                                                                                                                     ## length.
  ##   
                                                                                                                                               ## id: string (required)
                                                                                                                                               ##     
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## ID 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## job 
                                                                                                                                               ## whose 
                                                                                                                                               ## status 
                                                                                                                                               ## you 
                                                                                                                                               ## want 
                                                                                                                                               ## to 
                                                                                                                                               ## update.
  ##   
                                                                                                                                                         ## requestedJobStatus: string (required)
                                                                                                                                                         ##                     
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## status 
                                                                                                                                                         ## that 
                                                                                                                                                         ## you 
                                                                                                                                                         ## want 
                                                                                                                                                         ## to 
                                                                                                                                                         ## move 
                                                                                                                                                         ## the 
                                                                                                                                                         ## specified 
                                                                                                                                                         ## job 
                                                                                                                                                         ## to.
  var path_402656736 = newJObject()
  var query_402656737 = newJObject()
  add(query_402656737, "statusUpdateReason", newJString(statusUpdateReason))
  add(path_402656736, "id", newJString(id))
  add(query_402656737, "requestedJobStatus", newJString(requestedJobStatus))
  result = call_402656735.call(path_402656736, query_402656737, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_402656708(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_402656709, base: "/",
    makeUrl: url_UpdateJobStatus_402656710, schemes: {Scheme.Https, Scheme.Http})
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