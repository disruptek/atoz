
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_AddFacetToObject_605927 = ref object of OpenApiRestCall_605589
proc url_AddFacetToObject_605929(protocol: Scheme; host: string; base: string;
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

proc validate_AddFacetToObject_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606046 = header.getOrDefault("x-amz-data-partition")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "x-amz-data-partition", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Algorithm")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Algorithm", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-SignedHeaders", valid_606048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606072: Call_AddFacetToObject_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_606072.validator(path, query, header, formData, body)
  let scheme = call_606072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606072.url(scheme.get, call_606072.host, call_606072.base,
                         call_606072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606072, url, valid)

proc call*(call_606143: Call_AddFacetToObject_605927; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_606144 = newJObject()
  if body != nil:
    body_606144 = body
  result = call_606143.call(nil, nil, nil, nil, body_606144)

var addFacetToObject* = Call_AddFacetToObject_605927(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_605928, base: "/",
    url: url_AddFacetToObject_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_606183 = ref object of OpenApiRestCall_605589
proc url_ApplySchema_606185(protocol: Scheme; host: string; base: string;
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

proc validate_ApplySchema_606184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606186 = header.getOrDefault("X-Amz-Signature")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Signature", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Content-Sha256", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Date")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Date", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Credential")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Credential", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Security-Token")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Security-Token", valid_606190
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606191 = header.getOrDefault("x-amz-data-partition")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = nil)
  if valid_606191 != nil:
    section.add "x-amz-data-partition", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Algorithm")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Algorithm", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-SignedHeaders", valid_606193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606195: Call_ApplySchema_606183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_606195.validator(path, query, header, formData, body)
  let scheme = call_606195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606195.url(scheme.get, call_606195.host, call_606195.base,
                         call_606195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606195, url, valid)

proc call*(call_606196: Call_ApplySchema_606183; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_606197 = newJObject()
  if body != nil:
    body_606197 = body
  result = call_606196.call(nil, nil, nil, nil, body_606197)

var applySchema* = Call_ApplySchema_606183(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_606184,
                                        base: "/", url: url_ApplySchema_606185,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_606198 = ref object of OpenApiRestCall_605589
proc url_AttachObject_606200(protocol: Scheme; host: string; base: string;
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

proc validate_AttachObject_606199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606206 = header.getOrDefault("x-amz-data-partition")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = nil)
  if valid_606206 != nil:
    section.add "x-amz-data-partition", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Algorithm")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Algorithm", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-SignedHeaders", valid_606208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606210: Call_AttachObject_606198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_606210.validator(path, query, header, formData, body)
  let scheme = call_606210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606210.url(scheme.get, call_606210.host, call_606210.base,
                         call_606210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606210, url, valid)

proc call*(call_606211: Call_AttachObject_606198; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_606212 = newJObject()
  if body != nil:
    body_606212 = body
  result = call_606211.call(nil, nil, nil, nil, body_606212)

var attachObject* = Call_AttachObject_606198(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_606199, base: "/", url: url_AttachObject_606200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_606213 = ref object of OpenApiRestCall_605589
proc url_AttachPolicy_606215(protocol: Scheme; host: string; base: string;
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

proc validate_AttachPolicy_606214(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606221 = header.getOrDefault("x-amz-data-partition")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "x-amz-data-partition", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Algorithm")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Algorithm", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-SignedHeaders", valid_606223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606225: Call_AttachPolicy_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_606225.validator(path, query, header, formData, body)
  let scheme = call_606225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606225.url(scheme.get, call_606225.host, call_606225.base,
                         call_606225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606225, url, valid)

proc call*(call_606226: Call_AttachPolicy_606213; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_606227 = newJObject()
  if body != nil:
    body_606227 = body
  result = call_606226.call(nil, nil, nil, nil, body_606227)

var attachPolicy* = Call_AttachPolicy_606213(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_606214, base: "/", url: url_AttachPolicy_606215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_606228 = ref object of OpenApiRestCall_605589
proc url_AttachToIndex_606230(protocol: Scheme; host: string; base: string;
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

proc validate_AttachToIndex_606229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606231 = header.getOrDefault("X-Amz-Signature")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Signature", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Content-Sha256", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Date")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Date", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Credential")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Credential", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Security-Token")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Security-Token", valid_606235
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606236 = header.getOrDefault("x-amz-data-partition")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "x-amz-data-partition", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Algorithm")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Algorithm", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-SignedHeaders", valid_606238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606240: Call_AttachToIndex_606228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_606240.validator(path, query, header, formData, body)
  let scheme = call_606240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606240.url(scheme.get, call_606240.host, call_606240.base,
                         call_606240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606240, url, valid)

proc call*(call_606241: Call_AttachToIndex_606228; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_606242 = newJObject()
  if body != nil:
    body_606242 = body
  result = call_606241.call(nil, nil, nil, nil, body_606242)

var attachToIndex* = Call_AttachToIndex_606228(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_606229, base: "/", url: url_AttachToIndex_606230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_606243 = ref object of OpenApiRestCall_605589
proc url_AttachTypedLink_606245(protocol: Scheme; host: string; base: string;
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

proc validate_AttachTypedLink_606244(path: JsonNode; query: JsonNode;
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
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606251 = header.getOrDefault("x-amz-data-partition")
  valid_606251 = validateParameter(valid_606251, JString, required = true,
                                 default = nil)
  if valid_606251 != nil:
    section.add "x-amz-data-partition", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_AttachTypedLink_606243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_AttachTypedLink_606243; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606257 = newJObject()
  if body != nil:
    body_606257 = body
  result = call_606256.call(nil, nil, nil, nil, body_606257)

var attachTypedLink* = Call_AttachTypedLink_606243(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_606244, base: "/", url: url_AttachTypedLink_606245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_606258 = ref object of OpenApiRestCall_605589
proc url_BatchRead_606260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_BatchRead_606259(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606274 = header.getOrDefault("x-amz-consistency-level")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606274 != nil:
    section.add "x-amz-consistency-level", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606280 = header.getOrDefault("x-amz-data-partition")
  valid_606280 = validateParameter(valid_606280, JString, required = true,
                                 default = nil)
  if valid_606280 != nil:
    section.add "x-amz-data-partition", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Algorithm")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Algorithm", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-SignedHeaders", valid_606282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606284: Call_BatchRead_606258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_606284.validator(path, query, header, formData, body)
  let scheme = call_606284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606284.url(scheme.get, call_606284.host, call_606284.base,
                         call_606284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606284, url, valid)

proc call*(call_606285: Call_BatchRead_606258; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_606286 = newJObject()
  if body != nil:
    body_606286 = body
  result = call_606285.call(nil, nil, nil, nil, body_606286)

var batchRead* = Call_BatchRead_606258(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_606259,
                                    base: "/", url: url_BatchRead_606260,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_606287 = ref object of OpenApiRestCall_605589
proc url_BatchWrite_606289(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_BatchWrite_606288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606295 = header.getOrDefault("x-amz-data-partition")
  valid_606295 = validateParameter(valid_606295, JString, required = true,
                                 default = nil)
  if valid_606295 != nil:
    section.add "x-amz-data-partition", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Algorithm")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Algorithm", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-SignedHeaders", valid_606297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606299: Call_BatchWrite_606287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_606299.validator(path, query, header, formData, body)
  let scheme = call_606299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606299.url(scheme.get, call_606299.host, call_606299.base,
                         call_606299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606299, url, valid)

proc call*(call_606300: Call_BatchWrite_606287; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_606301 = newJObject()
  if body != nil:
    body_606301 = body
  result = call_606300.call(nil, nil, nil, nil, body_606301)

var batchWrite* = Call_BatchWrite_606287(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_606288,
                                      base: "/", url: url_BatchWrite_606289,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_606302 = ref object of OpenApiRestCall_605589
proc url_CreateDirectory_606304(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDirectory_606303(path: JsonNode; query: JsonNode;
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
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606310 = header.getOrDefault("x-amz-data-partition")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = nil)
  if valid_606310 != nil:
    section.add "x-amz-data-partition", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Algorithm")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Algorithm", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-SignedHeaders", valid_606312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_CreateDirectory_606302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_CreateDirectory_606302; body: JsonNode): Recallable =
  ## createDirectory
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ##   body: JObject (required)
  var body_606316 = newJObject()
  if body != nil:
    body_606316 = body
  result = call_606315.call(nil, nil, nil, nil, body_606316)

var createDirectory* = Call_CreateDirectory_606302(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_606303, base: "/", url: url_CreateDirectory_606304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_606317 = ref object of OpenApiRestCall_605589
proc url_CreateFacet_606319(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFacet_606318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606325 = header.getOrDefault("x-amz-data-partition")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "x-amz-data-partition", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Algorithm")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Algorithm", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-SignedHeaders", valid_606327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606329: Call_CreateFacet_606317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_606329.validator(path, query, header, formData, body)
  let scheme = call_606329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606329.url(scheme.get, call_606329.host, call_606329.base,
                         call_606329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606329, url, valid)

proc call*(call_606330: Call_CreateFacet_606317; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_606331 = newJObject()
  if body != nil:
    body_606331 = body
  result = call_606330.call(nil, nil, nil, nil, body_606331)

var createFacet* = Call_CreateFacet_606317(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_606318,
                                        base: "/", url: url_CreateFacet_606319,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_606332 = ref object of OpenApiRestCall_605589
proc url_CreateIndex_606334(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIndex_606333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606340 = header.getOrDefault("x-amz-data-partition")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = nil)
  if valid_606340 != nil:
    section.add "x-amz-data-partition", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Algorithm")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Algorithm", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-SignedHeaders", valid_606342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606344: Call_CreateIndex_606332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  let valid = call_606344.validator(path, query, header, formData, body)
  let scheme = call_606344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606344.url(scheme.get, call_606344.host, call_606344.base,
                         call_606344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606344, url, valid)

proc call*(call_606345: Call_CreateIndex_606332; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ##   body: JObject (required)
  var body_606346 = newJObject()
  if body != nil:
    body_606346 = body
  result = call_606345.call(nil, nil, nil, nil, body_606346)

var createIndex* = Call_CreateIndex_606332(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_606333,
                                        base: "/", url: url_CreateIndex_606334,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_606347 = ref object of OpenApiRestCall_605589
proc url_CreateObject_606349(protocol: Scheme; host: string; base: string;
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

proc validate_CreateObject_606348(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606355 = header.getOrDefault("x-amz-data-partition")
  valid_606355 = validateParameter(valid_606355, JString, required = true,
                                 default = nil)
  if valid_606355 != nil:
    section.add "x-amz-data-partition", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Algorithm")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Algorithm", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-SignedHeaders", valid_606357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_CreateObject_606347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_CreateObject_606347; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_606361 = newJObject()
  if body != nil:
    body_606361 = body
  result = call_606360.call(nil, nil, nil, nil, body_606361)

var createObject* = Call_CreateObject_606347(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_606348, base: "/", url: url_CreateObject_606349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_606362 = ref object of OpenApiRestCall_605589
proc url_CreateSchema_606364(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_606363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CreateSchema_606362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CreateSchema_606362; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var createSchema* = Call_CreateSchema_606362(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_606363, base: "/", url: url_CreateSchema_606364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_606376 = ref object of OpenApiRestCall_605589
proc url_CreateTypedLinkFacet_606378(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTypedLinkFacet_606377(path: JsonNode; query: JsonNode;
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
  var valid_606379 = header.getOrDefault("X-Amz-Signature")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Signature", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Content-Sha256", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Date")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Date", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Credential")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Credential", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Security-Token")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Security-Token", valid_606383
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606384 = header.getOrDefault("x-amz-data-partition")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = nil)
  if valid_606384 != nil:
    section.add "x-amz-data-partition", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_CreateTypedLinkFacet_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_CreateTypedLinkFacet_606376; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_606376(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_606377, base: "/",
    url: url_CreateTypedLinkFacet_606378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_606391 = ref object of OpenApiRestCall_605589
proc url_DeleteDirectory_606393(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDirectory_606392(path: JsonNode; query: JsonNode;
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
  var valid_606394 = header.getOrDefault("X-Amz-Signature")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Signature", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Content-Sha256", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Date")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Date", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Credential")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Credential", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Security-Token")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Security-Token", valid_606398
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606399 = header.getOrDefault("x-amz-data-partition")
  valid_606399 = validateParameter(valid_606399, JString, required = true,
                                 default = nil)
  if valid_606399 != nil:
    section.add "x-amz-data-partition", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606402: Call_DeleteDirectory_606391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_606402.validator(path, query, header, formData, body)
  let scheme = call_606402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606402.url(scheme.get, call_606402.host, call_606402.base,
                         call_606402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606402, url, valid)

proc call*(call_606403: Call_DeleteDirectory_606391): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_606403.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_606391(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_606392, base: "/", url: url_DeleteDirectory_606393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_606404 = ref object of OpenApiRestCall_605589
proc url_DeleteFacet_606406(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFacet_606405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606407 = header.getOrDefault("X-Amz-Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Signature", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Content-Sha256", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Date")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Date", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Credential")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Credential", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Security-Token")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Security-Token", valid_606411
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606412 = header.getOrDefault("x-amz-data-partition")
  valid_606412 = validateParameter(valid_606412, JString, required = true,
                                 default = nil)
  if valid_606412 != nil:
    section.add "x-amz-data-partition", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Algorithm")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Algorithm", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-SignedHeaders", valid_606414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606416: Call_DeleteFacet_606404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_606416.validator(path, query, header, formData, body)
  let scheme = call_606416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606416.url(scheme.get, call_606416.host, call_606416.base,
                         call_606416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606416, url, valid)

proc call*(call_606417: Call_DeleteFacet_606404; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_606418 = newJObject()
  if body != nil:
    body_606418 = body
  result = call_606417.call(nil, nil, nil, nil, body_606418)

var deleteFacet* = Call_DeleteFacet_606404(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_606405,
                                        base: "/", url: url_DeleteFacet_606406,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_606419 = ref object of OpenApiRestCall_605589
proc url_DeleteObject_606421(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_606420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606422 = header.getOrDefault("X-Amz-Signature")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Signature", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Content-Sha256", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Date")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Date", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Credential")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Credential", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Security-Token")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Security-Token", valid_606426
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606427 = header.getOrDefault("x-amz-data-partition")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "x-amz-data-partition", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Algorithm")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Algorithm", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-SignedHeaders", valid_606429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606431: Call_DeleteObject_606419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  let valid = call_606431.validator(path, query, header, formData, body)
  let scheme = call_606431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606431.url(scheme.get, call_606431.host, call_606431.base,
                         call_606431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606431, url, valid)

proc call*(call_606432: Call_DeleteObject_606419; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ##   body: JObject (required)
  var body_606433 = newJObject()
  if body != nil:
    body_606433 = body
  result = call_606432.call(nil, nil, nil, nil, body_606433)

var deleteObject* = Call_DeleteObject_606419(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_606420, base: "/", url: url_DeleteObject_606421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_606434 = ref object of OpenApiRestCall_605589
proc url_DeleteSchema_606436(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_606435(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606437 = header.getOrDefault("X-Amz-Signature")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Signature", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Content-Sha256", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Date")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Date", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Credential")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Credential", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Security-Token")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Security-Token", valid_606441
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606442 = header.getOrDefault("x-amz-data-partition")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "x-amz-data-partition", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Algorithm")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Algorithm", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-SignedHeaders", valid_606444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606445: Call_DeleteSchema_606434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_606445.validator(path, query, header, formData, body)
  let scheme = call_606445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606445.url(scheme.get, call_606445.host, call_606445.base,
                         call_606445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606445, url, valid)

proc call*(call_606446: Call_DeleteSchema_606434): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_606446.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_606434(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_606435, base: "/", url: url_DeleteSchema_606436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_606447 = ref object of OpenApiRestCall_605589
proc url_DeleteTypedLinkFacet_606449(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTypedLinkFacet_606448(path: JsonNode; query: JsonNode;
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
  var valid_606450 = header.getOrDefault("X-Amz-Signature")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Signature", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Content-Sha256", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Date")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Date", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Credential")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Credential", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Security-Token")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Security-Token", valid_606454
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606455 = header.getOrDefault("x-amz-data-partition")
  valid_606455 = validateParameter(valid_606455, JString, required = true,
                                 default = nil)
  if valid_606455 != nil:
    section.add "x-amz-data-partition", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Algorithm")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Algorithm", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-SignedHeaders", valid_606457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606459: Call_DeleteTypedLinkFacet_606447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606459.validator(path, query, header, formData, body)
  let scheme = call_606459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606459.url(scheme.get, call_606459.host, call_606459.base,
                         call_606459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606459, url, valid)

proc call*(call_606460: Call_DeleteTypedLinkFacet_606447; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606461 = newJObject()
  if body != nil:
    body_606461 = body
  result = call_606460.call(nil, nil, nil, nil, body_606461)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_606447(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_606448, base: "/",
    url: url_DeleteTypedLinkFacet_606449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_606462 = ref object of OpenApiRestCall_605589
proc url_DetachFromIndex_606464(protocol: Scheme; host: string; base: string;
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

proc validate_DetachFromIndex_606463(path: JsonNode; query: JsonNode;
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
  var valid_606465 = header.getOrDefault("X-Amz-Signature")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Signature", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Content-Sha256", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Date")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Date", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Credential")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Credential", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Security-Token")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Security-Token", valid_606469
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606470 = header.getOrDefault("x-amz-data-partition")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = nil)
  if valid_606470 != nil:
    section.add "x-amz-data-partition", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Algorithm")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Algorithm", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-SignedHeaders", valid_606472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606474: Call_DetachFromIndex_606462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_606474.validator(path, query, header, formData, body)
  let scheme = call_606474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606474.url(scheme.get, call_606474.host, call_606474.base,
                         call_606474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606474, url, valid)

proc call*(call_606475: Call_DetachFromIndex_606462; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_606476 = newJObject()
  if body != nil:
    body_606476 = body
  result = call_606475.call(nil, nil, nil, nil, body_606476)

var detachFromIndex* = Call_DetachFromIndex_606462(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_606463, base: "/", url: url_DetachFromIndex_606464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_606477 = ref object of OpenApiRestCall_605589
proc url_DetachObject_606479(protocol: Scheme; host: string; base: string;
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

proc validate_DetachObject_606478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606480 = header.getOrDefault("X-Amz-Signature")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Signature", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Content-Sha256", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Date")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Date", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Credential")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Credential", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Security-Token")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Security-Token", valid_606484
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606485 = header.getOrDefault("x-amz-data-partition")
  valid_606485 = validateParameter(valid_606485, JString, required = true,
                                 default = nil)
  if valid_606485 != nil:
    section.add "x-amz-data-partition", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Algorithm")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Algorithm", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-SignedHeaders", valid_606487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606489: Call_DetachObject_606477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_606489.validator(path, query, header, formData, body)
  let scheme = call_606489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606489.url(scheme.get, call_606489.host, call_606489.base,
                         call_606489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606489, url, valid)

proc call*(call_606490: Call_DetachObject_606477; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_606491 = newJObject()
  if body != nil:
    body_606491 = body
  result = call_606490.call(nil, nil, nil, nil, body_606491)

var detachObject* = Call_DetachObject_606477(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_606478, base: "/", url: url_DetachObject_606479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_606492 = ref object of OpenApiRestCall_605589
proc url_DetachPolicy_606494(protocol: Scheme; host: string; base: string;
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

proc validate_DetachPolicy_606493(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606495 = header.getOrDefault("X-Amz-Signature")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Signature", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Content-Sha256", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Date")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Date", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Credential")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Credential", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Security-Token")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Security-Token", valid_606499
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606500 = header.getOrDefault("x-amz-data-partition")
  valid_606500 = validateParameter(valid_606500, JString, required = true,
                                 default = nil)
  if valid_606500 != nil:
    section.add "x-amz-data-partition", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Algorithm")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Algorithm", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-SignedHeaders", valid_606502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606504: Call_DetachPolicy_606492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_606504.validator(path, query, header, formData, body)
  let scheme = call_606504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606504.url(scheme.get, call_606504.host, call_606504.base,
                         call_606504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606504, url, valid)

proc call*(call_606505: Call_DetachPolicy_606492; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_606506 = newJObject()
  if body != nil:
    body_606506 = body
  result = call_606505.call(nil, nil, nil, nil, body_606506)

var detachPolicy* = Call_DetachPolicy_606492(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_606493, base: "/", url: url_DetachPolicy_606494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_606507 = ref object of OpenApiRestCall_605589
proc url_DetachTypedLink_606509(protocol: Scheme; host: string; base: string;
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

proc validate_DetachTypedLink_606508(path: JsonNode; query: JsonNode;
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
  var valid_606510 = header.getOrDefault("X-Amz-Signature")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Signature", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Content-Sha256", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Date")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Date", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Credential")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Credential", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Security-Token")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Security-Token", valid_606514
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606515 = header.getOrDefault("x-amz-data-partition")
  valid_606515 = validateParameter(valid_606515, JString, required = true,
                                 default = nil)
  if valid_606515 != nil:
    section.add "x-amz-data-partition", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Algorithm")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Algorithm", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-SignedHeaders", valid_606517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606519: Call_DetachTypedLink_606507; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606519.validator(path, query, header, formData, body)
  let scheme = call_606519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606519.url(scheme.get, call_606519.host, call_606519.base,
                         call_606519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606519, url, valid)

proc call*(call_606520: Call_DetachTypedLink_606507; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606521 = newJObject()
  if body != nil:
    body_606521 = body
  result = call_606520.call(nil, nil, nil, nil, body_606521)

var detachTypedLink* = Call_DetachTypedLink_606507(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_606508, base: "/", url: url_DetachTypedLink_606509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_606522 = ref object of OpenApiRestCall_605589
proc url_DisableDirectory_606524(protocol: Scheme; host: string; base: string;
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

proc validate_DisableDirectory_606523(path: JsonNode; query: JsonNode;
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
  var valid_606525 = header.getOrDefault("X-Amz-Signature")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Signature", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Content-Sha256", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Date")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Date", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Credential")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Credential", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Security-Token")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Security-Token", valid_606529
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606530 = header.getOrDefault("x-amz-data-partition")
  valid_606530 = validateParameter(valid_606530, JString, required = true,
                                 default = nil)
  if valid_606530 != nil:
    section.add "x-amz-data-partition", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Algorithm")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Algorithm", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-SignedHeaders", valid_606532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606533: Call_DisableDirectory_606522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_606533.validator(path, query, header, formData, body)
  let scheme = call_606533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606533.url(scheme.get, call_606533.host, call_606533.base,
                         call_606533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606533, url, valid)

proc call*(call_606534: Call_DisableDirectory_606522): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_606534.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_606522(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_606523, base: "/",
    url: url_DisableDirectory_606524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_606535 = ref object of OpenApiRestCall_605589
proc url_EnableDirectory_606537(protocol: Scheme; host: string; base: string;
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

proc validate_EnableDirectory_606536(path: JsonNode; query: JsonNode;
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
  var valid_606538 = header.getOrDefault("X-Amz-Signature")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Signature", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Content-Sha256", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Date")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Date", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Credential")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Credential", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Security-Token")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Security-Token", valid_606542
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606543 = header.getOrDefault("x-amz-data-partition")
  valid_606543 = validateParameter(valid_606543, JString, required = true,
                                 default = nil)
  if valid_606543 != nil:
    section.add "x-amz-data-partition", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Algorithm")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Algorithm", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-SignedHeaders", valid_606545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606546: Call_EnableDirectory_606535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_606546.validator(path, query, header, formData, body)
  let scheme = call_606546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606546.url(scheme.get, call_606546.host, call_606546.base,
                         call_606546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606546, url, valid)

proc call*(call_606547: Call_EnableDirectory_606535): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_606547.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_606535(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_606536, base: "/", url: url_EnableDirectory_606537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_606548 = ref object of OpenApiRestCall_605589
proc url_GetAppliedSchemaVersion_606550(protocol: Scheme; host: string; base: string;
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

proc validate_GetAppliedSchemaVersion_606549(path: JsonNode; query: JsonNode;
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
  var valid_606551 = header.getOrDefault("X-Amz-Signature")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Signature", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Content-Sha256", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Date")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Date", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Credential")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Credential", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Security-Token")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Security-Token", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Algorithm")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Algorithm", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-SignedHeaders", valid_606557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606559: Call_GetAppliedSchemaVersion_606548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_606559.validator(path, query, header, formData, body)
  let scheme = call_606559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606559.url(scheme.get, call_606559.host, call_606559.base,
                         call_606559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606559, url, valid)

proc call*(call_606560: Call_GetAppliedSchemaVersion_606548; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_606561 = newJObject()
  if body != nil:
    body_606561 = body
  result = call_606560.call(nil, nil, nil, nil, body_606561)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_606548(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_606549, base: "/",
    url: url_GetAppliedSchemaVersion_606550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_606562 = ref object of OpenApiRestCall_605589
proc url_GetDirectory_606564(protocol: Scheme; host: string; base: string;
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

proc validate_GetDirectory_606563(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606565 = header.getOrDefault("X-Amz-Signature")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Signature", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Content-Sha256", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Date")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Date", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Credential")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Credential", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Security-Token")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Security-Token", valid_606569
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606570 = header.getOrDefault("x-amz-data-partition")
  valid_606570 = validateParameter(valid_606570, JString, required = true,
                                 default = nil)
  if valid_606570 != nil:
    section.add "x-amz-data-partition", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Algorithm")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Algorithm", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-SignedHeaders", valid_606572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606573: Call_GetDirectory_606562; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_606573.validator(path, query, header, formData, body)
  let scheme = call_606573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606573.url(scheme.get, call_606573.host, call_606573.base,
                         call_606573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606573, url, valid)

proc call*(call_606574: Call_GetDirectory_606562): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_606574.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_606562(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_606563, base: "/", url: url_GetDirectory_606564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_606575 = ref object of OpenApiRestCall_605589
proc url_UpdateFacet_606577(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFacet_606576(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606578 = header.getOrDefault("X-Amz-Signature")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Signature", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Content-Sha256", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Date")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Date", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Credential")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Credential", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Security-Token")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Security-Token", valid_606582
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606583 = header.getOrDefault("x-amz-data-partition")
  valid_606583 = validateParameter(valid_606583, JString, required = true,
                                 default = nil)
  if valid_606583 != nil:
    section.add "x-amz-data-partition", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Algorithm")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Algorithm", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-SignedHeaders", valid_606585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606587: Call_UpdateFacet_606575; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_606587.validator(path, query, header, formData, body)
  let scheme = call_606587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606587.url(scheme.get, call_606587.host, call_606587.base,
                         call_606587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606587, url, valid)

proc call*(call_606588: Call_UpdateFacet_606575; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_606589 = newJObject()
  if body != nil:
    body_606589 = body
  result = call_606588.call(nil, nil, nil, nil, body_606589)

var updateFacet* = Call_UpdateFacet_606575(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_606576,
                                        base: "/", url: url_UpdateFacet_606577,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_606590 = ref object of OpenApiRestCall_605589
proc url_GetFacet_606592(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFacet_606591(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606593 = header.getOrDefault("X-Amz-Signature")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Signature", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Content-Sha256", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Date")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Date", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Credential")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Credential", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Security-Token")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Security-Token", valid_606597
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606598 = header.getOrDefault("x-amz-data-partition")
  valid_606598 = validateParameter(valid_606598, JString, required = true,
                                 default = nil)
  if valid_606598 != nil:
    section.add "x-amz-data-partition", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606602: Call_GetFacet_606590; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_606602.validator(path, query, header, formData, body)
  let scheme = call_606602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606602.url(scheme.get, call_606602.host, call_606602.base,
                         call_606602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606602, url, valid)

proc call*(call_606603: Call_GetFacet_606590; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_606604 = newJObject()
  if body != nil:
    body_606604 = body
  result = call_606603.call(nil, nil, nil, nil, body_606604)

var getFacet* = Call_GetFacet_606590(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_606591, base: "/",
                                  url: url_GetFacet_606592,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_606605 = ref object of OpenApiRestCall_605589
proc url_GetLinkAttributes_606607(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAttributes_606606(path: JsonNode; query: JsonNode;
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
  var valid_606608 = header.getOrDefault("X-Amz-Signature")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Signature", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Content-Sha256", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Date")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Date", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Credential")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Credential", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Security-Token")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Security-Token", valid_606612
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606613 = header.getOrDefault("x-amz-data-partition")
  valid_606613 = validateParameter(valid_606613, JString, required = true,
                                 default = nil)
  if valid_606613 != nil:
    section.add "x-amz-data-partition", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Algorithm")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Algorithm", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-SignedHeaders", valid_606615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606617: Call_GetLinkAttributes_606605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_606617.validator(path, query, header, formData, body)
  let scheme = call_606617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606617.url(scheme.get, call_606617.host, call_606617.base,
                         call_606617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606617, url, valid)

proc call*(call_606618: Call_GetLinkAttributes_606605; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_606619 = newJObject()
  if body != nil:
    body_606619 = body
  result = call_606618.call(nil, nil, nil, nil, body_606619)

var getLinkAttributes* = Call_GetLinkAttributes_606605(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_606606, base: "/",
    url: url_GetLinkAttributes_606607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_606620 = ref object of OpenApiRestCall_605589
proc url_GetObjectAttributes_606622(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAttributes_606621(path: JsonNode; query: JsonNode;
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
  var valid_606623 = header.getOrDefault("x-amz-consistency-level")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606623 != nil:
    section.add "x-amz-consistency-level", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Signature")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Signature", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Content-Sha256", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Date")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Date", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Credential")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Credential", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Security-Token")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Security-Token", valid_606628
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606629 = header.getOrDefault("x-amz-data-partition")
  valid_606629 = validateParameter(valid_606629, JString, required = true,
                                 default = nil)
  if valid_606629 != nil:
    section.add "x-amz-data-partition", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Algorithm")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Algorithm", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-SignedHeaders", valid_606631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606633: Call_GetObjectAttributes_606620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_606633.validator(path, query, header, formData, body)
  let scheme = call_606633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606633.url(scheme.get, call_606633.host, call_606633.base,
                         call_606633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606633, url, valid)

proc call*(call_606634: Call_GetObjectAttributes_606620; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_606635 = newJObject()
  if body != nil:
    body_606635 = body
  result = call_606634.call(nil, nil, nil, nil, body_606635)

var getObjectAttributes* = Call_GetObjectAttributes_606620(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_606621, base: "/",
    url: url_GetObjectAttributes_606622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_606636 = ref object of OpenApiRestCall_605589
proc url_GetObjectInformation_606638(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectInformation_606637(path: JsonNode; query: JsonNode;
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
  var valid_606639 = header.getOrDefault("x-amz-consistency-level")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606639 != nil:
    section.add "x-amz-consistency-level", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Signature")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Signature", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Content-Sha256", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Date")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Date", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Credential")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Credential", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Security-Token")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Security-Token", valid_606644
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606645 = header.getOrDefault("x-amz-data-partition")
  valid_606645 = validateParameter(valid_606645, JString, required = true,
                                 default = nil)
  if valid_606645 != nil:
    section.add "x-amz-data-partition", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Algorithm")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Algorithm", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-SignedHeaders", valid_606647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606649: Call_GetObjectInformation_606636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_606649.validator(path, query, header, formData, body)
  let scheme = call_606649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606649.url(scheme.get, call_606649.host, call_606649.base,
                         call_606649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606649, url, valid)

proc call*(call_606650: Call_GetObjectInformation_606636; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_606651 = newJObject()
  if body != nil:
    body_606651 = body
  result = call_606650.call(nil, nil, nil, nil, body_606651)

var getObjectInformation* = Call_GetObjectInformation_606636(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_606637, base: "/",
    url: url_GetObjectInformation_606638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_606652 = ref object of OpenApiRestCall_605589
proc url_PutSchemaFromJson_606654(protocol: Scheme; host: string; base: string;
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

proc validate_PutSchemaFromJson_606653(path: JsonNode; query: JsonNode;
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
  var valid_606655 = header.getOrDefault("X-Amz-Signature")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Signature", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Content-Sha256", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Date")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Date", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Credential")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Credential", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Security-Token")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Security-Token", valid_606659
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606660 = header.getOrDefault("x-amz-data-partition")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "x-amz-data-partition", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Algorithm")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Algorithm", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-SignedHeaders", valid_606662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606664: Call_PutSchemaFromJson_606652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_606664.validator(path, query, header, formData, body)
  let scheme = call_606664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606664.url(scheme.get, call_606664.host, call_606664.base,
                         call_606664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606664, url, valid)

proc call*(call_606665: Call_PutSchemaFromJson_606652; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_606666 = newJObject()
  if body != nil:
    body_606666 = body
  result = call_606665.call(nil, nil, nil, nil, body_606666)

var putSchemaFromJson* = Call_PutSchemaFromJson_606652(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_606653, base: "/",
    url: url_PutSchemaFromJson_606654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_606667 = ref object of OpenApiRestCall_605589
proc url_GetSchemaAsJson_606669(protocol: Scheme; host: string; base: string;
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

proc validate_GetSchemaAsJson_606668(path: JsonNode; query: JsonNode;
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
  var valid_606670 = header.getOrDefault("X-Amz-Signature")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Signature", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Content-Sha256", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Date")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Date", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Credential")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Credential", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Security-Token")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Security-Token", valid_606674
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606675 = header.getOrDefault("x-amz-data-partition")
  valid_606675 = validateParameter(valid_606675, JString, required = true,
                                 default = nil)
  if valid_606675 != nil:
    section.add "x-amz-data-partition", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606678: Call_GetSchemaAsJson_606667; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_606678.validator(path, query, header, formData, body)
  let scheme = call_606678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606678.url(scheme.get, call_606678.host, call_606678.base,
                         call_606678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606678, url, valid)

proc call*(call_606679: Call_GetSchemaAsJson_606667): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  result = call_606679.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_606667(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_606668, base: "/", url: url_GetSchemaAsJson_606669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_606680 = ref object of OpenApiRestCall_605589
proc url_GetTypedLinkFacetInformation_606682(protocol: Scheme; host: string;
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

proc validate_GetTypedLinkFacetInformation_606681(path: JsonNode; query: JsonNode;
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
  var valid_606683 = header.getOrDefault("X-Amz-Signature")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Signature", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Content-Sha256", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Date")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Date", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Credential")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Credential", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Security-Token")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Security-Token", valid_606687
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606688 = header.getOrDefault("x-amz-data-partition")
  valid_606688 = validateParameter(valid_606688, JString, required = true,
                                 default = nil)
  if valid_606688 != nil:
    section.add "x-amz-data-partition", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Algorithm")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Algorithm", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-SignedHeaders", valid_606690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606692: Call_GetTypedLinkFacetInformation_606680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606692.validator(path, query, header, formData, body)
  let scheme = call_606692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606692.url(scheme.get, call_606692.host, call_606692.base,
                         call_606692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606692, url, valid)

proc call*(call_606693: Call_GetTypedLinkFacetInformation_606680; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606694 = newJObject()
  if body != nil:
    body_606694 = body
  result = call_606693.call(nil, nil, nil, nil, body_606694)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_606680(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_606681, base: "/",
    url: url_GetTypedLinkFacetInformation_606682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_606695 = ref object of OpenApiRestCall_605589
proc url_ListAppliedSchemaArns_606697(protocol: Scheme; host: string; base: string;
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

proc validate_ListAppliedSchemaArns_606696(path: JsonNode; query: JsonNode;
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
  var valid_606698 = query.getOrDefault("MaxResults")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "MaxResults", valid_606698
  var valid_606699 = query.getOrDefault("NextToken")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "NextToken", valid_606699
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
  var valid_606700 = header.getOrDefault("X-Amz-Signature")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Signature", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Content-Sha256", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Date")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Date", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Credential")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Credential", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Security-Token")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Security-Token", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Algorithm")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Algorithm", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-SignedHeaders", valid_606706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606708: Call_ListAppliedSchemaArns_606695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_606708.validator(path, query, header, formData, body)
  let scheme = call_606708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606708.url(scheme.get, call_606708.host, call_606708.base,
                         call_606708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606708, url, valid)

proc call*(call_606709: Call_ListAppliedSchemaArns_606695; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606710 = newJObject()
  var body_606711 = newJObject()
  add(query_606710, "MaxResults", newJString(MaxResults))
  add(query_606710, "NextToken", newJString(NextToken))
  if body != nil:
    body_606711 = body
  result = call_606709.call(nil, query_606710, nil, nil, body_606711)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_606695(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_606696, base: "/",
    url: url_ListAppliedSchemaArns_606697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_606713 = ref object of OpenApiRestCall_605589
proc url_ListAttachedIndices_606715(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttachedIndices_606714(path: JsonNode; query: JsonNode;
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
  var valid_606716 = query.getOrDefault("MaxResults")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "MaxResults", valid_606716
  var valid_606717 = query.getOrDefault("NextToken")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "NextToken", valid_606717
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
  var valid_606718 = header.getOrDefault("x-amz-consistency-level")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606718 != nil:
    section.add "x-amz-consistency-level", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Signature")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Signature", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Content-Sha256", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Date")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Date", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Credential")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Credential", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Security-Token")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Security-Token", valid_606723
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606724 = header.getOrDefault("x-amz-data-partition")
  valid_606724 = validateParameter(valid_606724, JString, required = true,
                                 default = nil)
  if valid_606724 != nil:
    section.add "x-amz-data-partition", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Algorithm")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Algorithm", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-SignedHeaders", valid_606726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606728: Call_ListAttachedIndices_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_606728.validator(path, query, header, formData, body)
  let scheme = call_606728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606728.url(scheme.get, call_606728.host, call_606728.base,
                         call_606728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606728, url, valid)

proc call*(call_606729: Call_ListAttachedIndices_606713; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606730 = newJObject()
  var body_606731 = newJObject()
  add(query_606730, "MaxResults", newJString(MaxResults))
  add(query_606730, "NextToken", newJString(NextToken))
  if body != nil:
    body_606731 = body
  result = call_606729.call(nil, query_606730, nil, nil, body_606731)

var listAttachedIndices* = Call_ListAttachedIndices_606713(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_606714, base: "/",
    url: url_ListAttachedIndices_606715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_606732 = ref object of OpenApiRestCall_605589
proc url_ListDevelopmentSchemaArns_606734(protocol: Scheme; host: string;
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

proc validate_ListDevelopmentSchemaArns_606733(path: JsonNode; query: JsonNode;
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
  var valid_606735 = query.getOrDefault("MaxResults")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "MaxResults", valid_606735
  var valid_606736 = query.getOrDefault("NextToken")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "NextToken", valid_606736
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
  var valid_606737 = header.getOrDefault("X-Amz-Signature")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Signature", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Content-Sha256", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Date")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Date", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Credential")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Credential", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Security-Token")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Security-Token", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Algorithm")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Algorithm", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-SignedHeaders", valid_606743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606745: Call_ListDevelopmentSchemaArns_606732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_606745.validator(path, query, header, formData, body)
  let scheme = call_606745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606745.url(scheme.get, call_606745.host, call_606745.base,
                         call_606745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606745, url, valid)

proc call*(call_606746: Call_ListDevelopmentSchemaArns_606732; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606747 = newJObject()
  var body_606748 = newJObject()
  add(query_606747, "MaxResults", newJString(MaxResults))
  add(query_606747, "NextToken", newJString(NextToken))
  if body != nil:
    body_606748 = body
  result = call_606746.call(nil, query_606747, nil, nil, body_606748)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_606732(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_606733, base: "/",
    url: url_ListDevelopmentSchemaArns_606734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_606749 = ref object of OpenApiRestCall_605589
proc url_ListDirectories_606751(protocol: Scheme; host: string; base: string;
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

proc validate_ListDirectories_606750(path: JsonNode; query: JsonNode;
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
  var valid_606752 = query.getOrDefault("MaxResults")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "MaxResults", valid_606752
  var valid_606753 = query.getOrDefault("NextToken")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "NextToken", valid_606753
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
  var valid_606754 = header.getOrDefault("X-Amz-Signature")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Signature", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Content-Sha256", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Date")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Date", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Credential")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Credential", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Security-Token")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Security-Token", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Algorithm")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Algorithm", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-SignedHeaders", valid_606760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606762: Call_ListDirectories_606749; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_606762.validator(path, query, header, formData, body)
  let scheme = call_606762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606762.url(scheme.get, call_606762.host, call_606762.base,
                         call_606762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606762, url, valid)

proc call*(call_606763: Call_ListDirectories_606749; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606764 = newJObject()
  var body_606765 = newJObject()
  add(query_606764, "MaxResults", newJString(MaxResults))
  add(query_606764, "NextToken", newJString(NextToken))
  if body != nil:
    body_606765 = body
  result = call_606763.call(nil, query_606764, nil, nil, body_606765)

var listDirectories* = Call_ListDirectories_606749(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_606750, base: "/", url: url_ListDirectories_606751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_606766 = ref object of OpenApiRestCall_605589
proc url_ListFacetAttributes_606768(protocol: Scheme; host: string; base: string;
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

proc validate_ListFacetAttributes_606767(path: JsonNode; query: JsonNode;
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
  var valid_606769 = query.getOrDefault("MaxResults")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "MaxResults", valid_606769
  var valid_606770 = query.getOrDefault("NextToken")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "NextToken", valid_606770
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
  var valid_606771 = header.getOrDefault("X-Amz-Signature")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Signature", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Content-Sha256", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Date")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Date", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Credential")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Credential", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Security-Token")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Security-Token", valid_606775
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606776 = header.getOrDefault("x-amz-data-partition")
  valid_606776 = validateParameter(valid_606776, JString, required = true,
                                 default = nil)
  if valid_606776 != nil:
    section.add "x-amz-data-partition", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Algorithm")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Algorithm", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-SignedHeaders", valid_606778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606780: Call_ListFacetAttributes_606766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_606780.validator(path, query, header, formData, body)
  let scheme = call_606780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606780.url(scheme.get, call_606780.host, call_606780.base,
                         call_606780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606780, url, valid)

proc call*(call_606781: Call_ListFacetAttributes_606766; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606782 = newJObject()
  var body_606783 = newJObject()
  add(query_606782, "MaxResults", newJString(MaxResults))
  add(query_606782, "NextToken", newJString(NextToken))
  if body != nil:
    body_606783 = body
  result = call_606781.call(nil, query_606782, nil, nil, body_606783)

var listFacetAttributes* = Call_ListFacetAttributes_606766(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_606767, base: "/",
    url: url_ListFacetAttributes_606768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_606784 = ref object of OpenApiRestCall_605589
proc url_ListFacetNames_606786(protocol: Scheme; host: string; base: string;
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

proc validate_ListFacetNames_606785(path: JsonNode; query: JsonNode;
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
  var valid_606787 = query.getOrDefault("MaxResults")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "MaxResults", valid_606787
  var valid_606788 = query.getOrDefault("NextToken")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "NextToken", valid_606788
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
  var valid_606789 = header.getOrDefault("X-Amz-Signature")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Signature", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Content-Sha256", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Date")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Date", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Credential")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Credential", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Security-Token")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Security-Token", valid_606793
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606794 = header.getOrDefault("x-amz-data-partition")
  valid_606794 = validateParameter(valid_606794, JString, required = true,
                                 default = nil)
  if valid_606794 != nil:
    section.add "x-amz-data-partition", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Algorithm")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Algorithm", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-SignedHeaders", valid_606796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606798: Call_ListFacetNames_606784; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_606798.validator(path, query, header, formData, body)
  let scheme = call_606798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606798.url(scheme.get, call_606798.host, call_606798.base,
                         call_606798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606798, url, valid)

proc call*(call_606799: Call_ListFacetNames_606784; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606800 = newJObject()
  var body_606801 = newJObject()
  add(query_606800, "MaxResults", newJString(MaxResults))
  add(query_606800, "NextToken", newJString(NextToken))
  if body != nil:
    body_606801 = body
  result = call_606799.call(nil, query_606800, nil, nil, body_606801)

var listFacetNames* = Call_ListFacetNames_606784(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_606785, base: "/", url: url_ListFacetNames_606786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_606802 = ref object of OpenApiRestCall_605589
proc url_ListIncomingTypedLinks_606804(protocol: Scheme; host: string; base: string;
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

proc validate_ListIncomingTypedLinks_606803(path: JsonNode; query: JsonNode;
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
  var valid_606805 = header.getOrDefault("X-Amz-Signature")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Signature", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Content-Sha256", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Date")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Date", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Credential")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Credential", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Security-Token")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Security-Token", valid_606809
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606810 = header.getOrDefault("x-amz-data-partition")
  valid_606810 = validateParameter(valid_606810, JString, required = true,
                                 default = nil)
  if valid_606810 != nil:
    section.add "x-amz-data-partition", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Algorithm")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Algorithm", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-SignedHeaders", valid_606812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606814: Call_ListIncomingTypedLinks_606802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606814.validator(path, query, header, formData, body)
  let scheme = call_606814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606814.url(scheme.get, call_606814.host, call_606814.base,
                         call_606814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606814, url, valid)

proc call*(call_606815: Call_ListIncomingTypedLinks_606802; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606816 = newJObject()
  if body != nil:
    body_606816 = body
  result = call_606815.call(nil, nil, nil, nil, body_606816)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_606802(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_606803, base: "/",
    url: url_ListIncomingTypedLinks_606804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_606817 = ref object of OpenApiRestCall_605589
proc url_ListIndex_606819(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListIndex_606818(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606820 = query.getOrDefault("MaxResults")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "MaxResults", valid_606820
  var valid_606821 = query.getOrDefault("NextToken")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "NextToken", valid_606821
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
  var valid_606822 = header.getOrDefault("x-amz-consistency-level")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606822 != nil:
    section.add "x-amz-consistency-level", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606828 = header.getOrDefault("x-amz-data-partition")
  valid_606828 = validateParameter(valid_606828, JString, required = true,
                                 default = nil)
  if valid_606828 != nil:
    section.add "x-amz-data-partition", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Algorithm")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Algorithm", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-SignedHeaders", valid_606830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606832: Call_ListIndex_606817; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_606832.validator(path, query, header, formData, body)
  let scheme = call_606832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606832.url(scheme.get, call_606832.host, call_606832.base,
                         call_606832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606832, url, valid)

proc call*(call_606833: Call_ListIndex_606817; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606834 = newJObject()
  var body_606835 = newJObject()
  add(query_606834, "MaxResults", newJString(MaxResults))
  add(query_606834, "NextToken", newJString(NextToken))
  if body != nil:
    body_606835 = body
  result = call_606833.call(nil, query_606834, nil, nil, body_606835)

var listIndex* = Call_ListIndex_606817(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_606818,
                                    base: "/", url: url_ListIndex_606819,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_606836 = ref object of OpenApiRestCall_605589
proc url_ListObjectAttributes_606838(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectAttributes_606837(path: JsonNode; query: JsonNode;
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
  var valid_606839 = query.getOrDefault("MaxResults")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "MaxResults", valid_606839
  var valid_606840 = query.getOrDefault("NextToken")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "NextToken", valid_606840
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
  var valid_606841 = header.getOrDefault("x-amz-consistency-level")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606841 != nil:
    section.add "x-amz-consistency-level", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Signature")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Signature", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Content-Sha256", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Date")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Date", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Credential")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Credential", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Security-Token")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Security-Token", valid_606846
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606847 = header.getOrDefault("x-amz-data-partition")
  valid_606847 = validateParameter(valid_606847, JString, required = true,
                                 default = nil)
  if valid_606847 != nil:
    section.add "x-amz-data-partition", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Algorithm")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Algorithm", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-SignedHeaders", valid_606849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606851: Call_ListObjectAttributes_606836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_606851.validator(path, query, header, formData, body)
  let scheme = call_606851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606851.url(scheme.get, call_606851.host, call_606851.base,
                         call_606851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606851, url, valid)

proc call*(call_606852: Call_ListObjectAttributes_606836; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606853 = newJObject()
  var body_606854 = newJObject()
  add(query_606853, "MaxResults", newJString(MaxResults))
  add(query_606853, "NextToken", newJString(NextToken))
  if body != nil:
    body_606854 = body
  result = call_606852.call(nil, query_606853, nil, nil, body_606854)

var listObjectAttributes* = Call_ListObjectAttributes_606836(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_606837, base: "/",
    url: url_ListObjectAttributes_606838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_606855 = ref object of OpenApiRestCall_605589
proc url_ListObjectChildren_606857(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectChildren_606856(path: JsonNode; query: JsonNode;
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
  var valid_606858 = query.getOrDefault("MaxResults")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "MaxResults", valid_606858
  var valid_606859 = query.getOrDefault("NextToken")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "NextToken", valid_606859
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
  var valid_606860 = header.getOrDefault("x-amz-consistency-level")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606860 != nil:
    section.add "x-amz-consistency-level", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Signature")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Signature", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Content-Sha256", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Date")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Date", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Credential")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Credential", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Security-Token")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Security-Token", valid_606865
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606866 = header.getOrDefault("x-amz-data-partition")
  valid_606866 = validateParameter(valid_606866, JString, required = true,
                                 default = nil)
  if valid_606866 != nil:
    section.add "x-amz-data-partition", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Algorithm")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Algorithm", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-SignedHeaders", valid_606868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606870: Call_ListObjectChildren_606855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_606870.validator(path, query, header, formData, body)
  let scheme = call_606870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606870.url(scheme.get, call_606870.host, call_606870.base,
                         call_606870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606870, url, valid)

proc call*(call_606871: Call_ListObjectChildren_606855; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606872 = newJObject()
  var body_606873 = newJObject()
  add(query_606872, "MaxResults", newJString(MaxResults))
  add(query_606872, "NextToken", newJString(NextToken))
  if body != nil:
    body_606873 = body
  result = call_606871.call(nil, query_606872, nil, nil, body_606873)

var listObjectChildren* = Call_ListObjectChildren_606855(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_606856, base: "/",
    url: url_ListObjectChildren_606857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_606874 = ref object of OpenApiRestCall_605589
proc url_ListObjectParentPaths_606876(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectParentPaths_606875(path: JsonNode; query: JsonNode;
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
  var valid_606877 = query.getOrDefault("MaxResults")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "MaxResults", valid_606877
  var valid_606878 = query.getOrDefault("NextToken")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "NextToken", valid_606878
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
  var valid_606879 = header.getOrDefault("X-Amz-Signature")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Signature", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Content-Sha256", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-Date")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Date", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Credential")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Credential", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Security-Token")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Security-Token", valid_606883
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606884 = header.getOrDefault("x-amz-data-partition")
  valid_606884 = validateParameter(valid_606884, JString, required = true,
                                 default = nil)
  if valid_606884 != nil:
    section.add "x-amz-data-partition", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Algorithm")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Algorithm", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-SignedHeaders", valid_606886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606888: Call_ListObjectParentPaths_606874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_606888.validator(path, query, header, formData, body)
  let scheme = call_606888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606888.url(scheme.get, call_606888.host, call_606888.base,
                         call_606888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606888, url, valid)

proc call*(call_606889: Call_ListObjectParentPaths_606874; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606890 = newJObject()
  var body_606891 = newJObject()
  add(query_606890, "MaxResults", newJString(MaxResults))
  add(query_606890, "NextToken", newJString(NextToken))
  if body != nil:
    body_606891 = body
  result = call_606889.call(nil, query_606890, nil, nil, body_606891)

var listObjectParentPaths* = Call_ListObjectParentPaths_606874(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_606875, base: "/",
    url: url_ListObjectParentPaths_606876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_606892 = ref object of OpenApiRestCall_605589
proc url_ListObjectParents_606894(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectParents_606893(path: JsonNode; query: JsonNode;
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
  var valid_606895 = query.getOrDefault("MaxResults")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "MaxResults", valid_606895
  var valid_606896 = query.getOrDefault("NextToken")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "NextToken", valid_606896
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
  var valid_606897 = header.getOrDefault("x-amz-consistency-level")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606897 != nil:
    section.add "x-amz-consistency-level", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Signature")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Signature", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Content-Sha256", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Date")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Date", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Credential")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Credential", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Security-Token")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Security-Token", valid_606902
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606903 = header.getOrDefault("x-amz-data-partition")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "x-amz-data-partition", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Algorithm")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Algorithm", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-SignedHeaders", valid_606905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606907: Call_ListObjectParents_606892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_606907.validator(path, query, header, formData, body)
  let scheme = call_606907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606907.url(scheme.get, call_606907.host, call_606907.base,
                         call_606907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606907, url, valid)

proc call*(call_606908: Call_ListObjectParents_606892; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606909 = newJObject()
  var body_606910 = newJObject()
  add(query_606909, "MaxResults", newJString(MaxResults))
  add(query_606909, "NextToken", newJString(NextToken))
  if body != nil:
    body_606910 = body
  result = call_606908.call(nil, query_606909, nil, nil, body_606910)

var listObjectParents* = Call_ListObjectParents_606892(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_606893, base: "/",
    url: url_ListObjectParents_606894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_606911 = ref object of OpenApiRestCall_605589
proc url_ListObjectPolicies_606913(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectPolicies_606912(path: JsonNode; query: JsonNode;
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
  var valid_606914 = query.getOrDefault("MaxResults")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "MaxResults", valid_606914
  var valid_606915 = query.getOrDefault("NextToken")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "NextToken", valid_606915
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
  var valid_606916 = header.getOrDefault("x-amz-consistency-level")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606916 != nil:
    section.add "x-amz-consistency-level", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Signature")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Signature", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Content-Sha256", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Date")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Date", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Credential")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Credential", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Security-Token")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Security-Token", valid_606921
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606922 = header.getOrDefault("x-amz-data-partition")
  valid_606922 = validateParameter(valid_606922, JString, required = true,
                                 default = nil)
  if valid_606922 != nil:
    section.add "x-amz-data-partition", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Algorithm")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Algorithm", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-SignedHeaders", valid_606924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606926: Call_ListObjectPolicies_606911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_606926.validator(path, query, header, formData, body)
  let scheme = call_606926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606926.url(scheme.get, call_606926.host, call_606926.base,
                         call_606926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606926, url, valid)

proc call*(call_606927: Call_ListObjectPolicies_606911; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606928 = newJObject()
  var body_606929 = newJObject()
  add(query_606928, "MaxResults", newJString(MaxResults))
  add(query_606928, "NextToken", newJString(NextToken))
  if body != nil:
    body_606929 = body
  result = call_606927.call(nil, query_606928, nil, nil, body_606929)

var listObjectPolicies* = Call_ListObjectPolicies_606911(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_606912, base: "/",
    url: url_ListObjectPolicies_606913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_606930 = ref object of OpenApiRestCall_605589
proc url_ListOutgoingTypedLinks_606932(protocol: Scheme; host: string; base: string;
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

proc validate_ListOutgoingTypedLinks_606931(path: JsonNode; query: JsonNode;
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
  var valid_606933 = header.getOrDefault("X-Amz-Signature")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Signature", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Content-Sha256", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Date")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Date", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Credential")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Credential", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Security-Token")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Security-Token", valid_606937
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606938 = header.getOrDefault("x-amz-data-partition")
  valid_606938 = validateParameter(valid_606938, JString, required = true,
                                 default = nil)
  if valid_606938 != nil:
    section.add "x-amz-data-partition", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Algorithm")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Algorithm", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-SignedHeaders", valid_606940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606942: Call_ListOutgoingTypedLinks_606930; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_606942.validator(path, query, header, formData, body)
  let scheme = call_606942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606942.url(scheme.get, call_606942.host, call_606942.base,
                         call_606942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606942, url, valid)

proc call*(call_606943: Call_ListOutgoingTypedLinks_606930; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_606944 = newJObject()
  if body != nil:
    body_606944 = body
  result = call_606943.call(nil, nil, nil, nil, body_606944)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_606930(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_606931, base: "/",
    url: url_ListOutgoingTypedLinks_606932, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_606945 = ref object of OpenApiRestCall_605589
proc url_ListPolicyAttachments_606947(protocol: Scheme; host: string; base: string;
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

proc validate_ListPolicyAttachments_606946(path: JsonNode; query: JsonNode;
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
  var valid_606948 = query.getOrDefault("MaxResults")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "MaxResults", valid_606948
  var valid_606949 = query.getOrDefault("NextToken")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "NextToken", valid_606949
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
  var valid_606950 = header.getOrDefault("x-amz-consistency-level")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_606950 != nil:
    section.add "x-amz-consistency-level", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Signature")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Signature", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Content-Sha256", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Date")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Date", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Credential")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Credential", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Security-Token")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Security-Token", valid_606955
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_606956 = header.getOrDefault("x-amz-data-partition")
  valid_606956 = validateParameter(valid_606956, JString, required = true,
                                 default = nil)
  if valid_606956 != nil:
    section.add "x-amz-data-partition", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Algorithm")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Algorithm", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-SignedHeaders", valid_606958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606960: Call_ListPolicyAttachments_606945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_606960.validator(path, query, header, formData, body)
  let scheme = call_606960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606960.url(scheme.get, call_606960.host, call_606960.base,
                         call_606960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606960, url, valid)

proc call*(call_606961: Call_ListPolicyAttachments_606945; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606962 = newJObject()
  var body_606963 = newJObject()
  add(query_606962, "MaxResults", newJString(MaxResults))
  add(query_606962, "NextToken", newJString(NextToken))
  if body != nil:
    body_606963 = body
  result = call_606961.call(nil, query_606962, nil, nil, body_606963)

var listPolicyAttachments* = Call_ListPolicyAttachments_606945(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_606946, base: "/",
    url: url_ListPolicyAttachments_606947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_606964 = ref object of OpenApiRestCall_605589
proc url_ListPublishedSchemaArns_606966(protocol: Scheme; host: string; base: string;
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

proc validate_ListPublishedSchemaArns_606965(path: JsonNode; query: JsonNode;
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
  var valid_606967 = query.getOrDefault("MaxResults")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "MaxResults", valid_606967
  var valid_606968 = query.getOrDefault("NextToken")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "NextToken", valid_606968
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
  var valid_606969 = header.getOrDefault("X-Amz-Signature")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Signature", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Content-Sha256", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Date")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Date", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Credential")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Credential", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Security-Token")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Security-Token", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Algorithm")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Algorithm", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-SignedHeaders", valid_606975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606977: Call_ListPublishedSchemaArns_606964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_606977.validator(path, query, header, formData, body)
  let scheme = call_606977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606977.url(scheme.get, call_606977.host, call_606977.base,
                         call_606977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606977, url, valid)

proc call*(call_606978: Call_ListPublishedSchemaArns_606964; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606979 = newJObject()
  var body_606980 = newJObject()
  add(query_606979, "MaxResults", newJString(MaxResults))
  add(query_606979, "NextToken", newJString(NextToken))
  if body != nil:
    body_606980 = body
  result = call_606978.call(nil, query_606979, nil, nil, body_606980)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_606964(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_606965, base: "/",
    url: url_ListPublishedSchemaArns_606966, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606981 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606983(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606982(path: JsonNode; query: JsonNode;
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
  var valid_606984 = query.getOrDefault("MaxResults")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "MaxResults", valid_606984
  var valid_606985 = query.getOrDefault("NextToken")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "NextToken", valid_606985
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
  var valid_606986 = header.getOrDefault("X-Amz-Signature")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Signature", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Content-Sha256", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Date")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Date", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Credential")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Credential", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Security-Token")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Security-Token", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Algorithm")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Algorithm", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-SignedHeaders", valid_606992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606994: Call_ListTagsForResource_606981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_606994.validator(path, query, header, formData, body)
  let scheme = call_606994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606994.url(scheme.get, call_606994.host, call_606994.base,
                         call_606994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606994, url, valid)

proc call*(call_606995: Call_ListTagsForResource_606981; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606996 = newJObject()
  var body_606997 = newJObject()
  add(query_606996, "MaxResults", newJString(MaxResults))
  add(query_606996, "NextToken", newJString(NextToken))
  if body != nil:
    body_606997 = body
  result = call_606995.call(nil, query_606996, nil, nil, body_606997)

var listTagsForResource* = Call_ListTagsForResource_606981(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_606982, base: "/",
    url: url_ListTagsForResource_606983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_606998 = ref object of OpenApiRestCall_605589
proc url_ListTypedLinkFacetAttributes_607000(protocol: Scheme; host: string;
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

proc validate_ListTypedLinkFacetAttributes_606999(path: JsonNode; query: JsonNode;
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
  var valid_607001 = query.getOrDefault("MaxResults")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "MaxResults", valid_607001
  var valid_607002 = query.getOrDefault("NextToken")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "NextToken", valid_607002
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
  var valid_607003 = header.getOrDefault("X-Amz-Signature")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Signature", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-Content-Sha256", valid_607004
  var valid_607005 = header.getOrDefault("X-Amz-Date")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Date", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Credential")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Credential", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Security-Token")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Security-Token", valid_607007
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607008 = header.getOrDefault("x-amz-data-partition")
  valid_607008 = validateParameter(valid_607008, JString, required = true,
                                 default = nil)
  if valid_607008 != nil:
    section.add "x-amz-data-partition", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Algorithm")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Algorithm", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-SignedHeaders", valid_607010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607012: Call_ListTypedLinkFacetAttributes_606998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_607012.validator(path, query, header, formData, body)
  let scheme = call_607012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607012.url(scheme.get, call_607012.host, call_607012.base,
                         call_607012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607012, url, valid)

proc call*(call_607013: Call_ListTypedLinkFacetAttributes_606998; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607014 = newJObject()
  var body_607015 = newJObject()
  add(query_607014, "MaxResults", newJString(MaxResults))
  add(query_607014, "NextToken", newJString(NextToken))
  if body != nil:
    body_607015 = body
  result = call_607013.call(nil, query_607014, nil, nil, body_607015)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_606998(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_606999, base: "/",
    url: url_ListTypedLinkFacetAttributes_607000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_607016 = ref object of OpenApiRestCall_605589
proc url_ListTypedLinkFacetNames_607018(protocol: Scheme; host: string; base: string;
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

proc validate_ListTypedLinkFacetNames_607017(path: JsonNode; query: JsonNode;
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
  var valid_607019 = query.getOrDefault("MaxResults")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "MaxResults", valid_607019
  var valid_607020 = query.getOrDefault("NextToken")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "NextToken", valid_607020
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
  var valid_607021 = header.getOrDefault("X-Amz-Signature")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Signature", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Content-Sha256", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Date")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Date", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Credential")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Credential", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Security-Token")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Security-Token", valid_607025
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607026 = header.getOrDefault("x-amz-data-partition")
  valid_607026 = validateParameter(valid_607026, JString, required = true,
                                 default = nil)
  if valid_607026 != nil:
    section.add "x-amz-data-partition", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-Algorithm")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-Algorithm", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-SignedHeaders", valid_607028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607030: Call_ListTypedLinkFacetNames_607016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_607030.validator(path, query, header, formData, body)
  let scheme = call_607030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607030.url(scheme.get, call_607030.host, call_607030.base,
                         call_607030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607030, url, valid)

proc call*(call_607031: Call_ListTypedLinkFacetNames_607016; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607032 = newJObject()
  var body_607033 = newJObject()
  add(query_607032, "MaxResults", newJString(MaxResults))
  add(query_607032, "NextToken", newJString(NextToken))
  if body != nil:
    body_607033 = body
  result = call_607031.call(nil, query_607032, nil, nil, body_607033)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_607016(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_607017, base: "/",
    url: url_ListTypedLinkFacetNames_607018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_607034 = ref object of OpenApiRestCall_605589
proc url_LookupPolicy_607036(protocol: Scheme; host: string; base: string;
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

proc validate_LookupPolicy_607035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607037 = query.getOrDefault("MaxResults")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "MaxResults", valid_607037
  var valid_607038 = query.getOrDefault("NextToken")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "NextToken", valid_607038
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
  var valid_607039 = header.getOrDefault("X-Amz-Signature")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Signature", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-Content-Sha256", valid_607040
  var valid_607041 = header.getOrDefault("X-Amz-Date")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "X-Amz-Date", valid_607041
  var valid_607042 = header.getOrDefault("X-Amz-Credential")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Credential", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-Security-Token")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Security-Token", valid_607043
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607044 = header.getOrDefault("x-amz-data-partition")
  valid_607044 = validateParameter(valid_607044, JString, required = true,
                                 default = nil)
  if valid_607044 != nil:
    section.add "x-amz-data-partition", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Algorithm")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Algorithm", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-SignedHeaders", valid_607046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607048: Call_LookupPolicy_607034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ## 
  let valid = call_607048.validator(path, query, header, formData, body)
  let scheme = call_607048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607048.url(scheme.get, call_607048.host, call_607048.base,
                         call_607048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607048, url, valid)

proc call*(call_607049: Call_LookupPolicy_607034; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607050 = newJObject()
  var body_607051 = newJObject()
  add(query_607050, "MaxResults", newJString(MaxResults))
  add(query_607050, "NextToken", newJString(NextToken))
  if body != nil:
    body_607051 = body
  result = call_607049.call(nil, query_607050, nil, nil, body_607051)

var lookupPolicy* = Call_LookupPolicy_607034(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_607035, base: "/", url: url_LookupPolicy_607036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_607052 = ref object of OpenApiRestCall_605589
proc url_PublishSchema_607054(protocol: Scheme; host: string; base: string;
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

proc validate_PublishSchema_607053(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607060 = header.getOrDefault("x-amz-data-partition")
  valid_607060 = validateParameter(valid_607060, JString, required = true,
                                 default = nil)
  if valid_607060 != nil:
    section.add "x-amz-data-partition", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Algorithm")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Algorithm", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-SignedHeaders", valid_607062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607064: Call_PublishSchema_607052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_607064.validator(path, query, header, formData, body)
  let scheme = call_607064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607064.url(scheme.get, call_607064.host, call_607064.base,
                         call_607064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607064, url, valid)

proc call*(call_607065: Call_PublishSchema_607052; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_607066 = newJObject()
  if body != nil:
    body_607066 = body
  result = call_607065.call(nil, nil, nil, nil, body_607066)

var publishSchema* = Call_PublishSchema_607052(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_607053, base: "/", url: url_PublishSchema_607054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_607067 = ref object of OpenApiRestCall_605589
proc url_RemoveFacetFromObject_607069(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveFacetFromObject_607068(path: JsonNode; query: JsonNode;
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
  var valid_607070 = header.getOrDefault("X-Amz-Signature")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Signature", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Content-Sha256", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Date")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Date", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Credential")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Credential", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Security-Token")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Security-Token", valid_607074
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607075 = header.getOrDefault("x-amz-data-partition")
  valid_607075 = validateParameter(valid_607075, JString, required = true,
                                 default = nil)
  if valid_607075 != nil:
    section.add "x-amz-data-partition", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Algorithm")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Algorithm", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-SignedHeaders", valid_607077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607079: Call_RemoveFacetFromObject_607067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_607079.validator(path, query, header, formData, body)
  let scheme = call_607079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607079.url(scheme.get, call_607079.host, call_607079.base,
                         call_607079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607079, url, valid)

proc call*(call_607080: Call_RemoveFacetFromObject_607067; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_607081 = newJObject()
  if body != nil:
    body_607081 = body
  result = call_607080.call(nil, nil, nil, nil, body_607081)

var removeFacetFromObject* = Call_RemoveFacetFromObject_607067(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_607068, base: "/",
    url: url_RemoveFacetFromObject_607069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607082 = ref object of OpenApiRestCall_605589
proc url_TagResource_607084(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_607083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607085 = header.getOrDefault("X-Amz-Signature")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Signature", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Content-Sha256", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Date")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Date", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-Credential")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-Credential", valid_607088
  var valid_607089 = header.getOrDefault("X-Amz-Security-Token")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "X-Amz-Security-Token", valid_607089
  var valid_607090 = header.getOrDefault("X-Amz-Algorithm")
  valid_607090 = validateParameter(valid_607090, JString, required = false,
                                 default = nil)
  if valid_607090 != nil:
    section.add "X-Amz-Algorithm", valid_607090
  var valid_607091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "X-Amz-SignedHeaders", valid_607091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607093: Call_TagResource_607082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_607093.validator(path, query, header, formData, body)
  let scheme = call_607093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607093.url(scheme.get, call_607093.host, call_607093.base,
                         call_607093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607093, url, valid)

proc call*(call_607094: Call_TagResource_607082; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_607095 = newJObject()
  if body != nil:
    body_607095 = body
  result = call_607094.call(nil, nil, nil, nil, body_607095)

var tagResource* = Call_TagResource_607082(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_607083,
                                        base: "/", url: url_TagResource_607084,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607096 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607098(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_607097(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607099 = header.getOrDefault("X-Amz-Signature")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-Signature", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-Content-Sha256", valid_607100
  var valid_607101 = header.getOrDefault("X-Amz-Date")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Date", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Credential")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Credential", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Security-Token")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Security-Token", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-Algorithm")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-Algorithm", valid_607104
  var valid_607105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-SignedHeaders", valid_607105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607107: Call_UntagResource_607096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_607107.validator(path, query, header, formData, body)
  let scheme = call_607107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607107.url(scheme.get, call_607107.host, call_607107.base,
                         call_607107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607107, url, valid)

proc call*(call_607108: Call_UntagResource_607096; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_607109 = newJObject()
  if body != nil:
    body_607109 = body
  result = call_607108.call(nil, nil, nil, nil, body_607109)

var untagResource* = Call_UntagResource_607096(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_607097, base: "/", url: url_UntagResource_607098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_607110 = ref object of OpenApiRestCall_605589
proc url_UpdateLinkAttributes_607112(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLinkAttributes_607111(path: JsonNode; query: JsonNode;
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
  var valid_607113 = header.getOrDefault("X-Amz-Signature")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Signature", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Content-Sha256", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Date")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Date", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Credential")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Credential", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Security-Token")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Security-Token", valid_607117
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607118 = header.getOrDefault("x-amz-data-partition")
  valid_607118 = validateParameter(valid_607118, JString, required = true,
                                 default = nil)
  if valid_607118 != nil:
    section.add "x-amz-data-partition", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-Algorithm")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-Algorithm", valid_607119
  var valid_607120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "X-Amz-SignedHeaders", valid_607120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607122: Call_UpdateLinkAttributes_607110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_607122.validator(path, query, header, formData, body)
  let scheme = call_607122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607122.url(scheme.get, call_607122.host, call_607122.base,
                         call_607122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607122, url, valid)

proc call*(call_607123: Call_UpdateLinkAttributes_607110; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_607124 = newJObject()
  if body != nil:
    body_607124 = body
  result = call_607123.call(nil, nil, nil, nil, body_607124)

var updateLinkAttributes* = Call_UpdateLinkAttributes_607110(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_607111, base: "/",
    url: url_UpdateLinkAttributes_607112, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_607125 = ref object of OpenApiRestCall_605589
proc url_UpdateObjectAttributes_607127(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateObjectAttributes_607126(path: JsonNode; query: JsonNode;
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
  var valid_607128 = header.getOrDefault("X-Amz-Signature")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Signature", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Content-Sha256", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Date")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Date", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Credential")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Credential", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Security-Token")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Security-Token", valid_607132
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607133 = header.getOrDefault("x-amz-data-partition")
  valid_607133 = validateParameter(valid_607133, JString, required = true,
                                 default = nil)
  if valid_607133 != nil:
    section.add "x-amz-data-partition", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-Algorithm")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Algorithm", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-SignedHeaders", valid_607135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607137: Call_UpdateObjectAttributes_607125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_607137.validator(path, query, header, formData, body)
  let scheme = call_607137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607137.url(scheme.get, call_607137.host, call_607137.base,
                         call_607137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607137, url, valid)

proc call*(call_607138: Call_UpdateObjectAttributes_607125; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_607139 = newJObject()
  if body != nil:
    body_607139 = body
  result = call_607138.call(nil, nil, nil, nil, body_607139)

var updateObjectAttributes* = Call_UpdateObjectAttributes_607125(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_607126, base: "/",
    url: url_UpdateObjectAttributes_607127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_607140 = ref object of OpenApiRestCall_605589
proc url_UpdateSchema_607142(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_607141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607143 = header.getOrDefault("X-Amz-Signature")
  valid_607143 = validateParameter(valid_607143, JString, required = false,
                                 default = nil)
  if valid_607143 != nil:
    section.add "X-Amz-Signature", valid_607143
  var valid_607144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607144 = validateParameter(valid_607144, JString, required = false,
                                 default = nil)
  if valid_607144 != nil:
    section.add "X-Amz-Content-Sha256", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Date")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Date", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Credential")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Credential", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Security-Token")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Security-Token", valid_607147
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607148 = header.getOrDefault("x-amz-data-partition")
  valid_607148 = validateParameter(valid_607148, JString, required = true,
                                 default = nil)
  if valid_607148 != nil:
    section.add "x-amz-data-partition", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Algorithm")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Algorithm", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-SignedHeaders", valid_607150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607152: Call_UpdateSchema_607140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_607152.validator(path, query, header, formData, body)
  let scheme = call_607152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607152.url(scheme.get, call_607152.host, call_607152.base,
                         call_607152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607152, url, valid)

proc call*(call_607153: Call_UpdateSchema_607140; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_607154 = newJObject()
  if body != nil:
    body_607154 = body
  result = call_607153.call(nil, nil, nil, nil, body_607154)

var updateSchema* = Call_UpdateSchema_607140(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_607141, base: "/", url: url_UpdateSchema_607142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_607155 = ref object of OpenApiRestCall_605589
proc url_UpdateTypedLinkFacet_607157(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTypedLinkFacet_607156(path: JsonNode; query: JsonNode;
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
  var valid_607158 = header.getOrDefault("X-Amz-Signature")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Signature", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Content-Sha256", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Date")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Date", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Credential")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Credential", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Security-Token")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Security-Token", valid_607162
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_607163 = header.getOrDefault("x-amz-data-partition")
  valid_607163 = validateParameter(valid_607163, JString, required = true,
                                 default = nil)
  if valid_607163 != nil:
    section.add "x-amz-data-partition", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-Algorithm")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Algorithm", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-SignedHeaders", valid_607165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607167: Call_UpdateTypedLinkFacet_607155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_607167.validator(path, query, header, formData, body)
  let scheme = call_607167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607167.url(scheme.get, call_607167.host, call_607167.base,
                         call_607167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607167, url, valid)

proc call*(call_607168: Call_UpdateTypedLinkFacet_607155; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_607169 = newJObject()
  if body != nil:
    body_607169 = body
  result = call_607168.call(nil, nil, nil, nil, body_607169)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_607155(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_607156, base: "/",
    url: url_UpdateTypedLinkFacet_607157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_607170 = ref object of OpenApiRestCall_605589
proc url_UpgradeAppliedSchema_607172(protocol: Scheme; host: string; base: string;
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

proc validate_UpgradeAppliedSchema_607171(path: JsonNode; query: JsonNode;
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
  var valid_607173 = header.getOrDefault("X-Amz-Signature")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Signature", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Content-Sha256", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Date")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Date", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Credential")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Credential", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Security-Token")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Security-Token", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Algorithm")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Algorithm", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-SignedHeaders", valid_607179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607181: Call_UpgradeAppliedSchema_607170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_607181.validator(path, query, header, formData, body)
  let scheme = call_607181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607181.url(scheme.get, call_607181.host, call_607181.base,
                         call_607181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607181, url, valid)

proc call*(call_607182: Call_UpgradeAppliedSchema_607170; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_607183 = newJObject()
  if body != nil:
    body_607183 = body
  result = call_607182.call(nil, nil, nil, nil, body_607183)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_607170(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_607171, base: "/",
    url: url_UpgradeAppliedSchema_607172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_607184 = ref object of OpenApiRestCall_605589
proc url_UpgradePublishedSchema_607186(protocol: Scheme; host: string; base: string;
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

proc validate_UpgradePublishedSchema_607185(path: JsonNode; query: JsonNode;
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
  var valid_607187 = header.getOrDefault("X-Amz-Signature")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Signature", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Content-Sha256", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Date")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Date", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Credential")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Credential", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Security-Token")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Security-Token", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Algorithm")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Algorithm", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-SignedHeaders", valid_607193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607195: Call_UpgradePublishedSchema_607184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_607195.validator(path, query, header, formData, body)
  let scheme = call_607195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607195.url(scheme.get, call_607195.host, call_607195.base,
                         call_607195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607195, url, valid)

proc call*(call_607196: Call_UpgradePublishedSchema_607184; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_607197 = newJObject()
  if body != nil:
    body_607197 = body
  result = call_607196.call(nil, nil, nil, nil, body_607197)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_607184(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_607185, base: "/",
    url: url_UpgradePublishedSchema_607186, schemes: {Scheme.Https, Scheme.Http})
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
