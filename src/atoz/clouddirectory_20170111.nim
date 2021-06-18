
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudDirectory
## version: 2017-01-11
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Cloud Directory</fullname> <p>Amazon Cloud Directory is a component of the AWS Directory Service that simplifies the development and management of cloud-scale web, mobile, and IoT applications. This guide describes the Cloud Directory operations that you can call programmatically and includes detailed information on data types and errors. For information about Cloud Directory features, see <a href="https://aws.amazon.com/directoryservice/">AWS Directory Service</a> and the <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/what_is_cloud_directory.html">Amazon Cloud Directory Developer Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/clouddirectory/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "clouddirectory.ap-northeast-1.amazonaws.com", "ap-southeast-1": "clouddirectory.ap-southeast-1.amazonaws.com", "us-west-2": "clouddirectory.us-west-2.amazonaws.com", "eu-west-2": "clouddirectory.eu-west-2.amazonaws.com", "ap-northeast-3": "clouddirectory.ap-northeast-3.amazonaws.com", "eu-central-1": "clouddirectory.eu-central-1.amazonaws.com", "us-east-2": "clouddirectory.us-east-2.amazonaws.com", "us-east-1": "clouddirectory.us-east-1.amazonaws.com", "cn-northwest-1": "clouddirectory.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "clouddirectory.ap-south-1.amazonaws.com", "eu-north-1": "clouddirectory.eu-north-1.amazonaws.com", "ap-northeast-2": "clouddirectory.ap-northeast-2.amazonaws.com", "us-west-1": "clouddirectory.us-west-1.amazonaws.com", "us-gov-east-1": "clouddirectory.us-gov-east-1.amazonaws.com", "eu-west-3": "clouddirectory.eu-west-3.amazonaws.com", "cn-north-1": "clouddirectory.cn-north-1.amazonaws.com.cn", "sa-east-1": "clouddirectory.sa-east-1.amazonaws.com", "eu-west-1": "clouddirectory.eu-west-1.amazonaws.com", "us-gov-west-1": "clouddirectory.us-gov-west-1.amazonaws.com", "ap-southeast-2": "clouddirectory.ap-southeast-2.amazonaws.com", "ca-central-1": "clouddirectory.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "clouddirectory.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "clouddirectory.ap-southeast-1.amazonaws.com",
      "us-west-2": "clouddirectory.us-west-2.amazonaws.com",
      "eu-west-2": "clouddirectory.eu-west-2.amazonaws.com",
      "ap-northeast-3": "clouddirectory.ap-northeast-3.amazonaws.com",
      "eu-central-1": "clouddirectory.eu-central-1.amazonaws.com",
      "us-east-2": "clouddirectory.us-east-2.amazonaws.com",
      "us-east-1": "clouddirectory.us-east-1.amazonaws.com",
      "cn-northwest-1": "clouddirectory.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "clouddirectory.ap-south-1.amazonaws.com",
      "eu-north-1": "clouddirectory.eu-north-1.amazonaws.com",
      "ap-northeast-2": "clouddirectory.ap-northeast-2.amazonaws.com",
      "us-west-1": "clouddirectory.us-west-1.amazonaws.com",
      "us-gov-east-1": "clouddirectory.us-gov-east-1.amazonaws.com",
      "eu-west-3": "clouddirectory.eu-west-3.amazonaws.com",
      "cn-north-1": "clouddirectory.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "clouddirectory.sa-east-1.amazonaws.com",
      "eu-west-1": "clouddirectory.eu-west-1.amazonaws.com",
      "us-gov-west-1": "clouddirectory.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "clouddirectory.ap-southeast-2.amazonaws.com",
      "ca-central-1": "clouddirectory.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "clouddirectory"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddFacetToObject_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddFacetToObject_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddFacetToObject_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                       ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656384 = header.getOrDefault("x-amz-data-partition")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true,
                                      default = nil)
  if valid_402656384 != nil:
    section.add "x-amz-data-partition", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656385
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

