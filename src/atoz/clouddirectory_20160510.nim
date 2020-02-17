
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudDirectory
## version: 2016-05-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Cloud Directory</fullname> <p>Amazon Cloud Directory is a component of the AWS Directory Service that simplifies the development and management of cloud-scale web, mobile, and IoT applications. This guide describes the Cloud Directory operations that you can call programmatically and includes detailed information on data types and errors. For information about AWS Directory Services features, see <a href="https://aws.amazon.com/directoryservice/">AWS Directory Service</a> and the <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/what_is.html">AWS Directory Service Administration Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/clouddirectory/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFacetToObject_610996 = ref object of OpenApiRestCall_610658
proc url_AddFacetToObject_610998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddFacetToObject_610997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611115 = header.getOrDefault("x-amz-data-partition")
  valid_611115 = validateParameter(valid_611115, JString, required = true,
                                 default = nil)
  if valid_611115 != nil:
    section.add "x-amz-data-partition", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Algorithm")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Algorithm", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-SignedHeaders", valid_611117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611141: Call_AddFacetToObject_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_611141.validator(path, query, header, formData, body)
  let scheme = call_611141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611141.url(scheme.get, call_611141.host, call_611141.base,
                         call_611141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611141, url, valid)

proc call*(call_611212: Call_AddFacetToObject_610996; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_611213 = newJObject()
  if body != nil:
    body_611213 = body
  result = call_611212.call(nil, nil, nil, nil, body_611213)

var addFacetToObject* = Call_AddFacetToObject_610996(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_610997, base: "/",
    url: url_AddFacetToObject_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_611252 = ref object of OpenApiRestCall_610658
proc url_ApplySchema_611254(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApplySchema_611253(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> into which the schema is copied. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611255 = header.getOrDefault("X-Amz-Signature")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Signature", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Content-Sha256", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Date")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Date", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Credential")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Credential", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Security-Token")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Security-Token", valid_611259
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611260 = header.getOrDefault("x-amz-data-partition")
  valid_611260 = validateParameter(valid_611260, JString, required = true,
                                 default = nil)
  if valid_611260 != nil:
    section.add "x-amz-data-partition", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Algorithm")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Algorithm", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-SignedHeaders", valid_611262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611264: Call_ApplySchema_611252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_611264.validator(path, query, header, formData, body)
  let scheme = call_611264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611264.url(scheme.get, call_611264.host, call_611264.base,
                         call_611264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611264, url, valid)

proc call*(call_611265: Call_ApplySchema_611252; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_611266 = newJObject()
  if body != nil:
    body_611266 = body
  result = call_611265.call(nil, nil, nil, nil, body_611266)

var applySchema* = Call_ApplySchema_611252(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_611253,
                                        base: "/", url: url_ApplySchema_611254,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_611267 = ref object of OpenApiRestCall_610658
proc url_AttachObject_611269(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachObject_611268(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611275 = header.getOrDefault("x-amz-data-partition")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = nil)
  if valid_611275 != nil:
    section.add "x-amz-data-partition", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Algorithm")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Algorithm", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-SignedHeaders", valid_611277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611279: Call_AttachObject_611267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_611279.validator(path, query, header, formData, body)
  let scheme = call_611279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611279.url(scheme.get, call_611279.host, call_611279.base,
                         call_611279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611279, url, valid)

proc call*(call_611280: Call_AttachObject_611267; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_611281 = newJObject()
  if body != nil:
    body_611281 = body
  result = call_611280.call(nil, nil, nil, nil, body_611281)

var attachObject* = Call_AttachObject_611267(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_611268, base: "/", url: url_AttachObject_611269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_611282 = ref object of OpenApiRestCall_610658
proc url_AttachPolicy_611284(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachPolicy_611283(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611285 = header.getOrDefault("X-Amz-Signature")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Signature", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Content-Sha256", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Date")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Date", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Credential")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Credential", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Security-Token")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Security-Token", valid_611289
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611290 = header.getOrDefault("x-amz-data-partition")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "x-amz-data-partition", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Algorithm")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Algorithm", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-SignedHeaders", valid_611292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611294: Call_AttachPolicy_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_611294.validator(path, query, header, formData, body)
  let scheme = call_611294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611294.url(scheme.get, call_611294.host, call_611294.base,
                         call_611294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611294, url, valid)

proc call*(call_611295: Call_AttachPolicy_611282; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_611296 = newJObject()
  if body != nil:
    body_611296 = body
  result = call_611295.call(nil, nil, nil, nil, body_611296)

var attachPolicy* = Call_AttachPolicy_611282(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_611283, base: "/", url: url_AttachPolicy_611284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_611297 = ref object of OpenApiRestCall_610658
proc url_AttachToIndex_611299(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachToIndex_611298(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Attaches the specified object to the specified index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where the object and index exist.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611300 = header.getOrDefault("X-Amz-Signature")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Signature", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Content-Sha256", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Date")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Date", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Credential")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Credential", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Security-Token")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Security-Token", valid_611304
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611305 = header.getOrDefault("x-amz-data-partition")
  valid_611305 = validateParameter(valid_611305, JString, required = true,
                                 default = nil)
  if valid_611305 != nil:
    section.add "x-amz-data-partition", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Algorithm")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Algorithm", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-SignedHeaders", valid_611307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611309: Call_AttachToIndex_611297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_611309.validator(path, query, header, formData, body)
  let scheme = call_611309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611309.url(scheme.get, call_611309.host, call_611309.base,
                         call_611309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611309, url, valid)

proc call*(call_611310: Call_AttachToIndex_611297; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_611311 = newJObject()
  if body != nil:
    body_611311 = body
  result = call_611310.call(nil, nil, nil, nil, body_611311)

var attachToIndex* = Call_AttachToIndex_611297(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_611298, base: "/", url: url_AttachToIndex_611299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_611312 = ref object of OpenApiRestCall_610658
proc url_AttachTypedLink_611314(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachTypedLink_611313(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to attach the typed link.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611315 = header.getOrDefault("X-Amz-Signature")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Signature", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Content-Sha256", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Date")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Date", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Credential")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Credential", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Security-Token")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Security-Token", valid_611319
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611320 = header.getOrDefault("x-amz-data-partition")
  valid_611320 = validateParameter(valid_611320, JString, required = true,
                                 default = nil)
  if valid_611320 != nil:
    section.add "x-amz-data-partition", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_AttachTypedLink_611312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_AttachTypedLink_611312; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611326 = newJObject()
  if body != nil:
    body_611326 = body
  result = call_611325.call(nil, nil, nil, nil, body_611326)

var attachTypedLink* = Call_AttachTypedLink_611312(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_611313, base: "/", url: url_AttachTypedLink_611314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_611327 = ref object of OpenApiRestCall_610658
proc url_BatchRead_611329(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchRead_611328(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Performs all the read operations in a batch. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("x-amz-consistency-level")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611343 != nil:
    section.add "x-amz-consistency-level", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611349 = header.getOrDefault("x-amz-data-partition")
  valid_611349 = validateParameter(valid_611349, JString, required = true,
                                 default = nil)
  if valid_611349 != nil:
    section.add "x-amz-data-partition", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Algorithm")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Algorithm", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-SignedHeaders", valid_611351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611353: Call_BatchRead_611327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_611353.validator(path, query, header, formData, body)
  let scheme = call_611353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611353.url(scheme.get, call_611353.host, call_611353.base,
                         call_611353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611353, url, valid)

proc call*(call_611354: Call_BatchRead_611327; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_611355 = newJObject()
  if body != nil:
    body_611355 = body
  result = call_611354.call(nil, nil, nil, nil, body_611355)

var batchRead* = Call_BatchRead_611327(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_611328,
                                    base: "/", url: url_BatchRead_611329,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_611356 = ref object of OpenApiRestCall_610658
proc url_BatchWrite_611358(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWrite_611357(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611364 = header.getOrDefault("x-amz-data-partition")
  valid_611364 = validateParameter(valid_611364, JString, required = true,
                                 default = nil)
  if valid_611364 != nil:
    section.add "x-amz-data-partition", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-Algorithm")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Algorithm", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-SignedHeaders", valid_611366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611368: Call_BatchWrite_611356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_611368.validator(path, query, header, formData, body)
  let scheme = call_611368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611368.url(scheme.get, call_611368.host, call_611368.base,
                         call_611368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611368, url, valid)

proc call*(call_611369: Call_BatchWrite_611356; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_611370 = newJObject()
  if body != nil:
    body_611370 = body
  result = call_611369.call(nil, nil, nil, nil, body_611370)

var batchWrite* = Call_BatchWrite_611356(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_611357,
                                      base: "/", url: url_BatchWrite_611358,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_611371 = ref object of OpenApiRestCall_610658
proc url_CreateDirectory_611373(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectory_611372(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the published schema that will be copied into the data <a>Directory</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611379 = header.getOrDefault("x-amz-data-partition")
  valid_611379 = validateParameter(valid_611379, JString, required = true,
                                 default = nil)
  if valid_611379 != nil:
    section.add "x-amz-data-partition", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Algorithm")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Algorithm", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-SignedHeaders", valid_611381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611383: Call_CreateDirectory_611371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  let valid = call_611383.validator(path, query, header, formData, body)
  let scheme = call_611383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611383.url(scheme.get, call_611383.host, call_611383.base,
                         call_611383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611383, url, valid)

proc call*(call_611384: Call_CreateDirectory_611371; body: JsonNode): Recallable =
  ## createDirectory
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ##   body: JObject (required)
  var body_611385 = newJObject()
  if body != nil:
    body_611385 = body
  result = call_611384.call(nil, nil, nil, nil, body_611385)

var createDirectory* = Call_CreateDirectory_611371(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_611372, base: "/", url: url_CreateDirectory_611373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_611386 = ref object of OpenApiRestCall_610658
proc url_CreateFacet_611388(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFacet_611387(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The schema ARN in which the new <a>Facet</a> will be created. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611394 = header.getOrDefault("x-amz-data-partition")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = nil)
  if valid_611394 != nil:
    section.add "x-amz-data-partition", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Algorithm")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Algorithm", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-SignedHeaders", valid_611396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611398: Call_CreateFacet_611386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_611398.validator(path, query, header, formData, body)
  let scheme = call_611398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611398.url(scheme.get, call_611398.host, call_611398.base,
                         call_611398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611398, url, valid)

proc call*(call_611399: Call_CreateFacet_611386; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_611400 = newJObject()
  if body != nil:
    body_611400 = body
  result = call_611399.call(nil, nil, nil, nil, body_611400)

var createFacet* = Call_CreateFacet_611386(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_611387,
                                        base: "/", url: url_CreateFacet_611388,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_611401 = ref object of OpenApiRestCall_610658
proc url_CreateIndex_611403(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIndex_611402(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory where the index should be created.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611409 = header.getOrDefault("x-amz-data-partition")
  valid_611409 = validateParameter(valid_611409, JString, required = true,
                                 default = nil)
  if valid_611409 != nil:
    section.add "x-amz-data-partition", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Algorithm")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Algorithm", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-SignedHeaders", valid_611411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611413: Call_CreateIndex_611401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  let valid = call_611413.validator(path, query, header, formData, body)
  let scheme = call_611413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611413.url(scheme.get, call_611413.host, call_611413.base,
                         call_611413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611413, url, valid)

proc call*(call_611414: Call_CreateIndex_611401; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ##   body: JObject (required)
  var body_611415 = newJObject()
  if body != nil:
    body_611415 = body
  result = call_611414.call(nil, nil, nil, nil, body_611415)

var createIndex* = Call_CreateIndex_611401(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_611402,
                                        base: "/", url: url_CreateIndex_611403,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_611416 = ref object of OpenApiRestCall_610658
proc url_CreateObject_611418(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateObject_611417(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> in which the object will be created. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611424 = header.getOrDefault("x-amz-data-partition")
  valid_611424 = validateParameter(valid_611424, JString, required = true,
                                 default = nil)
  if valid_611424 != nil:
    section.add "x-amz-data-partition", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Algorithm")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Algorithm", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-SignedHeaders", valid_611426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611428: Call_CreateObject_611416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_611428.validator(path, query, header, formData, body)
  let scheme = call_611428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611428.url(scheme.get, call_611428.host, call_611428.base,
                         call_611428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611428, url, valid)

proc call*(call_611429: Call_CreateObject_611416; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_611430 = newJObject()
  if body != nil:
    body_611430 = body
  result = call_611429.call(nil, nil, nil, nil, body_611430)

var createObject* = Call_CreateObject_611416(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_611417, base: "/", url: url_CreateObject_611418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_611431 = ref object of OpenApiRestCall_610658
proc url_CreateSchema_611433(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSchema_611432(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CreateSchema_611431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CreateSchema_611431; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var createSchema* = Call_CreateSchema_611431(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_611432, base: "/", url: url_CreateSchema_611433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_611445 = ref object of OpenApiRestCall_610658
proc url_CreateTypedLinkFacet_611447(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTypedLinkFacet_611446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Signature")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Signature", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Content-Sha256", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Date")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Date", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Credential")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Credential", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Security-Token")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Security-Token", valid_611452
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611453 = header.getOrDefault("x-amz-data-partition")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = nil)
  if valid_611453 != nil:
    section.add "x-amz-data-partition", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_CreateTypedLinkFacet_611445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_CreateTypedLinkFacet_611445; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_611445(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_611446, base: "/",
    url: url_CreateTypedLinkFacet_611447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_611460 = ref object of OpenApiRestCall_610658
proc url_DeleteDirectory_611462(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectory_611461(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to delete.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611463 = header.getOrDefault("X-Amz-Signature")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Signature", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Content-Sha256", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Date")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Date", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Credential")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Credential", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Security-Token")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Security-Token", valid_611467
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611468 = header.getOrDefault("x-amz-data-partition")
  valid_611468 = validateParameter(valid_611468, JString, required = true,
                                 default = nil)
  if valid_611468 != nil:
    section.add "x-amz-data-partition", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611471: Call_DeleteDirectory_611460; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_611471.validator(path, query, header, formData, body)
  let scheme = call_611471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611471.url(scheme.get, call_611471.host, call_611471.base,
                         call_611471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611471, url, valid)

proc call*(call_611472: Call_DeleteDirectory_611460): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_611472.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_611460(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_611461, base: "/", url: url_DeleteDirectory_611462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_611473 = ref object of OpenApiRestCall_610658
proc url_DeleteFacet_611475(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFacet_611474(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611476 = header.getOrDefault("X-Amz-Signature")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Signature", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Content-Sha256", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Date")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Date", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Credential")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Credential", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Security-Token")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Security-Token", valid_611480
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611481 = header.getOrDefault("x-amz-data-partition")
  valid_611481 = validateParameter(valid_611481, JString, required = true,
                                 default = nil)
  if valid_611481 != nil:
    section.add "x-amz-data-partition", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Algorithm")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Algorithm", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-SignedHeaders", valid_611483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611485: Call_DeleteFacet_611473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_611485.validator(path, query, header, formData, body)
  let scheme = call_611485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611485.url(scheme.get, call_611485.host, call_611485.base,
                         call_611485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611485, url, valid)

proc call*(call_611486: Call_DeleteFacet_611473; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_611487 = newJObject()
  if body != nil:
    body_611487 = body
  result = call_611486.call(nil, nil, nil, nil, body_611487)

var deleteFacet* = Call_DeleteFacet_611473(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_611474,
                                        base: "/", url: url_DeleteFacet_611475,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_611488 = ref object of OpenApiRestCall_610658
proc url_DeleteObject_611490(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteObject_611489(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611491 = header.getOrDefault("X-Amz-Signature")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Signature", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Content-Sha256", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Date")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Date", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Credential")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Credential", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Security-Token")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Security-Token", valid_611495
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611496 = header.getOrDefault("x-amz-data-partition")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "x-amz-data-partition", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Algorithm")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Algorithm", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-SignedHeaders", valid_611498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611500: Call_DeleteObject_611488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  let valid = call_611500.validator(path, query, header, formData, body)
  let scheme = call_611500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611500.url(scheme.get, call_611500.host, call_611500.base,
                         call_611500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611500, url, valid)

proc call*(call_611501: Call_DeleteObject_611488; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ##   body: JObject (required)
  var body_611502 = newJObject()
  if body != nil:
    body_611502 = body
  result = call_611501.call(nil, nil, nil, nil, body_611502)

var deleteObject* = Call_DeleteObject_611488(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_611489, base: "/", url: url_DeleteObject_611490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_611503 = ref object of OpenApiRestCall_610658
proc url_DeleteSchema_611505(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSchema_611504(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611506 = header.getOrDefault("X-Amz-Signature")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Signature", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Content-Sha256", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Date")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Date", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Credential")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Credential", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Security-Token")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Security-Token", valid_611510
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611511 = header.getOrDefault("x-amz-data-partition")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "x-amz-data-partition", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Algorithm")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Algorithm", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-SignedHeaders", valid_611513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611514: Call_DeleteSchema_611503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_611514.validator(path, query, header, formData, body)
  let scheme = call_611514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611514.url(scheme.get, call_611514.host, call_611514.base,
                         call_611514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611514, url, valid)

proc call*(call_611515: Call_DeleteSchema_611503): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_611515.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_611503(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_611504, base: "/", url: url_DeleteSchema_611505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_611516 = ref object of OpenApiRestCall_610658
proc url_DeleteTypedLinkFacet_611518(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTypedLinkFacet_611517(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611519 = header.getOrDefault("X-Amz-Signature")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Signature", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Content-Sha256", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Date")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Date", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Credential")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Credential", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Security-Token")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Security-Token", valid_611523
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611524 = header.getOrDefault("x-amz-data-partition")
  valid_611524 = validateParameter(valid_611524, JString, required = true,
                                 default = nil)
  if valid_611524 != nil:
    section.add "x-amz-data-partition", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Algorithm")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Algorithm", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-SignedHeaders", valid_611526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611528: Call_DeleteTypedLinkFacet_611516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611528.validator(path, query, header, formData, body)
  let scheme = call_611528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611528.url(scheme.get, call_611528.host, call_611528.base,
                         call_611528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611528, url, valid)

proc call*(call_611529: Call_DeleteTypedLinkFacet_611516; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611530 = newJObject()
  if body != nil:
    body_611530 = body
  result = call_611529.call(nil, nil, nil, nil, body_611530)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_611516(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_611517, base: "/",
    url: url_DeleteTypedLinkFacet_611518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_611531 = ref object of OpenApiRestCall_610658
proc url_DetachFromIndex_611533(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachFromIndex_611532(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Detaches the specified object from the specified index.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory the index and object exist in.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611534 = header.getOrDefault("X-Amz-Signature")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Signature", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Content-Sha256", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Date")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Date", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Credential")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Credential", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Security-Token")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Security-Token", valid_611538
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611539 = header.getOrDefault("x-amz-data-partition")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = nil)
  if valid_611539 != nil:
    section.add "x-amz-data-partition", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Algorithm")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Algorithm", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-SignedHeaders", valid_611541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611543: Call_DetachFromIndex_611531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_611543.validator(path, query, header, formData, body)
  let scheme = call_611543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611543.url(scheme.get, call_611543.host, call_611543.base,
                         call_611543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611543, url, valid)

proc call*(call_611544: Call_DetachFromIndex_611531; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_611545 = newJObject()
  if body != nil:
    body_611545 = body
  result = call_611544.call(nil, nil, nil, nil, body_611545)

var detachFromIndex* = Call_DetachFromIndex_611531(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_611532, base: "/", url: url_DetachFromIndex_611533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_611546 = ref object of OpenApiRestCall_610658
proc url_DetachObject_611548(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachObject_611547(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611549 = header.getOrDefault("X-Amz-Signature")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Signature", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Content-Sha256", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Date")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Date", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Credential")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Credential", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Security-Token")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Security-Token", valid_611553
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611554 = header.getOrDefault("x-amz-data-partition")
  valid_611554 = validateParameter(valid_611554, JString, required = true,
                                 default = nil)
  if valid_611554 != nil:
    section.add "x-amz-data-partition", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Algorithm")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Algorithm", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-SignedHeaders", valid_611556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611558: Call_DetachObject_611546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_611558.validator(path, query, header, formData, body)
  let scheme = call_611558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611558.url(scheme.get, call_611558.host, call_611558.base,
                         call_611558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611558, url, valid)

proc call*(call_611559: Call_DetachObject_611546; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_611560 = newJObject()
  if body != nil:
    body_611560 = body
  result = call_611559.call(nil, nil, nil, nil, body_611560)

var detachObject* = Call_DetachObject_611546(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_611547, base: "/", url: url_DetachObject_611548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_611561 = ref object of OpenApiRestCall_610658
proc url_DetachPolicy_611563(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachPolicy_611562(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Detaches a policy from an object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where both objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611564 = header.getOrDefault("X-Amz-Signature")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Signature", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Content-Sha256", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Date")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Date", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Credential")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Credential", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Security-Token")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Security-Token", valid_611568
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611569 = header.getOrDefault("x-amz-data-partition")
  valid_611569 = validateParameter(valid_611569, JString, required = true,
                                 default = nil)
  if valid_611569 != nil:
    section.add "x-amz-data-partition", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Algorithm")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Algorithm", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-SignedHeaders", valid_611571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611573: Call_DetachPolicy_611561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_611573.validator(path, query, header, formData, body)
  let scheme = call_611573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611573.url(scheme.get, call_611573.host, call_611573.base,
                         call_611573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611573, url, valid)

proc call*(call_611574: Call_DetachPolicy_611561; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_611575 = newJObject()
  if body != nil:
    body_611575 = body
  result = call_611574.call(nil, nil, nil, nil, body_611575)

var detachPolicy* = Call_DetachPolicy_611561(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_611562, base: "/", url: url_DetachPolicy_611563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_611576 = ref object of OpenApiRestCall_610658
proc url_DetachTypedLink_611578(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachTypedLink_611577(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to detach the typed link.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611579 = header.getOrDefault("X-Amz-Signature")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Signature", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Content-Sha256", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Date")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Date", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Credential")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Credential", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Security-Token")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Security-Token", valid_611583
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611584 = header.getOrDefault("x-amz-data-partition")
  valid_611584 = validateParameter(valid_611584, JString, required = true,
                                 default = nil)
  if valid_611584 != nil:
    section.add "x-amz-data-partition", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Algorithm")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Algorithm", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-SignedHeaders", valid_611586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611588: Call_DetachTypedLink_611576; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611588.validator(path, query, header, formData, body)
  let scheme = call_611588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611588.url(scheme.get, call_611588.host, call_611588.base,
                         call_611588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611588, url, valid)

proc call*(call_611589: Call_DetachTypedLink_611576; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611590 = newJObject()
  if body != nil:
    body_611590 = body
  result = call_611589.call(nil, nil, nil, nil, body_611590)

var detachTypedLink* = Call_DetachTypedLink_611576(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_611577, base: "/", url: url_DetachTypedLink_611578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_611591 = ref object of OpenApiRestCall_610658
proc url_DisableDirectory_611593(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableDirectory_611592(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to disable.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611594 = header.getOrDefault("X-Amz-Signature")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Signature", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Content-Sha256", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Date")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Date", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Credential")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Credential", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Security-Token")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Security-Token", valid_611598
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611599 = header.getOrDefault("x-amz-data-partition")
  valid_611599 = validateParameter(valid_611599, JString, required = true,
                                 default = nil)
  if valid_611599 != nil:
    section.add "x-amz-data-partition", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Algorithm")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Algorithm", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-SignedHeaders", valid_611601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611602: Call_DisableDirectory_611591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_611602.validator(path, query, header, formData, body)
  let scheme = call_611602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611602.url(scheme.get, call_611602.host, call_611602.base,
                         call_611602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611602, url, valid)

proc call*(call_611603: Call_DisableDirectory_611591): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_611603.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_611591(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_611592, base: "/",
    url: url_DisableDirectory_611593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_611604 = ref object of OpenApiRestCall_610658
proc url_EnableDirectory_611606(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableDirectory_611605(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to enable.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611607 = header.getOrDefault("X-Amz-Signature")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Signature", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Content-Sha256", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Date")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Date", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-Credential")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Credential", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Security-Token")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Security-Token", valid_611611
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611612 = header.getOrDefault("x-amz-data-partition")
  valid_611612 = validateParameter(valid_611612, JString, required = true,
                                 default = nil)
  if valid_611612 != nil:
    section.add "x-amz-data-partition", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Algorithm")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Algorithm", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-SignedHeaders", valid_611614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611615: Call_EnableDirectory_611604; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_611615.validator(path, query, header, formData, body)
  let scheme = call_611615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611615.url(scheme.get, call_611615.host, call_611615.base,
                         call_611615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611615, url, valid)

proc call*(call_611616: Call_EnableDirectory_611604): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_611616.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_611604(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_611605, base: "/", url: url_EnableDirectory_611606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_611617 = ref object of OpenApiRestCall_610658
proc url_GetAppliedSchemaVersion_611619(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppliedSchemaVersion_611618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611620 = header.getOrDefault("X-Amz-Signature")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Signature", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Content-Sha256", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Date")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Date", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Credential")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Credential", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Security-Token")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Security-Token", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Algorithm")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Algorithm", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-SignedHeaders", valid_611626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611628: Call_GetAppliedSchemaVersion_611617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_611628.validator(path, query, header, formData, body)
  let scheme = call_611628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611628.url(scheme.get, call_611628.host, call_611628.base,
                         call_611628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611628, url, valid)

proc call*(call_611629: Call_GetAppliedSchemaVersion_611617; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_611630 = newJObject()
  if body != nil:
    body_611630 = body
  result = call_611629.call(nil, nil, nil, nil, body_611630)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_611617(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_611618, base: "/",
    url: url_GetAppliedSchemaVersion_611619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_611631 = ref object of OpenApiRestCall_610658
proc url_GetDirectory_611633(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDirectory_611632(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata about a directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611639 = header.getOrDefault("x-amz-data-partition")
  valid_611639 = validateParameter(valid_611639, JString, required = true,
                                 default = nil)
  if valid_611639 != nil:
    section.add "x-amz-data-partition", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Algorithm")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Algorithm", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-SignedHeaders", valid_611641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611642: Call_GetDirectory_611631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_611642.validator(path, query, header, formData, body)
  let scheme = call_611642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611642.url(scheme.get, call_611642.host, call_611642.base,
                         call_611642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611642, url, valid)

proc call*(call_611643: Call_GetDirectory_611631): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_611643.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_611631(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_611632, base: "/", url: url_GetDirectory_611633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_611644 = ref object of OpenApiRestCall_610658
proc url_UpdateFacet_611646(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFacet_611645(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611647 = header.getOrDefault("X-Amz-Signature")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Signature", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Content-Sha256", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Date")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Date", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Credential")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Credential", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Security-Token")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Security-Token", valid_611651
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611652 = header.getOrDefault("x-amz-data-partition")
  valid_611652 = validateParameter(valid_611652, JString, required = true,
                                 default = nil)
  if valid_611652 != nil:
    section.add "x-amz-data-partition", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Algorithm")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Algorithm", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-SignedHeaders", valid_611654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611656: Call_UpdateFacet_611644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_611656.validator(path, query, header, formData, body)
  let scheme = call_611656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611656.url(scheme.get, call_611656.host, call_611656.base,
                         call_611656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611656, url, valid)

proc call*(call_611657: Call_UpdateFacet_611644; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_611658 = newJObject()
  if body != nil:
    body_611658 = body
  result = call_611657.call(nil, nil, nil, nil, body_611658)

var updateFacet* = Call_UpdateFacet_611644(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_611645,
                                        base: "/", url: url_UpdateFacet_611646,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_611659 = ref object of OpenApiRestCall_610658
proc url_GetFacet_611661(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFacet_611660(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Facet</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611662 = header.getOrDefault("X-Amz-Signature")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Signature", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Content-Sha256", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Date")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Date", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Credential")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Credential", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Security-Token")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Security-Token", valid_611666
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611667 = header.getOrDefault("x-amz-data-partition")
  valid_611667 = validateParameter(valid_611667, JString, required = true,
                                 default = nil)
  if valid_611667 != nil:
    section.add "x-amz-data-partition", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611671: Call_GetFacet_611659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_611671.validator(path, query, header, formData, body)
  let scheme = call_611671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611671.url(scheme.get, call_611671.host, call_611671.base,
                         call_611671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611671, url, valid)

proc call*(call_611672: Call_GetFacet_611659; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_611673 = newJObject()
  if body != nil:
    body_611673 = body
  result = call_611672.call(nil, nil, nil, nil, body_611673)

var getFacet* = Call_GetFacet_611659(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_611660, base: "/",
                                  url: url_GetFacet_611661,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_611674 = ref object of OpenApiRestCall_610658
proc url_GetLinkAttributes_611676(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLinkAttributes_611675(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see <a>arns</a> or <a 
  ## href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611677 = header.getOrDefault("X-Amz-Signature")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Signature", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Content-Sha256", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Date")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Date", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Credential")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Credential", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Security-Token")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Security-Token", valid_611681
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611682 = header.getOrDefault("x-amz-data-partition")
  valid_611682 = validateParameter(valid_611682, JString, required = true,
                                 default = nil)
  if valid_611682 != nil:
    section.add "x-amz-data-partition", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Algorithm")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Algorithm", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-SignedHeaders", valid_611684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611686: Call_GetLinkAttributes_611674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_611686.validator(path, query, header, formData, body)
  let scheme = call_611686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611686.url(scheme.get, call_611686.host, call_611686.base,
                         call_611686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611686, url, valid)

proc call*(call_611687: Call_GetLinkAttributes_611674; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_611688 = newJObject()
  if body != nil:
    body_611688 = body
  result = call_611687.call(nil, nil, nil, nil, body_611688)

var getLinkAttributes* = Call_GetLinkAttributes_611674(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_611675, base: "/",
    url: url_GetLinkAttributes_611676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_611689 = ref object of OpenApiRestCall_610658
proc url_GetObjectAttributes_611691(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectAttributes_611690(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level at which to retrieve the attributes on an object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611692 = header.getOrDefault("x-amz-consistency-level")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611692 != nil:
    section.add "x-amz-consistency-level", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Signature")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Signature", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Content-Sha256", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Date")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Date", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Credential")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Credential", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Security-Token")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Security-Token", valid_611697
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611698 = header.getOrDefault("x-amz-data-partition")
  valid_611698 = validateParameter(valid_611698, JString, required = true,
                                 default = nil)
  if valid_611698 != nil:
    section.add "x-amz-data-partition", valid_611698
  var valid_611699 = header.getOrDefault("X-Amz-Algorithm")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Algorithm", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-SignedHeaders", valid_611700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611702: Call_GetObjectAttributes_611689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_611702.validator(path, query, header, formData, body)
  let scheme = call_611702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611702.url(scheme.get, call_611702.host, call_611702.base,
                         call_611702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611702, url, valid)

proc call*(call_611703: Call_GetObjectAttributes_611689; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_611704 = newJObject()
  if body != nil:
    body_611704 = body
  result = call_611703.call(nil, nil, nil, nil, body_611704)

var getObjectAttributes* = Call_GetObjectAttributes_611689(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_611690, base: "/",
    url: url_GetObjectAttributes_611691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_611705 = ref object of OpenApiRestCall_610658
proc url_GetObjectInformation_611707(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectInformation_611706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata about an object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level at which to retrieve the object information.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory being retrieved.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611708 = header.getOrDefault("x-amz-consistency-level")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611708 != nil:
    section.add "x-amz-consistency-level", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Signature")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Signature", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Content-Sha256", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Date")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Date", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Credential")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Credential", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Security-Token")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Security-Token", valid_611713
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611714 = header.getOrDefault("x-amz-data-partition")
  valid_611714 = validateParameter(valid_611714, JString, required = true,
                                 default = nil)
  if valid_611714 != nil:
    section.add "x-amz-data-partition", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Algorithm")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Algorithm", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-SignedHeaders", valid_611716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611718: Call_GetObjectInformation_611705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_611718.validator(path, query, header, formData, body)
  let scheme = call_611718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611718.url(scheme.get, call_611718.host, call_611718.base,
                         call_611718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611718, url, valid)

proc call*(call_611719: Call_GetObjectInformation_611705; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_611720 = newJObject()
  if body != nil:
    body_611720 = body
  result = call_611719.call(nil, nil, nil, nil, body_611720)

var getObjectInformation* = Call_GetObjectInformation_611705(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_611706, base: "/",
    url: url_GetObjectInformation_611707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_611721 = ref object of OpenApiRestCall_610658
proc url_PutSchemaFromJson_611723(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSchemaFromJson_611722(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema to update.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611724 = header.getOrDefault("X-Amz-Signature")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Signature", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Content-Sha256", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Date")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Date", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Credential")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Credential", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Security-Token")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Security-Token", valid_611728
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611729 = header.getOrDefault("x-amz-data-partition")
  valid_611729 = validateParameter(valid_611729, JString, required = true,
                                 default = nil)
  if valid_611729 != nil:
    section.add "x-amz-data-partition", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Algorithm")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Algorithm", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-SignedHeaders", valid_611731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611733: Call_PutSchemaFromJson_611721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_611733.validator(path, query, header, formData, body)
  let scheme = call_611733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611733.url(scheme.get, call_611733.host, call_611733.base,
                         call_611733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611733, url, valid)

proc call*(call_611734: Call_PutSchemaFromJson_611721; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_611735 = newJObject()
  if body != nil:
    body_611735 = body
  result = call_611734.call(nil, nil, nil, nil, body_611735)

var putSchemaFromJson* = Call_PutSchemaFromJson_611721(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_611722, base: "/",
    url: url_PutSchemaFromJson_611723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_611736 = ref object of OpenApiRestCall_610658
proc url_GetSchemaAsJson_611738(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSchemaAsJson_611737(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema to retrieve.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611739 = header.getOrDefault("X-Amz-Signature")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Signature", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Content-Sha256", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Date")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Date", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Credential")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Credential", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Security-Token")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Security-Token", valid_611743
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611744 = header.getOrDefault("x-amz-data-partition")
  valid_611744 = validateParameter(valid_611744, JString, required = true,
                                 default = nil)
  if valid_611744 != nil:
    section.add "x-amz-data-partition", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611747: Call_GetSchemaAsJson_611736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_611747.validator(path, query, header, formData, body)
  let scheme = call_611747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611747.url(scheme.get, call_611747.host, call_611747.base,
                         call_611747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611747, url, valid)

proc call*(call_611748: Call_GetSchemaAsJson_611736): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  result = call_611748.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_611736(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_611737, base: "/", url: url_GetSchemaAsJson_611738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_611749 = ref object of OpenApiRestCall_610658
proc url_GetTypedLinkFacetInformation_611751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTypedLinkFacetInformation_611750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611752 = header.getOrDefault("X-Amz-Signature")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Signature", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Content-Sha256", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Date")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Date", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Credential")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Credential", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Security-Token")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Security-Token", valid_611756
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611757 = header.getOrDefault("x-amz-data-partition")
  valid_611757 = validateParameter(valid_611757, JString, required = true,
                                 default = nil)
  if valid_611757 != nil:
    section.add "x-amz-data-partition", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Algorithm")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Algorithm", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-SignedHeaders", valid_611759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611761: Call_GetTypedLinkFacetInformation_611749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611761.validator(path, query, header, formData, body)
  let scheme = call_611761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611761.url(scheme.get, call_611761.host, call_611761.base,
                         call_611761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611761, url, valid)

proc call*(call_611762: Call_GetTypedLinkFacetInformation_611749; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611763 = newJObject()
  if body != nil:
    body_611763 = body
  result = call_611762.call(nil, nil, nil, nil, body_611763)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_611749(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_611750, base: "/",
    url: url_GetTypedLinkFacetInformation_611751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_611764 = ref object of OpenApiRestCall_610658
proc url_ListAppliedSchemaArns_611766(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAppliedSchemaArns_611765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611767 = query.getOrDefault("MaxResults")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "MaxResults", valid_611767
  var valid_611768 = query.getOrDefault("NextToken")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "NextToken", valid_611768
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611769 = header.getOrDefault("X-Amz-Signature")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Signature", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Content-Sha256", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Date")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Date", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Credential")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Credential", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Security-Token")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Security-Token", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Algorithm")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Algorithm", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-SignedHeaders", valid_611775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611777: Call_ListAppliedSchemaArns_611764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_611777.validator(path, query, header, formData, body)
  let scheme = call_611777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611777.url(scheme.get, call_611777.host, call_611777.base,
                         call_611777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611777, url, valid)

proc call*(call_611778: Call_ListAppliedSchemaArns_611764; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611779 = newJObject()
  var body_611780 = newJObject()
  add(query_611779, "MaxResults", newJString(MaxResults))
  add(query_611779, "NextToken", newJString(NextToken))
  if body != nil:
    body_611780 = body
  result = call_611778.call(nil, query_611779, nil, nil, body_611780)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_611764(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_611765, base: "/",
    url: url_ListAppliedSchemaArns_611766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_611782 = ref object of OpenApiRestCall_610658
proc url_ListAttachedIndices_611784(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAttachedIndices_611783(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611785 = query.getOrDefault("MaxResults")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "MaxResults", valid_611785
  var valid_611786 = query.getOrDefault("NextToken")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "NextToken", valid_611786
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level to use for this operation.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611787 = header.getOrDefault("x-amz-consistency-level")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611787 != nil:
    section.add "x-amz-consistency-level", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Signature")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Signature", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Content-Sha256", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Date")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Date", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Credential")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Credential", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Security-Token")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Security-Token", valid_611792
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611793 = header.getOrDefault("x-amz-data-partition")
  valid_611793 = validateParameter(valid_611793, JString, required = true,
                                 default = nil)
  if valid_611793 != nil:
    section.add "x-amz-data-partition", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Algorithm")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Algorithm", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-SignedHeaders", valid_611795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611797: Call_ListAttachedIndices_611782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_611797.validator(path, query, header, formData, body)
  let scheme = call_611797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611797.url(scheme.get, call_611797.host, call_611797.base,
                         call_611797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611797, url, valid)

proc call*(call_611798: Call_ListAttachedIndices_611782; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611799 = newJObject()
  var body_611800 = newJObject()
  add(query_611799, "MaxResults", newJString(MaxResults))
  add(query_611799, "NextToken", newJString(NextToken))
  if body != nil:
    body_611800 = body
  result = call_611798.call(nil, query_611799, nil, nil, body_611800)

var listAttachedIndices* = Call_ListAttachedIndices_611782(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_611783, base: "/",
    url: url_ListAttachedIndices_611784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_611801 = ref object of OpenApiRestCall_610658
proc url_ListDevelopmentSchemaArns_611803(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevelopmentSchemaArns_611802(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611804 = query.getOrDefault("MaxResults")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "MaxResults", valid_611804
  var valid_611805 = query.getOrDefault("NextToken")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "NextToken", valid_611805
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611806 = header.getOrDefault("X-Amz-Signature")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Signature", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Content-Sha256", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Date")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Date", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Credential")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Credential", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Security-Token")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Security-Token", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Algorithm")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Algorithm", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-SignedHeaders", valid_611812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611814: Call_ListDevelopmentSchemaArns_611801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_611814.validator(path, query, header, formData, body)
  let scheme = call_611814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611814.url(scheme.get, call_611814.host, call_611814.base,
                         call_611814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611814, url, valid)

proc call*(call_611815: Call_ListDevelopmentSchemaArns_611801; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611816 = newJObject()
  var body_611817 = newJObject()
  add(query_611816, "MaxResults", newJString(MaxResults))
  add(query_611816, "NextToken", newJString(NextToken))
  if body != nil:
    body_611817 = body
  result = call_611815.call(nil, query_611816, nil, nil, body_611817)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_611801(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_611802, base: "/",
    url: url_ListDevelopmentSchemaArns_611803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_611818 = ref object of OpenApiRestCall_610658
proc url_ListDirectories_611820(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDirectories_611819(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_611821 = query.getOrDefault("MaxResults")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "MaxResults", valid_611821
  var valid_611822 = query.getOrDefault("NextToken")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "NextToken", valid_611822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611823 = header.getOrDefault("X-Amz-Signature")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Signature", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Content-Sha256", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Date")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Date", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Credential")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Credential", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Security-Token")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Security-Token", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Algorithm")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Algorithm", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-SignedHeaders", valid_611829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611831: Call_ListDirectories_611818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_611831.validator(path, query, header, formData, body)
  let scheme = call_611831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611831.url(scheme.get, call_611831.host, call_611831.base,
                         call_611831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611831, url, valid)

proc call*(call_611832: Call_ListDirectories_611818; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611833 = newJObject()
  var body_611834 = newJObject()
  add(query_611833, "MaxResults", newJString(MaxResults))
  add(query_611833, "NextToken", newJString(NextToken))
  if body != nil:
    body_611834 = body
  result = call_611832.call(nil, query_611833, nil, nil, body_611834)

var listDirectories* = Call_ListDirectories_611818(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_611819, base: "/", url: url_ListDirectories_611820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_611835 = ref object of OpenApiRestCall_610658
proc url_ListFacetAttributes_611837(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetAttributes_611836(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_611838 = query.getOrDefault("MaxResults")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "MaxResults", valid_611838
  var valid_611839 = query.getOrDefault("NextToken")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "NextToken", valid_611839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the schema where the facet resides.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611840 = header.getOrDefault("X-Amz-Signature")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Signature", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Content-Sha256", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Date")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Date", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Credential")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Credential", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Security-Token")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Security-Token", valid_611844
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611845 = header.getOrDefault("x-amz-data-partition")
  valid_611845 = validateParameter(valid_611845, JString, required = true,
                                 default = nil)
  if valid_611845 != nil:
    section.add "x-amz-data-partition", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Algorithm")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Algorithm", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-SignedHeaders", valid_611847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611849: Call_ListFacetAttributes_611835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_611849.validator(path, query, header, formData, body)
  let scheme = call_611849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611849.url(scheme.get, call_611849.host, call_611849.base,
                         call_611849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611849, url, valid)

proc call*(call_611850: Call_ListFacetAttributes_611835; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611851 = newJObject()
  var body_611852 = newJObject()
  add(query_611851, "MaxResults", newJString(MaxResults))
  add(query_611851, "NextToken", newJString(NextToken))
  if body != nil:
    body_611852 = body
  result = call_611850.call(nil, query_611851, nil, nil, body_611852)

var listFacetAttributes* = Call_ListFacetAttributes_611835(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_611836, base: "/",
    url: url_ListFacetAttributes_611837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_611853 = ref object of OpenApiRestCall_610658
proc url_ListFacetNames_611855(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetNames_611854(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_611856 = query.getOrDefault("MaxResults")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "MaxResults", valid_611856
  var valid_611857 = query.getOrDefault("NextToken")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "NextToken", valid_611857
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) to retrieve facet names from.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611858 = header.getOrDefault("X-Amz-Signature")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Signature", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Content-Sha256", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-Date")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Date", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Credential")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Credential", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Security-Token")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Security-Token", valid_611862
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611863 = header.getOrDefault("x-amz-data-partition")
  valid_611863 = validateParameter(valid_611863, JString, required = true,
                                 default = nil)
  if valid_611863 != nil:
    section.add "x-amz-data-partition", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Algorithm")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Algorithm", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-SignedHeaders", valid_611865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611867: Call_ListFacetNames_611853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_611867.validator(path, query, header, formData, body)
  let scheme = call_611867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611867.url(scheme.get, call_611867.host, call_611867.base,
                         call_611867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611867, url, valid)

proc call*(call_611868: Call_ListFacetNames_611853; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611869 = newJObject()
  var body_611870 = newJObject()
  add(query_611869, "MaxResults", newJString(MaxResults))
  add(query_611869, "NextToken", newJString(NextToken))
  if body != nil:
    body_611870 = body
  result = call_611868.call(nil, query_611869, nil, nil, body_611870)

var listFacetNames* = Call_ListFacetNames_611853(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_611854, base: "/", url: url_ListFacetNames_611855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_611871 = ref object of OpenApiRestCall_610658
proc url_ListIncomingTypedLinks_611873(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIncomingTypedLinks_611872(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611874 = header.getOrDefault("X-Amz-Signature")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Signature", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Content-Sha256", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Date")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Date", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Credential")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Credential", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Security-Token")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Security-Token", valid_611878
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611879 = header.getOrDefault("x-amz-data-partition")
  valid_611879 = validateParameter(valid_611879, JString, required = true,
                                 default = nil)
  if valid_611879 != nil:
    section.add "x-amz-data-partition", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Algorithm")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Algorithm", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-SignedHeaders", valid_611881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611883: Call_ListIncomingTypedLinks_611871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_611883.validator(path, query, header, formData, body)
  let scheme = call_611883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611883.url(scheme.get, call_611883.host, call_611883.base,
                         call_611883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611883, url, valid)

proc call*(call_611884: Call_ListIncomingTypedLinks_611871; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_611885 = newJObject()
  if body != nil:
    body_611885 = body
  result = call_611884.call(nil, nil, nil, nil, body_611885)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_611871(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_611872, base: "/",
    url: url_ListIncomingTypedLinks_611873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_611886 = ref object of OpenApiRestCall_610658
proc url_ListIndex_611888(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIndex_611887(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611889 = query.getOrDefault("MaxResults")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "MaxResults", valid_611889
  var valid_611890 = query.getOrDefault("NextToken")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "NextToken", valid_611890
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : The consistency level to execute the request at.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory that the index exists in.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611891 = header.getOrDefault("x-amz-consistency-level")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611891 != nil:
    section.add "x-amz-consistency-level", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Signature")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Signature", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Content-Sha256", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Date")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Date", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Credential")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Credential", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Security-Token")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Security-Token", valid_611896
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611897 = header.getOrDefault("x-amz-data-partition")
  valid_611897 = validateParameter(valid_611897, JString, required = true,
                                 default = nil)
  if valid_611897 != nil:
    section.add "x-amz-data-partition", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Algorithm")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Algorithm", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-SignedHeaders", valid_611899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611901: Call_ListIndex_611886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_611901.validator(path, query, header, formData, body)
  let scheme = call_611901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611901.url(scheme.get, call_611901.host, call_611901.base,
                         call_611901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611901, url, valid)

proc call*(call_611902: Call_ListIndex_611886; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611903 = newJObject()
  var body_611904 = newJObject()
  add(query_611903, "MaxResults", newJString(MaxResults))
  add(query_611903, "NextToken", newJString(NextToken))
  if body != nil:
    body_611904 = body
  result = call_611902.call(nil, query_611903, nil, nil, body_611904)

var listIndex* = Call_ListIndex_611886(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_611887,
                                    base: "/", url: url_ListIndex_611888,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_611905 = ref object of OpenApiRestCall_610658
proc url_ListObjectAttributes_611907(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectAttributes_611906(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611908 = query.getOrDefault("MaxResults")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "MaxResults", valid_611908
  var valid_611909 = query.getOrDefault("NextToken")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "NextToken", valid_611909
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611910 = header.getOrDefault("x-amz-consistency-level")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611910 != nil:
    section.add "x-amz-consistency-level", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Signature")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Signature", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Content-Sha256", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Date")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Date", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Credential")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Credential", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Security-Token")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Security-Token", valid_611915
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611916 = header.getOrDefault("x-amz-data-partition")
  valid_611916 = validateParameter(valid_611916, JString, required = true,
                                 default = nil)
  if valid_611916 != nil:
    section.add "x-amz-data-partition", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Algorithm")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Algorithm", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-SignedHeaders", valid_611918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611920: Call_ListObjectAttributes_611905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_611920.validator(path, query, header, formData, body)
  let scheme = call_611920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611920.url(scheme.get, call_611920.host, call_611920.base,
                         call_611920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611920, url, valid)

proc call*(call_611921: Call_ListObjectAttributes_611905; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611922 = newJObject()
  var body_611923 = newJObject()
  add(query_611922, "MaxResults", newJString(MaxResults))
  add(query_611922, "NextToken", newJString(NextToken))
  if body != nil:
    body_611923 = body
  result = call_611921.call(nil, query_611922, nil, nil, body_611923)

var listObjectAttributes* = Call_ListObjectAttributes_611905(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_611906, base: "/",
    url: url_ListObjectAttributes_611907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_611924 = ref object of OpenApiRestCall_610658
proc url_ListObjectChildren_611926(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectChildren_611925(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611927 = query.getOrDefault("MaxResults")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "MaxResults", valid_611927
  var valid_611928 = query.getOrDefault("NextToken")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "NextToken", valid_611928
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611929 = header.getOrDefault("x-amz-consistency-level")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611929 != nil:
    section.add "x-amz-consistency-level", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Signature")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Signature", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Content-Sha256", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Date")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Date", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Credential")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Credential", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Security-Token")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Security-Token", valid_611934
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611935 = header.getOrDefault("x-amz-data-partition")
  valid_611935 = validateParameter(valid_611935, JString, required = true,
                                 default = nil)
  if valid_611935 != nil:
    section.add "x-amz-data-partition", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Algorithm")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Algorithm", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-SignedHeaders", valid_611937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611939: Call_ListObjectChildren_611924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_611939.validator(path, query, header, formData, body)
  let scheme = call_611939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611939.url(scheme.get, call_611939.host, call_611939.base,
                         call_611939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611939, url, valid)

proc call*(call_611940: Call_ListObjectChildren_611924; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611941 = newJObject()
  var body_611942 = newJObject()
  add(query_611941, "MaxResults", newJString(MaxResults))
  add(query_611941, "NextToken", newJString(NextToken))
  if body != nil:
    body_611942 = body
  result = call_611940.call(nil, query_611941, nil, nil, body_611942)

var listObjectChildren* = Call_ListObjectChildren_611924(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_611925, base: "/",
    url: url_ListObjectChildren_611926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_611943 = ref object of OpenApiRestCall_610658
proc url_ListObjectParentPaths_611945(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParentPaths_611944(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
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
  var valid_611946 = query.getOrDefault("MaxResults")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "MaxResults", valid_611946
  var valid_611947 = query.getOrDefault("NextToken")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "NextToken", valid_611947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory to which the parent path applies.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611948 = header.getOrDefault("X-Amz-Signature")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Signature", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Content-Sha256", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-Date")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Date", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Credential")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Credential", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Security-Token")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Security-Token", valid_611952
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611953 = header.getOrDefault("x-amz-data-partition")
  valid_611953 = validateParameter(valid_611953, JString, required = true,
                                 default = nil)
  if valid_611953 != nil:
    section.add "x-amz-data-partition", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Algorithm")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Algorithm", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-SignedHeaders", valid_611955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611957: Call_ListObjectParentPaths_611943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_611957.validator(path, query, header, formData, body)
  let scheme = call_611957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611957.url(scheme.get, call_611957.host, call_611957.base,
                         call_611957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611957, url, valid)

proc call*(call_611958: Call_ListObjectParentPaths_611943; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611959 = newJObject()
  var body_611960 = newJObject()
  add(query_611959, "MaxResults", newJString(MaxResults))
  add(query_611959, "NextToken", newJString(NextToken))
  if body != nil:
    body_611960 = body
  result = call_611958.call(nil, query_611959, nil, nil, body_611960)

var listObjectParentPaths* = Call_ListObjectParentPaths_611943(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_611944, base: "/",
    url: url_ListObjectParentPaths_611945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_611961 = ref object of OpenApiRestCall_610658
proc url_ListObjectParents_611963(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParents_611962(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_611964 = query.getOrDefault("MaxResults")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "MaxResults", valid_611964
  var valid_611965 = query.getOrDefault("NextToken")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "NextToken", valid_611965
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611966 = header.getOrDefault("x-amz-consistency-level")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611966 != nil:
    section.add "x-amz-consistency-level", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Signature")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Signature", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Content-Sha256", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Date")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Date", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Credential")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Credential", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-Security-Token")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-Security-Token", valid_611971
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611972 = header.getOrDefault("x-amz-data-partition")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "x-amz-data-partition", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Algorithm")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Algorithm", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-SignedHeaders", valid_611974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611976: Call_ListObjectParents_611961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_611976.validator(path, query, header, formData, body)
  let scheme = call_611976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611976.url(scheme.get, call_611976.host, call_611976.base,
                         call_611976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611976, url, valid)

proc call*(call_611977: Call_ListObjectParents_611961; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611978 = newJObject()
  var body_611979 = newJObject()
  add(query_611978, "MaxResults", newJString(MaxResults))
  add(query_611978, "NextToken", newJString(NextToken))
  if body != nil:
    body_611979 = body
  result = call_611977.call(nil, query_611978, nil, nil, body_611979)

var listObjectParents* = Call_ListObjectParents_611961(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_611962, base: "/",
    url: url_ListObjectParents_611963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_611980 = ref object of OpenApiRestCall_610658
proc url_ListObjectPolicies_611982(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectPolicies_611981(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_611983 = query.getOrDefault("MaxResults")
  valid_611983 = validateParameter(valid_611983, JString, required = false,
                                 default = nil)
  if valid_611983 != nil:
    section.add "MaxResults", valid_611983
  var valid_611984 = query.getOrDefault("NextToken")
  valid_611984 = validateParameter(valid_611984, JString, required = false,
                                 default = nil)
  if valid_611984 != nil:
    section.add "NextToken", valid_611984
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611985 = header.getOrDefault("x-amz-consistency-level")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_611985 != nil:
    section.add "x-amz-consistency-level", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Signature")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Signature", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Content-Sha256", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Date")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Date", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Credential")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Credential", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Security-Token")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Security-Token", valid_611990
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_611991 = header.getOrDefault("x-amz-data-partition")
  valid_611991 = validateParameter(valid_611991, JString, required = true,
                                 default = nil)
  if valid_611991 != nil:
    section.add "x-amz-data-partition", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Algorithm")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Algorithm", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-SignedHeaders", valid_611993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611995: Call_ListObjectPolicies_611980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_611995.validator(path, query, header, formData, body)
  let scheme = call_611995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611995.url(scheme.get, call_611995.host, call_611995.base,
                         call_611995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611995, url, valid)

proc call*(call_611996: Call_ListObjectPolicies_611980; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611997 = newJObject()
  var body_611998 = newJObject()
  add(query_611997, "MaxResults", newJString(MaxResults))
  add(query_611997, "NextToken", newJString(NextToken))
  if body != nil:
    body_611998 = body
  result = call_611996.call(nil, query_611997, nil, nil, body_611998)

var listObjectPolicies* = Call_ListObjectPolicies_611980(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_611981, base: "/",
    url: url_ListObjectPolicies_611982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_611999 = ref object of OpenApiRestCall_610658
proc url_ListOutgoingTypedLinks_612001(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutgoingTypedLinks_612000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the directory where you want to list the typed links.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612002 = header.getOrDefault("X-Amz-Signature")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Signature", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Content-Sha256", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Date")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Date", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Credential")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Credential", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Security-Token")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Security-Token", valid_612006
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612007 = header.getOrDefault("x-amz-data-partition")
  valid_612007 = validateParameter(valid_612007, JString, required = true,
                                 default = nil)
  if valid_612007 != nil:
    section.add "x-amz-data-partition", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Algorithm")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Algorithm", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-SignedHeaders", valid_612009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612011: Call_ListOutgoingTypedLinks_611999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_612011.validator(path, query, header, formData, body)
  let scheme = call_612011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612011.url(scheme.get, call_612011.host, call_612011.base,
                         call_612011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612011, url, valid)

proc call*(call_612012: Call_ListOutgoingTypedLinks_611999; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_612013 = newJObject()
  if body != nil:
    body_612013 = body
  result = call_612012.call(nil, nil, nil, nil, body_612013)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_611999(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_612000, base: "/",
    url: url_ListOutgoingTypedLinks_612001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_612014 = ref object of OpenApiRestCall_610658
proc url_ListPolicyAttachments_612016(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicyAttachments_612015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612017 = query.getOrDefault("MaxResults")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "MaxResults", valid_612017
  var valid_612018 = query.getOrDefault("NextToken")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "NextToken", valid_612018
  result.add "query", section
  ## parameters in `header` object:
  ##   x-amz-consistency-level: JString
  ##                          : Represents the manner and timing in which the successful write or update of an object is reflected in a subsequent read operation of that same object.
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where objects reside. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612019 = header.getOrDefault("x-amz-consistency-level")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_612019 != nil:
    section.add "x-amz-consistency-level", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Signature")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Signature", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Content-Sha256", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Date")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Date", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Credential")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Credential", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Security-Token")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Security-Token", valid_612024
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612025 = header.getOrDefault("x-amz-data-partition")
  valid_612025 = validateParameter(valid_612025, JString, required = true,
                                 default = nil)
  if valid_612025 != nil:
    section.add "x-amz-data-partition", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Algorithm")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Algorithm", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-SignedHeaders", valid_612027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612029: Call_ListPolicyAttachments_612014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_612029.validator(path, query, header, formData, body)
  let scheme = call_612029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612029.url(scheme.get, call_612029.host, call_612029.base,
                         call_612029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612029, url, valid)

proc call*(call_612030: Call_ListPolicyAttachments_612014; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612031 = newJObject()
  var body_612032 = newJObject()
  add(query_612031, "MaxResults", newJString(MaxResults))
  add(query_612031, "NextToken", newJString(NextToken))
  if body != nil:
    body_612032 = body
  result = call_612030.call(nil, query_612031, nil, nil, body_612032)

var listPolicyAttachments* = Call_ListPolicyAttachments_612014(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_612015, base: "/",
    url: url_ListPolicyAttachments_612016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_612033 = ref object of OpenApiRestCall_610658
proc url_ListPublishedSchemaArns_612035(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublishedSchemaArns_612034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_612036 = query.getOrDefault("MaxResults")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "MaxResults", valid_612036
  var valid_612037 = query.getOrDefault("NextToken")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "NextToken", valid_612037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612038 = header.getOrDefault("X-Amz-Signature")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Signature", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Content-Sha256", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Date")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Date", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Credential")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Credential", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Security-Token")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Security-Token", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Algorithm")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Algorithm", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-SignedHeaders", valid_612044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612046: Call_ListPublishedSchemaArns_612033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_612046.validator(path, query, header, formData, body)
  let scheme = call_612046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612046.url(scheme.get, call_612046.host, call_612046.base,
                         call_612046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612046, url, valid)

proc call*(call_612047: Call_ListPublishedSchemaArns_612033; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612048 = newJObject()
  var body_612049 = newJObject()
  add(query_612048, "MaxResults", newJString(MaxResults))
  add(query_612048, "NextToken", newJString(NextToken))
  if body != nil:
    body_612049 = body
  result = call_612047.call(nil, query_612048, nil, nil, body_612049)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_612033(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_612034, base: "/",
    url: url_ListPublishedSchemaArns_612035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612050 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_612052(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_612051(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_612053 = query.getOrDefault("MaxResults")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "MaxResults", valid_612053
  var valid_612054 = query.getOrDefault("NextToken")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "NextToken", valid_612054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612055 = header.getOrDefault("X-Amz-Signature")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Signature", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-Content-Sha256", valid_612056
  var valid_612057 = header.getOrDefault("X-Amz-Date")
  valid_612057 = validateParameter(valid_612057, JString, required = false,
                                 default = nil)
  if valid_612057 != nil:
    section.add "X-Amz-Date", valid_612057
  var valid_612058 = header.getOrDefault("X-Amz-Credential")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "X-Amz-Credential", valid_612058
  var valid_612059 = header.getOrDefault("X-Amz-Security-Token")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "X-Amz-Security-Token", valid_612059
  var valid_612060 = header.getOrDefault("X-Amz-Algorithm")
  valid_612060 = validateParameter(valid_612060, JString, required = false,
                                 default = nil)
  if valid_612060 != nil:
    section.add "X-Amz-Algorithm", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-SignedHeaders", valid_612061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612063: Call_ListTagsForResource_612050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_612063.validator(path, query, header, formData, body)
  let scheme = call_612063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612063.url(scheme.get, call_612063.host, call_612063.base,
                         call_612063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612063, url, valid)

proc call*(call_612064: Call_ListTagsForResource_612050; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612065 = newJObject()
  var body_612066 = newJObject()
  add(query_612065, "MaxResults", newJString(MaxResults))
  add(query_612065, "NextToken", newJString(NextToken))
  if body != nil:
    body_612066 = body
  result = call_612064.call(nil, query_612065, nil, nil, body_612066)

var listTagsForResource* = Call_ListTagsForResource_612050(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_612051, base: "/",
    url: url_ListTagsForResource_612052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_612067 = ref object of OpenApiRestCall_610658
proc url_ListTypedLinkFacetAttributes_612069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetAttributes_612068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
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
  var valid_612070 = query.getOrDefault("MaxResults")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "MaxResults", valid_612070
  var valid_612071 = query.getOrDefault("NextToken")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "NextToken", valid_612071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612072 = header.getOrDefault("X-Amz-Signature")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "X-Amz-Signature", valid_612072
  var valid_612073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-Content-Sha256", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Date")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Date", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Credential")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Credential", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Security-Token")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Security-Token", valid_612076
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612077 = header.getOrDefault("x-amz-data-partition")
  valid_612077 = validateParameter(valid_612077, JString, required = true,
                                 default = nil)
  if valid_612077 != nil:
    section.add "x-amz-data-partition", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Algorithm")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Algorithm", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-SignedHeaders", valid_612079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612081: Call_ListTypedLinkFacetAttributes_612067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_612081.validator(path, query, header, formData, body)
  let scheme = call_612081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612081.url(scheme.get, call_612081.host, call_612081.base,
                         call_612081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612081, url, valid)

proc call*(call_612082: Call_ListTypedLinkFacetAttributes_612067; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612083 = newJObject()
  var body_612084 = newJObject()
  add(query_612083, "MaxResults", newJString(MaxResults))
  add(query_612083, "NextToken", newJString(NextToken))
  if body != nil:
    body_612084 = body
  result = call_612082.call(nil, query_612083, nil, nil, body_612084)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_612067(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_612068, base: "/",
    url: url_ListTypedLinkFacetAttributes_612069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_612085 = ref object of OpenApiRestCall_610658
proc url_ListTypedLinkFacetNames_612087(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetNames_612086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
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
  var valid_612088 = query.getOrDefault("MaxResults")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "MaxResults", valid_612088
  var valid_612089 = query.getOrDefault("NextToken")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "NextToken", valid_612089
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612090 = header.getOrDefault("X-Amz-Signature")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Signature", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Content-Sha256", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Date")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Date", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Credential")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Credential", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Security-Token")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Security-Token", valid_612094
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612095 = header.getOrDefault("x-amz-data-partition")
  valid_612095 = validateParameter(valid_612095, JString, required = true,
                                 default = nil)
  if valid_612095 != nil:
    section.add "x-amz-data-partition", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Algorithm")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Algorithm", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-SignedHeaders", valid_612097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612099: Call_ListTypedLinkFacetNames_612085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_612099.validator(path, query, header, formData, body)
  let scheme = call_612099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612099.url(scheme.get, call_612099.host, call_612099.base,
                         call_612099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612099, url, valid)

proc call*(call_612100: Call_ListTypedLinkFacetNames_612085; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612101 = newJObject()
  var body_612102 = newJObject()
  add(query_612101, "MaxResults", newJString(MaxResults))
  add(query_612101, "NextToken", newJString(NextToken))
  if body != nil:
    body_612102 = body
  result = call_612100.call(nil, query_612101, nil, nil, body_612102)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_612085(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_612086, base: "/",
    url: url_ListTypedLinkFacetNames_612087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_612103 = ref object of OpenApiRestCall_610658
proc url_LookupPolicy_612105(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LookupPolicy_612104(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
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
  var valid_612106 = query.getOrDefault("MaxResults")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "MaxResults", valid_612106
  var valid_612107 = query.getOrDefault("NextToken")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "NextToken", valid_612107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a>. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612108 = header.getOrDefault("X-Amz-Signature")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Signature", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-Content-Sha256", valid_612109
  var valid_612110 = header.getOrDefault("X-Amz-Date")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "X-Amz-Date", valid_612110
  var valid_612111 = header.getOrDefault("X-Amz-Credential")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Credential", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Security-Token")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Security-Token", valid_612112
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612113 = header.getOrDefault("x-amz-data-partition")
  valid_612113 = validateParameter(valid_612113, JString, required = true,
                                 default = nil)
  if valid_612113 != nil:
    section.add "x-amz-data-partition", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Algorithm")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Algorithm", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-SignedHeaders", valid_612115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612117: Call_LookupPolicy_612103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ## 
  let valid = call_612117.validator(path, query, header, formData, body)
  let scheme = call_612117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612117.url(scheme.get, call_612117.host, call_612117.base,
                         call_612117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612117, url, valid)

proc call*(call_612118: Call_LookupPolicy_612103; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612119 = newJObject()
  var body_612120 = newJObject()
  add(query_612119, "MaxResults", newJString(MaxResults))
  add(query_612119, "NextToken", newJString(NextToken))
  if body != nil:
    body_612120 = body
  result = call_612118.call(nil, query_612119, nil, nil, body_612120)

var lookupPolicy* = Call_LookupPolicy_612103(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_612104, base: "/", url: url_LookupPolicy_612105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_612121 = ref object of OpenApiRestCall_610658
proc url_PublishSchema_612123(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PublishSchema_612122(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the development schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612124 = header.getOrDefault("X-Amz-Signature")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Signature", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-Content-Sha256", valid_612125
  var valid_612126 = header.getOrDefault("X-Amz-Date")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Date", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Credential")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Credential", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Security-Token")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Security-Token", valid_612128
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612129 = header.getOrDefault("x-amz-data-partition")
  valid_612129 = validateParameter(valid_612129, JString, required = true,
                                 default = nil)
  if valid_612129 != nil:
    section.add "x-amz-data-partition", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Algorithm")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Algorithm", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-SignedHeaders", valid_612131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612133: Call_PublishSchema_612121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_612133.validator(path, query, header, formData, body)
  let scheme = call_612133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612133.url(scheme.get, call_612133.host, call_612133.base,
                         call_612133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612133, url, valid)

proc call*(call_612134: Call_PublishSchema_612121; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_612135 = newJObject()
  if body != nil:
    body_612135 = body
  result = call_612134.call(nil, nil, nil, nil, body_612135)

var publishSchema* = Call_PublishSchema_612121(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_612122, base: "/", url: url_PublishSchema_612123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_612136 = ref object of OpenApiRestCall_610658
proc url_RemoveFacetFromObject_612138(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveFacetFromObject_612137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified facet from the specified object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The ARN of the directory in which the object resides.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612139 = header.getOrDefault("X-Amz-Signature")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Signature", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Content-Sha256", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Date")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Date", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Credential")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Credential", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Security-Token")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Security-Token", valid_612143
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612144 = header.getOrDefault("x-amz-data-partition")
  valid_612144 = validateParameter(valid_612144, JString, required = true,
                                 default = nil)
  if valid_612144 != nil:
    section.add "x-amz-data-partition", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Algorithm")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Algorithm", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-SignedHeaders", valid_612146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612148: Call_RemoveFacetFromObject_612136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_612148.validator(path, query, header, formData, body)
  let scheme = call_612148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612148.url(scheme.get, call_612148.host, call_612148.base,
                         call_612148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612148, url, valid)

proc call*(call_612149: Call_RemoveFacetFromObject_612136; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_612150 = newJObject()
  if body != nil:
    body_612150 = body
  result = call_612149.call(nil, nil, nil, nil, body_612150)

var removeFacetFromObject* = Call_RemoveFacetFromObject_612136(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_612137, base: "/",
    url: url_RemoveFacetFromObject_612138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612151 = ref object of OpenApiRestCall_610658
proc url_TagResource_612153(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_612152(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## An API operation for adding tags to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612154 = header.getOrDefault("X-Amz-Signature")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Signature", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Content-Sha256", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Date")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Date", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-Credential")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-Credential", valid_612157
  var valid_612158 = header.getOrDefault("X-Amz-Security-Token")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "X-Amz-Security-Token", valid_612158
  var valid_612159 = header.getOrDefault("X-Amz-Algorithm")
  valid_612159 = validateParameter(valid_612159, JString, required = false,
                                 default = nil)
  if valid_612159 != nil:
    section.add "X-Amz-Algorithm", valid_612159
  var valid_612160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612160 = validateParameter(valid_612160, JString, required = false,
                                 default = nil)
  if valid_612160 != nil:
    section.add "X-Amz-SignedHeaders", valid_612160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612162: Call_TagResource_612151; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_612162.validator(path, query, header, formData, body)
  let scheme = call_612162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612162.url(scheme.get, call_612162.host, call_612162.base,
                         call_612162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612162, url, valid)

proc call*(call_612163: Call_TagResource_612151; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_612164 = newJObject()
  if body != nil:
    body_612164 = body
  result = call_612163.call(nil, nil, nil, nil, body_612164)

var tagResource* = Call_TagResource_612151(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_612152,
                                        base: "/", url: url_TagResource_612153,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612165 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612167(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_612166(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## An API operation for removing tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612168 = header.getOrDefault("X-Amz-Signature")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Signature", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Content-Sha256", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-Date")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Date", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Credential")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Credential", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Security-Token")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Security-Token", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-Algorithm")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-Algorithm", valid_612173
  var valid_612174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-SignedHeaders", valid_612174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612176: Call_UntagResource_612165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_612176.validator(path, query, header, formData, body)
  let scheme = call_612176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612176.url(scheme.get, call_612176.host, call_612176.base,
                         call_612176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612176, url, valid)

proc call*(call_612177: Call_UntagResource_612165; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_612178 = newJObject()
  if body != nil:
    body_612178 = body
  result = call_612177.call(nil, nil, nil, nil, body_612178)

var untagResource* = Call_UntagResource_612165(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_612166, base: "/", url: url_UntagResource_612167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_612179 = ref object of OpenApiRestCall_610658
proc url_UpdateLinkAttributes_612181(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLinkAttributes_612180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see <a>arns</a> or <a 
  ## href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612182 = header.getOrDefault("X-Amz-Signature")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Signature", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Content-Sha256", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Date")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Date", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Credential")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Credential", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Security-Token")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Security-Token", valid_612186
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612187 = header.getOrDefault("x-amz-data-partition")
  valid_612187 = validateParameter(valid_612187, JString, required = true,
                                 default = nil)
  if valid_612187 != nil:
    section.add "x-amz-data-partition", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-Algorithm")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-Algorithm", valid_612188
  var valid_612189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "X-Amz-SignedHeaders", valid_612189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612191: Call_UpdateLinkAttributes_612179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_612191.validator(path, query, header, formData, body)
  let scheme = call_612191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612191.url(scheme.get, call_612191.host, call_612191.base,
                         call_612191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612191, url, valid)

proc call*(call_612192: Call_UpdateLinkAttributes_612179; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_612193 = newJObject()
  if body != nil:
    body_612193 = body
  result = call_612192.call(nil, nil, nil, nil, body_612193)

var updateLinkAttributes* = Call_UpdateLinkAttributes_612179(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_612180, base: "/",
    url: url_UpdateLinkAttributes_612181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_612194 = ref object of OpenApiRestCall_610658
proc url_UpdateObjectAttributes_612196(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateObjectAttributes_612195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a given object's attributes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the <a>Directory</a> where the object resides. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612197 = header.getOrDefault("X-Amz-Signature")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Signature", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Content-Sha256", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Date")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Date", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Credential")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Credential", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Security-Token")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Security-Token", valid_612201
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612202 = header.getOrDefault("x-amz-data-partition")
  valid_612202 = validateParameter(valid_612202, JString, required = true,
                                 default = nil)
  if valid_612202 != nil:
    section.add "x-amz-data-partition", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-Algorithm")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Algorithm", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-SignedHeaders", valid_612204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612206: Call_UpdateObjectAttributes_612194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_612206.validator(path, query, header, formData, body)
  let scheme = call_612206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612206.url(scheme.get, call_612206.host, call_612206.base,
                         call_612206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612206, url, valid)

proc call*(call_612207: Call_UpdateObjectAttributes_612194; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_612208 = newJObject()
  if body != nil:
    body_612208 = body
  result = call_612207.call(nil, nil, nil, nil, body_612208)

var updateObjectAttributes* = Call_UpdateObjectAttributes_612194(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_612195, base: "/",
    url: url_UpdateObjectAttributes_612196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_612209 = ref object of OpenApiRestCall_610658
proc url_UpdateSchema_612211(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSchema_612210(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) of the development schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612212 = header.getOrDefault("X-Amz-Signature")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Signature", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Content-Sha256", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Date")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Date", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Credential")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Credential", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Security-Token")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Security-Token", valid_612216
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612217 = header.getOrDefault("x-amz-data-partition")
  valid_612217 = validateParameter(valid_612217, JString, required = true,
                                 default = nil)
  if valid_612217 != nil:
    section.add "x-amz-data-partition", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Algorithm")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Algorithm", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-SignedHeaders", valid_612219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612221: Call_UpdateSchema_612209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_612221.validator(path, query, header, formData, body)
  let scheme = call_612221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612221.url(scheme.get, call_612221.host, call_612221.base,
                         call_612221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612221, url, valid)

proc call*(call_612222: Call_UpdateSchema_612209; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_612223 = newJObject()
  if body != nil:
    body_612223 = body
  result = call_612222.call(nil, nil, nil, nil, body_612223)

var updateSchema* = Call_UpdateSchema_612209(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_612210, base: "/", url: url_UpdateSchema_612211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_612224 = ref object of OpenApiRestCall_610658
proc url_UpdateTypedLinkFacet_612226(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTypedLinkFacet_612225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the schema. For more information, see <a>arns</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612227 = header.getOrDefault("X-Amz-Signature")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "X-Amz-Signature", valid_612227
  var valid_612228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "X-Amz-Content-Sha256", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Date")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Date", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Credential")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Credential", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Security-Token")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Security-Token", valid_612231
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_612232 = header.getOrDefault("x-amz-data-partition")
  valid_612232 = validateParameter(valid_612232, JString, required = true,
                                 default = nil)
  if valid_612232 != nil:
    section.add "x-amz-data-partition", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Algorithm")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Algorithm", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-SignedHeaders", valid_612234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612236: Call_UpdateTypedLinkFacet_612224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_612236.validator(path, query, header, formData, body)
  let scheme = call_612236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612236.url(scheme.get, call_612236.host, call_612236.base,
                         call_612236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612236, url, valid)

proc call*(call_612237: Call_UpdateTypedLinkFacet_612224; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_612238 = newJObject()
  if body != nil:
    body_612238 = body
  result = call_612237.call(nil, nil, nil, nil, body_612238)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_612224(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_612225, base: "/",
    url: url_UpdateTypedLinkFacet_612226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_612239 = ref object of OpenApiRestCall_610658
proc url_UpgradeAppliedSchema_612241(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeAppliedSchema_612240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612242 = header.getOrDefault("X-Amz-Signature")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Signature", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Content-Sha256", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Date")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Date", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Credential")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Credential", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Security-Token")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Security-Token", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Algorithm")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Algorithm", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-SignedHeaders", valid_612248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612250: Call_UpgradeAppliedSchema_612239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_612250.validator(path, query, header, formData, body)
  let scheme = call_612250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612250.url(scheme.get, call_612250.host, call_612250.base,
                         call_612250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612250, url, valid)

proc call*(call_612251: Call_UpgradeAppliedSchema_612239; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_612252 = newJObject()
  if body != nil:
    body_612252 = body
  result = call_612251.call(nil, nil, nil, nil, body_612252)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_612239(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_612240, base: "/",
    url: url_UpgradeAppliedSchema_612241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_612253 = ref object of OpenApiRestCall_610658
proc url_UpgradePublishedSchema_612255(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradePublishedSchema_612254(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612256 = header.getOrDefault("X-Amz-Signature")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Signature", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Content-Sha256", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Date")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Date", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Credential")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Credential", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Security-Token")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Security-Token", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Algorithm")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Algorithm", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-SignedHeaders", valid_612262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612264: Call_UpgradePublishedSchema_612253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_612264.validator(path, query, header, formData, body)
  let scheme = call_612264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612264.url(scheme.get, call_612264.host, call_612264.base,
                         call_612264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612264, url, valid)

proc call*(call_612265: Call_UpgradePublishedSchema_612253; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_612266 = newJObject()
  if body != nil:
    body_612266 = body
  result = call_612265.call(nil, nil, nil, nil, body_612266)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_612253(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_612254, base: "/",
    url: url_UpgradePublishedSchema_612255, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
