
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "clouddirectory.ap-northeast-1.amazonaws.com", "ap-southeast-1": "clouddirectory.ap-southeast-1.amazonaws.com", "us-west-2": "clouddirectory.us-west-2.amazonaws.com", "eu-west-2": "clouddirectory.eu-west-2.amazonaws.com", "ap-northeast-3": "clouddirectory.ap-northeast-3.amazonaws.com", "eu-central-1": "clouddirectory.eu-central-1.amazonaws.com", "us-east-2": "clouddirectory.us-east-2.amazonaws.com", "us-east-1": "clouddirectory.us-east-1.amazonaws.com", "cn-northwest-1": "clouddirectory.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "clouddirectory.ap-south-1.amazonaws.com", "eu-north-1": "clouddirectory.eu-north-1.amazonaws.com", "ap-northeast-2": "clouddirectory.ap-northeast-2.amazonaws.com", "us-west-1": "clouddirectory.us-west-1.amazonaws.com", "us-gov-east-1": "clouddirectory.us-gov-east-1.amazonaws.com", "eu-west-3": "clouddirectory.eu-west-3.amazonaws.com", "cn-north-1": "clouddirectory.cn-north-1.amazonaws.com.cn", "sa-east-1": "clouddirectory.sa-east-1.amazonaws.com", "eu-west-1": "clouddirectory.eu-west-1.amazonaws.com", "us-gov-west-1": "clouddirectory.us-gov-west-1.amazonaws.com", "ap-southeast-2": "clouddirectory.ap-southeast-2.amazonaws.com", "ca-central-1": "clouddirectory.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddFacetToObject_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddFacetToObject_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddFacetToObject_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Algorithm", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Signature")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Signature", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Credential")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Credential", valid_21625888
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21625889 = header.getOrDefault("x-amz-data-partition")
  valid_21625889 = validateParameter(valid_21625889, JString, required = true,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "x-amz-data-partition", valid_21625889
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

proc call*(call_21625915: Call_AddFacetToObject_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_AddFacetToObject_21625779; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_21625979 = newJObject()
  if body != nil:
    body_21625979 = body
  result = call_21625978.call(nil, nil, nil, nil, body_21625979)

var addFacetToObject* = Call_AddFacetToObject_21625779(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_21625780, base: "/",
    makeUrl: url_AddFacetToObject_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_21626015 = ref object of OpenApiRestCall_21625435
proc url_ApplySchema_21626017(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApplySchema_21626016(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> into which the schema is copied. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626018 = header.getOrDefault("X-Amz-Date")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Date", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Security-Token", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Algorithm", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-Signature")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Signature", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Credential")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Credential", valid_21626024
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626025 = header.getOrDefault("x-amz-data-partition")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "x-amz-data-partition", valid_21626025
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

proc call*(call_21626027: Call_ApplySchema_21626015; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_21626027.validator(path, query, header, formData, body, _)
  let scheme = call_21626027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626027.makeUrl(scheme.get, call_21626027.host, call_21626027.base,
                               call_21626027.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626027, uri, valid, _)

proc call*(call_21626028: Call_ApplySchema_21626015; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_21626029 = newJObject()
  if body != nil:
    body_21626029 = body
  result = call_21626028.call(nil, nil, nil, nil, body_21626029)

var applySchema* = Call_ApplySchema_21626015(name: "applySchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
    validator: validate_ApplySchema_21626016, base: "/", makeUrl: url_ApplySchema_21626017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_21626030 = ref object of OpenApiRestCall_21625435
proc url_AttachObject_21626032(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachObject_21626031(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626033 = header.getOrDefault("X-Amz-Date")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Date", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Security-Token", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626040 = header.getOrDefault("x-amz-data-partition")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "x-amz-data-partition", valid_21626040
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

proc call*(call_21626042: Call_AttachObject_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_21626042.validator(path, query, header, formData, body, _)
  let scheme = call_21626042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626042.makeUrl(scheme.get, call_21626042.host, call_21626042.base,
                               call_21626042.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626042, uri, valid, _)

proc call*(call_21626043: Call_AttachObject_21626030; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_21626044 = newJObject()
  if body != nil:
    body_21626044 = body
  result = call_21626043.call(nil, nil, nil, nil, body_21626044)

var attachObject* = Call_AttachObject_21626030(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_21626031, base: "/", makeUrl: url_AttachObject_21626032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_21626045 = ref object of OpenApiRestCall_21625435
proc url_AttachPolicy_21626047(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachPolicy_21626046(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626048 = header.getOrDefault("X-Amz-Date")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Date", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Security-Token", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626055 = header.getOrDefault("x-amz-data-partition")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "x-amz-data-partition", valid_21626055
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

proc call*(call_21626057: Call_AttachPolicy_21626045; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_21626057.validator(path, query, header, formData, body, _)
  let scheme = call_21626057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626057.makeUrl(scheme.get, call_21626057.host, call_21626057.base,
                               call_21626057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626057, uri, valid, _)

proc call*(call_21626058: Call_AttachPolicy_21626045; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_21626059 = newJObject()
  if body != nil:
    body_21626059 = body
  result = call_21626058.call(nil, nil, nil, nil, body_21626059)

var attachPolicy* = Call_AttachPolicy_21626045(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_21626046, base: "/", makeUrl: url_AttachPolicy_21626047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_21626060 = ref object of OpenApiRestCall_21625435
proc url_AttachToIndex_21626062(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachToIndex_21626061(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Attaches the specified object to the specified index.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where the object and index exist.
  section = newJObject()
  var valid_21626063 = header.getOrDefault("X-Amz-Date")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Date", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Security-Token", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626070 = header.getOrDefault("x-amz-data-partition")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "x-amz-data-partition", valid_21626070
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

proc call*(call_21626072: Call_AttachToIndex_21626060; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_21626072.validator(path, query, header, formData, body, _)
  let scheme = call_21626072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626072.makeUrl(scheme.get, call_21626072.host, call_21626072.base,
                               call_21626072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626072, uri, valid, _)

proc call*(call_21626073: Call_AttachToIndex_21626060; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_21626074 = newJObject()
  if body != nil:
    body_21626074 = body
  result = call_21626073.call(nil, nil, nil, nil, body_21626074)

var attachToIndex* = Call_AttachToIndex_21626060(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_21626061, base: "/",
    makeUrl: url_AttachToIndex_21626062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_21626075 = ref object of OpenApiRestCall_21625435
proc url_AttachTypedLink_21626077(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachTypedLink_21626076(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to attach the typed link.
  section = newJObject()
  var valid_21626078 = header.getOrDefault("X-Amz-Date")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Date", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Security-Token", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626085 = header.getOrDefault("x-amz-data-partition")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "x-amz-data-partition", valid_21626085
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

proc call*(call_21626087: Call_AttachTypedLink_21626075; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626087.validator(path, query, header, formData, body, _)
  let scheme = call_21626087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626087.makeUrl(scheme.get, call_21626087.host, call_21626087.base,
                               call_21626087.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626087, uri, valid, _)

proc call*(call_21626088: Call_AttachTypedLink_21626075; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626089 = newJObject()
  if body != nil:
    body_21626089 = body
  result = call_21626088.call(nil, nil, nil, nil, body_21626089)

var attachTypedLink* = Call_AttachTypedLink_21626075(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_21626076, base: "/",
    makeUrl: url_AttachTypedLink_21626077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_21626090 = ref object of OpenApiRestCall_21625435
proc url_BatchRead_21626092(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchRead_21626091(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626093 = header.getOrDefault("X-Amz-Date")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Date", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Security-Token", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626113 = header.getOrDefault("x-amz-consistency-level")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626113 != nil:
    section.add "x-amz-consistency-level", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626115 = header.getOrDefault("x-amz-data-partition")
  valid_21626115 = validateParameter(valid_21626115, JString, required = true,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "x-amz-data-partition", valid_21626115
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

proc call*(call_21626117: Call_BatchRead_21626090; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_21626117.validator(path, query, header, formData, body, _)
  let scheme = call_21626117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626117.makeUrl(scheme.get, call_21626117.host, call_21626117.base,
                               call_21626117.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626117, uri, valid, _)

proc call*(call_21626118: Call_BatchRead_21626090; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_21626119 = newJObject()
  if body != nil:
    body_21626119 = body
  result = call_21626118.call(nil, nil, nil, nil, body_21626119)

var batchRead* = Call_BatchRead_21626090(name: "batchRead",
                                      meth: HttpMethod.HttpPost,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                      validator: validate_BatchRead_21626091,
                                      base: "/", makeUrl: url_BatchRead_21626092,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_21626120 = ref object of OpenApiRestCall_21625435
proc url_BatchWrite_21626122(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWrite_21626121(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626123 = header.getOrDefault("X-Amz-Date")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Date", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Security-Token", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626130 = header.getOrDefault("x-amz-data-partition")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "x-amz-data-partition", valid_21626130
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

proc call*(call_21626132: Call_BatchWrite_21626120; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_21626132.validator(path, query, header, formData, body, _)
  let scheme = call_21626132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626132.makeUrl(scheme.get, call_21626132.host, call_21626132.base,
                               call_21626132.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626132, uri, valid, _)

proc call*(call_21626133: Call_BatchWrite_21626120; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_21626134 = newJObject()
  if body != nil:
    body_21626134 = body
  result = call_21626133.call(nil, nil, nil, nil, body_21626134)

var batchWrite* = Call_BatchWrite_21626120(name: "batchWrite",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                        validator: validate_BatchWrite_21626121,
                                        base: "/", makeUrl: url_BatchWrite_21626122,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_21626135 = ref object of OpenApiRestCall_21625435
proc url_CreateDirectory_21626137(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectory_21626136(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the published schema that will be copied into the data <a>Directory</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626138 = header.getOrDefault("X-Amz-Date")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Date", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Security-Token", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626145 = header.getOrDefault("x-amz-data-partition")
  valid_21626145 = validateParameter(valid_21626145, JString, required = true,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "x-amz-data-partition", valid_21626145
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

proc call*(call_21626147: Call_CreateDirectory_21626135; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ## 
  let valid = call_21626147.validator(path, query, header, formData, body, _)
  let scheme = call_21626147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626147.makeUrl(scheme.get, call_21626147.host, call_21626147.base,
                               call_21626147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626147, uri, valid, _)

proc call*(call_21626148: Call_CreateDirectory_21626135; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626149 = newJObject()
  if body != nil:
    body_21626149 = body
  result = call_21626148.call(nil, nil, nil, nil, body_21626149)

var createDirectory* = Call_CreateDirectory_21626135(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_21626136, base: "/",
    makeUrl: url_CreateDirectory_21626137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_21626150 = ref object of OpenApiRestCall_21625435
proc url_CreateFacet_21626152(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFacet_21626151(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The schema ARN in which the new <a>Facet</a> will be created. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626153 = header.getOrDefault("X-Amz-Date")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Date", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Security-Token", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626160 = header.getOrDefault("x-amz-data-partition")
  valid_21626160 = validateParameter(valid_21626160, JString, required = true,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "x-amz-data-partition", valid_21626160
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

proc call*(call_21626162: Call_CreateFacet_21626150; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_21626162.validator(path, query, header, formData, body, _)
  let scheme = call_21626162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626162.makeUrl(scheme.get, call_21626162.host, call_21626162.base,
                               call_21626162.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626162, uri, valid, _)

proc call*(call_21626163: Call_CreateFacet_21626150; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_21626164 = newJObject()
  if body != nil:
    body_21626164 = body
  result = call_21626163.call(nil, nil, nil, nil, body_21626164)

var createFacet* = Call_CreateFacet_21626150(name: "createFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
    validator: validate_CreateFacet_21626151, base: "/", makeUrl: url_CreateFacet_21626152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_21626165 = ref object of OpenApiRestCall_21625435
proc url_CreateIndex_21626167(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIndex_21626166(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory where the index should be created.
  section = newJObject()
  var valid_21626168 = header.getOrDefault("X-Amz-Date")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Date", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Security-Token", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626175 = header.getOrDefault("x-amz-data-partition")
  valid_21626175 = validateParameter(valid_21626175, JString, required = true,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "x-amz-data-partition", valid_21626175
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

proc call*(call_21626177: Call_CreateIndex_21626165; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ## 
  let valid = call_21626177.validator(path, query, header, formData, body, _)
  let scheme = call_21626177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626177.makeUrl(scheme.get, call_21626177.host, call_21626177.base,
                               call_21626177.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626177, uri, valid, _)

proc call*(call_21626178: Call_CreateIndex_21626165; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ##   body: JObject (required)
  var body_21626179 = newJObject()
  if body != nil:
    body_21626179 = body
  result = call_21626178.call(nil, nil, nil, nil, body_21626179)

var createIndex* = Call_CreateIndex_21626165(name: "createIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
    validator: validate_CreateIndex_21626166, base: "/", makeUrl: url_CreateIndex_21626167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_21626180 = ref object of OpenApiRestCall_21625435
proc url_CreateObject_21626182(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateObject_21626181(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> in which the object will be created. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626183 = header.getOrDefault("X-Amz-Date")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Date", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Security-Token", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626190 = header.getOrDefault("x-amz-data-partition")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "x-amz-data-partition", valid_21626190
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

proc call*(call_21626192: Call_CreateObject_21626180; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_21626192.validator(path, query, header, formData, body, _)
  let scheme = call_21626192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626192.makeUrl(scheme.get, call_21626192.host, call_21626192.base,
                               call_21626192.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626192, uri, valid, _)

proc call*(call_21626193: Call_CreateObject_21626180; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_21626194 = newJObject()
  if body != nil:
    body_21626194 = body
  result = call_21626193.call(nil, nil, nil, nil, body_21626194)

var createObject* = Call_CreateObject_21626180(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_21626181, base: "/", makeUrl: url_CreateObject_21626182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_21626195 = ref object of OpenApiRestCall_21625435
proc url_CreateSchema_21626197(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSchema_21626196(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CreateSchema_21626195; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateSchema_21626195; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createSchema* = Call_CreateSchema_21626195(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_21626196, base: "/", makeUrl: url_CreateSchema_21626197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateTypedLinkFacet_21626211(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTypedLinkFacet_21626210(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626219 = header.getOrDefault("x-amz-data-partition")
  valid_21626219 = validateParameter(valid_21626219, JString, required = true,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "x-amz-data-partition", valid_21626219
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

proc call*(call_21626221: Call_CreateTypedLinkFacet_21626209; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateTypedLinkFacet_21626209; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_21626209(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_21626210, base: "/",
    makeUrl: url_CreateTypedLinkFacet_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_21626224 = ref object of OpenApiRestCall_21625435
proc url_DeleteDirectory_21626226(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectory_21626225(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to delete.
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Algorithm", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Signature")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Signature", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Credential")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Credential", valid_21626233
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626234 = header.getOrDefault("x-amz-data-partition")
  valid_21626234 = validateParameter(valid_21626234, JString, required = true,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "x-amz-data-partition", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_DeleteDirectory_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_DeleteDirectory_21626224): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_21626236.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_21626224(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_21626225, base: "/",
    makeUrl: url_DeleteDirectory_21626226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_21626237 = ref object of OpenApiRestCall_21625435
proc url_DeleteFacet_21626239(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFacet_21626238(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626240 = header.getOrDefault("X-Amz-Date")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Date", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Security-Token", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Algorithm", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Signature")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Signature", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Credential")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Credential", valid_21626246
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626247 = header.getOrDefault("x-amz-data-partition")
  valid_21626247 = validateParameter(valid_21626247, JString, required = true,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "x-amz-data-partition", valid_21626247
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

proc call*(call_21626249: Call_DeleteFacet_21626237; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_21626249.validator(path, query, header, formData, body, _)
  let scheme = call_21626249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626249.makeUrl(scheme.get, call_21626249.host, call_21626249.base,
                               call_21626249.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626249, uri, valid, _)

proc call*(call_21626250: Call_DeleteFacet_21626237; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_21626251 = newJObject()
  if body != nil:
    body_21626251 = body
  result = call_21626250.call(nil, nil, nil, nil, body_21626251)

var deleteFacet* = Call_DeleteFacet_21626237(name: "deleteFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
    validator: validate_DeleteFacet_21626238, base: "/", makeUrl: url_DeleteFacet_21626239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_21626252 = ref object of OpenApiRestCall_21625435
proc url_DeleteObject_21626254(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteObject_21626253(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626255 = header.getOrDefault("X-Amz-Date")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Date", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Security-Token", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Algorithm", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Signature")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Signature", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Credential")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Credential", valid_21626261
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626262 = header.getOrDefault("x-amz-data-partition")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "x-amz-data-partition", valid_21626262
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

proc call*(call_21626264: Call_DeleteObject_21626252; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ## 
  let valid = call_21626264.validator(path, query, header, formData, body, _)
  let scheme = call_21626264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626264.makeUrl(scheme.get, call_21626264.host, call_21626264.base,
                               call_21626264.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626264, uri, valid, _)

proc call*(call_21626265: Call_DeleteObject_21626252; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ##   body: JObject (required)
  var body_21626266 = newJObject()
  if body != nil:
    body_21626266 = body
  result = call_21626265.call(nil, nil, nil, nil, body_21626266)

var deleteObject* = Call_DeleteObject_21626252(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_21626253, base: "/", makeUrl: url_DeleteObject_21626254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_21626267 = ref object of OpenApiRestCall_21625435
proc url_DeleteSchema_21626269(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSchema_21626268(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626270 = header.getOrDefault("X-Amz-Date")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Date", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Security-Token", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Algorithm", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Signature")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Signature", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Credential")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Credential", valid_21626276
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626277 = header.getOrDefault("x-amz-data-partition")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "x-amz-data-partition", valid_21626277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626278: Call_DeleteSchema_21626267; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_21626278.validator(path, query, header, formData, body, _)
  let scheme = call_21626278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626278.makeUrl(scheme.get, call_21626278.host, call_21626278.base,
                               call_21626278.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626278, uri, valid, _)

proc call*(call_21626279: Call_DeleteSchema_21626267): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_21626279.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_21626267(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_21626268, base: "/", makeUrl: url_DeleteSchema_21626269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_21626280 = ref object of OpenApiRestCall_21625435
proc url_DeleteTypedLinkFacet_21626282(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTypedLinkFacet_21626281(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626283 = header.getOrDefault("X-Amz-Date")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Date", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Security-Token", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Algorithm", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Signature")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Signature", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Credential")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Credential", valid_21626289
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626290 = header.getOrDefault("x-amz-data-partition")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "x-amz-data-partition", valid_21626290
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

proc call*(call_21626292: Call_DeleteTypedLinkFacet_21626280; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626292.validator(path, query, header, formData, body, _)
  let scheme = call_21626292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626292.makeUrl(scheme.get, call_21626292.host, call_21626292.base,
                               call_21626292.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626292, uri, valid, _)

proc call*(call_21626293: Call_DeleteTypedLinkFacet_21626280; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626294 = newJObject()
  if body != nil:
    body_21626294 = body
  result = call_21626293.call(nil, nil, nil, nil, body_21626294)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_21626280(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_21626281, base: "/",
    makeUrl: url_DeleteTypedLinkFacet_21626282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_21626295 = ref object of OpenApiRestCall_21625435
proc url_DetachFromIndex_21626297(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachFromIndex_21626296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory the index and object exist in.
  section = newJObject()
  var valid_21626298 = header.getOrDefault("X-Amz-Date")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Date", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Security-Token", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Algorithm", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Signature")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Signature", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Credential")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Credential", valid_21626304
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626305 = header.getOrDefault("x-amz-data-partition")
  valid_21626305 = validateParameter(valid_21626305, JString, required = true,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "x-amz-data-partition", valid_21626305
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

proc call*(call_21626307: Call_DetachFromIndex_21626295; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_21626307.validator(path, query, header, formData, body, _)
  let scheme = call_21626307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626307.makeUrl(scheme.get, call_21626307.host, call_21626307.base,
                               call_21626307.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626307, uri, valid, _)

proc call*(call_21626308: Call_DetachFromIndex_21626295; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_21626309 = newJObject()
  if body != nil:
    body_21626309 = body
  result = call_21626308.call(nil, nil, nil, nil, body_21626309)

var detachFromIndex* = Call_DetachFromIndex_21626295(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_21626296, base: "/",
    makeUrl: url_DetachFromIndex_21626297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_21626310 = ref object of OpenApiRestCall_21625435
proc url_DetachObject_21626312(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachObject_21626311(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626313 = header.getOrDefault("X-Amz-Date")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Date", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Security-Token", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Algorithm", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Signature")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Signature", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Credential")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Credential", valid_21626319
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626320 = header.getOrDefault("x-amz-data-partition")
  valid_21626320 = validateParameter(valid_21626320, JString, required = true,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "x-amz-data-partition", valid_21626320
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

proc call*(call_21626322: Call_DetachObject_21626310; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_21626322.validator(path, query, header, formData, body, _)
  let scheme = call_21626322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626322.makeUrl(scheme.get, call_21626322.host, call_21626322.base,
                               call_21626322.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626322, uri, valid, _)

proc call*(call_21626323: Call_DetachObject_21626310; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_21626324 = newJObject()
  if body != nil:
    body_21626324 = body
  result = call_21626323.call(nil, nil, nil, nil, body_21626324)

var detachObject* = Call_DetachObject_21626310(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_21626311, base: "/", makeUrl: url_DetachObject_21626312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_21626325 = ref object of OpenApiRestCall_21625435
proc url_DetachPolicy_21626327(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachPolicy_21626326(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Detaches a policy from an object.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626328 = header.getOrDefault("X-Amz-Date")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Date", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Security-Token", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Algorithm", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Signature")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Signature", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Credential")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Credential", valid_21626334
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626335 = header.getOrDefault("x-amz-data-partition")
  valid_21626335 = validateParameter(valid_21626335, JString, required = true,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "x-amz-data-partition", valid_21626335
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

proc call*(call_21626337: Call_DetachPolicy_21626325; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_21626337.validator(path, query, header, formData, body, _)
  let scheme = call_21626337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626337.makeUrl(scheme.get, call_21626337.host, call_21626337.base,
                               call_21626337.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626337, uri, valid, _)

proc call*(call_21626338: Call_DetachPolicy_21626325; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_21626339 = newJObject()
  if body != nil:
    body_21626339 = body
  result = call_21626338.call(nil, nil, nil, nil, body_21626339)

var detachPolicy* = Call_DetachPolicy_21626325(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_21626326, base: "/", makeUrl: url_DetachPolicy_21626327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_21626340 = ref object of OpenApiRestCall_21625435
proc url_DetachTypedLink_21626342(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachTypedLink_21626341(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to detach the typed link.
  section = newJObject()
  var valid_21626343 = header.getOrDefault("X-Amz-Date")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Date", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Security-Token", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Algorithm", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Signature")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Signature", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Credential")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Credential", valid_21626349
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626350 = header.getOrDefault("x-amz-data-partition")
  valid_21626350 = validateParameter(valid_21626350, JString, required = true,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "x-amz-data-partition", valid_21626350
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

proc call*(call_21626352: Call_DetachTypedLink_21626340; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626352.validator(path, query, header, formData, body, _)
  let scheme = call_21626352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626352.makeUrl(scheme.get, call_21626352.host, call_21626352.base,
                               call_21626352.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626352, uri, valid, _)

proc call*(call_21626353: Call_DetachTypedLink_21626340; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626354 = newJObject()
  if body != nil:
    body_21626354 = body
  result = call_21626353.call(nil, nil, nil, nil, body_21626354)

var detachTypedLink* = Call_DetachTypedLink_21626340(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_21626341, base: "/",
    makeUrl: url_DetachTypedLink_21626342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_21626355 = ref object of OpenApiRestCall_21625435
proc url_DisableDirectory_21626357(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableDirectory_21626356(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to disable.
  section = newJObject()
  var valid_21626358 = header.getOrDefault("X-Amz-Date")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Date", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Security-Token", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Algorithm", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Signature")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Signature", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Credential")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Credential", valid_21626364
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626365 = header.getOrDefault("x-amz-data-partition")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "x-amz-data-partition", valid_21626365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626366: Call_DisableDirectory_21626355; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_21626366.validator(path, query, header, formData, body, _)
  let scheme = call_21626366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626366.makeUrl(scheme.get, call_21626366.host, call_21626366.base,
                               call_21626366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626366, uri, valid, _)

proc call*(call_21626367: Call_DisableDirectory_21626355): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_21626367.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_21626355(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_21626356, base: "/",
    makeUrl: url_DisableDirectory_21626357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_21626368 = ref object of OpenApiRestCall_21625435
proc url_EnableDirectory_21626370(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableDirectory_21626369(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to enable.
  section = newJObject()
  var valid_21626371 = header.getOrDefault("X-Amz-Date")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Date", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Security-Token", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Algorithm", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Signature")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Signature", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Credential")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Credential", valid_21626377
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626378 = header.getOrDefault("x-amz-data-partition")
  valid_21626378 = validateParameter(valid_21626378, JString, required = true,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "x-amz-data-partition", valid_21626378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626379: Call_EnableDirectory_21626368; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_21626379.validator(path, query, header, formData, body, _)
  let scheme = call_21626379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626379.makeUrl(scheme.get, call_21626379.host, call_21626379.base,
                               call_21626379.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626379, uri, valid, _)

proc call*(call_21626380: Call_EnableDirectory_21626368): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_21626380.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_21626368(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_21626369, base: "/",
    makeUrl: url_EnableDirectory_21626370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_21626381 = ref object of OpenApiRestCall_21625435
proc url_GetAppliedSchemaVersion_21626383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppliedSchemaVersion_21626382(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626384 = header.getOrDefault("X-Amz-Date")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Date", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Security-Token", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Algorithm", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Signature")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Signature", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Credential")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Credential", valid_21626390
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

proc call*(call_21626392: Call_GetAppliedSchemaVersion_21626381;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_21626392.validator(path, query, header, formData, body, _)
  let scheme = call_21626392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626392.makeUrl(scheme.get, call_21626392.host, call_21626392.base,
                               call_21626392.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626392, uri, valid, _)

proc call*(call_21626393: Call_GetAppliedSchemaVersion_21626381; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_21626394 = newJObject()
  if body != nil:
    body_21626394 = body
  result = call_21626393.call(nil, nil, nil, nil, body_21626394)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_21626381(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_21626382, base: "/",
    makeUrl: url_GetAppliedSchemaVersion_21626383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_21626395 = ref object of OpenApiRestCall_21625435
proc url_GetDirectory_21626397(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDirectory_21626396(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves metadata about a directory.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory.
  section = newJObject()
  var valid_21626398 = header.getOrDefault("X-Amz-Date")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Date", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Security-Token", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626400
  var valid_21626401 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Algorithm", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Signature")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Signature", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Credential")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Credential", valid_21626404
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626405 = header.getOrDefault("x-amz-data-partition")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "x-amz-data-partition", valid_21626405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626406: Call_GetDirectory_21626395; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_21626406.validator(path, query, header, formData, body, _)
  let scheme = call_21626406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626406.makeUrl(scheme.get, call_21626406.host, call_21626406.base,
                               call_21626406.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626406, uri, valid, _)

proc call*(call_21626407: Call_GetDirectory_21626395): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_21626407.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_21626395(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_21626396, base: "/", makeUrl: url_GetDirectory_21626397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_21626408 = ref object of OpenApiRestCall_21625435
proc url_UpdateFacet_21626410(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFacet_21626409(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626411 = header.getOrDefault("X-Amz-Date")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Date", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Security-Token", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Algorithm", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Signature")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Signature", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-Credential")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Credential", valid_21626417
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626418 = header.getOrDefault("x-amz-data-partition")
  valid_21626418 = validateParameter(valid_21626418, JString, required = true,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "x-amz-data-partition", valid_21626418
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

proc call*(call_21626420: Call_UpdateFacet_21626408; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_21626420.validator(path, query, header, formData, body, _)
  let scheme = call_21626420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626420.makeUrl(scheme.get, call_21626420.host, call_21626420.base,
                               call_21626420.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626420, uri, valid, _)

proc call*(call_21626421: Call_UpdateFacet_21626408; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_21626422 = newJObject()
  if body != nil:
    body_21626422 = body
  result = call_21626421.call(nil, nil, nil, nil, body_21626422)

var updateFacet* = Call_UpdateFacet_21626408(name: "updateFacet",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
    validator: validate_UpdateFacet_21626409, base: "/", makeUrl: url_UpdateFacet_21626410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_21626423 = ref object of OpenApiRestCall_21625435
proc url_GetFacet_21626425(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFacet_21626424(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626426 = header.getOrDefault("X-Amz-Date")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Date", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Security-Token", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Algorithm", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Signature")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Signature", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Credential")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Credential", valid_21626432
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626433 = header.getOrDefault("x-amz-data-partition")
  valid_21626433 = validateParameter(valid_21626433, JString, required = true,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "x-amz-data-partition", valid_21626433
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

proc call*(call_21626435: Call_GetFacet_21626423; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_21626435.validator(path, query, header, formData, body, _)
  let scheme = call_21626435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626435.makeUrl(scheme.get, call_21626435.host, call_21626435.base,
                               call_21626435.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626435, uri, valid, _)

proc call*(call_21626436: Call_GetFacet_21626423; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_21626437 = newJObject()
  if body != nil:
    body_21626437 = body
  result = call_21626436.call(nil, nil, nil, nil, body_21626437)

var getFacet* = Call_GetFacet_21626423(name: "getFacet", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                    validator: validate_GetFacet_21626424,
                                    base: "/", makeUrl: url_GetFacet_21626425,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_21626438 = ref object of OpenApiRestCall_21625435
proc url_GetLinkAttributes_21626440(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLinkAttributes_21626439(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see <a>arns</a> or <a 
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  section = newJObject()
  var valid_21626441 = header.getOrDefault("X-Amz-Date")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Date", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Security-Token", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Algorithm", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Signature")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Signature", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Credential")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Credential", valid_21626447
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626448 = header.getOrDefault("x-amz-data-partition")
  valid_21626448 = validateParameter(valid_21626448, JString, required = true,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "x-amz-data-partition", valid_21626448
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

proc call*(call_21626450: Call_GetLinkAttributes_21626438; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_21626450.validator(path, query, header, formData, body, _)
  let scheme = call_21626450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626450.makeUrl(scheme.get, call_21626450.host, call_21626450.base,
                               call_21626450.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626450, uri, valid, _)

proc call*(call_21626451: Call_GetLinkAttributes_21626438; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_21626452 = newJObject()
  if body != nil:
    body_21626452 = body
  result = call_21626451.call(nil, nil, nil, nil, body_21626452)

var getLinkAttributes* = Call_GetLinkAttributes_21626438(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_21626439, base: "/",
    makeUrl: url_GetLinkAttributes_21626440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_21626453 = ref object of OpenApiRestCall_21625435
proc url_GetObjectAttributes_21626455(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectAttributes_21626454(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level at which to retrieve the attributes on an object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides.
  section = newJObject()
  var valid_21626456 = header.getOrDefault("X-Amz-Date")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Date", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Security-Token", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Algorithm", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Signature")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Signature", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626461
  var valid_21626462 = header.getOrDefault("x-amz-consistency-level")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626462 != nil:
    section.add "x-amz-consistency-level", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Credential")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Credential", valid_21626463
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626464 = header.getOrDefault("x-amz-data-partition")
  valid_21626464 = validateParameter(valid_21626464, JString, required = true,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "x-amz-data-partition", valid_21626464
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

proc call*(call_21626466: Call_GetObjectAttributes_21626453; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_21626466.validator(path, query, header, formData, body, _)
  let scheme = call_21626466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626466.makeUrl(scheme.get, call_21626466.host, call_21626466.base,
                               call_21626466.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626466, uri, valid, _)

proc call*(call_21626467: Call_GetObjectAttributes_21626453; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_21626468 = newJObject()
  if body != nil:
    body_21626468 = body
  result = call_21626467.call(nil, nil, nil, nil, body_21626468)

var getObjectAttributes* = Call_GetObjectAttributes_21626453(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_21626454, base: "/",
    makeUrl: url_GetObjectAttributes_21626455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_21626469 = ref object of OpenApiRestCall_21625435
proc url_GetObjectInformation_21626471(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectInformation_21626470(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level at which to retrieve the object information.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory being retrieved.
  section = newJObject()
  var valid_21626472 = header.getOrDefault("X-Amz-Date")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Date", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Security-Token", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Algorithm", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Signature")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Signature", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626477
  var valid_21626478 = header.getOrDefault("x-amz-consistency-level")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626478 != nil:
    section.add "x-amz-consistency-level", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Credential")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Credential", valid_21626479
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626480 = header.getOrDefault("x-amz-data-partition")
  valid_21626480 = validateParameter(valid_21626480, JString, required = true,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "x-amz-data-partition", valid_21626480
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

proc call*(call_21626482: Call_GetObjectInformation_21626469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_21626482.validator(path, query, header, formData, body, _)
  let scheme = call_21626482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626482.makeUrl(scheme.get, call_21626482.host, call_21626482.base,
                               call_21626482.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626482, uri, valid, _)

proc call*(call_21626483: Call_GetObjectInformation_21626469; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_21626484 = newJObject()
  if body != nil:
    body_21626484 = body
  result = call_21626483.call(nil, nil, nil, nil, body_21626484)

var getObjectInformation* = Call_GetObjectInformation_21626469(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_21626470, base: "/",
    makeUrl: url_GetObjectInformation_21626471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_21626485 = ref object of OpenApiRestCall_21625435
proc url_PutSchemaFromJson_21626487(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSchemaFromJson_21626486(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema to update.
  section = newJObject()
  var valid_21626488 = header.getOrDefault("X-Amz-Date")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Date", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Security-Token", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Algorithm", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Signature")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Signature", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Credential")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Credential", valid_21626494
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626495 = header.getOrDefault("x-amz-data-partition")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "x-amz-data-partition", valid_21626495
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

proc call*(call_21626497: Call_PutSchemaFromJson_21626485; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_21626497.validator(path, query, header, formData, body, _)
  let scheme = call_21626497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626497.makeUrl(scheme.get, call_21626497.host, call_21626497.base,
                               call_21626497.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626497, uri, valid, _)

proc call*(call_21626498: Call_PutSchemaFromJson_21626485; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_21626499 = newJObject()
  if body != nil:
    body_21626499 = body
  result = call_21626498.call(nil, nil, nil, nil, body_21626499)

var putSchemaFromJson* = Call_PutSchemaFromJson_21626485(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_21626486, base: "/",
    makeUrl: url_PutSchemaFromJson_21626487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_21626500 = ref object of OpenApiRestCall_21625435
proc url_GetSchemaAsJson_21626502(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSchemaAsJson_21626501(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema to retrieve.
  section = newJObject()
  var valid_21626503 = header.getOrDefault("X-Amz-Date")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Date", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Security-Token", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Algorithm", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Signature")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Signature", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Credential")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Credential", valid_21626509
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626510 = header.getOrDefault("x-amz-data-partition")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "x-amz-data-partition", valid_21626510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626511: Call_GetSchemaAsJson_21626500; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_21626511.validator(path, query, header, formData, body, _)
  let scheme = call_21626511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626511.makeUrl(scheme.get, call_21626511.host, call_21626511.base,
                               call_21626511.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626511, uri, valid, _)

proc call*(call_21626512: Call_GetSchemaAsJson_21626500): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  result = call_21626512.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_21626500(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_21626501, base: "/",
    makeUrl: url_GetSchemaAsJson_21626502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_21626513 = ref object of OpenApiRestCall_21625435
proc url_GetTypedLinkFacetInformation_21626515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTypedLinkFacetInformation_21626514(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626516 = header.getOrDefault("X-Amz-Date")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Date", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Security-Token", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Algorithm", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Signature")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Signature", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Credential")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Credential", valid_21626522
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626523 = header.getOrDefault("x-amz-data-partition")
  valid_21626523 = validateParameter(valid_21626523, JString, required = true,
                                   default = nil)
  if valid_21626523 != nil:
    section.add "x-amz-data-partition", valid_21626523
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

proc call*(call_21626525: Call_GetTypedLinkFacetInformation_21626513;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626525.validator(path, query, header, formData, body, _)
  let scheme = call_21626525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626525.makeUrl(scheme.get, call_21626525.host, call_21626525.base,
                               call_21626525.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626525, uri, valid, _)

proc call*(call_21626526: Call_GetTypedLinkFacetInformation_21626513;
          body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626527 = newJObject()
  if body != nil:
    body_21626527 = body
  result = call_21626526.call(nil, nil, nil, nil, body_21626527)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_21626513(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_21626514, base: "/",
    makeUrl: url_GetTypedLinkFacetInformation_21626515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_21626528 = ref object of OpenApiRestCall_21625435
proc url_ListAppliedSchemaArns_21626530(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAppliedSchemaArns_21626529(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626531 = query.getOrDefault("NextToken")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "NextToken", valid_21626531
  var valid_21626532 = query.getOrDefault("MaxResults")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "MaxResults", valid_21626532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626533 = header.getOrDefault("X-Amz-Date")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Date", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Security-Token", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Algorithm", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Signature")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Signature", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Credential")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Credential", valid_21626539
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

proc call*(call_21626541: Call_ListAppliedSchemaArns_21626528;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_21626541.validator(path, query, header, formData, body, _)
  let scheme = call_21626541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626541.makeUrl(scheme.get, call_21626541.host, call_21626541.base,
                               call_21626541.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626541, uri, valid, _)

proc call*(call_21626542: Call_ListAppliedSchemaArns_21626528; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626544 = newJObject()
  var body_21626545 = newJObject()
  add(query_21626544, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626545 = body
  add(query_21626544, "MaxResults", newJString(MaxResults))
  result = call_21626542.call(nil, query_21626544, nil, nil, body_21626545)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_21626528(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_21626529, base: "/",
    makeUrl: url_ListAppliedSchemaArns_21626530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_21626549 = ref object of OpenApiRestCall_21625435
proc url_ListAttachedIndices_21626551(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAttachedIndices_21626550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists indices attached to the specified object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626552 = query.getOrDefault("NextToken")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "NextToken", valid_21626552
  var valid_21626553 = query.getOrDefault("MaxResults")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "MaxResults", valid_21626553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level to use for this operation.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory.
  section = newJObject()
  var valid_21626554 = header.getOrDefault("X-Amz-Date")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Date", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Security-Token", valid_21626555
  var valid_21626556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626556
  var valid_21626557 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Algorithm", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Signature")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Signature", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626559
  var valid_21626560 = header.getOrDefault("x-amz-consistency-level")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626560 != nil:
    section.add "x-amz-consistency-level", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Credential")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Credential", valid_21626561
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626562 = header.getOrDefault("x-amz-data-partition")
  valid_21626562 = validateParameter(valid_21626562, JString, required = true,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "x-amz-data-partition", valid_21626562
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

proc call*(call_21626564: Call_ListAttachedIndices_21626549; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_21626564.validator(path, query, header, formData, body, _)
  let scheme = call_21626564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626564.makeUrl(scheme.get, call_21626564.host, call_21626564.base,
                               call_21626564.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626564, uri, valid, _)

proc call*(call_21626565: Call_ListAttachedIndices_21626549; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626566 = newJObject()
  var body_21626567 = newJObject()
  add(query_21626566, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626567 = body
  add(query_21626566, "MaxResults", newJString(MaxResults))
  result = call_21626565.call(nil, query_21626566, nil, nil, body_21626567)

var listAttachedIndices* = Call_ListAttachedIndices_21626549(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_21626550, base: "/",
    makeUrl: url_ListAttachedIndices_21626551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_21626568 = ref object of OpenApiRestCall_21625435
proc url_ListDevelopmentSchemaArns_21626570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevelopmentSchemaArns_21626569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626571 = query.getOrDefault("NextToken")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "NextToken", valid_21626571
  var valid_21626572 = query.getOrDefault("MaxResults")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "MaxResults", valid_21626572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626573 = header.getOrDefault("X-Amz-Date")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Date", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Security-Token", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
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

proc call*(call_21626581: Call_ListDevelopmentSchemaArns_21626568;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_ListDevelopmentSchemaArns_21626568; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626583 = newJObject()
  var body_21626584 = newJObject()
  add(query_21626583, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626584 = body
  add(query_21626583, "MaxResults", newJString(MaxResults))
  result = call_21626582.call(nil, query_21626583, nil, nil, body_21626584)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_21626568(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_21626569, base: "/",
    makeUrl: url_ListDevelopmentSchemaArns_21626570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_21626585 = ref object of OpenApiRestCall_21625435
proc url_ListDirectories_21626587(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDirectories_21626586(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626588 = query.getOrDefault("NextToken")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "NextToken", valid_21626588
  var valid_21626589 = query.getOrDefault("MaxResults")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "MaxResults", valid_21626589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626590 = header.getOrDefault("X-Amz-Date")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Date", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Security-Token", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Algorithm", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Signature")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Signature", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Credential")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Credential", valid_21626596
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

proc call*(call_21626598: Call_ListDirectories_21626585; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_21626598.validator(path, query, header, formData, body, _)
  let scheme = call_21626598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626598.makeUrl(scheme.get, call_21626598.host, call_21626598.base,
                               call_21626598.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626598, uri, valid, _)

proc call*(call_21626599: Call_ListDirectories_21626585; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626600 = newJObject()
  var body_21626601 = newJObject()
  add(query_21626600, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626601 = body
  add(query_21626600, "MaxResults", newJString(MaxResults))
  result = call_21626599.call(nil, query_21626600, nil, nil, body_21626601)

var listDirectories* = Call_ListDirectories_21626585(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_21626586, base: "/",
    makeUrl: url_ListDirectories_21626587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_21626602 = ref object of OpenApiRestCall_21625435
proc url_ListFacetAttributes_21626604(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetAttributes_21626603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves attributes attached to the facet.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626605 = query.getOrDefault("NextToken")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "NextToken", valid_21626605
  var valid_21626606 = query.getOrDefault("MaxResults")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "MaxResults", valid_21626606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema where the facet resides.
  section = newJObject()
  var valid_21626607 = header.getOrDefault("X-Amz-Date")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Date", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Security-Token", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Algorithm", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Signature")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Signature", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Credential")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Credential", valid_21626613
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626614 = header.getOrDefault("x-amz-data-partition")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "x-amz-data-partition", valid_21626614
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

proc call*(call_21626616: Call_ListFacetAttributes_21626602; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_21626616.validator(path, query, header, formData, body, _)
  let scheme = call_21626616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626616.makeUrl(scheme.get, call_21626616.host, call_21626616.base,
                               call_21626616.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626616, uri, valid, _)

proc call*(call_21626617: Call_ListFacetAttributes_21626602; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626618 = newJObject()
  var body_21626619 = newJObject()
  add(query_21626618, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626619 = body
  add(query_21626618, "MaxResults", newJString(MaxResults))
  result = call_21626617.call(nil, query_21626618, nil, nil, body_21626619)

var listFacetAttributes* = Call_ListFacetAttributes_21626602(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_21626603, base: "/",
    makeUrl: url_ListFacetAttributes_21626604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_21626620 = ref object of OpenApiRestCall_21625435
proc url_ListFacetNames_21626622(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetNames_21626621(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626623 = query.getOrDefault("NextToken")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "NextToken", valid_21626623
  var valid_21626624 = query.getOrDefault("MaxResults")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "MaxResults", valid_21626624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) to retrieve facet names from.
  section = newJObject()
  var valid_21626625 = header.getOrDefault("X-Amz-Date")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Date", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Security-Token", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Algorithm", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Signature")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Signature", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Credential")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Credential", valid_21626631
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626632 = header.getOrDefault("x-amz-data-partition")
  valid_21626632 = validateParameter(valid_21626632, JString, required = true,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "x-amz-data-partition", valid_21626632
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

proc call*(call_21626634: Call_ListFacetNames_21626620; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_21626634.validator(path, query, header, formData, body, _)
  let scheme = call_21626634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626634.makeUrl(scheme.get, call_21626634.host, call_21626634.base,
                               call_21626634.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626634, uri, valid, _)

proc call*(call_21626635: Call_ListFacetNames_21626620; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626636 = newJObject()
  var body_21626637 = newJObject()
  add(query_21626636, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626637 = body
  add(query_21626636, "MaxResults", newJString(MaxResults))
  result = call_21626635.call(nil, query_21626636, nil, nil, body_21626637)

var listFacetNames* = Call_ListFacetNames_21626620(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_21626621, base: "/",
    makeUrl: url_ListFacetNames_21626622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_21626638 = ref object of OpenApiRestCall_21625435
proc url_ListIncomingTypedLinks_21626640(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIncomingTypedLinks_21626639(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  section = newJObject()
  var valid_21626641 = header.getOrDefault("X-Amz-Date")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "X-Amz-Date", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Security-Token", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Algorithm", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Signature")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Signature", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Credential")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Credential", valid_21626647
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626648 = header.getOrDefault("x-amz-data-partition")
  valid_21626648 = validateParameter(valid_21626648, JString, required = true,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "x-amz-data-partition", valid_21626648
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

proc call*(call_21626650: Call_ListIncomingTypedLinks_21626638;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626650.validator(path, query, header, formData, body, _)
  let scheme = call_21626650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626650.makeUrl(scheme.get, call_21626650.host, call_21626650.base,
                               call_21626650.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626650, uri, valid, _)

proc call*(call_21626651: Call_ListIncomingTypedLinks_21626638; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626652 = newJObject()
  if body != nil:
    body_21626652 = body
  result = call_21626651.call(nil, nil, nil, nil, body_21626652)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_21626638(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_21626639, base: "/",
    makeUrl: url_ListIncomingTypedLinks_21626640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_21626653 = ref object of OpenApiRestCall_21625435
proc url_ListIndex_21626655(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIndex_21626654(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists objects attached to the specified index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626656 = query.getOrDefault("NextToken")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "NextToken", valid_21626656
  var valid_21626657 = query.getOrDefault("MaxResults")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "MaxResults", valid_21626657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level to execute the request at.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory that the index exists in.
  section = newJObject()
  var valid_21626658 = header.getOrDefault("X-Amz-Date")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Date", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Security-Token", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Algorithm", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Signature")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Signature", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626663
  var valid_21626664 = header.getOrDefault("x-amz-consistency-level")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626664 != nil:
    section.add "x-amz-consistency-level", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Credential")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Credential", valid_21626665
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626666 = header.getOrDefault("x-amz-data-partition")
  valid_21626666 = validateParameter(valid_21626666, JString, required = true,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "x-amz-data-partition", valid_21626666
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

proc call*(call_21626668: Call_ListIndex_21626653; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_21626668.validator(path, query, header, formData, body, _)
  let scheme = call_21626668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626668.makeUrl(scheme.get, call_21626668.host, call_21626668.base,
                               call_21626668.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626668, uri, valid, _)

proc call*(call_21626669: Call_ListIndex_21626653; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626670 = newJObject()
  var body_21626671 = newJObject()
  add(query_21626670, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626671 = body
  add(query_21626670, "MaxResults", newJString(MaxResults))
  result = call_21626669.call(nil, query_21626670, nil, nil, body_21626671)

var listIndex* = Call_ListIndex_21626653(name: "listIndex",
                                      meth: HttpMethod.HttpPost,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                      validator: validate_ListIndex_21626654,
                                      base: "/", makeUrl: url_ListIndex_21626655,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListManagedSchemaArns_21626672 = ref object of OpenApiRestCall_21625435
proc url_ListManagedSchemaArns_21626674(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListManagedSchemaArns_21626673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626675 = query.getOrDefault("NextToken")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "NextToken", valid_21626675
  var valid_21626676 = query.getOrDefault("MaxResults")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "MaxResults", valid_21626676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Algorithm", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Signature")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Signature", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Credential")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Credential", valid_21626683
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

proc call*(call_21626685: Call_ListManagedSchemaArns_21626672;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_21626685.validator(path, query, header, formData, body, _)
  let scheme = call_21626685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626685.makeUrl(scheme.get, call_21626685.host, call_21626685.base,
                               call_21626685.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626685, uri, valid, _)

proc call*(call_21626686: Call_ListManagedSchemaArns_21626672; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listManagedSchemaArns
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626687 = newJObject()
  var body_21626688 = newJObject()
  add(query_21626687, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626688 = body
  add(query_21626687, "MaxResults", newJString(MaxResults))
  result = call_21626686.call(nil, query_21626687, nil, nil, body_21626688)

var listManagedSchemaArns* = Call_ListManagedSchemaArns_21626672(
    name: "listManagedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/managed",
    validator: validate_ListManagedSchemaArns_21626673, base: "/",
    makeUrl: url_ListManagedSchemaArns_21626674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_21626689 = ref object of OpenApiRestCall_21625435
proc url_ListObjectAttributes_21626691(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectAttributes_21626690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all attributes that are associated with an object. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626692 = query.getOrDefault("NextToken")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "NextToken", valid_21626692
  var valid_21626693 = query.getOrDefault("MaxResults")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "MaxResults", valid_21626693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626694 = header.getOrDefault("X-Amz-Date")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Date", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Security-Token", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Algorithm", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Signature")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Signature", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626699
  var valid_21626700 = header.getOrDefault("x-amz-consistency-level")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626700 != nil:
    section.add "x-amz-consistency-level", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Credential")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Credential", valid_21626701
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626702 = header.getOrDefault("x-amz-data-partition")
  valid_21626702 = validateParameter(valid_21626702, JString, required = true,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "x-amz-data-partition", valid_21626702
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

proc call*(call_21626704: Call_ListObjectAttributes_21626689; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_21626704.validator(path, query, header, formData, body, _)
  let scheme = call_21626704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626704.makeUrl(scheme.get, call_21626704.host, call_21626704.base,
                               call_21626704.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626704, uri, valid, _)

proc call*(call_21626705: Call_ListObjectAttributes_21626689; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626706 = newJObject()
  var body_21626707 = newJObject()
  add(query_21626706, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626707 = body
  add(query_21626706, "MaxResults", newJString(MaxResults))
  result = call_21626705.call(nil, query_21626706, nil, nil, body_21626707)

var listObjectAttributes* = Call_ListObjectAttributes_21626689(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_21626690, base: "/",
    makeUrl: url_ListObjectAttributes_21626691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_21626708 = ref object of OpenApiRestCall_21625435
proc url_ListObjectChildren_21626710(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectChildren_21626709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626711 = query.getOrDefault("NextToken")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "NextToken", valid_21626711
  var valid_21626712 = query.getOrDefault("MaxResults")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "MaxResults", valid_21626712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626713 = header.getOrDefault("X-Amz-Date")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Date", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Security-Token", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Algorithm", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-Signature")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Signature", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626718
  var valid_21626719 = header.getOrDefault("x-amz-consistency-level")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626719 != nil:
    section.add "x-amz-consistency-level", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Credential")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Credential", valid_21626720
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626721 = header.getOrDefault("x-amz-data-partition")
  valid_21626721 = validateParameter(valid_21626721, JString, required = true,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "x-amz-data-partition", valid_21626721
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

proc call*(call_21626723: Call_ListObjectChildren_21626708; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_21626723.validator(path, query, header, formData, body, _)
  let scheme = call_21626723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626723.makeUrl(scheme.get, call_21626723.host, call_21626723.base,
                               call_21626723.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626723, uri, valid, _)

proc call*(call_21626724: Call_ListObjectChildren_21626708; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626725 = newJObject()
  var body_21626726 = newJObject()
  add(query_21626725, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626726 = body
  add(query_21626725, "MaxResults", newJString(MaxResults))
  result = call_21626724.call(nil, query_21626725, nil, nil, body_21626726)

var listObjectChildren* = Call_ListObjectChildren_21626708(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_21626709, base: "/",
    makeUrl: url_ListObjectChildren_21626710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_21626727 = ref object of OpenApiRestCall_21625435
proc url_ListObjectParentPaths_21626729(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParentPaths_21626728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626730 = query.getOrDefault("NextToken")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "NextToken", valid_21626730
  var valid_21626731 = query.getOrDefault("MaxResults")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "MaxResults", valid_21626731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to which the parent path applies.
  section = newJObject()
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Algorithm", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Signature")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Signature", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Credential")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Credential", valid_21626738
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626739 = header.getOrDefault("x-amz-data-partition")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "x-amz-data-partition", valid_21626739
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

proc call*(call_21626741: Call_ListObjectParentPaths_21626727;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_21626741.validator(path, query, header, formData, body, _)
  let scheme = call_21626741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626741.makeUrl(scheme.get, call_21626741.host, call_21626741.base,
                               call_21626741.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626741, uri, valid, _)

proc call*(call_21626742: Call_ListObjectParentPaths_21626727; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626743 = newJObject()
  var body_21626744 = newJObject()
  add(query_21626743, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626744 = body
  add(query_21626743, "MaxResults", newJString(MaxResults))
  result = call_21626742.call(nil, query_21626743, nil, nil, body_21626744)

var listObjectParentPaths* = Call_ListObjectParentPaths_21626727(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_21626728, base: "/",
    makeUrl: url_ListObjectParentPaths_21626729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_21626745 = ref object of OpenApiRestCall_21625435
proc url_ListObjectParents_21626747(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParents_21626746(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626748 = query.getOrDefault("NextToken")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "NextToken", valid_21626748
  var valid_21626749 = query.getOrDefault("MaxResults")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "MaxResults", valid_21626749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626750 = header.getOrDefault("X-Amz-Date")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Date", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Security-Token", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Algorithm", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Signature")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Signature", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626755
  var valid_21626756 = header.getOrDefault("x-amz-consistency-level")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626756 != nil:
    section.add "x-amz-consistency-level", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Credential")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Credential", valid_21626757
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626758 = header.getOrDefault("x-amz-data-partition")
  valid_21626758 = validateParameter(valid_21626758, JString, required = true,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "x-amz-data-partition", valid_21626758
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

proc call*(call_21626760: Call_ListObjectParents_21626745; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_21626760.validator(path, query, header, formData, body, _)
  let scheme = call_21626760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626760.makeUrl(scheme.get, call_21626760.host, call_21626760.base,
                               call_21626760.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626760, uri, valid, _)

proc call*(call_21626761: Call_ListObjectParents_21626745; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626762 = newJObject()
  var body_21626763 = newJObject()
  add(query_21626762, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626763 = body
  add(query_21626762, "MaxResults", newJString(MaxResults))
  result = call_21626761.call(nil, query_21626762, nil, nil, body_21626763)

var listObjectParents* = Call_ListObjectParents_21626745(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_21626746, base: "/",
    makeUrl: url_ListObjectParents_21626747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_21626764 = ref object of OpenApiRestCall_21625435
proc url_ListObjectPolicies_21626766(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectPolicies_21626765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626767 = query.getOrDefault("NextToken")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "NextToken", valid_21626767
  var valid_21626768 = query.getOrDefault("MaxResults")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "MaxResults", valid_21626768
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626769 = header.getOrDefault("X-Amz-Date")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Date", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Security-Token", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Algorithm", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Signature")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Signature", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626774
  var valid_21626775 = header.getOrDefault("x-amz-consistency-level")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626775 != nil:
    section.add "x-amz-consistency-level", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Credential")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Credential", valid_21626776
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626777 = header.getOrDefault("x-amz-data-partition")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "x-amz-data-partition", valid_21626777
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

proc call*(call_21626779: Call_ListObjectPolicies_21626764; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_21626779.validator(path, query, header, formData, body, _)
  let scheme = call_21626779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626779.makeUrl(scheme.get, call_21626779.host, call_21626779.base,
                               call_21626779.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626779, uri, valid, _)

proc call*(call_21626780: Call_ListObjectPolicies_21626764; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626781 = newJObject()
  var body_21626782 = newJObject()
  add(query_21626781, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626782 = body
  add(query_21626781, "MaxResults", newJString(MaxResults))
  result = call_21626780.call(nil, query_21626781, nil, nil, body_21626782)

var listObjectPolicies* = Call_ListObjectPolicies_21626764(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_21626765, base: "/",
    makeUrl: url_ListObjectPolicies_21626766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_21626783 = ref object of OpenApiRestCall_21625435
proc url_ListOutgoingTypedLinks_21626785(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutgoingTypedLinks_21626784(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  section = newJObject()
  var valid_21626786 = header.getOrDefault("X-Amz-Date")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Date", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Security-Token", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Algorithm", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-Signature")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Signature", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Credential")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Credential", valid_21626792
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626793 = header.getOrDefault("x-amz-data-partition")
  valid_21626793 = validateParameter(valid_21626793, JString, required = true,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "x-amz-data-partition", valid_21626793
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

proc call*(call_21626795: Call_ListOutgoingTypedLinks_21626783;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626795.validator(path, query, header, formData, body, _)
  let scheme = call_21626795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626795.makeUrl(scheme.get, call_21626795.host, call_21626795.base,
                               call_21626795.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626795, uri, valid, _)

proc call*(call_21626796: Call_ListOutgoingTypedLinks_21626783; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21626797 = newJObject()
  if body != nil:
    body_21626797 = body
  result = call_21626796.call(nil, nil, nil, nil, body_21626797)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_21626783(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_21626784, base: "/",
    makeUrl: url_ListOutgoingTypedLinks_21626785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_21626798 = ref object of OpenApiRestCall_21625435
proc url_ListPolicyAttachments_21626800(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicyAttachments_21626799(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626801 = query.getOrDefault("NextToken")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "NextToken", valid_21626801
  var valid_21626802 = query.getOrDefault("MaxResults")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "MaxResults", valid_21626802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626803 = header.getOrDefault("X-Amz-Date")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Date", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Security-Token", valid_21626804
  var valid_21626805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Algorithm", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Signature")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Signature", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626808
  var valid_21626809 = header.getOrDefault("x-amz-consistency-level")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = newJString("SERIALIZABLE"))
  if valid_21626809 != nil:
    section.add "x-amz-consistency-level", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-Credential")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-Credential", valid_21626810
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626811 = header.getOrDefault("x-amz-data-partition")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "x-amz-data-partition", valid_21626811
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

proc call*(call_21626813: Call_ListPolicyAttachments_21626798;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_21626813.validator(path, query, header, formData, body, _)
  let scheme = call_21626813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626813.makeUrl(scheme.get, call_21626813.host, call_21626813.base,
                               call_21626813.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626813, uri, valid, _)

proc call*(call_21626814: Call_ListPolicyAttachments_21626798; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626815 = newJObject()
  var body_21626816 = newJObject()
  add(query_21626815, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626816 = body
  add(query_21626815, "MaxResults", newJString(MaxResults))
  result = call_21626814.call(nil, query_21626815, nil, nil, body_21626816)

var listPolicyAttachments* = Call_ListPolicyAttachments_21626798(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_21626799, base: "/",
    makeUrl: url_ListPolicyAttachments_21626800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_21626817 = ref object of OpenApiRestCall_21625435
proc url_ListPublishedSchemaArns_21626819(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublishedSchemaArns_21626818(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626820 = query.getOrDefault("NextToken")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "NextToken", valid_21626820
  var valid_21626821 = query.getOrDefault("MaxResults")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "MaxResults", valid_21626821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626822 = header.getOrDefault("X-Amz-Date")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Date", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Security-Token", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Algorithm", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Signature")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Signature", valid_21626826
  var valid_21626827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Credential")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Credential", valid_21626828
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

proc call*(call_21626830: Call_ListPublishedSchemaArns_21626817;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_21626830.validator(path, query, header, formData, body, _)
  let scheme = call_21626830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626830.makeUrl(scheme.get, call_21626830.host, call_21626830.base,
                               call_21626830.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626830, uri, valid, _)

proc call*(call_21626831: Call_ListPublishedSchemaArns_21626817; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626832 = newJObject()
  var body_21626833 = newJObject()
  add(query_21626832, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626833 = body
  add(query_21626832, "MaxResults", newJString(MaxResults))
  result = call_21626831.call(nil, query_21626832, nil, nil, body_21626833)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_21626817(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_21626818, base: "/",
    makeUrl: url_ListPublishedSchemaArns_21626819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626834 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626836(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626837 = query.getOrDefault("NextToken")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "NextToken", valid_21626837
  var valid_21626838 = query.getOrDefault("MaxResults")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "MaxResults", valid_21626838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626839 = header.getOrDefault("X-Amz-Date")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Date", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Security-Token", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626841
  var valid_21626842 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Algorithm", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Signature")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Signature", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Credential")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Credential", valid_21626845
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

proc call*(call_21626847: Call_ListTagsForResource_21626834; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_21626847.validator(path, query, header, formData, body, _)
  let scheme = call_21626847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626847.makeUrl(scheme.get, call_21626847.host, call_21626847.base,
                               call_21626847.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626847, uri, valid, _)

proc call*(call_21626848: Call_ListTagsForResource_21626834; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626849 = newJObject()
  var body_21626850 = newJObject()
  add(query_21626849, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626850 = body
  add(query_21626849, "MaxResults", newJString(MaxResults))
  result = call_21626848.call(nil, query_21626849, nil, nil, body_21626850)

var listTagsForResource* = Call_ListTagsForResource_21626834(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_21626835, base: "/",
    makeUrl: url_ListTagsForResource_21626836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_21626851 = ref object of OpenApiRestCall_21625435
proc url_ListTypedLinkFacetAttributes_21626853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetAttributes_21626852(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626854 = query.getOrDefault("NextToken")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "NextToken", valid_21626854
  var valid_21626855 = query.getOrDefault("MaxResults")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "MaxResults", valid_21626855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626856 = header.getOrDefault("X-Amz-Date")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Date", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Security-Token", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Algorithm", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Signature")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Signature", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Credential")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Credential", valid_21626862
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626863 = header.getOrDefault("x-amz-data-partition")
  valid_21626863 = validateParameter(valid_21626863, JString, required = true,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "x-amz-data-partition", valid_21626863
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

proc call*(call_21626865: Call_ListTypedLinkFacetAttributes_21626851;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626865.validator(path, query, header, formData, body, _)
  let scheme = call_21626865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626865.makeUrl(scheme.get, call_21626865.host, call_21626865.base,
                               call_21626865.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626865, uri, valid, _)

proc call*(call_21626866: Call_ListTypedLinkFacetAttributes_21626851;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626867 = newJObject()
  var body_21626868 = newJObject()
  add(query_21626867, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626868 = body
  add(query_21626867, "MaxResults", newJString(MaxResults))
  result = call_21626866.call(nil, query_21626867, nil, nil, body_21626868)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_21626851(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_21626852, base: "/",
    makeUrl: url_ListTypedLinkFacetAttributes_21626853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_21626869 = ref object of OpenApiRestCall_21625435
proc url_ListTypedLinkFacetNames_21626871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetNames_21626870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626872 = query.getOrDefault("NextToken")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "NextToken", valid_21626872
  var valid_21626873 = query.getOrDefault("MaxResults")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "MaxResults", valid_21626873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626874 = header.getOrDefault("X-Amz-Date")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Date", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Security-Token", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Algorithm", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-Signature")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-Signature", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626879
  var valid_21626880 = header.getOrDefault("X-Amz-Credential")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Credential", valid_21626880
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626881 = header.getOrDefault("x-amz-data-partition")
  valid_21626881 = validateParameter(valid_21626881, JString, required = true,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "x-amz-data-partition", valid_21626881
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

proc call*(call_21626883: Call_ListTypedLinkFacetNames_21626869;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21626883.validator(path, query, header, formData, body, _)
  let scheme = call_21626883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626883.makeUrl(scheme.get, call_21626883.host, call_21626883.base,
                               call_21626883.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626883, uri, valid, _)

proc call*(call_21626884: Call_ListTypedLinkFacetNames_21626869; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626885 = newJObject()
  var body_21626886 = newJObject()
  add(query_21626885, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626886 = body
  add(query_21626885, "MaxResults", newJString(MaxResults))
  result = call_21626884.call(nil, query_21626885, nil, nil, body_21626886)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_21626869(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_21626870, base: "/",
    makeUrl: url_ListTypedLinkFacetNames_21626871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_21626887 = ref object of OpenApiRestCall_21625435
proc url_LookupPolicy_21626889(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LookupPolicy_21626888(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626890 = query.getOrDefault("NextToken")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "NextToken", valid_21626890
  var valid_21626891 = query.getOrDefault("MaxResults")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "MaxResults", valid_21626891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626892 = header.getOrDefault("X-Amz-Date")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-Date", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-Security-Token", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626894
  var valid_21626895 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Algorithm", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Signature")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Signature", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Credential")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Credential", valid_21626898
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626899 = header.getOrDefault("x-amz-data-partition")
  valid_21626899 = validateParameter(valid_21626899, JString, required = true,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "x-amz-data-partition", valid_21626899
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

proc call*(call_21626901: Call_LookupPolicy_21626887; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ## 
  let valid = call_21626901.validator(path, query, header, formData, body, _)
  let scheme = call_21626901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626901.makeUrl(scheme.get, call_21626901.host, call_21626901.base,
                               call_21626901.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626901, uri, valid, _)

proc call*(call_21626902: Call_LookupPolicy_21626887; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626903 = newJObject()
  var body_21626904 = newJObject()
  add(query_21626903, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626904 = body
  add(query_21626903, "MaxResults", newJString(MaxResults))
  result = call_21626902.call(nil, query_21626903, nil, nil, body_21626904)

var lookupPolicy* = Call_LookupPolicy_21626887(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_21626888, base: "/", makeUrl: url_LookupPolicy_21626889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_21626905 = ref object of OpenApiRestCall_21625435
proc url_PublishSchema_21626907(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PublishSchema_21626906(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Publishes a development schema with a major version and a recommended minor version.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626908 = header.getOrDefault("X-Amz-Date")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Date", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Security-Token", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Algorithm", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Signature")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Signature", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Credential")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Credential", valid_21626914
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626915 = header.getOrDefault("x-amz-data-partition")
  valid_21626915 = validateParameter(valid_21626915, JString, required = true,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "x-amz-data-partition", valid_21626915
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

proc call*(call_21626917: Call_PublishSchema_21626905; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_21626917.validator(path, query, header, formData, body, _)
  let scheme = call_21626917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626917.makeUrl(scheme.get, call_21626917.host, call_21626917.base,
                               call_21626917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626917, uri, valid, _)

proc call*(call_21626918: Call_PublishSchema_21626905; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_21626919 = newJObject()
  if body != nil:
    body_21626919 = body
  result = call_21626918.call(nil, nil, nil, nil, body_21626919)

var publishSchema* = Call_PublishSchema_21626905(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_21626906, base: "/",
    makeUrl: url_PublishSchema_21626907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_21626920 = ref object of OpenApiRestCall_21625435
proc url_RemoveFacetFromObject_21626922(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveFacetFromObject_21626921(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory in which the object resides.
  section = newJObject()
  var valid_21626923 = header.getOrDefault("X-Amz-Date")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-Date", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Security-Token", valid_21626924
  var valid_21626925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626925
  var valid_21626926 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Algorithm", valid_21626926
  var valid_21626927 = header.getOrDefault("X-Amz-Signature")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "X-Amz-Signature", valid_21626927
  var valid_21626928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626928
  var valid_21626929 = header.getOrDefault("X-Amz-Credential")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "X-Amz-Credential", valid_21626929
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626930 = header.getOrDefault("x-amz-data-partition")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "x-amz-data-partition", valid_21626930
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

proc call*(call_21626932: Call_RemoveFacetFromObject_21626920;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_21626932.validator(path, query, header, formData, body, _)
  let scheme = call_21626932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626932.makeUrl(scheme.get, call_21626932.host, call_21626932.base,
                               call_21626932.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626932, uri, valid, _)

proc call*(call_21626933: Call_RemoveFacetFromObject_21626920; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_21626934 = newJObject()
  if body != nil:
    body_21626934 = body
  result = call_21626933.call(nil, nil, nil, nil, body_21626934)

var removeFacetFromObject* = Call_RemoveFacetFromObject_21626920(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_21626921, base: "/",
    makeUrl: url_RemoveFacetFromObject_21626922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626935 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626937(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626936(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626938 = header.getOrDefault("X-Amz-Date")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Date", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Security-Token", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Algorithm", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Signature")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Signature", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Credential")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Credential", valid_21626944
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

proc call*(call_21626946: Call_TagResource_21626935; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_21626946.validator(path, query, header, formData, body, _)
  let scheme = call_21626946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626946.makeUrl(scheme.get, call_21626946.host, call_21626946.base,
                               call_21626946.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626946, uri, valid, _)

proc call*(call_21626947: Call_TagResource_21626935; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_21626948 = newJObject()
  if body != nil:
    body_21626948 = body
  result = call_21626947.call(nil, nil, nil, nil, body_21626948)

var tagResource* = Call_TagResource_21626935(name: "tagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/add",
    validator: validate_TagResource_21626936, base: "/", makeUrl: url_TagResource_21626937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626949 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626951(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626950(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## An API operation for removing tags from a resource.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626952 = header.getOrDefault("X-Amz-Date")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Date", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Security-Token", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Algorithm", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Signature")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Signature", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Credential")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Credential", valid_21626958
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

proc call*(call_21626960: Call_UntagResource_21626949; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_21626960.validator(path, query, header, formData, body, _)
  let scheme = call_21626960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626960.makeUrl(scheme.get, call_21626960.host, call_21626960.base,
                               call_21626960.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626960, uri, valid, _)

proc call*(call_21626961: Call_UntagResource_21626949; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_21626962 = newJObject()
  if body != nil:
    body_21626962 = body
  result = call_21626961.call(nil, nil, nil, nil, body_21626962)

var untagResource* = Call_UntagResource_21626949(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_21626950, base: "/",
    makeUrl: url_UntagResource_21626951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_21626963 = ref object of OpenApiRestCall_21625435
proc url_UpdateLinkAttributes_21626965(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLinkAttributes_21626964(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see <a>arns</a> or <a 
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  section = newJObject()
  var valid_21626966 = header.getOrDefault("X-Amz-Date")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Date", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Security-Token", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Algorithm", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-Signature")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-Signature", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626971
  var valid_21626972 = header.getOrDefault("X-Amz-Credential")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Credential", valid_21626972
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626973 = header.getOrDefault("x-amz-data-partition")
  valid_21626973 = validateParameter(valid_21626973, JString, required = true,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "x-amz-data-partition", valid_21626973
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

proc call*(call_21626975: Call_UpdateLinkAttributes_21626963; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_21626975.validator(path, query, header, formData, body, _)
  let scheme = call_21626975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626975.makeUrl(scheme.get, call_21626975.host, call_21626975.base,
                               call_21626975.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626975, uri, valid, _)

proc call*(call_21626976: Call_UpdateLinkAttributes_21626963; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_21626977 = newJObject()
  if body != nil:
    body_21626977 = body
  result = call_21626976.call(nil, nil, nil, nil, body_21626977)

var updateLinkAttributes* = Call_UpdateLinkAttributes_21626963(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_21626964, base: "/",
    makeUrl: url_UpdateLinkAttributes_21626965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_21626978 = ref object of OpenApiRestCall_21625435
proc url_UpdateObjectAttributes_21626980(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateObjectAttributes_21626979(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626981 = header.getOrDefault("X-Amz-Date")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Date", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Security-Token", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Algorithm", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Signature")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Signature", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Credential")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Credential", valid_21626987
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21626988 = header.getOrDefault("x-amz-data-partition")
  valid_21626988 = validateParameter(valid_21626988, JString, required = true,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "x-amz-data-partition", valid_21626988
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

proc call*(call_21626990: Call_UpdateObjectAttributes_21626978;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_21626990.validator(path, query, header, formData, body, _)
  let scheme = call_21626990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626990.makeUrl(scheme.get, call_21626990.host, call_21626990.base,
                               call_21626990.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626990, uri, valid, _)

proc call*(call_21626991: Call_UpdateObjectAttributes_21626978; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_21626992 = newJObject()
  if body != nil:
    body_21626992 = body
  result = call_21626991.call(nil, nil, nil, nil, body_21626992)

var updateObjectAttributes* = Call_UpdateObjectAttributes_21626978(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_21626979, base: "/",
    makeUrl: url_UpdateObjectAttributes_21626980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_21626993 = ref object of OpenApiRestCall_21625435
proc url_UpdateSchema_21626995(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSchema_21626994(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates the schema name with a new name. Only development schema names can be updated.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21626996 = header.getOrDefault("X-Amz-Date")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Date", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Security-Token", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Algorithm", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Signature")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Signature", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Credential")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Credential", valid_21627002
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21627003 = header.getOrDefault("x-amz-data-partition")
  valid_21627003 = validateParameter(valid_21627003, JString, required = true,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "x-amz-data-partition", valid_21627003
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

proc call*(call_21627005: Call_UpdateSchema_21626993; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_21627005.validator(path, query, header, formData, body, _)
  let scheme = call_21627005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627005.makeUrl(scheme.get, call_21627005.host, call_21627005.base,
                               call_21627005.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627005, uri, valid, _)

proc call*(call_21627006: Call_UpdateSchema_21626993; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_21627007 = newJObject()
  if body != nil:
    body_21627007 = body
  result = call_21627006.call(nil, nil, nil, nil, body_21627007)

var updateSchema* = Call_UpdateSchema_21626993(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_21626994, base: "/", makeUrl: url_UpdateSchema_21626995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_21627008 = ref object of OpenApiRestCall_21625435
proc url_UpdateTypedLinkFacet_21627010(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTypedLinkFacet_21627009(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  section = newJObject()
  var valid_21627011 = header.getOrDefault("X-Amz-Date")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Date", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Security-Token", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Algorithm", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Signature")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Signature", valid_21627015
  var valid_21627016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627016
  var valid_21627017 = header.getOrDefault("X-Amz-Credential")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "X-Amz-Credential", valid_21627017
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_21627018 = header.getOrDefault("x-amz-data-partition")
  valid_21627018 = validateParameter(valid_21627018, JString, required = true,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "x-amz-data-partition", valid_21627018
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

proc call*(call_21627020: Call_UpdateTypedLinkFacet_21627008; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_21627020.validator(path, query, header, formData, body, _)
  let scheme = call_21627020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627020.makeUrl(scheme.get, call_21627020.host, call_21627020.base,
                               call_21627020.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627020, uri, valid, _)

proc call*(call_21627021: Call_UpdateTypedLinkFacet_21627008; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_21627022 = newJObject()
  if body != nil:
    body_21627022 = body
  result = call_21627021.call(nil, nil, nil, nil, body_21627022)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_21627008(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_21627009, base: "/",
    makeUrl: url_UpdateTypedLinkFacet_21627010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_21627023 = ref object of OpenApiRestCall_21625435
proc url_UpgradeAppliedSchema_21627025(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeAppliedSchema_21627024(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627026 = header.getOrDefault("X-Amz-Date")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Date", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Security-Token", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Algorithm", valid_21627029
  var valid_21627030 = header.getOrDefault("X-Amz-Signature")
  valid_21627030 = validateParameter(valid_21627030, JString, required = false,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "X-Amz-Signature", valid_21627030
  var valid_21627031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627031 = validateParameter(valid_21627031, JString, required = false,
                                   default = nil)
  if valid_21627031 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627031
  var valid_21627032 = header.getOrDefault("X-Amz-Credential")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "X-Amz-Credential", valid_21627032
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

proc call*(call_21627034: Call_UpgradeAppliedSchema_21627023; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_21627034.validator(path, query, header, formData, body, _)
  let scheme = call_21627034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627034.makeUrl(scheme.get, call_21627034.host, call_21627034.base,
                               call_21627034.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627034, uri, valid, _)

proc call*(call_21627035: Call_UpgradeAppliedSchema_21627023; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_21627036 = newJObject()
  if body != nil:
    body_21627036 = body
  result = call_21627035.call(nil, nil, nil, nil, body_21627036)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_21627023(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_21627024, base: "/",
    makeUrl: url_UpgradeAppliedSchema_21627025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_21627037 = ref object of OpenApiRestCall_21625435
proc url_UpgradePublishedSchema_21627039(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradePublishedSchema_21627038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627040 = header.getOrDefault("X-Amz-Date")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Date", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Security-Token", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-Algorithm", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Signature")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Signature", valid_21627044
  var valid_21627045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627045
  var valid_21627046 = header.getOrDefault("X-Amz-Credential")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "X-Amz-Credential", valid_21627046
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

proc call*(call_21627048: Call_UpgradePublishedSchema_21627037;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_21627048.validator(path, query, header, formData, body, _)
  let scheme = call_21627048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627048.makeUrl(scheme.get, call_21627048.host, call_21627048.base,
                               call_21627048.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627048, uri, valid, _)

proc call*(call_21627049: Call_UpgradePublishedSchema_21627037; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_21627050 = newJObject()
  if body != nil:
    body_21627050 = body
  result = call_21627049.call(nil, nil, nil, nil, body_21627050)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_21627037(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_21627038, base: "/",
    makeUrl: url_UpgradePublishedSchema_21627039,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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