proc call*(call_402656400: Call_AddFacetToObject_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
                                                                                         ## 
  let valid = call_402656400.validator(path, query, header, formData, body, _)
  let scheme = call_402656400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656400.makeUrl(scheme.get, call_402656400.host, call_402656400.base,
                                   call_402656400.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656400, uri, valid, _)

proc call*(call_402656449: Call_AddFacetToObject_402656294; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   
                                                                                                ## body: JObject (required)
  var body_402656450 = newJObject()
  if body != nil:
    body_402656450 = body
  result = call_402656449.call(nil, nil, nil, nil, body_402656450)

var addFacetToObject* = Call_AddFacetToObject_402656294(
    name: "addFacetToObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_402656295, base: "/",
    makeUrl: url_AddFacetToObject_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_402656477 = ref object of OpenApiRestCall_402656044
proc url_ApplySchema_402656479(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApplySchema_402656478(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> into which the schema is copied. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656486 = header.getOrDefault("x-amz-data-partition")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true,
                                      default = nil)
  if valid_402656486 != nil:
    section.add "x-amz-data-partition", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656487
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

proc call*(call_402656489: Call_ApplySchema_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
                                                                                         ## 
  let valid = call_402656489.validator(path, query, header, formData, body, _)
  let scheme = call_402656489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656489.makeUrl(scheme.get, call_402656489.host, call_402656489.base,
                                   call_402656489.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656489, uri, valid, _)

proc call*(call_402656490: Call_ApplySchema_402656477; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   
                                                                                                                                                           ## body: JObject (required)
  var body_402656491 = newJObject()
  if body != nil:
    body_402656491 = body
  result = call_402656490.call(nil, nil, nil, nil, body_402656491)

var applySchema* = Call_ApplySchema_402656477(name: "applySchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
    validator: validate_ApplySchema_402656478, base: "/",
    makeUrl: url_ApplySchema_402656479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_402656492 = ref object of OpenApiRestCall_402656044
proc url_AttachObject_402656494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachObject_402656493(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656495 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Security-Token", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Signature")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Signature", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Algorithm", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Date")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Date", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Credential")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Credential", valid_402656500
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656501 = header.getOrDefault("x-amz-data-partition")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "x-amz-data-partition", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656502
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

proc call*(call_402656504: Call_AttachObject_402656492; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
                                                                                         ## 
  let valid = call_402656504.validator(path, query, header, formData, body, _)
  let scheme = call_402656504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656504.makeUrl(scheme.get, call_402656504.host, call_402656504.base,
                                   call_402656504.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656504, uri, valid, _)

proc call*(call_402656505: Call_AttachObject_402656492; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   
                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656506 = newJObject()
  if body != nil:
    body_402656506 = body
  result = call_402656505.call(nil, nil, nil, nil, body_402656506)

var attachObject* = Call_AttachObject_402656492(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_402656493, base: "/",
    makeUrl: url_AttachObject_402656494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_402656507 = ref object of OpenApiRestCall_402656044
proc url_AttachPolicy_402656509(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachPolicy_402656508(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                        ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656510 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Security-Token", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Signature")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Signature", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Algorithm", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Date")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Date", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Credential")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Credential", valid_402656515
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656516 = header.getOrDefault("x-amz-data-partition")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true,
                                      default = nil)
  if valid_402656516 != nil:
    section.add "x-amz-data-partition", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656517
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

proc call*(call_402656519: Call_AttachPolicy_402656507; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
                                                                                         ## 
  let valid = call_402656519.validator(path, query, header, formData, body, _)
  let scheme = call_402656519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656519.makeUrl(scheme.get, call_402656519.host, call_402656519.base,
                                   call_402656519.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656519, uri, valid, _)

proc call*(call_402656520: Call_AttachPolicy_402656507; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   
                                                                                                            ## body: JObject (required)
  var body_402656521 = newJObject()
  if body != nil:
    body_402656521 = body
  result = call_402656520.call(nil, nil, nil, nil, body_402656521)

var attachPolicy* = Call_AttachPolicy_402656507(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_402656508, base: "/",
    makeUrl: url_AttachPolicy_402656509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_402656522 = ref object of OpenApiRestCall_402656044
proc url_AttachToIndex_402656524(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachToIndex_402656523(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attaches the specified object to the specified index.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory where the object and index exist.
  ##   
                                                                                                                                            ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656525 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Security-Token", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Signature")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Signature", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Algorithm", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Date")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Date", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Credential")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Credential", valid_402656530
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656531 = header.getOrDefault("x-amz-data-partition")
  valid_402656531 = validateParameter(valid_402656531, JString, required = true,
                                      default = nil)
  if valid_402656531 != nil:
    section.add "x-amz-data-partition", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656532
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

proc call*(call_402656534: Call_AttachToIndex_402656522; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches the specified object to the specified index.
                                                                                         ## 
  let valid = call_402656534.validator(path, query, header, formData, body, _)
  let scheme = call_402656534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656534.makeUrl(scheme.get, call_402656534.host, call_402656534.base,
                                   call_402656534.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656534, uri, valid, _)

proc call*(call_402656535: Call_AttachToIndex_402656522; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_402656536 = newJObject()
  if body != nil:
    body_402656536 = body
  result = call_402656535.call(nil, nil, nil, nil, body_402656536)

var attachToIndex* = Call_AttachToIndex_402656522(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_402656523, base: "/",
    makeUrl: url_AttachToIndex_402656524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_402656537 = ref object of OpenApiRestCall_402656044
proc url_AttachTypedLink_402656539(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachTypedLink_402656538(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory where you want to attach the typed link.
  ##   
                                                                                                                                                   ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656540 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Security-Token", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Signature")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Signature", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Algorithm", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Date")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Date", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Credential")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Credential", valid_402656545
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656546 = header.getOrDefault("x-amz-data-partition")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true,
                                      default = nil)
  if valid_402656546 != nil:
    section.add "x-amz-data-partition", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656547
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

proc call*(call_402656549: Call_AttachTypedLink_402656537; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402656549.validator(path, query, header, formData, body, _)
  let scheme = call_402656549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656549.makeUrl(scheme.get, call_402656549.host, call_402656549.base,
                                   call_402656549.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656549, uri, valid, _)

proc call*(call_402656550: Call_AttachTypedLink_402656537; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656551 = newJObject()
  if body != nil:
    body_402656551 = body
  result = call_402656550.call(nil, nil, nil, nil, body_402656551)

var attachTypedLink* = Call_AttachTypedLink_402656537(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_402656538, base: "/",
    makeUrl: url_AttachTypedLink_402656539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_402656552 = ref object of OpenApiRestCall_402656044
proc url_BatchRead_402656554(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchRead_402656553(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Performs all the read operations in a batch. 
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
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a>. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656555 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Security-Token", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Signature")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Signature", valid_402656556
  var valid_402656569 = header.getOrDefault("x-amz-consistency-level")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402656569 != nil:
    section.add "x-amz-consistency-level", valid_402656569
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656574 = header.getOrDefault("x-amz-data-partition")
  valid_402656574 = validateParameter(valid_402656574, JString, required = true,
                                      default = nil)
  if valid_402656574 != nil:
    section.add "x-amz-data-partition", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656575
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

proc call*(call_402656577: Call_BatchRead_402656552; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Performs all the read operations in a batch. 
                                                                                         ## 
  let valid = call_402656577.validator(path, query, header, formData, body, _)
  let scheme = call_402656577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656577.makeUrl(scheme.get, call_402656577.host, call_402656577.base,
                                   call_402656577.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656577, uri, valid, _)

proc call*(call_402656578: Call_BatchRead_402656552; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_402656579 = newJObject()
  if body != nil:
    body_402656579 = body
  result = call_402656578.call(nil, nil, nil, nil, body_402656579)

var batchRead* = Call_BatchRead_402656552(name: "batchRead",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
    validator: validate_BatchRead_402656553, base: "/", makeUrl: url_BatchRead_402656554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_402656580 = ref object of OpenApiRestCall_402656044
proc url_BatchWrite_402656582(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWrite_402656581(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656589 = header.getOrDefault("x-amz-data-partition")
  valid_402656589 = validateParameter(valid_402656589, JString, required = true,
                                      default = nil)
  if valid_402656589 != nil:
    section.add "x-amz-data-partition", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656590
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

proc call*(call_402656592: Call_BatchWrite_402656580; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
                                                                                         ## 
  let valid = call_402656592.validator(path, query, header, formData, body, _)
  let scheme = call_402656592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656592.makeUrl(scheme.get, call_402656592.host, call_402656592.base,
                                   call_402656592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656592, uri, valid, _)

proc call*(call_402656593: Call_BatchWrite_402656580; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   
                                                                                             ## body: JObject (required)
  var body_402656594 = newJObject()
  if body != nil:
    body_402656594 = body
  result = call_402656593.call(nil, nil, nil, nil, body_402656594)

var batchWrite* = Call_BatchWrite_402656580(name: "batchWrite",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
    validator: validate_BatchWrite_402656581, base: "/",
    makeUrl: url_BatchWrite_402656582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_402656595 = ref object of OpenApiRestCall_402656044
proc url_CreateDirectory_402656597(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectory_402656596(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the published schema that will be copied into the data <a>Directory</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                            ## X-Amz-SignedHeaders: JString
  section = newJObject()
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656604 = header.getOrDefault("x-amz-data-partition")
  valid_402656604 = validateParameter(valid_402656604, JString, required = true,
                                      default = nil)
  if valid_402656604 != nil:
    section.add "x-amz-data-partition", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656605
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

proc call*(call_402656607: Call_CreateDirectory_402656595; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656607.validator(path, query, header, formData, body, _)
  let scheme = call_402656607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656607.makeUrl(scheme.get, call_402656607.host, call_402656607.base,
                                   call_402656607.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656607, uri, valid, _)

proc call*(call_402656608: Call_CreateDirectory_402656595; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656609 = newJObject()
  if body != nil:
    body_402656609 = body
  result = call_402656608.call(nil, nil, nil, nil, body_402656609)

var createDirectory* = Call_CreateDirectory_402656595(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_402656596, base: "/",
    makeUrl: url_CreateDirectory_402656597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_402656610 = ref object of OpenApiRestCall_402656044
proc url_CreateFacet_402656612(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFacet_402656611(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The schema ARN in which the new <a>Facet</a> will be created. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656619 = header.getOrDefault("x-amz-data-partition")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "x-amz-data-partition", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656620
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

proc call*(call_402656622: Call_CreateFacet_402656610; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
                                                                                         ## 
  let valid = call_402656622.validator(path, query, header, formData, body, _)
  let scheme = call_402656622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656622.makeUrl(scheme.get, call_402656622.host, call_402656622.base,
                                   call_402656622.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656622, uri, valid, _)

proc call*(call_402656623: Call_CreateFacet_402656610; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   
                                                                                                              ## body: JObject (required)
  var body_402656624 = newJObject()
  if body != nil:
    body_402656624 = body
  result = call_402656623.call(nil, nil, nil, nil, body_402656624)

var createFacet* = Call_CreateFacet_402656610(name: "createFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
    validator: validate_CreateFacet_402656611, base: "/",
    makeUrl: url_CreateFacet_402656612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_402656625 = ref object of OpenApiRestCall_402656044
proc url_CreateIndex_402656627(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIndex_402656626(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory where the index should be created.
  ##   
                                                                                                                      ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656634 = header.getOrDefault("x-amz-data-partition")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "x-amz-data-partition", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
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

proc call*(call_402656637: Call_CreateIndex_402656625; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
                                                                                         ## 
  let valid = call_402656637.validator(path, query, header, formData, body, _)
  let scheme = call_402656637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656637.makeUrl(scheme.get, call_402656637.host, call_402656637.base,
                                   call_402656637.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656637, uri, valid, _)

proc call*(call_402656638: Call_CreateIndex_402656625; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ##   
                                                                                                                                                                               ## body: JObject (required)
  var body_402656639 = newJObject()
  if body != nil:
    body_402656639 = body
  result = call_402656638.call(nil, nil, nil, nil, body_402656639)

var createIndex* = Call_CreateIndex_402656625(name: "createIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
    validator: validate_CreateIndex_402656626, base: "/",
    makeUrl: url_CreateIndex_402656627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_402656640 = ref object of OpenApiRestCall_402656044
proc url_CreateObject_402656642(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateObject_402656641(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> in which the object will be created. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                                  ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656649 = header.getOrDefault("x-amz-data-partition")
  valid_402656649 = validateParameter(valid_402656649, JString, required = true,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "x-amz-data-partition", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656650
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

proc call*(call_402656652: Call_CreateObject_402656640; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
                                                                                         ## 
  let valid = call_402656652.validator(path, query, header, formData, body, _)
  let scheme = call_402656652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656652.makeUrl(scheme.get, call_402656652.host, call_402656652.base,
                                   call_402656652.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656652, uri, valid, _)

proc call*(call_402656653: Call_CreateObject_402656640; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   
                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656654 = newJObject()
  if body != nil:
    body_402656654 = body
  result = call_402656653.call(nil, nil, nil, nil, body_402656654)

var createObject* = Call_CreateObject_402656640(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_402656641, base: "/",
    makeUrl: url_CreateObject_402656642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_402656655 = ref object of OpenApiRestCall_402656044
proc url_CreateSchema_402656657(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSchema_402656656(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
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
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_CreateSchema_402656655; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_CreateSchema_402656655; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var createSchema* = Call_CreateSchema_402656655(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_402656656, base: "/",
    makeUrl: url_CreateSchema_402656657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_402656669 = ref object of OpenApiRestCall_402656044
proc url_CreateTypedLinkFacet_402656671(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTypedLinkFacet_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Security-Token", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Signature")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Signature", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Algorithm", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Date")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Date", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Credential")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Credential", valid_402656677
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656678 = header.getOrDefault("x-amz-data-partition")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true,
                                      default = nil)
  if valid_402656678 != nil:
    section.add "x-amz-data-partition", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_CreateTypedLinkFacet_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_CreateTypedLinkFacet_402656669; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_402656669(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_402656670, base: "/",
    makeUrl: url_CreateTypedLinkFacet_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_402656684 = ref object of OpenApiRestCall_402656044
proc url_DeleteDirectory_402656686(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectory_402656685(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory to delete.
  ##   
                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Security-Token", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Signature")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Signature", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Algorithm", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Date")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Date", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Credential")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Credential", valid_402656692
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656693 = header.getOrDefault("x-amz-data-partition")
  valid_402656693 = validateParameter(valid_402656693, JString, required = true,
                                      default = nil)
  if valid_402656693 != nil:
    section.add "x-amz-data-partition", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656695: Call_DeleteDirectory_402656684; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
                                                                                         ## 
  let valid = call_402656695.validator(path, query, header, formData, body, _)
  let scheme = call_402656695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656695.makeUrl(scheme.get, call_402656695.host, call_402656695.base,
                                   call_402656695.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656695, uri, valid, _)

proc call*(call_402656696: Call_DeleteDirectory_402656684): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_402656696.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_402656684(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_402656685, base: "/",
    makeUrl: url_DeleteDirectory_402656686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_402656697 = ref object of OpenApiRestCall_402656044
proc url_DeleteFacet_402656699(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFacet_402656698(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                          ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656700 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Security-Token", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Signature")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Signature", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Algorithm", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Date")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Date", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Credential")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Credential", valid_402656705
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656706 = header.getOrDefault("x-amz-data-partition")
  valid_402656706 = validateParameter(valid_402656706, JString, required = true,
                                      default = nil)
  if valid_402656706 != nil:
    section.add "x-amz-data-partition", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
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

proc call*(call_402656709: Call_DeleteFacet_402656697; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_DeleteFacet_402656697; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   
                                                                                                                                                                           ## body: JObject (required)
  var body_402656711 = newJObject()
  if body != nil:
    body_402656711 = body
  result = call_402656710.call(nil, nil, nil, nil, body_402656711)

var deleteFacet* = Call_DeleteFacet_402656697(name: "deleteFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
    validator: validate_DeleteFacet_402656698, base: "/",
    makeUrl: url_DeleteFacet_402656699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_402656712 = ref object of OpenApiRestCall_402656044
proc url_DeleteObject_402656714(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteObject_402656713(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                       ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Algorithm", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Date")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Date", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Credential")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Credential", valid_402656720
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656721 = header.getOrDefault("x-amz-data-partition")
  valid_402656721 = validateParameter(valid_402656721, JString, required = true,
                                      default = nil)
  if valid_402656721 != nil:
    section.add "x-amz-data-partition", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656722
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

proc call*(call_402656724: Call_DeleteObject_402656712; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
                                                                                         ## 
  let valid = call_402656724.validator(path, query, header, formData, body, _)
  let scheme = call_402656724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656724.makeUrl(scheme.get, call_402656724.host, call_402656724.base,
                                   call_402656724.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656724, uri, valid, _)

proc call*(call_402656725: Call_DeleteObject_402656712; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656726 = newJObject()
  if body != nil:
    body_402656726 = body
  result = call_402656725.call(nil, nil, nil, nil, body_402656726)

var deleteObject* = Call_DeleteObject_402656712(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_402656713, base: "/",
    makeUrl: url_DeleteObject_402656714, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_402656727 = ref object of OpenApiRestCall_402656044
proc url_DeleteSchema_402656729(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSchema_402656728(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656730 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Security-Token", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Signature")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Signature", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Algorithm", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Date")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Date", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Credential")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Credential", valid_402656735
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656736 = header.getOrDefault("x-amz-data-partition")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true,
                                      default = nil)
  if valid_402656736 != nil:
    section.add "x-amz-data-partition", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656738: Call_DeleteSchema_402656727; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
                                                                                         ## 
  let valid = call_402656738.validator(path, query, header, formData, body, _)
  let scheme = call_402656738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656738.makeUrl(scheme.get, call_402656738.host, call_402656738.base,
                                   call_402656738.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656738, uri, valid, _)

proc call*(call_402656739: Call_DeleteSchema_402656727): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_402656739.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_402656727(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_402656728, base: "/",
    makeUrl: url_DeleteSchema_402656729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_402656740 = ref object of OpenApiRestCall_402656044
proc url_DeleteTypedLinkFacet_402656742(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTypedLinkFacet_402656741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656743 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Security-Token", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Signature")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Signature", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Algorithm", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Date")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Date", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Credential")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Credential", valid_402656748
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656749 = header.getOrDefault("x-amz-data-partition")
  valid_402656749 = validateParameter(valid_402656749, JString, required = true,
                                      default = nil)
  if valid_402656749 != nil:
    section.add "x-amz-data-partition", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656750
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

proc call*(call_402656752: Call_DeleteTypedLinkFacet_402656740;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402656752.validator(path, query, header, formData, body, _)
  let scheme = call_402656752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656752.makeUrl(scheme.get, call_402656752.host, call_402656752.base,
                                   call_402656752.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656752, uri, valid, _)

proc call*(call_402656753: Call_DeleteTypedLinkFacet_402656740; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656754 = newJObject()
  if body != nil:
    body_402656754 = body
  result = call_402656753.call(nil, nil, nil, nil, body_402656754)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_402656740(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_402656741, base: "/",
    makeUrl: url_DeleteTypedLinkFacet_402656742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_402656755 = ref object of OpenApiRestCall_402656044
proc url_DetachFromIndex_402656757(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachFromIndex_402656756(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Detaches the specified object from the specified index.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory the index and object exist in.
  ##   
                                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656758 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Security-Token", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Signature")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Signature", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Algorithm", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Date")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Date", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Credential")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Credential", valid_402656763
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656764 = header.getOrDefault("x-amz-data-partition")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true,
                                      default = nil)
  if valid_402656764 != nil:
    section.add "x-amz-data-partition", valid_402656764
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

proc call*(call_402656767: Call_DetachFromIndex_402656755; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches the specified object from the specified index.
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

proc call*(call_402656768: Call_DetachFromIndex_402656755; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_402656769 = newJObject()
  if body != nil:
    body_402656769 = body
  result = call_402656768.call(nil, nil, nil, nil, body_402656769)

var detachFromIndex* = Call_DetachFromIndex_402656755(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_402656756, base: "/",
    makeUrl: url_DetachFromIndex_402656757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_402656770 = ref object of OpenApiRestCall_402656044
proc url_DetachObject_402656772(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachObject_402656771(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                   ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656779 = header.getOrDefault("x-amz-data-partition")
  valid_402656779 = validateParameter(valid_402656779, JString, required = true,
                                      default = nil)
  if valid_402656779 != nil:
    section.add "x-amz-data-partition", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656780
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

proc call*(call_402656782: Call_DetachObject_402656770; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
                                                                                         ## 
  let valid = call_402656782.validator(path, query, header, formData, body, _)
  let scheme = call_402656782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656782.makeUrl(scheme.get, call_402656782.host, call_402656782.base,
                                   call_402656782.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656782, uri, valid, _)

proc call*(call_402656783: Call_DetachObject_402656770; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   
                                                                                                                                     ## body: JObject (required)
  var body_402656784 = newJObject()
  if body != nil:
    body_402656784 = body
  result = call_402656783.call(nil, nil, nil, nil, body_402656784)

var detachObject* = Call_DetachObject_402656770(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_402656771, base: "/",
    makeUrl: url_DetachObject_402656772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_402656785 = ref object of OpenApiRestCall_402656044
proc url_DetachPolicy_402656787(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachPolicy_402656786(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Detaches a policy from an object.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                        ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656788 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Security-Token", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Signature")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Signature", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Algorithm", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Date")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Date", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Credential")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Credential", valid_402656793
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656794 = header.getOrDefault("x-amz-data-partition")
  valid_402656794 = validateParameter(valid_402656794, JString, required = true,
                                      default = nil)
  if valid_402656794 != nil:
    section.add "x-amz-data-partition", valid_402656794
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

proc call*(call_402656797: Call_DetachPolicy_402656785; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a policy from an object.
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

proc call*(call_402656798: Call_DetachPolicy_402656785; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_402656799 = newJObject()
  if body != nil:
    body_402656799 = body
  result = call_402656798.call(nil, nil, nil, nil, body_402656799)

var detachPolicy* = Call_DetachPolicy_402656785(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_402656786, base: "/",
    makeUrl: url_DetachPolicy_402656787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_402656800 = ref object of OpenApiRestCall_402656044
proc url_DetachTypedLink_402656802(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachTypedLink_402656801(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory where you want to detach the typed link.
  ##   
                                                                                                                                                   ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656809 = header.getOrDefault("x-amz-data-partition")
  valid_402656809 = validateParameter(valid_402656809, JString, required = true,
                                      default = nil)
  if valid_402656809 != nil:
    section.add "x-amz-data-partition", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656810
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

proc call*(call_402656812: Call_DetachTypedLink_402656800; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_DetachTypedLink_402656800; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656814 = newJObject()
  if body != nil:
    body_402656814 = body
  result = call_402656813.call(nil, nil, nil, nil, body_402656814)

var detachTypedLink* = Call_DetachTypedLink_402656800(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_402656801, base: "/",
    makeUrl: url_DetachTypedLink_402656802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_402656815 = ref object of OpenApiRestCall_402656044
proc url_DisableDirectory_402656817(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableDirectory_402656816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory to disable.
  ##   
                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656818 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Security-Token", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Signature")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Signature", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Algorithm", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Date")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Date", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Credential")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Credential", valid_402656823
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656824 = header.getOrDefault("x-amz-data-partition")
  valid_402656824 = validateParameter(valid_402656824, JString, required = true,
                                      default = nil)
  if valid_402656824 != nil:
    section.add "x-amz-data-partition", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656826: Call_DisableDirectory_402656815;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
                                                                                         ## 
  let valid = call_402656826.validator(path, query, header, formData, body, _)
  let scheme = call_402656826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656826.makeUrl(scheme.get, call_402656826.host, call_402656826.base,
                                   call_402656826.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656826, uri, valid, _)

proc call*(call_402656827: Call_DisableDirectory_402656815): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_402656827.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_402656815(
    name: "disableDirectory", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_402656816, base: "/",
    makeUrl: url_DisableDirectory_402656817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_402656828 = ref object of OpenApiRestCall_402656044
proc url_EnableDirectory_402656830(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableDirectory_402656829(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory to enable.
  ##   
                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656831 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Security-Token", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Signature")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Signature", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Algorithm", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Date")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Date", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Credential")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Credential", valid_402656836
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656837 = header.getOrDefault("x-amz-data-partition")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true,
                                      default = nil)
  if valid_402656837 != nil:
    section.add "x-amz-data-partition", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656839: Call_EnableDirectory_402656828; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
                                                                                         ## 
  let valid = call_402656839.validator(path, query, header, formData, body, _)
  let scheme = call_402656839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656839.makeUrl(scheme.get, call_402656839.host, call_402656839.base,
                                   call_402656839.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656839, uri, valid, _)

proc call*(call_402656840: Call_EnableDirectory_402656828): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_402656840.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_402656828(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_402656829, base: "/",
    makeUrl: url_EnableDirectory_402656830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_402656841 = ref object of OpenApiRestCall_402656044
proc url_GetAppliedSchemaVersion_402656843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppliedSchemaVersion_402656842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns current applied schema version ARN, including the minor version in use.
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

proc call*(call_402656852: Call_GetAppliedSchemaVersion_402656841;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
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

proc call*(call_402656853: Call_GetAppliedSchemaVersion_402656841;
           body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   
                                                                                    ## body: JObject (required)
  var body_402656854 = newJObject()
  if body != nil:
    body_402656854 = body
  result = call_402656853.call(nil, nil, nil, nil, body_402656854)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_402656841(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_402656842, base: "/",
    makeUrl: url_GetAppliedSchemaVersion_402656843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_402656855 = ref object of OpenApiRestCall_402656044
proc url_GetDirectory_402656857(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDirectory_402656856(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata about a directory.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory.
  ##   
                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656858 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Security-Token", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Signature")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Signature", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Algorithm", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Date")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Date", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Credential")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Credential", valid_402656863
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656864 = header.getOrDefault("x-amz-data-partition")
  valid_402656864 = validateParameter(valid_402656864, JString, required = true,
                                      default = nil)
  if valid_402656864 != nil:
    section.add "x-amz-data-partition", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656866: Call_GetDirectory_402656855; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata about a directory.
                                                                                         ## 
  let valid = call_402656866.validator(path, query, header, formData, body, _)
  let scheme = call_402656866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656866.makeUrl(scheme.get, call_402656866.host, call_402656866.base,
                                   call_402656866.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656866, uri, valid, _)

proc call*(call_402656867: Call_GetDirectory_402656855): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_402656867.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_402656855(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_402656856, base: "/",
    makeUrl: url_GetDirectory_402656857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_402656868 = ref object of OpenApiRestCall_402656044
proc url_UpdateFacet_402656870(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFacet_402656869(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                          ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656877 = header.getOrDefault("x-amz-data-partition")
  valid_402656877 = validateParameter(valid_402656877, JString, required = true,
                                      default = nil)
  if valid_402656877 != nil:
    section.add "x-amz-data-partition", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656878
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

proc call*(call_402656880: Call_UpdateFacet_402656868; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
                                                                                         ## 
  let valid = call_402656880.validator(path, query, header, formData, body, _)
  let scheme = call_402656880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656880.makeUrl(scheme.get, call_402656880.host, call_402656880.base,
                                   call_402656880.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656880, uri, valid, _)

proc call*(call_402656881: Call_UpdateFacet_402656868; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   
                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656882 = newJObject()
  if body != nil:
    body_402656882 = body
  result = call_402656881.call(nil, nil, nil, nil, body_402656882)

var updateFacet* = Call_UpdateFacet_402656868(name: "updateFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
    validator: validate_UpdateFacet_402656869, base: "/",
    makeUrl: url_UpdateFacet_402656870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_402656883 = ref object of OpenApiRestCall_402656044
proc url_GetFacet_402656885(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFacet_402656884(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                          ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656892 = header.getOrDefault("x-amz-data-partition")
  valid_402656892 = validateParameter(valid_402656892, JString, required = true,
                                      default = nil)
  if valid_402656892 != nil:
    section.add "x-amz-data-partition", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656893
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

proc call*(call_402656895: Call_GetFacet_402656883; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
                                                                                         ## 
  let valid = call_402656895.validator(path, query, header, formData, body, _)
  let scheme = call_402656895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656895.makeUrl(scheme.get, call_402656895.host, call_402656895.base,
                                   call_402656895.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656895, uri, valid, _)

proc call*(call_402656896: Call_GetFacet_402656883; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   
                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656897 = newJObject()
  if body != nil:
    body_402656897 = body
  result = call_402656896.call(nil, nil, nil, nil, body_402656897)

var getFacet* = Call_GetFacet_402656883(name: "getFacet",
                                        meth: HttpMethod.HttpPost,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_GetFacet_402656884,
                                        base: "/", makeUrl: url_GetFacet_402656885,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_402656898 = ref object of OpenApiRestCall_402656044
proc url_GetLinkAttributes_402656900(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLinkAttributes_402656899(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves attributes that are associated with a typed link.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see <a>arns</a> or <a 
                                ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed 
                                ## Links</a>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656907 = header.getOrDefault("x-amz-data-partition")
  valid_402656907 = validateParameter(valid_402656907, JString, required = true,
                                      default = nil)
  if valid_402656907 != nil:
    section.add "x-amz-data-partition", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656908
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

proc call*(call_402656910: Call_GetLinkAttributes_402656898;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes that are associated with a typed link.
                                                                                         ## 
  let valid = call_402656910.validator(path, query, header, formData, body, _)
  let scheme = call_402656910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656910.makeUrl(scheme.get, call_402656910.host, call_402656910.base,
                                   call_402656910.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656910, uri, valid, _)

proc call*(call_402656911: Call_GetLinkAttributes_402656898; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_402656912 = newJObject()
  if body != nil:
    body_402656912 = body
  result = call_402656911.call(nil, nil, nil, nil, body_402656912)

var getLinkAttributes* = Call_GetLinkAttributes_402656898(
    name: "getLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_402656899, base: "/",
    makeUrl: url_GetLinkAttributes_402656900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_402656913 = ref object of OpenApiRestCall_402656044
proc url_GetObjectAttributes_402656915(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectAttributes_402656914(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves attributes within a facet that are associated with an object.
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
  ##   x-amz-consistency-level: JString
                               ##                          : The consistency level at which to retrieve the attributes on an object.
  ##   
                                                                                                                                    ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                    ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                               ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                     ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                 ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                 ##                       
                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                                                                                 ## Resource 
                                                                                                                                                                                                                                                 ## Name 
                                                                                                                                                                                                                                                 ## (ARN) 
                                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                                 ## is 
                                                                                                                                                                                                                                                 ## associated 
                                                                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                 ## <a>Directory</a> 
                                                                                                                                                                                                                                                 ## where 
                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                 ## object 
                                                                                                                                                                                                                                                 ## resides.
  ##   
                                                                                                                                                                                                                                                            ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656916 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Security-Token", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Signature")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Signature", valid_402656917
  var valid_402656918 = header.getOrDefault("x-amz-consistency-level")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402656918 != nil:
    section.add "x-amz-consistency-level", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Algorithm", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Date")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Date", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Credential")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Credential", valid_402656922
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656923 = header.getOrDefault("x-amz-data-partition")
  valid_402656923 = validateParameter(valid_402656923, JString, required = true,
                                      default = nil)
  if valid_402656923 != nil:
    section.add "x-amz-data-partition", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656924
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

proc call*(call_402656926: Call_GetObjectAttributes_402656913;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
                                                                                         ## 
  let valid = call_402656926.validator(path, query, header, formData, body, _)
  let scheme = call_402656926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656926.makeUrl(scheme.get, call_402656926.host, call_402656926.base,
                                   call_402656926.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656926, uri, valid, _)

proc call*(call_402656927: Call_GetObjectAttributes_402656913; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   
                                                                            ## body: JObject (required)
  var body_402656928 = newJObject()
  if body != nil:
    body_402656928 = body
  result = call_402656927.call(nil, nil, nil, nil, body_402656928)

var getObjectAttributes* = Call_GetObjectAttributes_402656913(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_402656914, base: "/",
    makeUrl: url_GetObjectAttributes_402656915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_402656929 = ref object of OpenApiRestCall_402656044
proc url_GetObjectInformation_402656931(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectInformation_402656930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves metadata about an object.
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
  ##   x-amz-consistency-level: JString
                               ##                          : The consistency level at which to retrieve the object information.
  ##   
                                                                                                                               ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                               ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                          ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                            ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                            ##                       
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                            ## ARN 
                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## directory 
                                                                                                                                                                                                                                            ## being 
                                                                                                                                                                                                                                            ## retrieved.
  ##   
                                                                                                                                                                                                                                                         ## X-Amz-SignedHeaders: JString
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
  var valid_402656934 = header.getOrDefault("x-amz-consistency-level")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402656934 != nil:
    section.add "x-amz-consistency-level", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Algorithm", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Date")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Date", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Credential")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Credential", valid_402656938
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656939 = header.getOrDefault("x-amz-data-partition")
  valid_402656939 = validateParameter(valid_402656939, JString, required = true,
                                      default = nil)
  if valid_402656939 != nil:
    section.add "x-amz-data-partition", valid_402656939
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

proc call*(call_402656942: Call_GetObjectInformation_402656929;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata about an object.
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

proc call*(call_402656943: Call_GetObjectInformation_402656929; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_402656944 = newJObject()
  if body != nil:
    body_402656944 = body
  result = call_402656943.call(nil, nil, nil, nil, body_402656944)

var getObjectInformation* = Call_GetObjectInformation_402656929(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_402656930, base: "/",
    makeUrl: url_GetObjectInformation_402656931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_402656945 = ref object of OpenApiRestCall_402656044
proc url_PutSchemaFromJson_402656947(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSchemaFromJson_402656946(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the schema to update.
  ##   
                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656948 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Security-Token", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Signature")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Signature", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Algorithm", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Date")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Date", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Credential")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Credential", valid_402656953
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656954 = header.getOrDefault("x-amz-data-partition")
  valid_402656954 = validateParameter(valid_402656954, JString, required = true,
                                      default = nil)
  if valid_402656954 != nil:
    section.add "x-amz-data-partition", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656955
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

proc call*(call_402656957: Call_PutSchemaFromJson_402656945;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
                                                                                         ## 
  let valid = call_402656957.validator(path, query, header, formData, body, _)
  let scheme = call_402656957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656957.makeUrl(scheme.get, call_402656957.host, call_402656957.base,
                                   call_402656957.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656957, uri, valid, _)

proc call*(call_402656958: Call_PutSchemaFromJson_402656945; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ##   
                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656959 = newJObject()
  if body != nil:
    body_402656959 = body
  result = call_402656958.call(nil, nil, nil, nil, body_402656959)

var putSchemaFromJson* = Call_PutSchemaFromJson_402656945(
    name: "putSchemaFromJson", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_402656946, base: "/",
    makeUrl: url_PutSchemaFromJson_402656947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_402656960 = ref object of OpenApiRestCall_402656044
proc url_GetSchemaAsJson_402656962(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSchemaAsJson_402656961(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the schema to retrieve.
  ##   
                                                                                             ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656963 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Security-Token", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Signature")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Signature", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Algorithm", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Date")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Date", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Credential")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Credential", valid_402656968
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656969 = header.getOrDefault("x-amz-data-partition")
  valid_402656969 = validateParameter(valid_402656969, JString, required = true,
                                      default = nil)
  if valid_402656969 != nil:
    section.add "x-amz-data-partition", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656971: Call_GetSchemaAsJson_402656960; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
                                                                                         ## 
  let valid = call_402656971.validator(path, query, header, formData, body, _)
  let scheme = call_402656971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656971.makeUrl(scheme.get, call_402656971.host, call_402656971.base,
                                   call_402656971.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656971, uri, valid, _)

proc call*(call_402656972: Call_GetSchemaAsJson_402656960): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  result = call_402656972.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_402656960(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_402656961, base: "/",
    makeUrl: url_GetSchemaAsJson_402656962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_402656973 = ref object of OpenApiRestCall_402656044
proc url_GetTypedLinkFacetInformation_402656975(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTypedLinkFacetInformation_402656974(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656976 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Security-Token", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Signature")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Signature", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Algorithm", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Date")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Date", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Credential")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Credential", valid_402656981
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402656982 = header.getOrDefault("x-amz-data-partition")
  valid_402656982 = validateParameter(valid_402656982, JString, required = true,
                                      default = nil)
  if valid_402656982 != nil:
    section.add "x-amz-data-partition", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656983
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

proc call*(call_402656985: Call_GetTypedLinkFacetInformation_402656973;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402656985.validator(path, query, header, formData, body, _)
  let scheme = call_402656985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656985.makeUrl(scheme.get, call_402656985.host, call_402656985.base,
                                   call_402656985.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656985, uri, valid, _)

proc call*(call_402656986: Call_GetTypedLinkFacetInformation_402656973;
           body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656987 = newJObject()
  if body != nil:
    body_402656987 = body
  result = call_402656986.call(nil, nil, nil, nil, body_402656987)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_402656973(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_402656974, base: "/",
    makeUrl: url_GetTypedLinkFacetInformation_402656975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_402656988 = ref object of OpenApiRestCall_402656044
proc url_ListAppliedSchemaArns_402656990(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAppliedSchemaArns_402656989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656991 = query.getOrDefault("MaxResults")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "MaxResults", valid_402656991
  var valid_402656992 = query.getOrDefault("NextToken")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "NextToken", valid_402656992
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
  var valid_402656993 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Security-Token", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Signature")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Signature", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Algorithm", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Date")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Date", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Credential")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Credential", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656999
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

proc call*(call_402657001: Call_ListAppliedSchemaArns_402656988;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
                                                                                         ## 
  let valid = call_402657001.validator(path, query, header, formData, body, _)
  let scheme = call_402657001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657001.makeUrl(scheme.get, call_402657001.host, call_402657001.base,
                                   call_402657001.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657001, uri, valid, _)

proc call*(call_402657002: Call_ListAppliedSchemaArns_402656988; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   
                                                                                                                        ## MaxResults: string
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  ##   
                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                           ## NextToken: string
                                                                                                                                                           ##            
                                                                                                                                                           ## : 
                                                                                                                                                           ## Pagination 
                                                                                                                                                           ## token
  var query_402657003 = newJObject()
  var body_402657004 = newJObject()
  add(query_402657003, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657004 = body
  add(query_402657003, "NextToken", newJString(NextToken))
  result = call_402657002.call(nil, query_402657003, nil, nil, body_402657004)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_402656988(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_402656989, base: "/",
    makeUrl: url_ListAppliedSchemaArns_402656990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_402657005 = ref object of OpenApiRestCall_402656044
proc url_ListAttachedIndices_402657007(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAttachedIndices_402657006(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists indices attached to the specified object.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657008 = query.getOrDefault("MaxResults")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "MaxResults", valid_402657008
  var valid_402657009 = query.getOrDefault("NextToken")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "NextToken", valid_402657009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : The consistency level to use for this operation.
  ##   
                                                                                                             ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                             ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                        ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                              ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                          ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                          ##                       
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                          ## ARN 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## directory.
  ##   
                                                                                                                                                                                                                                       ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657010 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Security-Token", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Signature")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Signature", valid_402657011
  var valid_402657012 = header.getOrDefault("x-amz-consistency-level")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657012 != nil:
    section.add "x-amz-consistency-level", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Algorithm", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Date")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Date", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Credential")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Credential", valid_402657016
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657017 = header.getOrDefault("x-amz-data-partition")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true,
                                      default = nil)
  if valid_402657017 != nil:
    section.add "x-amz-data-partition", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
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

proc call*(call_402657020: Call_ListAttachedIndices_402657005;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists indices attached to the specified object.
                                                                                         ## 
  let valid = call_402657020.validator(path, query, header, formData, body, _)
  let scheme = call_402657020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657020.makeUrl(scheme.get, call_402657020.host, call_402657020.base,
                                   call_402657020.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657020, uri, valid, _)

proc call*(call_402657021: Call_ListAttachedIndices_402657005; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   MaxResults: string
                                                    ##             : Pagination limit
  ##   
                                                                                     ## body: JObject (required)
  ##   
                                                                                                                ## NextToken: string
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## token
  var query_402657022 = newJObject()
  var body_402657023 = newJObject()
  add(query_402657022, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657023 = body
  add(query_402657022, "NextToken", newJString(NextToken))
  result = call_402657021.call(nil, query_402657022, nil, nil, body_402657023)

var listAttachedIndices* = Call_ListAttachedIndices_402657005(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_402657006, base: "/",
    makeUrl: url_ListAttachedIndices_402657007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_402657024 = ref object of OpenApiRestCall_402656044
proc url_ListDevelopmentSchemaArns_402657026(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevelopmentSchemaArns_402657025(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657027 = query.getOrDefault("MaxResults")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "MaxResults", valid_402657027
  var valid_402657028 = query.getOrDefault("NextToken")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "NextToken", valid_402657028
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
  var valid_402657029 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Security-Token", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Signature")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Signature", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Algorithm", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Date")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Date", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Credential")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Credential", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657035
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

proc call*(call_402657037: Call_ListDevelopmentSchemaArns_402657024;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
                                                                                         ## 
  let valid = call_402657037.validator(path, query, header, formData, body, _)
  let scheme = call_402657037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657037.makeUrl(scheme.get, call_402657037.host, call_402657037.base,
                                   call_402657037.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657037, uri, valid, _)

proc call*(call_402657038: Call_ListDevelopmentSchemaArns_402657024;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   
                                                                                   ## MaxResults: string
                                                                                   ##             
                                                                                   ## : 
                                                                                   ## Pagination 
                                                                                   ## limit
  ##   
                                                                                           ## body: JObject (required)
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## token
  var query_402657039 = newJObject()
  var body_402657040 = newJObject()
  add(query_402657039, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657040 = body
  add(query_402657039, "NextToken", newJString(NextToken))
  result = call_402657038.call(nil, query_402657039, nil, nil, body_402657040)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_402657024(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_402657025, base: "/",
    makeUrl: url_ListDevelopmentSchemaArns_402657026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_402657041 = ref object of OpenApiRestCall_402656044
proc url_ListDirectories_402657043(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDirectories_402657042(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists directories created within an account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657044 = query.getOrDefault("MaxResults")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "MaxResults", valid_402657044
  var valid_402657045 = query.getOrDefault("NextToken")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "NextToken", valid_402657045
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
  var valid_402657046 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Security-Token", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Signature")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Signature", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Algorithm", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Date")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Date", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Credential")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Credential", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657052
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

proc call*(call_402657054: Call_ListDirectories_402657041; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists directories created within an account.
                                                                                         ## 
  let valid = call_402657054.validator(path, query, header, formData, body, _)
  let scheme = call_402657054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657054.makeUrl(scheme.get, call_402657054.host, call_402657054.base,
                                   call_402657054.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657054, uri, valid, _)

proc call*(call_402657055: Call_ListDirectories_402657041; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   MaxResults: string
                                                 ##             : Pagination limit
  ##   
                                                                                  ## body: JObject (required)
  ##   
                                                                                                             ## NextToken: string
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## token
  var query_402657056 = newJObject()
  var body_402657057 = newJObject()
  add(query_402657056, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657057 = body
  add(query_402657056, "NextToken", newJString(NextToken))
  result = call_402657055.call(nil, query_402657056, nil, nil, body_402657057)

var listDirectories* = Call_ListDirectories_402657041(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_402657042, base: "/",
    makeUrl: url_ListDirectories_402657043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_402657058 = ref object of OpenApiRestCall_402656044
proc url_ListFacetAttributes_402657060(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetAttributes_402657059(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves attributes attached to the facet.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657061 = query.getOrDefault("MaxResults")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "MaxResults", valid_402657061
  var valid_402657062 = query.getOrDefault("NextToken")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "NextToken", valid_402657062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the schema where the facet resides.
  ##   
                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657063 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Security-Token", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Signature")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Signature", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Algorithm", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Date")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Date", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Credential")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Credential", valid_402657068
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657069 = header.getOrDefault("x-amz-data-partition")
  valid_402657069 = validateParameter(valid_402657069, JString, required = true,
                                      default = nil)
  if valid_402657069 != nil:
    section.add "x-amz-data-partition", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657070
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

proc call*(call_402657072: Call_ListFacetAttributes_402657058;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes attached to the facet.
                                                                                         ## 
  let valid = call_402657072.validator(path, query, header, formData, body, _)
  let scheme = call_402657072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657072.makeUrl(scheme.get, call_402657072.host, call_402657072.base,
                                   call_402657072.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657072, uri, valid, _)

proc call*(call_402657073: Call_ListFacetAttributes_402657058; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   MaxResults: string
                                                ##             : Pagination limit
  ##   
                                                                                 ## body: JObject (required)
  ##   
                                                                                                            ## NextToken: string
                                                                                                            ##            
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## token
  var query_402657074 = newJObject()
  var body_402657075 = newJObject()
  add(query_402657074, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657075 = body
  add(query_402657074, "NextToken", newJString(NextToken))
  result = call_402657073.call(nil, query_402657074, nil, nil, body_402657075)

var listFacetAttributes* = Call_ListFacetAttributes_402657058(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_402657059, base: "/",
    makeUrl: url_ListFacetAttributes_402657060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_402657076 = ref object of OpenApiRestCall_402656044
proc url_ListFacetNames_402657078(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetNames_402657077(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the names of facets that exist in a schema.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657079 = query.getOrDefault("MaxResults")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "MaxResults", valid_402657079
  var valid_402657080 = query.getOrDefault("NextToken")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "NextToken", valid_402657080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) to retrieve facet names from.
  ##   
                                                                                                                       ## X-Amz-SignedHeaders: JString
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
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657087 = header.getOrDefault("x-amz-data-partition")
  valid_402657087 = validateParameter(valid_402657087, JString, required = true,
                                      default = nil)
  if valid_402657087 != nil:
    section.add "x-amz-data-partition", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657088
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

proc call*(call_402657090: Call_ListFacetNames_402657076; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the names of facets that exist in a schema.
                                                                                         ## 
  let valid = call_402657090.validator(path, query, header, formData, body, _)
  let scheme = call_402657090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657090.makeUrl(scheme.get, call_402657090.host, call_402657090.base,
                                   call_402657090.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657090, uri, valid, _)

proc call*(call_402657091: Call_ListFacetNames_402657076; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   MaxResults: string
                                                          ##             : Pagination limit
  ##   
                                                                                           ## body: JObject (required)
  ##   
                                                                                                                      ## NextToken: string
                                                                                                                      ##            
                                                                                                                      ## : 
                                                                                                                      ## Pagination 
                                                                                                                      ## token
  var query_402657092 = newJObject()
  var body_402657093 = newJObject()
  add(query_402657092, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657093 = body
  add(query_402657092, "NextToken", newJString(NextToken))
  result = call_402657091.call(nil, query_402657092, nil, nil, body_402657093)

var listFacetNames* = Call_ListFacetNames_402657076(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_402657077, base: "/",
    makeUrl: url_ListFacetNames_402657078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_402657094 = ref object of OpenApiRestCall_402656044
proc url_ListIncomingTypedLinks_402657096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIncomingTypedLinks_402657095(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ##   
                                                                                                                                                  ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657097 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Security-Token", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Signature")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Signature", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Algorithm", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Date")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Date", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Credential")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Credential", valid_402657102
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657103 = header.getOrDefault("x-amz-data-partition")
  valid_402657103 = validateParameter(valid_402657103, JString, required = true,
                                      default = nil)
  if valid_402657103 != nil:
    section.add "x-amz-data-partition", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657104
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

proc call*(call_402657106: Call_ListIncomingTypedLinks_402657094;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402657106.validator(path, query, header, formData, body, _)
  let scheme = call_402657106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657106.makeUrl(scheme.get, call_402657106.host, call_402657106.base,
                                   call_402657106.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657106, uri, valid, _)

proc call*(call_402657107: Call_ListIncomingTypedLinks_402657094; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657108 = newJObject()
  if body != nil:
    body_402657108 = body
  result = call_402657107.call(nil, nil, nil, nil, body_402657108)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_402657094(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_402657095, base: "/",
    makeUrl: url_ListIncomingTypedLinks_402657096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_402657109 = ref object of OpenApiRestCall_402656044
proc url_ListIndex_402657111(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIndex_402657110(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists objects attached to the specified index.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657112 = query.getOrDefault("MaxResults")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "MaxResults", valid_402657112
  var valid_402657113 = query.getOrDefault("NextToken")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "NextToken", valid_402657113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : The consistency level to execute the request at.
  ##   
                                                                                                             ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                             ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                        ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                              ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                          ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                          ##                       
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                          ## ARN 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## directory 
                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## index 
                                                                                                                                                                                                                          ## exists 
                                                                                                                                                                                                                          ## in.
  ##   
                                                                                                                                                                                                                                ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657114 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Security-Token", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Signature")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Signature", valid_402657115
  var valid_402657116 = header.getOrDefault("x-amz-consistency-level")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657116 != nil:
    section.add "x-amz-consistency-level", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Algorithm", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Date")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Date", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-Credential")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-Credential", valid_402657120
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657121 = header.getOrDefault("x-amz-data-partition")
  valid_402657121 = validateParameter(valid_402657121, JString, required = true,
                                      default = nil)
  if valid_402657121 != nil:
    section.add "x-amz-data-partition", valid_402657121
  var valid_402657122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657122
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

proc call*(call_402657124: Call_ListIndex_402657109; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists objects attached to the specified index.
                                                                                         ## 
  let valid = call_402657124.validator(path, query, header, formData, body, _)
  let scheme = call_402657124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657124.makeUrl(scheme.get, call_402657124.host, call_402657124.base,
                                   call_402657124.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657124, uri, valid, _)

proc call*(call_402657125: Call_ListIndex_402657109; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   MaxResults: string
                                                   ##             : Pagination limit
  ##   
                                                                                    ## body: JObject (required)
  ##   
                                                                                                               ## NextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## token
  var query_402657126 = newJObject()
  var body_402657127 = newJObject()
  add(query_402657126, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657127 = body
  add(query_402657126, "NextToken", newJString(NextToken))
  result = call_402657125.call(nil, query_402657126, nil, nil, body_402657127)

var listIndex* = Call_ListIndex_402657109(name: "listIndex",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
    validator: validate_ListIndex_402657110, base: "/", makeUrl: url_ListIndex_402657111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListManagedSchemaArns_402657128 = ref object of OpenApiRestCall_402656044
proc url_ListManagedSchemaArns_402657130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListManagedSchemaArns_402657129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657131 = query.getOrDefault("MaxResults")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "MaxResults", valid_402657131
  var valid_402657132 = query.getOrDefault("NextToken")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "NextToken", valid_402657132
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
  var valid_402657133 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Security-Token", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Signature")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Signature", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Algorithm", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Date")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Date", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Credential")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Credential", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657139
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

proc call*(call_402657141: Call_ListManagedSchemaArns_402657128;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
                                                                                         ## 
  let valid = call_402657141.validator(path, query, header, formData, body, _)
  let scheme = call_402657141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657141.makeUrl(scheme.get, call_402657141.host, call_402657141.base,
                                   call_402657141.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657141, uri, valid, _)

proc call*(call_402657142: Call_ListManagedSchemaArns_402657128; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listManagedSchemaArns
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ##   
                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                             ##             
                                                                                                                                                                             ## : 
                                                                                                                                                                             ## Pagination 
                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## token
  var query_402657143 = newJObject()
  var body_402657144 = newJObject()
  add(query_402657143, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657144 = body
  add(query_402657143, "NextToken", newJString(NextToken))
  result = call_402657142.call(nil, query_402657143, nil, nil, body_402657144)

var listManagedSchemaArns* = Call_ListManagedSchemaArns_402657128(
    name: "listManagedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/managed",
    validator: validate_ListManagedSchemaArns_402657129, base: "/",
    makeUrl: url_ListManagedSchemaArns_402657130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_402657145 = ref object of OpenApiRestCall_402656044
proc url_ListObjectAttributes_402657147(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectAttributes_402657146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all attributes that are associated with an object. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657148 = query.getOrDefault("MaxResults")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "MaxResults", valid_402657148
  var valid_402657149 = query.getOrDefault("NextToken")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "NextToken", valid_402657149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a> 
                                                                                                                                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## object 
                                                                                                                                                                                                                                                                                                                                ## resides. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657150 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Security-Token", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Signature")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Signature", valid_402657151
  var valid_402657152 = header.getOrDefault("x-amz-consistency-level")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657152 != nil:
    section.add "x-amz-consistency-level", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Algorithm", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Date")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Date", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Credential")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Credential", valid_402657156
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657157 = header.getOrDefault("x-amz-data-partition")
  valid_402657157 = validateParameter(valid_402657157, JString, required = true,
                                      default = nil)
  if valid_402657157 != nil:
    section.add "x-amz-data-partition", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657158
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

proc call*(call_402657160: Call_ListObjectAttributes_402657145;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all attributes that are associated with an object. 
                                                                                         ## 
  let valid = call_402657160.validator(path, query, header, formData, body, _)
  let scheme = call_402657160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657160.makeUrl(scheme.get, call_402657160.host, call_402657160.base,
                                   call_402657160.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657160, uri, valid, _)

proc call*(call_402657161: Call_ListObjectAttributes_402657145; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   MaxResults: string
                                                              ##             : Pagination limit
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## NextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  var query_402657162 = newJObject()
  var body_402657163 = newJObject()
  add(query_402657162, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657163 = body
  add(query_402657162, "NextToken", newJString(NextToken))
  result = call_402657161.call(nil, query_402657162, nil, nil, body_402657163)

var listObjectAttributes* = Call_ListObjectAttributes_402657145(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_402657146, base: "/",
    makeUrl: url_ListObjectAttributes_402657147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_402657164 = ref object of OpenApiRestCall_402656044
proc url_ListObjectChildren_402657166(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectChildren_402657165(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of child objects that are associated with a given object.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657167 = query.getOrDefault("MaxResults")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "MaxResults", valid_402657167
  var valid_402657168 = query.getOrDefault("NextToken")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "NextToken", valid_402657168
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a> 
                                                                                                                                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## object 
                                                                                                                                                                                                                                                                                                                                ## resides. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657169 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Security-Token", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Signature")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Signature", valid_402657170
  var valid_402657171 = header.getOrDefault("x-amz-consistency-level")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657171 != nil:
    section.add "x-amz-consistency-level", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Algorithm", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Date")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Date", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Credential")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Credential", valid_402657175
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657176 = header.getOrDefault("x-amz-data-partition")
  valid_402657176 = validateParameter(valid_402657176, JString, required = true,
                                      default = nil)
  if valid_402657176 != nil:
    section.add "x-amz-data-partition", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657177
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

proc call*(call_402657179: Call_ListObjectChildren_402657164;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
                                                                                         ## 
  let valid = call_402657179.validator(path, query, header, formData, body, _)
  let scheme = call_402657179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657179.makeUrl(scheme.get, call_402657179.host, call_402657179.base,
                                   call_402657179.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657179, uri, valid, _)

proc call*(call_402657180: Call_ListObjectChildren_402657164; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   
                                                                                       ## MaxResults: string
                                                                                       ##             
                                                                                       ## : 
                                                                                       ## Pagination 
                                                                                       ## limit
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## NextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  var query_402657181 = newJObject()
  var body_402657182 = newJObject()
  add(query_402657181, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657182 = body
  add(query_402657181, "NextToken", newJString(NextToken))
  result = call_402657180.call(nil, query_402657181, nil, nil, body_402657182)

var listObjectChildren* = Call_ListObjectChildren_402657164(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_402657165, base: "/",
    makeUrl: url_ListObjectChildren_402657166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_402657183 = ref object of OpenApiRestCall_402656044
proc url_ListObjectParentPaths_402657185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParentPaths_402657184(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657186 = query.getOrDefault("MaxResults")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "MaxResults", valid_402657186
  var valid_402657187 = query.getOrDefault("NextToken")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "NextToken", valid_402657187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory to which the parent path applies.
  ##   
                                                                                                                     ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657188 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Security-Token", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Signature")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Signature", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Algorithm", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Date")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Date", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Credential")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Credential", valid_402657193
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657194 = header.getOrDefault("x-amz-data-partition")
  valid_402657194 = validateParameter(valid_402657194, JString, required = true,
                                      default = nil)
  if valid_402657194 != nil:
    section.add "x-amz-data-partition", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657195
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

proc call*(call_402657197: Call_ListObjectParentPaths_402657183;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
                                                                                         ## 
  let valid = call_402657197.validator(path, query, header, formData, body, _)
  let scheme = call_402657197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657197.makeUrl(scheme.get, call_402657197.host, call_402657197.base,
                                   call_402657197.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657197, uri, valid, _)

proc call*(call_402657198: Call_ListObjectParentPaths_402657183; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token
  var query_402657199 = newJObject()
  var body_402657200 = newJObject()
  add(query_402657199, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657200 = body
  add(query_402657199, "NextToken", newJString(NextToken))
  result = call_402657198.call(nil, query_402657199, nil, nil, body_402657200)

var listObjectParentPaths* = Call_ListObjectParentPaths_402657183(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_402657184, base: "/",
    makeUrl: url_ListObjectParentPaths_402657185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_402657201 = ref object of OpenApiRestCall_402656044
proc url_ListObjectParents_402657203(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParents_402657202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists parent objects that are associated with a given object in pagination fashion.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657204 = query.getOrDefault("MaxResults")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "MaxResults", valid_402657204
  var valid_402657205 = query.getOrDefault("NextToken")
  valid_402657205 = validateParameter(valid_402657205, JString,
                                      required = false, default = nil)
  if valid_402657205 != nil:
    section.add "NextToken", valid_402657205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a> 
                                                                                                                                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## object 
                                                                                                                                                                                                                                                                                                                                ## resides. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657206 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Security-Token", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-Signature")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-Signature", valid_402657207
  var valid_402657208 = header.getOrDefault("x-amz-consistency-level")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657208 != nil:
    section.add "x-amz-consistency-level", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-Algorithm", valid_402657210
  var valid_402657211 = header.getOrDefault("X-Amz-Date")
  valid_402657211 = validateParameter(valid_402657211, JString,
                                      required = false, default = nil)
  if valid_402657211 != nil:
    section.add "X-Amz-Date", valid_402657211
  var valid_402657212 = header.getOrDefault("X-Amz-Credential")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-Credential", valid_402657212
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657213 = header.getOrDefault("x-amz-data-partition")
  valid_402657213 = validateParameter(valid_402657213, JString, required = true,
                                      default = nil)
  if valid_402657213 != nil:
    section.add "x-amz-data-partition", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657214
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

proc call*(call_402657216: Call_ListObjectParents_402657201;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
                                                                                         ## 
  let valid = call_402657216.validator(path, query, header, formData, body, _)
  let scheme = call_402657216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657216.makeUrl(scheme.get, call_402657216.host, call_402657216.base,
                                   call_402657216.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657216, uri, valid, _)

proc call*(call_402657217: Call_ListObjectParents_402657201; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   
                                                                                        ## MaxResults: string
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## Pagination 
                                                                                        ## limit
  ##   
                                                                                                ## body: JObject (required)
  ##   
                                                                                                                           ## NextToken: string
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  var query_402657218 = newJObject()
  var body_402657219 = newJObject()
  add(query_402657218, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657219 = body
  add(query_402657218, "NextToken", newJString(NextToken))
  result = call_402657217.call(nil, query_402657218, nil, nil, body_402657219)

var listObjectParents* = Call_ListObjectParents_402657201(
    name: "listObjectParents", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_402657202, base: "/",
    makeUrl: url_ListObjectParents_402657203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_402657220 = ref object of OpenApiRestCall_402656044
proc url_ListObjectPolicies_402657222(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectPolicies_402657221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns policies attached to an object in pagination fashion.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657223 = query.getOrDefault("MaxResults")
  valid_402657223 = validateParameter(valid_402657223, JString,
                                      required = false, default = nil)
  if valid_402657223 != nil:
    section.add "MaxResults", valid_402657223
  var valid_402657224 = query.getOrDefault("NextToken")
  valid_402657224 = validateParameter(valid_402657224, JString,
                                      required = false, default = nil)
  if valid_402657224 != nil:
    section.add "NextToken", valid_402657224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a> 
                                                                                                                                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                                                                                                                                ## objects 
                                                                                                                                                                                                                                                                                                                                ## reside. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657225 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "X-Amz-Security-Token", valid_402657225
  var valid_402657226 = header.getOrDefault("X-Amz-Signature")
  valid_402657226 = validateParameter(valid_402657226, JString,
                                      required = false, default = nil)
  if valid_402657226 != nil:
    section.add "X-Amz-Signature", valid_402657226
  var valid_402657227 = header.getOrDefault("x-amz-consistency-level")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657227 != nil:
    section.add "x-amz-consistency-level", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Algorithm", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Date")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Date", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Credential")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Credential", valid_402657231
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657232 = header.getOrDefault("x-amz-data-partition")
  valid_402657232 = validateParameter(valid_402657232, JString, required = true,
                                      default = nil)
  if valid_402657232 != nil:
    section.add "x-amz-data-partition", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657233
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

proc call*(call_402657235: Call_ListObjectPolicies_402657220;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns policies attached to an object in pagination fashion.
                                                                                         ## 
  let valid = call_402657235.validator(path, query, header, formData, body, _)
  let scheme = call_402657235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657235.makeUrl(scheme.get, call_402657235.host, call_402657235.base,
                                   call_402657235.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657235, uri, valid, _)

proc call*(call_402657236: Call_ListObjectPolicies_402657220; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   MaxResults: string
                                                                  ##             : Pagination limit
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  var query_402657237 = newJObject()
  var body_402657238 = newJObject()
  add(query_402657237, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657238 = body
  add(query_402657237, "NextToken", newJString(NextToken))
  result = call_402657236.call(nil, query_402657237, nil, nil, body_402657238)

var listObjectPolicies* = Call_ListObjectPolicies_402657220(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_402657221, base: "/",
    makeUrl: url_ListObjectPolicies_402657222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_402657239 = ref object of OpenApiRestCall_402656044
proc url_ListOutgoingTypedLinks_402657241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutgoingTypedLinks_402657240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ##   
                                                                                                                                                  ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657242 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657242 = validateParameter(valid_402657242, JString,
                                      required = false, default = nil)
  if valid_402657242 != nil:
    section.add "X-Amz-Security-Token", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Signature")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Signature", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Algorithm", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Date")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Date", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Credential")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Credential", valid_402657247
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657248 = header.getOrDefault("x-amz-data-partition")
  valid_402657248 = validateParameter(valid_402657248, JString, required = true,
                                      default = nil)
  if valid_402657248 != nil:
    section.add "x-amz-data-partition", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657249
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

proc call*(call_402657251: Call_ListOutgoingTypedLinks_402657239;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402657251.validator(path, query, header, formData, body, _)
  let scheme = call_402657251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657251.makeUrl(scheme.get, call_402657251.host, call_402657251.base,
                                   call_402657251.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657251, uri, valid, _)

proc call*(call_402657252: Call_ListOutgoingTypedLinks_402657239; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657253 = newJObject()
  if body != nil:
    body_402657253 = body
  result = call_402657252.call(nil, nil, nil, nil, body_402657253)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_402657239(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_402657240, base: "/",
    makeUrl: url_ListOutgoingTypedLinks_402657241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_402657254 = ref object of OpenApiRestCall_402656044
proc url_ListPolicyAttachments_402657256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicyAttachments_402657255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657257 = query.getOrDefault("MaxResults")
  valid_402657257 = validateParameter(valid_402657257, JString,
                                      required = false, default = nil)
  if valid_402657257 != nil:
    section.add "MaxResults", valid_402657257
  var valid_402657258 = query.getOrDefault("NextToken")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "NextToken", valid_402657258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   x-amz-consistency-level: JString
                               ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   
                                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                                ## x-amz-data-partition: JString (required)
                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                ## Resource 
                                                                                                                                                                                                                                                                                                                                ## Name 
                                                                                                                                                                                                                                                                                                                                ## (ARN) 
                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                ## associated 
                                                                                                                                                                                                                                                                                                                                ## with 
                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                ## <a>Directory</a> 
                                                                                                                                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                                                                                                                                ## objects 
                                                                                                                                                                                                                                                                                                                                ## reside. 
                                                                                                                                                                                                                                                                                                                                ## For 
                                                                                                                                                                                                                                                                                                                                ## more 
                                                                                                                                                                                                                                                                                                                                ## information, 
                                                                                                                                                                                                                                                                                                                                ## see 
                                                                                                                                                                                                                                                                                                                                ## <a>arns</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657259 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Security-Token", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Signature")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Signature", valid_402657260
  var valid_402657261 = header.getOrDefault("x-amz-consistency-level")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false,
                                      default = newJString("SERIALIZABLE"))
  if valid_402657261 != nil:
    section.add "x-amz-consistency-level", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Algorithm", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Date")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Date", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Credential")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Credential", valid_402657265
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657266 = header.getOrDefault("x-amz-data-partition")
  valid_402657266 = validateParameter(valid_402657266, JString, required = true,
                                      default = nil)
  if valid_402657266 != nil:
    section.add "x-amz-data-partition", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657267
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

proc call*(call_402657269: Call_ListPolicyAttachments_402657254;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
                                                                                         ## 
  let valid = call_402657269.validator(path, query, header, formData, body, _)
  let scheme = call_402657269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657269.makeUrl(scheme.get, call_402657269.host, call_402657269.base,
                                   call_402657269.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657269, uri, valid, _)

proc call*(call_402657270: Call_ListPolicyAttachments_402657254; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   
                                                                                           ## MaxResults: string
                                                                                           ##             
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## limit
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  var query_402657271 = newJObject()
  var body_402657272 = newJObject()
  add(query_402657271, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657272 = body
  add(query_402657271, "NextToken", newJString(NextToken))
  result = call_402657270.call(nil, query_402657271, nil, nil, body_402657272)

var listPolicyAttachments* = Call_ListPolicyAttachments_402657254(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_402657255, base: "/",
    makeUrl: url_ListPolicyAttachments_402657256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_402657273 = ref object of OpenApiRestCall_402656044
proc url_ListPublishedSchemaArns_402657275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublishedSchemaArns_402657274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657276 = query.getOrDefault("MaxResults")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "MaxResults", valid_402657276
  var valid_402657277 = query.getOrDefault("NextToken")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "NextToken", valid_402657277
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
  var valid_402657278 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Security-Token", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-Signature")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Signature", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Algorithm", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Date")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Date", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-Credential")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-Credential", valid_402657283
  var valid_402657284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657284 = validateParameter(valid_402657284, JString,
                                      required = false, default = nil)
  if valid_402657284 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657284
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

proc call*(call_402657286: Call_ListPublishedSchemaArns_402657273;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
                                                                                         ## 
  let valid = call_402657286.validator(path, query, header, formData, body, _)
  let scheme = call_402657286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657286.makeUrl(scheme.get, call_402657286.host, call_402657286.base,
                                   call_402657286.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657286, uri, valid, _)

proc call*(call_402657287: Call_ListPublishedSchemaArns_402657273;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   
                                                                                                                                                                                            ## MaxResults: string
                                                                                                                                                                                            ##             
                                                                                                                                                                                            ## : 
                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                               ## token
  var query_402657288 = newJObject()
  var body_402657289 = newJObject()
  add(query_402657288, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657289 = body
  add(query_402657288, "NextToken", newJString(NextToken))
  result = call_402657287.call(nil, query_402657288, nil, nil, body_402657289)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_402657273(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_402657274, base: "/",
    makeUrl: url_ListPublishedSchemaArns_402657275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657290 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657292(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402657291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657293 = query.getOrDefault("MaxResults")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "MaxResults", valid_402657293
  var valid_402657294 = query.getOrDefault("NextToken")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "NextToken", valid_402657294
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
  var valid_402657295 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Security-Token", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Signature")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Signature", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Algorithm", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-Date")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-Date", valid_402657299
  var valid_402657300 = header.getOrDefault("X-Amz-Credential")
  valid_402657300 = validateParameter(valid_402657300, JString,
                                      required = false, default = nil)
  if valid_402657300 != nil:
    section.add "X-Amz-Credential", valid_402657300
  var valid_402657301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657301 = validateParameter(valid_402657301, JString,
                                      required = false, default = nil)
  if valid_402657301 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657301
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

proc call*(call_402657303: Call_ListTagsForResource_402657290;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
                                                                                         ## 
  let valid = call_402657303.validator(path, query, header, formData, body, _)
  let scheme = call_402657303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657303.makeUrl(scheme.get, call_402657303.host, call_402657303.base,
                                   call_402657303.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657303, uri, valid, _)

proc call*(call_402657304: Call_ListTagsForResource_402657290; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   
                                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                                               ##             
                                                                                                                                                                                               ## : 
                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                  ## token
  var query_402657305 = newJObject()
  var body_402657306 = newJObject()
  add(query_402657305, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657306 = body
  add(query_402657305, "NextToken", newJString(NextToken))
  result = call_402657304.call(nil, query_402657305, nil, nil, body_402657306)

var listTagsForResource* = Call_ListTagsForResource_402657290(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_402657291, base: "/",
    makeUrl: url_ListTagsForResource_402657292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_402657307 = ref object of OpenApiRestCall_402656044
proc url_ListTypedLinkFacetAttributes_402657309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetAttributes_402657308(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657310 = query.getOrDefault("MaxResults")
  valid_402657310 = validateParameter(valid_402657310, JString,
                                      required = false, default = nil)
  if valid_402657310 != nil:
    section.add "MaxResults", valid_402657310
  var valid_402657311 = query.getOrDefault("NextToken")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "NextToken", valid_402657311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657312 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Security-Token", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-Signature")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-Signature", valid_402657313
  var valid_402657314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657314
  var valid_402657315 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "X-Amz-Algorithm", valid_402657315
  var valid_402657316 = header.getOrDefault("X-Amz-Date")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "X-Amz-Date", valid_402657316
  var valid_402657317 = header.getOrDefault("X-Amz-Credential")
  valid_402657317 = validateParameter(valid_402657317, JString,
                                      required = false, default = nil)
  if valid_402657317 != nil:
    section.add "X-Amz-Credential", valid_402657317
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657318 = header.getOrDefault("x-amz-data-partition")
  valid_402657318 = validateParameter(valid_402657318, JString, required = true,
                                      default = nil)
  if valid_402657318 != nil:
    section.add "x-amz-data-partition", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657319
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

proc call*(call_402657321: Call_ListTypedLinkFacetAttributes_402657307;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402657321.validator(path, query, header, formData, body, _)
  let scheme = call_402657321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657321.makeUrl(scheme.get, call_402657321.host, call_402657321.base,
                                   call_402657321.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657321, uri, valid, _)

proc call*(call_402657322: Call_ListTypedLinkFacetAttributes_402657307;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                                                       ## MaxResults: string
                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                          ## NextToken: string
                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                          ## token
  var query_402657323 = newJObject()
  var body_402657324 = newJObject()
  add(query_402657323, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657324 = body
  add(query_402657323, "NextToken", newJString(NextToken))
  result = call_402657322.call(nil, query_402657323, nil, nil, body_402657324)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_402657307(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_402657308, base: "/",
    makeUrl: url_ListTypedLinkFacetAttributes_402657309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_402657325 = ref object of OpenApiRestCall_402656044
proc url_ListTypedLinkFacetNames_402657327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetNames_402657326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657328 = query.getOrDefault("MaxResults")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "MaxResults", valid_402657328
  var valid_402657329 = query.getOrDefault("NextToken")
  valid_402657329 = validateParameter(valid_402657329, JString,
                                      required = false, default = nil)
  if valid_402657329 != nil:
    section.add "NextToken", valid_402657329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657330 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "X-Amz-Security-Token", valid_402657330
  var valid_402657331 = header.getOrDefault("X-Amz-Signature")
  valid_402657331 = validateParameter(valid_402657331, JString,
                                      required = false, default = nil)
  if valid_402657331 != nil:
    section.add "X-Amz-Signature", valid_402657331
  var valid_402657332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657332 = validateParameter(valid_402657332, JString,
                                      required = false, default = nil)
  if valid_402657332 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Algorithm", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Date")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Date", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Credential")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Credential", valid_402657335
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657336 = header.getOrDefault("x-amz-data-partition")
  valid_402657336 = validateParameter(valid_402657336, JString, required = true,
                                      default = nil)
  if valid_402657336 != nil:
    section.add "x-amz-data-partition", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657337
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

proc call*(call_402657339: Call_ListTypedLinkFacetNames_402657325;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402657339.validator(path, query, header, formData, body, _)
  let scheme = call_402657339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657339.makeUrl(scheme.get, call_402657339.host, call_402657339.base,
                                   call_402657339.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657339, uri, valid, _)

proc call*(call_402657340: Call_ListTypedLinkFacetNames_402657325;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                    ## token
  var query_402657341 = newJObject()
  var body_402657342 = newJObject()
  add(query_402657341, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657342 = body
  add(query_402657341, "NextToken", newJString(NextToken))
  result = call_402657340.call(nil, query_402657341, nil, nil, body_402657342)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_402657325(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_402657326, base: "/",
    makeUrl: url_ListTypedLinkFacetNames_402657327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_402657343 = ref object of OpenApiRestCall_402656044
proc url_LookupPolicy_402657345(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LookupPolicy_402657344(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657346 = query.getOrDefault("MaxResults")
  valid_402657346 = validateParameter(valid_402657346, JString,
                                      required = false, default = nil)
  if valid_402657346 != nil:
    section.add "MaxResults", valid_402657346
  var valid_402657347 = query.getOrDefault("NextToken")
  valid_402657347 = validateParameter(valid_402657347, JString,
                                      required = false, default = nil)
  if valid_402657347 != nil:
    section.add "NextToken", valid_402657347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657348 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-Security-Token", valid_402657348
  var valid_402657349 = header.getOrDefault("X-Amz-Signature")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "X-Amz-Signature", valid_402657349
  var valid_402657350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657350 = validateParameter(valid_402657350, JString,
                                      required = false, default = nil)
  if valid_402657350 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Algorithm", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Date")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Date", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Credential")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Credential", valid_402657353
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657354 = header.getOrDefault("x-amz-data-partition")
  valid_402657354 = validateParameter(valid_402657354, JString, required = true,
                                      default = nil)
  if valid_402657354 != nil:
    section.add "x-amz-data-partition", valid_402657354
  var valid_402657355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657355
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

proc call*(call_402657357: Call_LookupPolicy_402657343; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
                                                                                         ## 
  let valid = call_402657357.validator(path, query, header, formData, body, _)
  let scheme = call_402657357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657357.makeUrl(scheme.get, call_402657357.host, call_402657357.base,
                                   call_402657357.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657357, uri, valid, _)

proc call*(call_402657358: Call_LookupPolicy_402657343; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## token
  var query_402657359 = newJObject()
  var body_402657360 = newJObject()
  add(query_402657359, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657360 = body
  add(query_402657359, "NextToken", newJString(NextToken))
  result = call_402657358.call(nil, query_402657359, nil, nil, body_402657360)

var lookupPolicy* = Call_LookupPolicy_402657343(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_402657344, base: "/",
    makeUrl: url_LookupPolicy_402657345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_402657361 = ref object of OpenApiRestCall_402656044
proc url_PublishSchema_402657363(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PublishSchema_402657362(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Publishes a development schema with a major version and a recommended minor version.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657364 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Security-Token", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Signature")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Signature", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Algorithm", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Date")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Date", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-Credential")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-Credential", valid_402657369
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657370 = header.getOrDefault("x-amz-data-partition")
  valid_402657370 = validateParameter(valid_402657370, JString, required = true,
                                      default = nil)
  if valid_402657370 != nil:
    section.add "x-amz-data-partition", valid_402657370
  var valid_402657371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657371
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

proc call*(call_402657373: Call_PublishSchema_402657361; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
                                                                                         ## 
  let valid = call_402657373.validator(path, query, header, formData, body, _)
  let scheme = call_402657373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657373.makeUrl(scheme.get, call_402657373.host, call_402657373.base,
                                   call_402657373.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657373, uri, valid, _)

proc call*(call_402657374: Call_PublishSchema_402657361; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   
                                                                                         ## body: JObject (required)
  var body_402657375 = newJObject()
  if body != nil:
    body_402657375 = body
  result = call_402657374.call(nil, nil, nil, nil, body_402657375)

var publishSchema* = Call_PublishSchema_402657361(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_402657362, base: "/",
    makeUrl: url_PublishSchema_402657363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_402657376 = ref object of OpenApiRestCall_402656044
proc url_RemoveFacetFromObject_402657378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveFacetFromObject_402657377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the specified facet from the specified object.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The ARN of the directory in which the object resides.
  ##   
                                                                                                                ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657379 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Security-Token", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-Signature")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-Signature", valid_402657380
  var valid_402657381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657381
  var valid_402657382 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "X-Amz-Algorithm", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-Date")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-Date", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-Credential")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-Credential", valid_402657384
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657385 = header.getOrDefault("x-amz-data-partition")
  valid_402657385 = validateParameter(valid_402657385, JString, required = true,
                                      default = nil)
  if valid_402657385 != nil:
    section.add "x-amz-data-partition", valid_402657385
  var valid_402657386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657386
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

proc call*(call_402657388: Call_RemoveFacetFromObject_402657376;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified facet from the specified object.
                                                                                         ## 
  let valid = call_402657388.validator(path, query, header, formData, body, _)
  let scheme = call_402657388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657388.makeUrl(scheme.get, call_402657388.host, call_402657388.base,
                                   call_402657388.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657388, uri, valid, _)

proc call*(call_402657389: Call_RemoveFacetFromObject_402657376; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_402657390 = newJObject()
  if body != nil:
    body_402657390 = body
  result = call_402657389.call(nil, nil, nil, nil, body_402657390)

var removeFacetFromObject* = Call_RemoveFacetFromObject_402657376(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_402657377, base: "/",
    makeUrl: url_RemoveFacetFromObject_402657378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657391 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657393(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657392(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## An API operation for adding tags to a resource.
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
  var valid_402657394 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657394 = validateParameter(valid_402657394, JString,
                                      required = false, default = nil)
  if valid_402657394 != nil:
    section.add "X-Amz-Security-Token", valid_402657394
  var valid_402657395 = header.getOrDefault("X-Amz-Signature")
  valid_402657395 = validateParameter(valid_402657395, JString,
                                      required = false, default = nil)
  if valid_402657395 != nil:
    section.add "X-Amz-Signature", valid_402657395
  var valid_402657396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657396
  var valid_402657397 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657397 = validateParameter(valid_402657397, JString,
                                      required = false, default = nil)
  if valid_402657397 != nil:
    section.add "X-Amz-Algorithm", valid_402657397
  var valid_402657398 = header.getOrDefault("X-Amz-Date")
  valid_402657398 = validateParameter(valid_402657398, JString,
                                      required = false, default = nil)
  if valid_402657398 != nil:
    section.add "X-Amz-Date", valid_402657398
  var valid_402657399 = header.getOrDefault("X-Amz-Credential")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "X-Amz-Credential", valid_402657399
  var valid_402657400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657400
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

proc call*(call_402657402: Call_TagResource_402657391; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An API operation for adding tags to a resource.
                                                                                         ## 
  let valid = call_402657402.validator(path, query, header, formData, body, _)
  let scheme = call_402657402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657402.makeUrl(scheme.get, call_402657402.host, call_402657402.base,
                                   call_402657402.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657402, uri, valid, _)

proc call*(call_402657403: Call_TagResource_402657391; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_402657404 = newJObject()
  if body != nil:
    body_402657404 = body
  result = call_402657403.call(nil, nil, nil, nil, body_402657404)

var tagResource* = Call_TagResource_402657391(name: "tagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/add",
    validator: validate_TagResource_402657392, base: "/",
    makeUrl: url_TagResource_402657393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657405 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657407(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657406(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## An API operation for removing tags from a resource.
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
  var valid_402657408 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Security-Token", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-Signature")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Signature", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657410
  var valid_402657411 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657411 = validateParameter(valid_402657411, JString,
                                      required = false, default = nil)
  if valid_402657411 != nil:
    section.add "X-Amz-Algorithm", valid_402657411
  var valid_402657412 = header.getOrDefault("X-Amz-Date")
  valid_402657412 = validateParameter(valid_402657412, JString,
                                      required = false, default = nil)
  if valid_402657412 != nil:
    section.add "X-Amz-Date", valid_402657412
  var valid_402657413 = header.getOrDefault("X-Amz-Credential")
  valid_402657413 = validateParameter(valid_402657413, JString,
                                      required = false, default = nil)
  if valid_402657413 != nil:
    section.add "X-Amz-Credential", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657414
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

proc call*(call_402657416: Call_UntagResource_402657405; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An API operation for removing tags from a resource.
                                                                                         ## 
  let valid = call_402657416.validator(path, query, header, formData, body, _)
  let scheme = call_402657416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657416.makeUrl(scheme.get, call_402657416.host, call_402657416.base,
                                   call_402657416.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657416, uri, valid, _)

proc call*(call_402657417: Call_UntagResource_402657405; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_402657418 = newJObject()
  if body != nil:
    body_402657418 = body
  result = call_402657417.call(nil, nil, nil, nil, body_402657418)

var untagResource* = Call_UntagResource_402657405(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_402657406, base: "/",
    makeUrl: url_UntagResource_402657407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_402657419 = ref object of OpenApiRestCall_402656044
proc url_UpdateLinkAttributes_402657421(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLinkAttributes_402657420(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see <a>arns</a> or <a 
                                ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed 
                                ## Links</a>.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657422 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Security-Token", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Signature")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Signature", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-Algorithm", valid_402657425
  var valid_402657426 = header.getOrDefault("X-Amz-Date")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "X-Amz-Date", valid_402657426
  var valid_402657427 = header.getOrDefault("X-Amz-Credential")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "X-Amz-Credential", valid_402657427
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657428 = header.getOrDefault("x-amz-data-partition")
  valid_402657428 = validateParameter(valid_402657428, JString, required = true,
                                      default = nil)
  if valid_402657428 != nil:
    section.add "x-amz-data-partition", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657429
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

proc call*(call_402657431: Call_UpdateLinkAttributes_402657419;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
                                                                                         ## 
  let valid = call_402657431.validator(path, query, header, formData, body, _)
  let scheme = call_402657431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657431.makeUrl(scheme.get, call_402657431.host, call_402657431.base,
                                   call_402657431.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657431, uri, valid, _)

proc call*(call_402657432: Call_UpdateLinkAttributes_402657419; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   
                                                                                                                                                                                   ## body: JObject (required)
  var body_402657433 = newJObject()
  if body != nil:
    body_402657433 = body
  result = call_402657432.call(nil, nil, nil, nil, body_402657433)

var updateLinkAttributes* = Call_UpdateLinkAttributes_402657419(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_402657420, base: "/",
    makeUrl: url_UpdateLinkAttributes_402657421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_402657434 = ref object of OpenApiRestCall_402656044
proc url_UpdateObjectAttributes_402657436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateObjectAttributes_402657435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a given object's attributes.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                                                       ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657437 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Security-Token", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Signature")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Signature", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-Algorithm", valid_402657440
  var valid_402657441 = header.getOrDefault("X-Amz-Date")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "X-Amz-Date", valid_402657441
  var valid_402657442 = header.getOrDefault("X-Amz-Credential")
  valid_402657442 = validateParameter(valid_402657442, JString,
                                      required = false, default = nil)
  if valid_402657442 != nil:
    section.add "X-Amz-Credential", valid_402657442
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657443 = header.getOrDefault("x-amz-data-partition")
  valid_402657443 = validateParameter(valid_402657443, JString, required = true,
                                      default = nil)
  if valid_402657443 != nil:
    section.add "x-amz-data-partition", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657444
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

proc call*(call_402657446: Call_UpdateObjectAttributes_402657434;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a given object's attributes.
                                                                                         ## 
  let valid = call_402657446.validator(path, query, header, formData, body, _)
  let scheme = call_402657446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657446.makeUrl(scheme.get, call_402657446.host, call_402657446.base,
                                   call_402657446.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657446, uri, valid, _)

proc call*(call_402657447: Call_UpdateObjectAttributes_402657434; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_402657448 = newJObject()
  if body != nil:
    body_402657448 = body
  result = call_402657447.call(nil, nil, nil, nil, body_402657448)

var updateObjectAttributes* = Call_UpdateObjectAttributes_402657434(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_402657435, base: "/",
    makeUrl: url_UpdateObjectAttributes_402657436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_402657449 = ref object of OpenApiRestCall_402656044
proc url_UpdateSchema_402657451(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSchema_402657450(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the schema name with a new name. Only development schema names can be updated.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657452 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Security-Token", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Signature")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Signature", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657454
  var valid_402657455 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657455 = validateParameter(valid_402657455, JString,
                                      required = false, default = nil)
  if valid_402657455 != nil:
    section.add "X-Amz-Algorithm", valid_402657455
  var valid_402657456 = header.getOrDefault("X-Amz-Date")
  valid_402657456 = validateParameter(valid_402657456, JString,
                                      required = false, default = nil)
  if valid_402657456 != nil:
    section.add "X-Amz-Date", valid_402657456
  var valid_402657457 = header.getOrDefault("X-Amz-Credential")
  valid_402657457 = validateParameter(valid_402657457, JString,
                                      required = false, default = nil)
  if valid_402657457 != nil:
    section.add "X-Amz-Credential", valid_402657457
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657458 = header.getOrDefault("x-amz-data-partition")
  valid_402657458 = validateParameter(valid_402657458, JString, required = true,
                                      default = nil)
  if valid_402657458 != nil:
    section.add "x-amz-data-partition", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657459
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

proc call*(call_402657461: Call_UpdateSchema_402657449; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
                                                                                         ## 
  let valid = call_402657461.validator(path, query, header, formData, body, _)
  let scheme = call_402657461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657461.makeUrl(scheme.get, call_402657461.host, call_402657461.base,
                                   call_402657461.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657461, uri, valid, _)

proc call*(call_402657462: Call_UpdateSchema_402657449; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   
                                                                                           ## body: JObject (required)
  var body_402657463 = newJObject()
  if body != nil:
    body_402657463 = body
  result = call_402657462.call(nil, nil, nil, nil, body_402657463)

var updateSchema* = Call_UpdateSchema_402657449(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_402657450, base: "/",
    makeUrl: url_UpdateSchema_402657451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_402657464 = ref object of OpenApiRestCall_402656044
proc url_UpdateTypedLinkFacet_402657466(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTypedLinkFacet_402657465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
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
  ##   x-amz-data-partition: JString (required)
                                ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   
                                                                                                                                                                    ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657467 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Security-Token", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Signature")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Signature", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657469
  var valid_402657470 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "X-Amz-Algorithm", valid_402657470
  var valid_402657471 = header.getOrDefault("X-Amz-Date")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "X-Amz-Date", valid_402657471
  var valid_402657472 = header.getOrDefault("X-Amz-Credential")
  valid_402657472 = validateParameter(valid_402657472, JString,
                                      required = false, default = nil)
  if valid_402657472 != nil:
    section.add "X-Amz-Credential", valid_402657472
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_402657473 = header.getOrDefault("x-amz-data-partition")
  valid_402657473 = validateParameter(valid_402657473, JString, required = true,
                                      default = nil)
  if valid_402657473 != nil:
    section.add "x-amz-data-partition", valid_402657473
  var valid_402657474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657474
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

proc call*(call_402657476: Call_UpdateTypedLinkFacet_402657464;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
                                                                                         ## 
  let valid = call_402657476.validator(path, query, header, formData, body, _)
  let scheme = call_402657476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657476.makeUrl(scheme.get, call_402657476.host, call_402657476.base,
                                   call_402657476.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657476, uri, valid, _)

proc call*(call_402657477: Call_UpdateTypedLinkFacet_402657464; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   
                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402657478 = newJObject()
  if body != nil:
    body_402657478 = body
  result = call_402657477.call(nil, nil, nil, nil, body_402657478)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_402657464(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_402657465, base: "/",
    makeUrl: url_UpdateTypedLinkFacet_402657466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_402657479 = ref object of OpenApiRestCall_402656044
proc url_UpgradeAppliedSchema_402657481(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeAppliedSchema_402657480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
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
  var valid_402657482 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "X-Amz-Security-Token", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Signature")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Signature", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657484
  var valid_402657485 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "X-Amz-Algorithm", valid_402657485
  var valid_402657486 = header.getOrDefault("X-Amz-Date")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Date", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Credential")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Credential", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657488
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

proc call*(call_402657490: Call_UpgradeAppliedSchema_402657479;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
                                                                                         ## 
  let valid = call_402657490.validator(path, query, header, formData, body, _)
  let scheme = call_402657490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657490.makeUrl(scheme.get, call_402657490.host, call_402657490.base,
                                   call_402657490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657490, uri, valid, _)

proc call*(call_402657491: Call_UpgradeAppliedSchema_402657479; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657492 = newJObject()
  if body != nil:
    body_402657492 = body
  result = call_402657491.call(nil, nil, nil, nil, body_402657492)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_402657479(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_402657480, base: "/",
    makeUrl: url_UpgradeAppliedSchema_402657481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_402657493 = ref object of OpenApiRestCall_402656044
proc url_UpgradePublishedSchema_402657495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradePublishedSchema_402657494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
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
  var valid_402657496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657496 = validateParameter(valid_402657496, JString,
                                      required = false, default = nil)
  if valid_402657496 != nil:
    section.add "X-Amz-Security-Token", valid_402657496
  var valid_402657497 = header.getOrDefault("X-Amz-Signature")
  valid_402657497 = validateParameter(valid_402657497, JString,
                                      required = false, default = nil)
  if valid_402657497 != nil:
    section.add "X-Amz-Signature", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-Algorithm", valid_402657499
  var valid_402657500 = header.getOrDefault("X-Amz-Date")
  valid_402657500 = validateParameter(valid_402657500, JString,
                                      required = false, default = nil)
  if valid_402657500 != nil:
    section.add "X-Amz-Date", valid_402657500
  var valid_402657501 = header.getOrDefault("X-Amz-Credential")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Credential", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657502
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

proc call*(call_402657504: Call_UpgradePublishedSchema_402657493;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
                                                                                         ## 
  let valid = call_402657504.validator(path, query, header, formData, body, _)
  let scheme = call_402657504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657504.makeUrl(scheme.get, call_402657504.host, call_402657504.base,
                                   call_402657504.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657504, uri, valid, _)

proc call*(call_402657505: Call_UpgradePublishedSchema_402657493; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   
                                                                                                                                    ## body: JObject (required)
  var body_402657506 = newJObject()
  if body != nil:
    body_402657506 = body
  result = call_402657505.call(nil, nil, nil, nil, body_402657506)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_402657493(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_402657494, base: "/",
    makeUrl: url_UpgradePublishedSchema_402657495,
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