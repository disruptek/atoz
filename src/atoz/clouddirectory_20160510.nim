
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddFacetToObject_772933 = ref object of OpenApiRestCall_772597
proc url_AddFacetToObject_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddFacetToObject_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773054 = header.getOrDefault("x-amz-data-partition")
  valid_773054 = validateParameter(valid_773054, JString, required = true,
                                 default = nil)
  if valid_773054 != nil:
    section.add "x-amz-data-partition", valid_773054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773078: Call_AddFacetToObject_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_773078.validator(path, query, header, formData, body)
  let scheme = call_773078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773078.url(scheme.get, call_773078.host, call_773078.base,
                         call_773078.route, valid.getOrDefault("path"))
  result = hook(call_773078, url, valid)

proc call*(call_773149: Call_AddFacetToObject_772933; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_773150 = newJObject()
  if body != nil:
    body_773150 = body
  result = call_773149.call(nil, nil, nil, nil, body_773150)

var addFacetToObject* = Call_AddFacetToObject_772933(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_772934, base: "/",
    url: url_AddFacetToObject_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_773189 = ref object of OpenApiRestCall_772597
proc url_ApplySchema_773191(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApplySchema_773190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773192 = header.getOrDefault("X-Amz-Date")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Date", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Security-Token")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Security-Token", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Content-Sha256", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Algorithm")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Algorithm", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Signature")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Signature", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-SignedHeaders", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-Credential")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-Credential", valid_773198
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773199 = header.getOrDefault("x-amz-data-partition")
  valid_773199 = validateParameter(valid_773199, JString, required = true,
                                 default = nil)
  if valid_773199 != nil:
    section.add "x-amz-data-partition", valid_773199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773201: Call_ApplySchema_773189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_773201.validator(path, query, header, formData, body)
  let scheme = call_773201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773201.url(scheme.get, call_773201.host, call_773201.base,
                         call_773201.route, valid.getOrDefault("path"))
  result = hook(call_773201, url, valid)

proc call*(call_773202: Call_ApplySchema_773189; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_773203 = newJObject()
  if body != nil:
    body_773203 = body
  result = call_773202.call(nil, nil, nil, nil, body_773203)

var applySchema* = Call_ApplySchema_773189(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_773190,
                                        base: "/", url: url_ApplySchema_773191,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_773204 = ref object of OpenApiRestCall_772597
proc url_AttachObject_773206(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachObject_773205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773207 = header.getOrDefault("X-Amz-Date")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Date", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Security-Token")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Security-Token", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Content-Sha256", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Algorithm")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Algorithm", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Signature")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Signature", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-SignedHeaders", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Credential")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Credential", valid_773213
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773214 = header.getOrDefault("x-amz-data-partition")
  valid_773214 = validateParameter(valid_773214, JString, required = true,
                                 default = nil)
  if valid_773214 != nil:
    section.add "x-amz-data-partition", valid_773214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773216: Call_AttachObject_773204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_773216.validator(path, query, header, formData, body)
  let scheme = call_773216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773216.url(scheme.get, call_773216.host, call_773216.base,
                         call_773216.route, valid.getOrDefault("path"))
  result = hook(call_773216, url, valid)

proc call*(call_773217: Call_AttachObject_773204; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_773218 = newJObject()
  if body != nil:
    body_773218 = body
  result = call_773217.call(nil, nil, nil, nil, body_773218)

var attachObject* = Call_AttachObject_773204(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_773205, base: "/", url: url_AttachObject_773206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_773219 = ref object of OpenApiRestCall_772597
proc url_AttachPolicy_773221(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachPolicy_773220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773222 = header.getOrDefault("X-Amz-Date")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Date", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Security-Token")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Security-Token", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Content-Sha256", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Algorithm")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Algorithm", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Signature")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Signature", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-SignedHeaders", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Credential")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Credential", valid_773228
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773229 = header.getOrDefault("x-amz-data-partition")
  valid_773229 = validateParameter(valid_773229, JString, required = true,
                                 default = nil)
  if valid_773229 != nil:
    section.add "x-amz-data-partition", valid_773229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773231: Call_AttachPolicy_773219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_773231.validator(path, query, header, formData, body)
  let scheme = call_773231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773231.url(scheme.get, call_773231.host, call_773231.base,
                         call_773231.route, valid.getOrDefault("path"))
  result = hook(call_773231, url, valid)

proc call*(call_773232: Call_AttachPolicy_773219; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_773233 = newJObject()
  if body != nil:
    body_773233 = body
  result = call_773232.call(nil, nil, nil, nil, body_773233)

var attachPolicy* = Call_AttachPolicy_773219(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_773220, base: "/", url: url_AttachPolicy_773221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_773234 = ref object of OpenApiRestCall_772597
proc url_AttachToIndex_773236(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachToIndex_773235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773237 = header.getOrDefault("X-Amz-Date")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Date", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Security-Token")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Security-Token", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Content-Sha256", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Algorithm")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Algorithm", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Signature")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Signature", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-SignedHeaders", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Credential")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Credential", valid_773243
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773244 = header.getOrDefault("x-amz-data-partition")
  valid_773244 = validateParameter(valid_773244, JString, required = true,
                                 default = nil)
  if valid_773244 != nil:
    section.add "x-amz-data-partition", valid_773244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773246: Call_AttachToIndex_773234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_773246.validator(path, query, header, formData, body)
  let scheme = call_773246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773246.url(scheme.get, call_773246.host, call_773246.base,
                         call_773246.route, valid.getOrDefault("path"))
  result = hook(call_773246, url, valid)

proc call*(call_773247: Call_AttachToIndex_773234; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_773248 = newJObject()
  if body != nil:
    body_773248 = body
  result = call_773247.call(nil, nil, nil, nil, body_773248)

var attachToIndex* = Call_AttachToIndex_773234(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_773235, base: "/", url: url_AttachToIndex_773236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_773249 = ref object of OpenApiRestCall_772597
proc url_AttachTypedLink_773251(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachTypedLink_773250(path: JsonNode; query: JsonNode;
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
  var valid_773252 = header.getOrDefault("X-Amz-Date")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Date", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Security-Token")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Security-Token", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Content-Sha256", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Algorithm")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Algorithm", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Signature")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Signature", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-SignedHeaders", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Credential")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Credential", valid_773258
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773259 = header.getOrDefault("x-amz-data-partition")
  valid_773259 = validateParameter(valid_773259, JString, required = true,
                                 default = nil)
  if valid_773259 != nil:
    section.add "x-amz-data-partition", valid_773259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773261: Call_AttachTypedLink_773249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773261.validator(path, query, header, formData, body)
  let scheme = call_773261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773261.url(scheme.get, call_773261.host, call_773261.base,
                         call_773261.route, valid.getOrDefault("path"))
  result = hook(call_773261, url, valid)

proc call*(call_773262: Call_AttachTypedLink_773249; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773263 = newJObject()
  if body != nil:
    body_773263 = body
  result = call_773262.call(nil, nil, nil, nil, body_773263)

var attachTypedLink* = Call_AttachTypedLink_773249(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_773250, base: "/", url: url_AttachTypedLink_773251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_773264 = ref object of OpenApiRestCall_772597
proc url_BatchRead_773266(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchRead_773265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773286 = header.getOrDefault("x-amz-consistency-level")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773286 != nil:
    section.add "x-amz-consistency-level", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773288 = header.getOrDefault("x-amz-data-partition")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = nil)
  if valid_773288 != nil:
    section.add "x-amz-data-partition", valid_773288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773290: Call_BatchRead_773264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_773290.validator(path, query, header, formData, body)
  let scheme = call_773290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773290.url(scheme.get, call_773290.host, call_773290.base,
                         call_773290.route, valid.getOrDefault("path"))
  result = hook(call_773290, url, valid)

proc call*(call_773291: Call_BatchRead_773264; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_773292 = newJObject()
  if body != nil:
    body_773292 = body
  result = call_773291.call(nil, nil, nil, nil, body_773292)

var batchRead* = Call_BatchRead_773264(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_773265,
                                    base: "/", url: url_BatchRead_773266,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_773293 = ref object of OpenApiRestCall_772597
proc url_BatchWrite_773295(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchWrite_773294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773296 = header.getOrDefault("X-Amz-Date")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Date", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Security-Token")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Security-Token", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773303 = header.getOrDefault("x-amz-data-partition")
  valid_773303 = validateParameter(valid_773303, JString, required = true,
                                 default = nil)
  if valid_773303 != nil:
    section.add "x-amz-data-partition", valid_773303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773305: Call_BatchWrite_773293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_773305.validator(path, query, header, formData, body)
  let scheme = call_773305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773305.url(scheme.get, call_773305.host, call_773305.base,
                         call_773305.route, valid.getOrDefault("path"))
  result = hook(call_773305, url, valid)

proc call*(call_773306: Call_BatchWrite_773293; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_773307 = newJObject()
  if body != nil:
    body_773307 = body
  result = call_773306.call(nil, nil, nil, nil, body_773307)

var batchWrite* = Call_BatchWrite_773293(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_773294,
                                      base: "/", url: url_BatchWrite_773295,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_773308 = ref object of OpenApiRestCall_772597
proc url_CreateDirectory_773310(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDirectory_773309(path: JsonNode; query: JsonNode;
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
  var valid_773311 = header.getOrDefault("X-Amz-Date")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Date", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Security-Token")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Security-Token", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773318 = header.getOrDefault("x-amz-data-partition")
  valid_773318 = validateParameter(valid_773318, JString, required = true,
                                 default = nil)
  if valid_773318 != nil:
    section.add "x-amz-data-partition", valid_773318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773320: Call_CreateDirectory_773308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  let valid = call_773320.validator(path, query, header, formData, body)
  let scheme = call_773320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773320.url(scheme.get, call_773320.host, call_773320.base,
                         call_773320.route, valid.getOrDefault("path"))
  result = hook(call_773320, url, valid)

proc call*(call_773321: Call_CreateDirectory_773308; body: JsonNode): Recallable =
  ## createDirectory
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ##   body: JObject (required)
  var body_773322 = newJObject()
  if body != nil:
    body_773322 = body
  result = call_773321.call(nil, nil, nil, nil, body_773322)

var createDirectory* = Call_CreateDirectory_773308(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_773309, base: "/", url: url_CreateDirectory_773310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_773323 = ref object of OpenApiRestCall_772597
proc url_CreateFacet_773325(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFacet_773324(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773326 = header.getOrDefault("X-Amz-Date")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Date", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Security-Token")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Security-Token", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773333 = header.getOrDefault("x-amz-data-partition")
  valid_773333 = validateParameter(valid_773333, JString, required = true,
                                 default = nil)
  if valid_773333 != nil:
    section.add "x-amz-data-partition", valid_773333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773335: Call_CreateFacet_773323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_773335.validator(path, query, header, formData, body)
  let scheme = call_773335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773335.url(scheme.get, call_773335.host, call_773335.base,
                         call_773335.route, valid.getOrDefault("path"))
  result = hook(call_773335, url, valid)

proc call*(call_773336: Call_CreateFacet_773323; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_773337 = newJObject()
  if body != nil:
    body_773337 = body
  result = call_773336.call(nil, nil, nil, nil, body_773337)

var createFacet* = Call_CreateFacet_773323(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_773324,
                                        base: "/", url: url_CreateFacet_773325,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_773338 = ref object of OpenApiRestCall_772597
proc url_CreateIndex_773340(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateIndex_773339(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773341 = header.getOrDefault("X-Amz-Date")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Date", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Security-Token")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Security-Token", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773348 = header.getOrDefault("x-amz-data-partition")
  valid_773348 = validateParameter(valid_773348, JString, required = true,
                                 default = nil)
  if valid_773348 != nil:
    section.add "x-amz-data-partition", valid_773348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773350: Call_CreateIndex_773338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  let valid = call_773350.validator(path, query, header, formData, body)
  let scheme = call_773350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773350.url(scheme.get, call_773350.host, call_773350.base,
                         call_773350.route, valid.getOrDefault("path"))
  result = hook(call_773350, url, valid)

proc call*(call_773351: Call_CreateIndex_773338; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ##   body: JObject (required)
  var body_773352 = newJObject()
  if body != nil:
    body_773352 = body
  result = call_773351.call(nil, nil, nil, nil, body_773352)

var createIndex* = Call_CreateIndex_773338(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_773339,
                                        base: "/", url: url_CreateIndex_773340,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_773353 = ref object of OpenApiRestCall_772597
proc url_CreateObject_773355(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateObject_773354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773363 = header.getOrDefault("x-amz-data-partition")
  valid_773363 = validateParameter(valid_773363, JString, required = true,
                                 default = nil)
  if valid_773363 != nil:
    section.add "x-amz-data-partition", valid_773363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773365: Call_CreateObject_773353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_773365.validator(path, query, header, formData, body)
  let scheme = call_773365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773365.url(scheme.get, call_773365.host, call_773365.base,
                         call_773365.route, valid.getOrDefault("path"))
  result = hook(call_773365, url, valid)

proc call*(call_773366: Call_CreateObject_773353; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_773367 = newJObject()
  if body != nil:
    body_773367 = body
  result = call_773366.call(nil, nil, nil, nil, body_773367)

var createObject* = Call_CreateObject_773353(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_773354, base: "/", url: url_CreateObject_773355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_773368 = ref object of OpenApiRestCall_772597
proc url_CreateSchema_773370(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSchema_773369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773371 = header.getOrDefault("X-Amz-Date")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Date", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Security-Token")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Security-Token", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_CreateSchema_773368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_CreateSchema_773368; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var createSchema* = Call_CreateSchema_773368(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_773369, base: "/", url: url_CreateSchema_773370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_773382 = ref object of OpenApiRestCall_772597
proc url_CreateTypedLinkFacet_773384(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTypedLinkFacet_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  var valid_773387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "X-Amz-Content-Sha256", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Algorithm")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Algorithm", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Signature")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Signature", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-SignedHeaders", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Credential")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Credential", valid_773391
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773392 = header.getOrDefault("x-amz-data-partition")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = nil)
  if valid_773392 != nil:
    section.add "x-amz-data-partition", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_CreateTypedLinkFacet_773382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_CreateTypedLinkFacet_773382; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_773382(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_773383, base: "/",
    url: url_CreateTypedLinkFacet_773384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_773397 = ref object of OpenApiRestCall_772597
proc url_DeleteDirectory_773399(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDirectory_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = header.getOrDefault("X-Amz-Date")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-Date", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Security-Token")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Security-Token", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Content-Sha256", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Algorithm")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Algorithm", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Signature")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Signature", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-SignedHeaders", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Credential")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Credential", valid_773406
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773407 = header.getOrDefault("x-amz-data-partition")
  valid_773407 = validateParameter(valid_773407, JString, required = true,
                                 default = nil)
  if valid_773407 != nil:
    section.add "x-amz-data-partition", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773408: Call_DeleteDirectory_773397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_773408.validator(path, query, header, formData, body)
  let scheme = call_773408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773408.url(scheme.get, call_773408.host, call_773408.base,
                         call_773408.route, valid.getOrDefault("path"))
  result = hook(call_773408, url, valid)

proc call*(call_773409: Call_DeleteDirectory_773397): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_773409.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_773397(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_773398, base: "/", url: url_DeleteDirectory_773399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_773410 = ref object of OpenApiRestCall_772597
proc url_DeleteFacet_773412(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFacet_773411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773413 = header.getOrDefault("X-Amz-Date")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Date", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Security-Token")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Security-Token", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Content-Sha256", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Algorithm")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Algorithm", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Signature")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Signature", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-SignedHeaders", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Credential")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Credential", valid_773419
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773420 = header.getOrDefault("x-amz-data-partition")
  valid_773420 = validateParameter(valid_773420, JString, required = true,
                                 default = nil)
  if valid_773420 != nil:
    section.add "x-amz-data-partition", valid_773420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773422: Call_DeleteFacet_773410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_773422.validator(path, query, header, formData, body)
  let scheme = call_773422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773422.url(scheme.get, call_773422.host, call_773422.base,
                         call_773422.route, valid.getOrDefault("path"))
  result = hook(call_773422, url, valid)

proc call*(call_773423: Call_DeleteFacet_773410; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_773424 = newJObject()
  if body != nil:
    body_773424 = body
  result = call_773423.call(nil, nil, nil, nil, body_773424)

var deleteFacet* = Call_DeleteFacet_773410(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_773411,
                                        base: "/", url: url_DeleteFacet_773412,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_773425 = ref object of OpenApiRestCall_772597
proc url_DeleteObject_773427(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteObject_773426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773428 = header.getOrDefault("X-Amz-Date")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Date", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Security-Token")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Security-Token", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Content-Sha256", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Algorithm")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Algorithm", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Signature")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Signature", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-SignedHeaders", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Credential")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Credential", valid_773434
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773435 = header.getOrDefault("x-amz-data-partition")
  valid_773435 = validateParameter(valid_773435, JString, required = true,
                                 default = nil)
  if valid_773435 != nil:
    section.add "x-amz-data-partition", valid_773435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773437: Call_DeleteObject_773425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  let valid = call_773437.validator(path, query, header, formData, body)
  let scheme = call_773437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773437.url(scheme.get, call_773437.host, call_773437.base,
                         call_773437.route, valid.getOrDefault("path"))
  result = hook(call_773437, url, valid)

proc call*(call_773438: Call_DeleteObject_773425; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ##   body: JObject (required)
  var body_773439 = newJObject()
  if body != nil:
    body_773439 = body
  result = call_773438.call(nil, nil, nil, nil, body_773439)

var deleteObject* = Call_DeleteObject_773425(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_773426, base: "/", url: url_DeleteObject_773427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_773440 = ref object of OpenApiRestCall_772597
proc url_DeleteSchema_773442(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSchema_773441(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773443 = header.getOrDefault("X-Amz-Date")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Date", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Security-Token")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Security-Token", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Content-Sha256", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Algorithm")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Algorithm", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Signature")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Signature", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-SignedHeaders", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Credential")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Credential", valid_773449
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773450 = header.getOrDefault("x-amz-data-partition")
  valid_773450 = validateParameter(valid_773450, JString, required = true,
                                 default = nil)
  if valid_773450 != nil:
    section.add "x-amz-data-partition", valid_773450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773451: Call_DeleteSchema_773440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_773451.validator(path, query, header, formData, body)
  let scheme = call_773451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773451.url(scheme.get, call_773451.host, call_773451.base,
                         call_773451.route, valid.getOrDefault("path"))
  result = hook(call_773451, url, valid)

proc call*(call_773452: Call_DeleteSchema_773440): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_773452.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_773440(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_773441, base: "/", url: url_DeleteSchema_773442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_773453 = ref object of OpenApiRestCall_772597
proc url_DeleteTypedLinkFacet_773455(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTypedLinkFacet_773454(path: JsonNode; query: JsonNode;
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
  var valid_773456 = header.getOrDefault("X-Amz-Date")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Date", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Security-Token")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Security-Token", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Content-Sha256", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Algorithm")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Algorithm", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Signature")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Signature", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-SignedHeaders", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Credential")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Credential", valid_773462
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773463 = header.getOrDefault("x-amz-data-partition")
  valid_773463 = validateParameter(valid_773463, JString, required = true,
                                 default = nil)
  if valid_773463 != nil:
    section.add "x-amz-data-partition", valid_773463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773465: Call_DeleteTypedLinkFacet_773453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773465.validator(path, query, header, formData, body)
  let scheme = call_773465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773465.url(scheme.get, call_773465.host, call_773465.base,
                         call_773465.route, valid.getOrDefault("path"))
  result = hook(call_773465, url, valid)

proc call*(call_773466: Call_DeleteTypedLinkFacet_773453; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773467 = newJObject()
  if body != nil:
    body_773467 = body
  result = call_773466.call(nil, nil, nil, nil, body_773467)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_773453(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_773454, base: "/",
    url: url_DeleteTypedLinkFacet_773455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_773468 = ref object of OpenApiRestCall_772597
proc url_DetachFromIndex_773470(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachFromIndex_773469(path: JsonNode; query: JsonNode;
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
  var valid_773471 = header.getOrDefault("X-Amz-Date")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Date", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Security-Token")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Security-Token", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Content-Sha256", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Algorithm")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Algorithm", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Signature")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Signature", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-SignedHeaders", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Credential")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Credential", valid_773477
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773478 = header.getOrDefault("x-amz-data-partition")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "x-amz-data-partition", valid_773478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773480: Call_DetachFromIndex_773468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_773480.validator(path, query, header, formData, body)
  let scheme = call_773480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773480.url(scheme.get, call_773480.host, call_773480.base,
                         call_773480.route, valid.getOrDefault("path"))
  result = hook(call_773480, url, valid)

proc call*(call_773481: Call_DetachFromIndex_773468; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_773482 = newJObject()
  if body != nil:
    body_773482 = body
  result = call_773481.call(nil, nil, nil, nil, body_773482)

var detachFromIndex* = Call_DetachFromIndex_773468(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_773469, base: "/", url: url_DetachFromIndex_773470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_773483 = ref object of OpenApiRestCall_772597
proc url_DetachObject_773485(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachObject_773484(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773486 = header.getOrDefault("X-Amz-Date")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Date", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Security-Token")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Security-Token", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Content-Sha256", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Algorithm")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Algorithm", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Signature")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Signature", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-SignedHeaders", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Credential")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Credential", valid_773492
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773493 = header.getOrDefault("x-amz-data-partition")
  valid_773493 = validateParameter(valid_773493, JString, required = true,
                                 default = nil)
  if valid_773493 != nil:
    section.add "x-amz-data-partition", valid_773493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773495: Call_DetachObject_773483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_773495.validator(path, query, header, formData, body)
  let scheme = call_773495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773495.url(scheme.get, call_773495.host, call_773495.base,
                         call_773495.route, valid.getOrDefault("path"))
  result = hook(call_773495, url, valid)

proc call*(call_773496: Call_DetachObject_773483; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_773497 = newJObject()
  if body != nil:
    body_773497 = body
  result = call_773496.call(nil, nil, nil, nil, body_773497)

var detachObject* = Call_DetachObject_773483(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_773484, base: "/", url: url_DetachObject_773485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_773498 = ref object of OpenApiRestCall_772597
proc url_DetachPolicy_773500(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachPolicy_773499(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773501 = header.getOrDefault("X-Amz-Date")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Date", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Security-Token")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Security-Token", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Content-Sha256", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Algorithm")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Algorithm", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Signature")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Signature", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-SignedHeaders", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Credential")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Credential", valid_773507
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773508 = header.getOrDefault("x-amz-data-partition")
  valid_773508 = validateParameter(valid_773508, JString, required = true,
                                 default = nil)
  if valid_773508 != nil:
    section.add "x-amz-data-partition", valid_773508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773510: Call_DetachPolicy_773498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_773510.validator(path, query, header, formData, body)
  let scheme = call_773510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773510.url(scheme.get, call_773510.host, call_773510.base,
                         call_773510.route, valid.getOrDefault("path"))
  result = hook(call_773510, url, valid)

proc call*(call_773511: Call_DetachPolicy_773498; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_773512 = newJObject()
  if body != nil:
    body_773512 = body
  result = call_773511.call(nil, nil, nil, nil, body_773512)

var detachPolicy* = Call_DetachPolicy_773498(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_773499, base: "/", url: url_DetachPolicy_773500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_773513 = ref object of OpenApiRestCall_772597
proc url_DetachTypedLink_773515(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachTypedLink_773514(path: JsonNode; query: JsonNode;
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
  var valid_773516 = header.getOrDefault("X-Amz-Date")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Date", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Security-Token")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Security-Token", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Content-Sha256", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Algorithm")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Algorithm", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Signature")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Signature", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-SignedHeaders", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Credential")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Credential", valid_773522
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773523 = header.getOrDefault("x-amz-data-partition")
  valid_773523 = validateParameter(valid_773523, JString, required = true,
                                 default = nil)
  if valid_773523 != nil:
    section.add "x-amz-data-partition", valid_773523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773525: Call_DetachTypedLink_773513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773525.validator(path, query, header, formData, body)
  let scheme = call_773525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773525.url(scheme.get, call_773525.host, call_773525.base,
                         call_773525.route, valid.getOrDefault("path"))
  result = hook(call_773525, url, valid)

proc call*(call_773526: Call_DetachTypedLink_773513; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773527 = newJObject()
  if body != nil:
    body_773527 = body
  result = call_773526.call(nil, nil, nil, nil, body_773527)

var detachTypedLink* = Call_DetachTypedLink_773513(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_773514, base: "/", url: url_DetachTypedLink_773515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_773528 = ref object of OpenApiRestCall_772597
proc url_DisableDirectory_773530(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDirectory_773529(path: JsonNode; query: JsonNode;
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
  var valid_773531 = header.getOrDefault("X-Amz-Date")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Date", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Security-Token")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Security-Token", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Content-Sha256", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Algorithm")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Algorithm", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Signature")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Signature", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-SignedHeaders", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Credential")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Credential", valid_773537
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773538 = header.getOrDefault("x-amz-data-partition")
  valid_773538 = validateParameter(valid_773538, JString, required = true,
                                 default = nil)
  if valid_773538 != nil:
    section.add "x-amz-data-partition", valid_773538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773539: Call_DisableDirectory_773528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_773539.validator(path, query, header, formData, body)
  let scheme = call_773539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773539.url(scheme.get, call_773539.host, call_773539.base,
                         call_773539.route, valid.getOrDefault("path"))
  result = hook(call_773539, url, valid)

proc call*(call_773540: Call_DisableDirectory_773528): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_773540.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_773528(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_773529, base: "/",
    url: url_DisableDirectory_773530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_773541 = ref object of OpenApiRestCall_772597
proc url_EnableDirectory_773543(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDirectory_773542(path: JsonNode; query: JsonNode;
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
  var valid_773544 = header.getOrDefault("X-Amz-Date")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Date", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Security-Token")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Security-Token", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Content-Sha256", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Algorithm")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Algorithm", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Signature")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Signature", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-SignedHeaders", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Credential")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Credential", valid_773550
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773551 = header.getOrDefault("x-amz-data-partition")
  valid_773551 = validateParameter(valid_773551, JString, required = true,
                                 default = nil)
  if valid_773551 != nil:
    section.add "x-amz-data-partition", valid_773551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773552: Call_EnableDirectory_773541; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_773552.validator(path, query, header, formData, body)
  let scheme = call_773552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773552.url(scheme.get, call_773552.host, call_773552.base,
                         call_773552.route, valid.getOrDefault("path"))
  result = hook(call_773552, url, valid)

proc call*(call_773553: Call_EnableDirectory_773541): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_773553.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_773541(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_773542, base: "/", url: url_EnableDirectory_773543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_773554 = ref object of OpenApiRestCall_772597
proc url_GetAppliedSchemaVersion_773556(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppliedSchemaVersion_773555(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773557 = header.getOrDefault("X-Amz-Date")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "X-Amz-Date", valid_773557
  var valid_773558 = header.getOrDefault("X-Amz-Security-Token")
  valid_773558 = validateParameter(valid_773558, JString, required = false,
                                 default = nil)
  if valid_773558 != nil:
    section.add "X-Amz-Security-Token", valid_773558
  var valid_773559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Content-Sha256", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Algorithm")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Algorithm", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Signature")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Signature", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-SignedHeaders", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Credential")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Credential", valid_773563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773565: Call_GetAppliedSchemaVersion_773554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_773565.validator(path, query, header, formData, body)
  let scheme = call_773565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773565.url(scheme.get, call_773565.host, call_773565.base,
                         call_773565.route, valid.getOrDefault("path"))
  result = hook(call_773565, url, valid)

proc call*(call_773566: Call_GetAppliedSchemaVersion_773554; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_773567 = newJObject()
  if body != nil:
    body_773567 = body
  result = call_773566.call(nil, nil, nil, nil, body_773567)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_773554(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_773555, base: "/",
    url: url_GetAppliedSchemaVersion_773556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_773568 = ref object of OpenApiRestCall_772597
proc url_GetDirectory_773570(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDirectory_773569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773571 = header.getOrDefault("X-Amz-Date")
  valid_773571 = validateParameter(valid_773571, JString, required = false,
                                 default = nil)
  if valid_773571 != nil:
    section.add "X-Amz-Date", valid_773571
  var valid_773572 = header.getOrDefault("X-Amz-Security-Token")
  valid_773572 = validateParameter(valid_773572, JString, required = false,
                                 default = nil)
  if valid_773572 != nil:
    section.add "X-Amz-Security-Token", valid_773572
  var valid_773573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773573 = validateParameter(valid_773573, JString, required = false,
                                 default = nil)
  if valid_773573 != nil:
    section.add "X-Amz-Content-Sha256", valid_773573
  var valid_773574 = header.getOrDefault("X-Amz-Algorithm")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Algorithm", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Signature")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Signature", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-SignedHeaders", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Credential")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Credential", valid_773577
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773578 = header.getOrDefault("x-amz-data-partition")
  valid_773578 = validateParameter(valid_773578, JString, required = true,
                                 default = nil)
  if valid_773578 != nil:
    section.add "x-amz-data-partition", valid_773578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773579: Call_GetDirectory_773568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_773579.validator(path, query, header, formData, body)
  let scheme = call_773579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773579.url(scheme.get, call_773579.host, call_773579.base,
                         call_773579.route, valid.getOrDefault("path"))
  result = hook(call_773579, url, valid)

proc call*(call_773580: Call_GetDirectory_773568): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_773580.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_773568(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_773569, base: "/", url: url_GetDirectory_773570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_773581 = ref object of OpenApiRestCall_772597
proc url_UpdateFacet_773583(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFacet_773582(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773584 = header.getOrDefault("X-Amz-Date")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Date", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Security-Token")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Security-Token", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-Content-Sha256", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Algorithm")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Algorithm", valid_773587
  var valid_773588 = header.getOrDefault("X-Amz-Signature")
  valid_773588 = validateParameter(valid_773588, JString, required = false,
                                 default = nil)
  if valid_773588 != nil:
    section.add "X-Amz-Signature", valid_773588
  var valid_773589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773589 = validateParameter(valid_773589, JString, required = false,
                                 default = nil)
  if valid_773589 != nil:
    section.add "X-Amz-SignedHeaders", valid_773589
  var valid_773590 = header.getOrDefault("X-Amz-Credential")
  valid_773590 = validateParameter(valid_773590, JString, required = false,
                                 default = nil)
  if valid_773590 != nil:
    section.add "X-Amz-Credential", valid_773590
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773591 = header.getOrDefault("x-amz-data-partition")
  valid_773591 = validateParameter(valid_773591, JString, required = true,
                                 default = nil)
  if valid_773591 != nil:
    section.add "x-amz-data-partition", valid_773591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773593: Call_UpdateFacet_773581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_773593.validator(path, query, header, formData, body)
  let scheme = call_773593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773593.url(scheme.get, call_773593.host, call_773593.base,
                         call_773593.route, valid.getOrDefault("path"))
  result = hook(call_773593, url, valid)

proc call*(call_773594: Call_UpdateFacet_773581; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_773595 = newJObject()
  if body != nil:
    body_773595 = body
  result = call_773594.call(nil, nil, nil, nil, body_773595)

var updateFacet* = Call_UpdateFacet_773581(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_773582,
                                        base: "/", url: url_UpdateFacet_773583,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_773596 = ref object of OpenApiRestCall_772597
proc url_GetFacet_773598(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFacet_773597(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773599 = header.getOrDefault("X-Amz-Date")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Date", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Security-Token")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Security-Token", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Content-Sha256", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Algorithm")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Algorithm", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Signature")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Signature", valid_773603
  var valid_773604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773604 = validateParameter(valid_773604, JString, required = false,
                                 default = nil)
  if valid_773604 != nil:
    section.add "X-Amz-SignedHeaders", valid_773604
  var valid_773605 = header.getOrDefault("X-Amz-Credential")
  valid_773605 = validateParameter(valid_773605, JString, required = false,
                                 default = nil)
  if valid_773605 != nil:
    section.add "X-Amz-Credential", valid_773605
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773606 = header.getOrDefault("x-amz-data-partition")
  valid_773606 = validateParameter(valid_773606, JString, required = true,
                                 default = nil)
  if valid_773606 != nil:
    section.add "x-amz-data-partition", valid_773606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773608: Call_GetFacet_773596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_773608.validator(path, query, header, formData, body)
  let scheme = call_773608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773608.url(scheme.get, call_773608.host, call_773608.base,
                         call_773608.route, valid.getOrDefault("path"))
  result = hook(call_773608, url, valid)

proc call*(call_773609: Call_GetFacet_773596; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_773610 = newJObject()
  if body != nil:
    body_773610 = body
  result = call_773609.call(nil, nil, nil, nil, body_773610)

var getFacet* = Call_GetFacet_773596(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_773597, base: "/",
                                  url: url_GetFacet_773598,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_773611 = ref object of OpenApiRestCall_772597
proc url_GetLinkAttributes_773613(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLinkAttributes_773612(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the typed link resides. For more information, see <a>arns</a> or <a 
  ## href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  section = newJObject()
  var valid_773614 = header.getOrDefault("X-Amz-Date")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Date", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Security-Token")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Security-Token", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Content-Sha256", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Algorithm")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Algorithm", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Signature")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Signature", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-SignedHeaders", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Credential")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Credential", valid_773620
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773621 = header.getOrDefault("x-amz-data-partition")
  valid_773621 = validateParameter(valid_773621, JString, required = true,
                                 default = nil)
  if valid_773621 != nil:
    section.add "x-amz-data-partition", valid_773621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773623: Call_GetLinkAttributes_773611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_773623.validator(path, query, header, formData, body)
  let scheme = call_773623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773623.url(scheme.get, call_773623.host, call_773623.base,
                         call_773623.route, valid.getOrDefault("path"))
  result = hook(call_773623, url, valid)

proc call*(call_773624: Call_GetLinkAttributes_773611; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_773625 = newJObject()
  if body != nil:
    body_773625 = body
  result = call_773624.call(nil, nil, nil, nil, body_773625)

var getLinkAttributes* = Call_GetLinkAttributes_773611(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_773612, base: "/",
    url: url_GetLinkAttributes_773613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_773626 = ref object of OpenApiRestCall_772597
proc url_GetObjectAttributes_773628(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetObjectAttributes_773627(path: JsonNode; query: JsonNode;
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
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Content-Sha256", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Algorithm")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Algorithm", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Signature")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Signature", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-SignedHeaders", valid_773634
  var valid_773635 = header.getOrDefault("x-amz-consistency-level")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773635 != nil:
    section.add "x-amz-consistency-level", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Credential")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Credential", valid_773636
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773637 = header.getOrDefault("x-amz-data-partition")
  valid_773637 = validateParameter(valid_773637, JString, required = true,
                                 default = nil)
  if valid_773637 != nil:
    section.add "x-amz-data-partition", valid_773637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773639: Call_GetObjectAttributes_773626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_773639.validator(path, query, header, formData, body)
  let scheme = call_773639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773639.url(scheme.get, call_773639.host, call_773639.base,
                         call_773639.route, valid.getOrDefault("path"))
  result = hook(call_773639, url, valid)

proc call*(call_773640: Call_GetObjectAttributes_773626; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_773641 = newJObject()
  if body != nil:
    body_773641 = body
  result = call_773640.call(nil, nil, nil, nil, body_773641)

var getObjectAttributes* = Call_GetObjectAttributes_773626(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_773627, base: "/",
    url: url_GetObjectAttributes_773628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_773642 = ref object of OpenApiRestCall_772597
proc url_GetObjectInformation_773644(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetObjectInformation_773643(path: JsonNode; query: JsonNode;
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
  var valid_773645 = header.getOrDefault("X-Amz-Date")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Date", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Security-Token")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Security-Token", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Content-Sha256", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Algorithm")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Algorithm", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Signature")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Signature", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-SignedHeaders", valid_773650
  var valid_773651 = header.getOrDefault("x-amz-consistency-level")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773651 != nil:
    section.add "x-amz-consistency-level", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Credential")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Credential", valid_773652
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773653 = header.getOrDefault("x-amz-data-partition")
  valid_773653 = validateParameter(valid_773653, JString, required = true,
                                 default = nil)
  if valid_773653 != nil:
    section.add "x-amz-data-partition", valid_773653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773655: Call_GetObjectInformation_773642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_773655.validator(path, query, header, formData, body)
  let scheme = call_773655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773655.url(scheme.get, call_773655.host, call_773655.base,
                         call_773655.route, valid.getOrDefault("path"))
  result = hook(call_773655, url, valid)

proc call*(call_773656: Call_GetObjectInformation_773642; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_773657 = newJObject()
  if body != nil:
    body_773657 = body
  result = call_773656.call(nil, nil, nil, nil, body_773657)

var getObjectInformation* = Call_GetObjectInformation_773642(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_773643, base: "/",
    url: url_GetObjectInformation_773644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_773658 = ref object of OpenApiRestCall_772597
proc url_PutSchemaFromJson_773660(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutSchemaFromJson_773659(path: JsonNode; query: JsonNode;
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
  var valid_773661 = header.getOrDefault("X-Amz-Date")
  valid_773661 = validateParameter(valid_773661, JString, required = false,
                                 default = nil)
  if valid_773661 != nil:
    section.add "X-Amz-Date", valid_773661
  var valid_773662 = header.getOrDefault("X-Amz-Security-Token")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Security-Token", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Content-Sha256", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Algorithm")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Algorithm", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Signature")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Signature", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-SignedHeaders", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Credential")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Credential", valid_773667
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773668 = header.getOrDefault("x-amz-data-partition")
  valid_773668 = validateParameter(valid_773668, JString, required = true,
                                 default = nil)
  if valid_773668 != nil:
    section.add "x-amz-data-partition", valid_773668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773670: Call_PutSchemaFromJson_773658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_773670.validator(path, query, header, formData, body)
  let scheme = call_773670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773670.url(scheme.get, call_773670.host, call_773670.base,
                         call_773670.route, valid.getOrDefault("path"))
  result = hook(call_773670, url, valid)

proc call*(call_773671: Call_PutSchemaFromJson_773658; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_773672 = newJObject()
  if body != nil:
    body_773672 = body
  result = call_773671.call(nil, nil, nil, nil, body_773672)

var putSchemaFromJson* = Call_PutSchemaFromJson_773658(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_773659, base: "/",
    url: url_PutSchemaFromJson_773660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_773673 = ref object of OpenApiRestCall_772597
proc url_GetSchemaAsJson_773675(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSchemaAsJson_773674(path: JsonNode; query: JsonNode;
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
  var valid_773676 = header.getOrDefault("X-Amz-Date")
  valid_773676 = validateParameter(valid_773676, JString, required = false,
                                 default = nil)
  if valid_773676 != nil:
    section.add "X-Amz-Date", valid_773676
  var valid_773677 = header.getOrDefault("X-Amz-Security-Token")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "X-Amz-Security-Token", valid_773677
  var valid_773678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773678 = validateParameter(valid_773678, JString, required = false,
                                 default = nil)
  if valid_773678 != nil:
    section.add "X-Amz-Content-Sha256", valid_773678
  var valid_773679 = header.getOrDefault("X-Amz-Algorithm")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Algorithm", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Signature")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Signature", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-SignedHeaders", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Credential")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Credential", valid_773682
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773683 = header.getOrDefault("x-amz-data-partition")
  valid_773683 = validateParameter(valid_773683, JString, required = true,
                                 default = nil)
  if valid_773683 != nil:
    section.add "x-amz-data-partition", valid_773683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773684: Call_GetSchemaAsJson_773673; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_773684.validator(path, query, header, formData, body)
  let scheme = call_773684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773684.url(scheme.get, call_773684.host, call_773684.base,
                         call_773684.route, valid.getOrDefault("path"))
  result = hook(call_773684, url, valid)

proc call*(call_773685: Call_GetSchemaAsJson_773673): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  result = call_773685.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_773673(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_773674, base: "/", url: url_GetSchemaAsJson_773675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_773686 = ref object of OpenApiRestCall_772597
proc url_GetTypedLinkFacetInformation_773688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTypedLinkFacetInformation_773687(path: JsonNode; query: JsonNode;
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
  var valid_773689 = header.getOrDefault("X-Amz-Date")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Date", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Security-Token")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Security-Token", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-Content-Sha256", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Algorithm")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Algorithm", valid_773692
  var valid_773693 = header.getOrDefault("X-Amz-Signature")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Signature", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-SignedHeaders", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Credential")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Credential", valid_773695
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773696 = header.getOrDefault("x-amz-data-partition")
  valid_773696 = validateParameter(valid_773696, JString, required = true,
                                 default = nil)
  if valid_773696 != nil:
    section.add "x-amz-data-partition", valid_773696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773698: Call_GetTypedLinkFacetInformation_773686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773698.validator(path, query, header, formData, body)
  let scheme = call_773698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773698.url(scheme.get, call_773698.host, call_773698.base,
                         call_773698.route, valid.getOrDefault("path"))
  result = hook(call_773698, url, valid)

proc call*(call_773699: Call_GetTypedLinkFacetInformation_773686; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773700 = newJObject()
  if body != nil:
    body_773700 = body
  result = call_773699.call(nil, nil, nil, nil, body_773700)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_773686(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_773687, base: "/",
    url: url_GetTypedLinkFacetInformation_773688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_773701 = ref object of OpenApiRestCall_772597
proc url_ListAppliedSchemaArns_773703(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAppliedSchemaArns_773702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773704 = query.getOrDefault("NextToken")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "NextToken", valid_773704
  var valid_773705 = query.getOrDefault("MaxResults")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "MaxResults", valid_773705
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
  var valid_773706 = header.getOrDefault("X-Amz-Date")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Date", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Security-Token")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Security-Token", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Content-Sha256", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Algorithm")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Algorithm", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Signature")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Signature", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-SignedHeaders", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-Credential")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-Credential", valid_773712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773714: Call_ListAppliedSchemaArns_773701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_773714.validator(path, query, header, formData, body)
  let scheme = call_773714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773714.url(scheme.get, call_773714.host, call_773714.base,
                         call_773714.route, valid.getOrDefault("path"))
  result = hook(call_773714, url, valid)

proc call*(call_773715: Call_ListAppliedSchemaArns_773701; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773716 = newJObject()
  var body_773717 = newJObject()
  add(query_773716, "NextToken", newJString(NextToken))
  if body != nil:
    body_773717 = body
  add(query_773716, "MaxResults", newJString(MaxResults))
  result = call_773715.call(nil, query_773716, nil, nil, body_773717)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_773701(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_773702, base: "/",
    url: url_ListAppliedSchemaArns_773703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_773719 = ref object of OpenApiRestCall_772597
proc url_ListAttachedIndices_773721(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAttachedIndices_773720(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_773722 = query.getOrDefault("NextToken")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "NextToken", valid_773722
  var valid_773723 = query.getOrDefault("MaxResults")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "MaxResults", valid_773723
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
  var valid_773724 = header.getOrDefault("X-Amz-Date")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Date", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Security-Token")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Security-Token", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Content-Sha256", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Algorithm")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Algorithm", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Signature")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Signature", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-SignedHeaders", valid_773729
  var valid_773730 = header.getOrDefault("x-amz-consistency-level")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773730 != nil:
    section.add "x-amz-consistency-level", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Credential")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Credential", valid_773731
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773732 = header.getOrDefault("x-amz-data-partition")
  valid_773732 = validateParameter(valid_773732, JString, required = true,
                                 default = nil)
  if valid_773732 != nil:
    section.add "x-amz-data-partition", valid_773732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773734: Call_ListAttachedIndices_773719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_773734.validator(path, query, header, formData, body)
  let scheme = call_773734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773734.url(scheme.get, call_773734.host, call_773734.base,
                         call_773734.route, valid.getOrDefault("path"))
  result = hook(call_773734, url, valid)

proc call*(call_773735: Call_ListAttachedIndices_773719; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773736 = newJObject()
  var body_773737 = newJObject()
  add(query_773736, "NextToken", newJString(NextToken))
  if body != nil:
    body_773737 = body
  add(query_773736, "MaxResults", newJString(MaxResults))
  result = call_773735.call(nil, query_773736, nil, nil, body_773737)

var listAttachedIndices* = Call_ListAttachedIndices_773719(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_773720, base: "/",
    url: url_ListAttachedIndices_773721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_773738 = ref object of OpenApiRestCall_772597
proc url_ListDevelopmentSchemaArns_773740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevelopmentSchemaArns_773739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773741 = query.getOrDefault("NextToken")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "NextToken", valid_773741
  var valid_773742 = query.getOrDefault("MaxResults")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "MaxResults", valid_773742
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
  var valid_773743 = header.getOrDefault("X-Amz-Date")
  valid_773743 = validateParameter(valid_773743, JString, required = false,
                                 default = nil)
  if valid_773743 != nil:
    section.add "X-Amz-Date", valid_773743
  var valid_773744 = header.getOrDefault("X-Amz-Security-Token")
  valid_773744 = validateParameter(valid_773744, JString, required = false,
                                 default = nil)
  if valid_773744 != nil:
    section.add "X-Amz-Security-Token", valid_773744
  var valid_773745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Content-Sha256", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Algorithm")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Algorithm", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Signature")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Signature", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-SignedHeaders", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Credential")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Credential", valid_773749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773751: Call_ListDevelopmentSchemaArns_773738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_773751.validator(path, query, header, formData, body)
  let scheme = call_773751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773751.url(scheme.get, call_773751.host, call_773751.base,
                         call_773751.route, valid.getOrDefault("path"))
  result = hook(call_773751, url, valid)

proc call*(call_773752: Call_ListDevelopmentSchemaArns_773738; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773753 = newJObject()
  var body_773754 = newJObject()
  add(query_773753, "NextToken", newJString(NextToken))
  if body != nil:
    body_773754 = body
  add(query_773753, "MaxResults", newJString(MaxResults))
  result = call_773752.call(nil, query_773753, nil, nil, body_773754)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_773738(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_773739, base: "/",
    url: url_ListDevelopmentSchemaArns_773740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_773755 = ref object of OpenApiRestCall_772597
proc url_ListDirectories_773757(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDirectories_773756(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_773758 = query.getOrDefault("NextToken")
  valid_773758 = validateParameter(valid_773758, JString, required = false,
                                 default = nil)
  if valid_773758 != nil:
    section.add "NextToken", valid_773758
  var valid_773759 = query.getOrDefault("MaxResults")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "MaxResults", valid_773759
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
  var valid_773760 = header.getOrDefault("X-Amz-Date")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Date", valid_773760
  var valid_773761 = header.getOrDefault("X-Amz-Security-Token")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Security-Token", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Content-Sha256", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Algorithm")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Algorithm", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Signature")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Signature", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-SignedHeaders", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Credential")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Credential", valid_773766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773768: Call_ListDirectories_773755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_773768.validator(path, query, header, formData, body)
  let scheme = call_773768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773768.url(scheme.get, call_773768.host, call_773768.base,
                         call_773768.route, valid.getOrDefault("path"))
  result = hook(call_773768, url, valid)

proc call*(call_773769: Call_ListDirectories_773755; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773770 = newJObject()
  var body_773771 = newJObject()
  add(query_773770, "NextToken", newJString(NextToken))
  if body != nil:
    body_773771 = body
  add(query_773770, "MaxResults", newJString(MaxResults))
  result = call_773769.call(nil, query_773770, nil, nil, body_773771)

var listDirectories* = Call_ListDirectories_773755(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_773756, base: "/", url: url_ListDirectories_773757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_773772 = ref object of OpenApiRestCall_772597
proc url_ListFacetAttributes_773774(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFacetAttributes_773773(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_773775 = query.getOrDefault("NextToken")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "NextToken", valid_773775
  var valid_773776 = query.getOrDefault("MaxResults")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "MaxResults", valid_773776
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
  var valid_773777 = header.getOrDefault("X-Amz-Date")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Date", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Security-Token")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Security-Token", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Content-Sha256", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Algorithm")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Algorithm", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-Signature")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Signature", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-SignedHeaders", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Credential")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Credential", valid_773783
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773784 = header.getOrDefault("x-amz-data-partition")
  valid_773784 = validateParameter(valid_773784, JString, required = true,
                                 default = nil)
  if valid_773784 != nil:
    section.add "x-amz-data-partition", valid_773784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773786: Call_ListFacetAttributes_773772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_773786.validator(path, query, header, formData, body)
  let scheme = call_773786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773786.url(scheme.get, call_773786.host, call_773786.base,
                         call_773786.route, valid.getOrDefault("path"))
  result = hook(call_773786, url, valid)

proc call*(call_773787: Call_ListFacetAttributes_773772; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773788 = newJObject()
  var body_773789 = newJObject()
  add(query_773788, "NextToken", newJString(NextToken))
  if body != nil:
    body_773789 = body
  add(query_773788, "MaxResults", newJString(MaxResults))
  result = call_773787.call(nil, query_773788, nil, nil, body_773789)

var listFacetAttributes* = Call_ListFacetAttributes_773772(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_773773, base: "/",
    url: url_ListFacetAttributes_773774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_773790 = ref object of OpenApiRestCall_772597
proc url_ListFacetNames_773792(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFacetNames_773791(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_773793 = query.getOrDefault("NextToken")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "NextToken", valid_773793
  var valid_773794 = query.getOrDefault("MaxResults")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "MaxResults", valid_773794
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
  var valid_773795 = header.getOrDefault("X-Amz-Date")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Date", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-Security-Token")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Security-Token", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Content-Sha256", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Algorithm")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Algorithm", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Signature")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Signature", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-SignedHeaders", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Credential")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Credential", valid_773801
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773802 = header.getOrDefault("x-amz-data-partition")
  valid_773802 = validateParameter(valid_773802, JString, required = true,
                                 default = nil)
  if valid_773802 != nil:
    section.add "x-amz-data-partition", valid_773802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773804: Call_ListFacetNames_773790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_773804.validator(path, query, header, formData, body)
  let scheme = call_773804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773804.url(scheme.get, call_773804.host, call_773804.base,
                         call_773804.route, valid.getOrDefault("path"))
  result = hook(call_773804, url, valid)

proc call*(call_773805: Call_ListFacetNames_773790; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773806 = newJObject()
  var body_773807 = newJObject()
  add(query_773806, "NextToken", newJString(NextToken))
  if body != nil:
    body_773807 = body
  add(query_773806, "MaxResults", newJString(MaxResults))
  result = call_773805.call(nil, query_773806, nil, nil, body_773807)

var listFacetNames* = Call_ListFacetNames_773790(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_773791, base: "/", url: url_ListFacetNames_773792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_773808 = ref object of OpenApiRestCall_772597
proc url_ListIncomingTypedLinks_773810(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIncomingTypedLinks_773809(path: JsonNode; query: JsonNode;
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
  var valid_773811 = header.getOrDefault("X-Amz-Date")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Date", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Security-Token")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Security-Token", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Content-Sha256", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-Algorithm")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-Algorithm", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Signature")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Signature", valid_773815
  var valid_773816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773816 = validateParameter(valid_773816, JString, required = false,
                                 default = nil)
  if valid_773816 != nil:
    section.add "X-Amz-SignedHeaders", valid_773816
  var valid_773817 = header.getOrDefault("X-Amz-Credential")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Credential", valid_773817
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773818 = header.getOrDefault("x-amz-data-partition")
  valid_773818 = validateParameter(valid_773818, JString, required = true,
                                 default = nil)
  if valid_773818 != nil:
    section.add "x-amz-data-partition", valid_773818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773820: Call_ListIncomingTypedLinks_773808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773820.validator(path, query, header, formData, body)
  let scheme = call_773820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773820.url(scheme.get, call_773820.host, call_773820.base,
                         call_773820.route, valid.getOrDefault("path"))
  result = hook(call_773820, url, valid)

proc call*(call_773821: Call_ListIncomingTypedLinks_773808; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773822 = newJObject()
  if body != nil:
    body_773822 = body
  result = call_773821.call(nil, nil, nil, nil, body_773822)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_773808(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_773809, base: "/",
    url: url_ListIncomingTypedLinks_773810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_773823 = ref object of OpenApiRestCall_772597
proc url_ListIndex_773825(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIndex_773824(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773826 = query.getOrDefault("NextToken")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "NextToken", valid_773826
  var valid_773827 = query.getOrDefault("MaxResults")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "MaxResults", valid_773827
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
  var valid_773828 = header.getOrDefault("X-Amz-Date")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Date", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-Security-Token")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-Security-Token", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Content-Sha256", valid_773830
  var valid_773831 = header.getOrDefault("X-Amz-Algorithm")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "X-Amz-Algorithm", valid_773831
  var valid_773832 = header.getOrDefault("X-Amz-Signature")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Signature", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-SignedHeaders", valid_773833
  var valid_773834 = header.getOrDefault("x-amz-consistency-level")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773834 != nil:
    section.add "x-amz-consistency-level", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Credential")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Credential", valid_773835
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773836 = header.getOrDefault("x-amz-data-partition")
  valid_773836 = validateParameter(valid_773836, JString, required = true,
                                 default = nil)
  if valid_773836 != nil:
    section.add "x-amz-data-partition", valid_773836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773838: Call_ListIndex_773823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_773838.validator(path, query, header, formData, body)
  let scheme = call_773838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773838.url(scheme.get, call_773838.host, call_773838.base,
                         call_773838.route, valid.getOrDefault("path"))
  result = hook(call_773838, url, valid)

proc call*(call_773839: Call_ListIndex_773823; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773840 = newJObject()
  var body_773841 = newJObject()
  add(query_773840, "NextToken", newJString(NextToken))
  if body != nil:
    body_773841 = body
  add(query_773840, "MaxResults", newJString(MaxResults))
  result = call_773839.call(nil, query_773840, nil, nil, body_773841)

var listIndex* = Call_ListIndex_773823(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_773824,
                                    base: "/", url: url_ListIndex_773825,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_773842 = ref object of OpenApiRestCall_772597
proc url_ListObjectAttributes_773844(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectAttributes_773843(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773845 = query.getOrDefault("NextToken")
  valid_773845 = validateParameter(valid_773845, JString, required = false,
                                 default = nil)
  if valid_773845 != nil:
    section.add "NextToken", valid_773845
  var valid_773846 = query.getOrDefault("MaxResults")
  valid_773846 = validateParameter(valid_773846, JString, required = false,
                                 default = nil)
  if valid_773846 != nil:
    section.add "MaxResults", valid_773846
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
  var valid_773847 = header.getOrDefault("X-Amz-Date")
  valid_773847 = validateParameter(valid_773847, JString, required = false,
                                 default = nil)
  if valid_773847 != nil:
    section.add "X-Amz-Date", valid_773847
  var valid_773848 = header.getOrDefault("X-Amz-Security-Token")
  valid_773848 = validateParameter(valid_773848, JString, required = false,
                                 default = nil)
  if valid_773848 != nil:
    section.add "X-Amz-Security-Token", valid_773848
  var valid_773849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773849 = validateParameter(valid_773849, JString, required = false,
                                 default = nil)
  if valid_773849 != nil:
    section.add "X-Amz-Content-Sha256", valid_773849
  var valid_773850 = header.getOrDefault("X-Amz-Algorithm")
  valid_773850 = validateParameter(valid_773850, JString, required = false,
                                 default = nil)
  if valid_773850 != nil:
    section.add "X-Amz-Algorithm", valid_773850
  var valid_773851 = header.getOrDefault("X-Amz-Signature")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Signature", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-SignedHeaders", valid_773852
  var valid_773853 = header.getOrDefault("x-amz-consistency-level")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773853 != nil:
    section.add "x-amz-consistency-level", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Credential")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Credential", valid_773854
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773855 = header.getOrDefault("x-amz-data-partition")
  valid_773855 = validateParameter(valid_773855, JString, required = true,
                                 default = nil)
  if valid_773855 != nil:
    section.add "x-amz-data-partition", valid_773855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773857: Call_ListObjectAttributes_773842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_773857.validator(path, query, header, formData, body)
  let scheme = call_773857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773857.url(scheme.get, call_773857.host, call_773857.base,
                         call_773857.route, valid.getOrDefault("path"))
  result = hook(call_773857, url, valid)

proc call*(call_773858: Call_ListObjectAttributes_773842; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773859 = newJObject()
  var body_773860 = newJObject()
  add(query_773859, "NextToken", newJString(NextToken))
  if body != nil:
    body_773860 = body
  add(query_773859, "MaxResults", newJString(MaxResults))
  result = call_773858.call(nil, query_773859, nil, nil, body_773860)

var listObjectAttributes* = Call_ListObjectAttributes_773842(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_773843, base: "/",
    url: url_ListObjectAttributes_773844, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_773861 = ref object of OpenApiRestCall_772597
proc url_ListObjectChildren_773863(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectChildren_773862(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_773864 = query.getOrDefault("NextToken")
  valid_773864 = validateParameter(valid_773864, JString, required = false,
                                 default = nil)
  if valid_773864 != nil:
    section.add "NextToken", valid_773864
  var valid_773865 = query.getOrDefault("MaxResults")
  valid_773865 = validateParameter(valid_773865, JString, required = false,
                                 default = nil)
  if valid_773865 != nil:
    section.add "MaxResults", valid_773865
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
  var valid_773866 = header.getOrDefault("X-Amz-Date")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Date", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-Security-Token")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Security-Token", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Content-Sha256", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Algorithm")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Algorithm", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Signature")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Signature", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-SignedHeaders", valid_773871
  var valid_773872 = header.getOrDefault("x-amz-consistency-level")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773872 != nil:
    section.add "x-amz-consistency-level", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Credential")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Credential", valid_773873
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773874 = header.getOrDefault("x-amz-data-partition")
  valid_773874 = validateParameter(valid_773874, JString, required = true,
                                 default = nil)
  if valid_773874 != nil:
    section.add "x-amz-data-partition", valid_773874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773876: Call_ListObjectChildren_773861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_773876.validator(path, query, header, formData, body)
  let scheme = call_773876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773876.url(scheme.get, call_773876.host, call_773876.base,
                         call_773876.route, valid.getOrDefault("path"))
  result = hook(call_773876, url, valid)

proc call*(call_773877: Call_ListObjectChildren_773861; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773878 = newJObject()
  var body_773879 = newJObject()
  add(query_773878, "NextToken", newJString(NextToken))
  if body != nil:
    body_773879 = body
  add(query_773878, "MaxResults", newJString(MaxResults))
  result = call_773877.call(nil, query_773878, nil, nil, body_773879)

var listObjectChildren* = Call_ListObjectChildren_773861(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_773862, base: "/",
    url: url_ListObjectChildren_773863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_773880 = ref object of OpenApiRestCall_772597
proc url_ListObjectParentPaths_773882(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectParentPaths_773881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
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
  var valid_773883 = query.getOrDefault("NextToken")
  valid_773883 = validateParameter(valid_773883, JString, required = false,
                                 default = nil)
  if valid_773883 != nil:
    section.add "NextToken", valid_773883
  var valid_773884 = query.getOrDefault("MaxResults")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "MaxResults", valid_773884
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
  var valid_773885 = header.getOrDefault("X-Amz-Date")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Date", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-Security-Token")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Security-Token", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Content-Sha256", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Algorithm")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Algorithm", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Signature")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Signature", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-SignedHeaders", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Credential")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Credential", valid_773891
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773892 = header.getOrDefault("x-amz-data-partition")
  valid_773892 = validateParameter(valid_773892, JString, required = true,
                                 default = nil)
  if valid_773892 != nil:
    section.add "x-amz-data-partition", valid_773892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773894: Call_ListObjectParentPaths_773880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_773894.validator(path, query, header, formData, body)
  let scheme = call_773894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773894.url(scheme.get, call_773894.host, call_773894.base,
                         call_773894.route, valid.getOrDefault("path"))
  result = hook(call_773894, url, valid)

proc call*(call_773895: Call_ListObjectParentPaths_773880; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773896 = newJObject()
  var body_773897 = newJObject()
  add(query_773896, "NextToken", newJString(NextToken))
  if body != nil:
    body_773897 = body
  add(query_773896, "MaxResults", newJString(MaxResults))
  result = call_773895.call(nil, query_773896, nil, nil, body_773897)

var listObjectParentPaths* = Call_ListObjectParentPaths_773880(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_773881, base: "/",
    url: url_ListObjectParentPaths_773882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_773898 = ref object of OpenApiRestCall_772597
proc url_ListObjectParents_773900(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectParents_773899(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_773901 = query.getOrDefault("NextToken")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "NextToken", valid_773901
  var valid_773902 = query.getOrDefault("MaxResults")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "MaxResults", valid_773902
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
  var valid_773903 = header.getOrDefault("X-Amz-Date")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Date", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Security-Token")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Security-Token", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Content-Sha256", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Algorithm")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Algorithm", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-Signature")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-Signature", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-SignedHeaders", valid_773908
  var valid_773909 = header.getOrDefault("x-amz-consistency-level")
  valid_773909 = validateParameter(valid_773909, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773909 != nil:
    section.add "x-amz-consistency-level", valid_773909
  var valid_773910 = header.getOrDefault("X-Amz-Credential")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Credential", valid_773910
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773911 = header.getOrDefault("x-amz-data-partition")
  valid_773911 = validateParameter(valid_773911, JString, required = true,
                                 default = nil)
  if valid_773911 != nil:
    section.add "x-amz-data-partition", valid_773911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773913: Call_ListObjectParents_773898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_773913.validator(path, query, header, formData, body)
  let scheme = call_773913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773913.url(scheme.get, call_773913.host, call_773913.base,
                         call_773913.route, valid.getOrDefault("path"))
  result = hook(call_773913, url, valid)

proc call*(call_773914: Call_ListObjectParents_773898; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773915 = newJObject()
  var body_773916 = newJObject()
  add(query_773915, "NextToken", newJString(NextToken))
  if body != nil:
    body_773916 = body
  add(query_773915, "MaxResults", newJString(MaxResults))
  result = call_773914.call(nil, query_773915, nil, nil, body_773916)

var listObjectParents* = Call_ListObjectParents_773898(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_773899, base: "/",
    url: url_ListObjectParents_773900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_773917 = ref object of OpenApiRestCall_772597
proc url_ListObjectPolicies_773919(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectPolicies_773918(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_773920 = query.getOrDefault("NextToken")
  valid_773920 = validateParameter(valid_773920, JString, required = false,
                                 default = nil)
  if valid_773920 != nil:
    section.add "NextToken", valid_773920
  var valid_773921 = query.getOrDefault("MaxResults")
  valid_773921 = validateParameter(valid_773921, JString, required = false,
                                 default = nil)
  if valid_773921 != nil:
    section.add "MaxResults", valid_773921
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
  var valid_773922 = header.getOrDefault("X-Amz-Date")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Date", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Security-Token")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Security-Token", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Content-Sha256", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-Algorithm")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Algorithm", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Signature")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Signature", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-SignedHeaders", valid_773927
  var valid_773928 = header.getOrDefault("x-amz-consistency-level")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773928 != nil:
    section.add "x-amz-consistency-level", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Credential")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Credential", valid_773929
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773930 = header.getOrDefault("x-amz-data-partition")
  valid_773930 = validateParameter(valid_773930, JString, required = true,
                                 default = nil)
  if valid_773930 != nil:
    section.add "x-amz-data-partition", valid_773930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773932: Call_ListObjectPolicies_773917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_773932.validator(path, query, header, formData, body)
  let scheme = call_773932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773932.url(scheme.get, call_773932.host, call_773932.base,
                         call_773932.route, valid.getOrDefault("path"))
  result = hook(call_773932, url, valid)

proc call*(call_773933: Call_ListObjectPolicies_773917; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773934 = newJObject()
  var body_773935 = newJObject()
  add(query_773934, "NextToken", newJString(NextToken))
  if body != nil:
    body_773935 = body
  add(query_773934, "MaxResults", newJString(MaxResults))
  result = call_773933.call(nil, query_773934, nil, nil, body_773935)

var listObjectPolicies* = Call_ListObjectPolicies_773917(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_773918, base: "/",
    url: url_ListObjectPolicies_773919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_773936 = ref object of OpenApiRestCall_772597
proc url_ListOutgoingTypedLinks_773938(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOutgoingTypedLinks_773937(path: JsonNode; query: JsonNode;
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
  var valid_773939 = header.getOrDefault("X-Amz-Date")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Date", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Security-Token")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Security-Token", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Content-Sha256", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-Algorithm")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-Algorithm", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Signature")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Signature", valid_773943
  var valid_773944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773944 = validateParameter(valid_773944, JString, required = false,
                                 default = nil)
  if valid_773944 != nil:
    section.add "X-Amz-SignedHeaders", valid_773944
  var valid_773945 = header.getOrDefault("X-Amz-Credential")
  valid_773945 = validateParameter(valid_773945, JString, required = false,
                                 default = nil)
  if valid_773945 != nil:
    section.add "X-Amz-Credential", valid_773945
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773946 = header.getOrDefault("x-amz-data-partition")
  valid_773946 = validateParameter(valid_773946, JString, required = true,
                                 default = nil)
  if valid_773946 != nil:
    section.add "x-amz-data-partition", valid_773946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773948: Call_ListOutgoingTypedLinks_773936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_773948.validator(path, query, header, formData, body)
  let scheme = call_773948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773948.url(scheme.get, call_773948.host, call_773948.base,
                         call_773948.route, valid.getOrDefault("path"))
  result = hook(call_773948, url, valid)

proc call*(call_773949: Call_ListOutgoingTypedLinks_773936; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_773950 = newJObject()
  if body != nil:
    body_773950 = body
  result = call_773949.call(nil, nil, nil, nil, body_773950)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_773936(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_773937, base: "/",
    url: url_ListOutgoingTypedLinks_773938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_773951 = ref object of OpenApiRestCall_772597
proc url_ListPolicyAttachments_773953(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPolicyAttachments_773952(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773954 = query.getOrDefault("NextToken")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "NextToken", valid_773954
  var valid_773955 = query.getOrDefault("MaxResults")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "MaxResults", valid_773955
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
  var valid_773956 = header.getOrDefault("X-Amz-Date")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Date", valid_773956
  var valid_773957 = header.getOrDefault("X-Amz-Security-Token")
  valid_773957 = validateParameter(valid_773957, JString, required = false,
                                 default = nil)
  if valid_773957 != nil:
    section.add "X-Amz-Security-Token", valid_773957
  var valid_773958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773958 = validateParameter(valid_773958, JString, required = false,
                                 default = nil)
  if valid_773958 != nil:
    section.add "X-Amz-Content-Sha256", valid_773958
  var valid_773959 = header.getOrDefault("X-Amz-Algorithm")
  valid_773959 = validateParameter(valid_773959, JString, required = false,
                                 default = nil)
  if valid_773959 != nil:
    section.add "X-Amz-Algorithm", valid_773959
  var valid_773960 = header.getOrDefault("X-Amz-Signature")
  valid_773960 = validateParameter(valid_773960, JString, required = false,
                                 default = nil)
  if valid_773960 != nil:
    section.add "X-Amz-Signature", valid_773960
  var valid_773961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773961 = validateParameter(valid_773961, JString, required = false,
                                 default = nil)
  if valid_773961 != nil:
    section.add "X-Amz-SignedHeaders", valid_773961
  var valid_773962 = header.getOrDefault("x-amz-consistency-level")
  valid_773962 = validateParameter(valid_773962, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_773962 != nil:
    section.add "x-amz-consistency-level", valid_773962
  var valid_773963 = header.getOrDefault("X-Amz-Credential")
  valid_773963 = validateParameter(valid_773963, JString, required = false,
                                 default = nil)
  if valid_773963 != nil:
    section.add "X-Amz-Credential", valid_773963
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_773964 = header.getOrDefault("x-amz-data-partition")
  valid_773964 = validateParameter(valid_773964, JString, required = true,
                                 default = nil)
  if valid_773964 != nil:
    section.add "x-amz-data-partition", valid_773964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773966: Call_ListPolicyAttachments_773951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_773966.validator(path, query, header, formData, body)
  let scheme = call_773966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773966.url(scheme.get, call_773966.host, call_773966.base,
                         call_773966.route, valid.getOrDefault("path"))
  result = hook(call_773966, url, valid)

proc call*(call_773967: Call_ListPolicyAttachments_773951; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773968 = newJObject()
  var body_773969 = newJObject()
  add(query_773968, "NextToken", newJString(NextToken))
  if body != nil:
    body_773969 = body
  add(query_773968, "MaxResults", newJString(MaxResults))
  result = call_773967.call(nil, query_773968, nil, nil, body_773969)

var listPolicyAttachments* = Call_ListPolicyAttachments_773951(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_773952, base: "/",
    url: url_ListPolicyAttachments_773953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_773970 = ref object of OpenApiRestCall_772597
proc url_ListPublishedSchemaArns_773972(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPublishedSchemaArns_773971(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_773973 = query.getOrDefault("NextToken")
  valid_773973 = validateParameter(valid_773973, JString, required = false,
                                 default = nil)
  if valid_773973 != nil:
    section.add "NextToken", valid_773973
  var valid_773974 = query.getOrDefault("MaxResults")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "MaxResults", valid_773974
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
  var valid_773975 = header.getOrDefault("X-Amz-Date")
  valid_773975 = validateParameter(valid_773975, JString, required = false,
                                 default = nil)
  if valid_773975 != nil:
    section.add "X-Amz-Date", valid_773975
  var valid_773976 = header.getOrDefault("X-Amz-Security-Token")
  valid_773976 = validateParameter(valid_773976, JString, required = false,
                                 default = nil)
  if valid_773976 != nil:
    section.add "X-Amz-Security-Token", valid_773976
  var valid_773977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773977 = validateParameter(valid_773977, JString, required = false,
                                 default = nil)
  if valid_773977 != nil:
    section.add "X-Amz-Content-Sha256", valid_773977
  var valid_773978 = header.getOrDefault("X-Amz-Algorithm")
  valid_773978 = validateParameter(valid_773978, JString, required = false,
                                 default = nil)
  if valid_773978 != nil:
    section.add "X-Amz-Algorithm", valid_773978
  var valid_773979 = header.getOrDefault("X-Amz-Signature")
  valid_773979 = validateParameter(valid_773979, JString, required = false,
                                 default = nil)
  if valid_773979 != nil:
    section.add "X-Amz-Signature", valid_773979
  var valid_773980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773980 = validateParameter(valid_773980, JString, required = false,
                                 default = nil)
  if valid_773980 != nil:
    section.add "X-Amz-SignedHeaders", valid_773980
  var valid_773981 = header.getOrDefault("X-Amz-Credential")
  valid_773981 = validateParameter(valid_773981, JString, required = false,
                                 default = nil)
  if valid_773981 != nil:
    section.add "X-Amz-Credential", valid_773981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773983: Call_ListPublishedSchemaArns_773970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_773983.validator(path, query, header, formData, body)
  let scheme = call_773983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773983.url(scheme.get, call_773983.host, call_773983.base,
                         call_773983.route, valid.getOrDefault("path"))
  result = hook(call_773983, url, valid)

proc call*(call_773984: Call_ListPublishedSchemaArns_773970; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773985 = newJObject()
  var body_773986 = newJObject()
  add(query_773985, "NextToken", newJString(NextToken))
  if body != nil:
    body_773986 = body
  add(query_773985, "MaxResults", newJString(MaxResults))
  result = call_773984.call(nil, query_773985, nil, nil, body_773986)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_773970(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_773971, base: "/",
    url: url_ListPublishedSchemaArns_773972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773987 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773989(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773988(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_773990 = query.getOrDefault("NextToken")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "NextToken", valid_773990
  var valid_773991 = query.getOrDefault("MaxResults")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "MaxResults", valid_773991
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
  var valid_773992 = header.getOrDefault("X-Amz-Date")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-Date", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Security-Token")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Security-Token", valid_773993
  var valid_773994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773994 = validateParameter(valid_773994, JString, required = false,
                                 default = nil)
  if valid_773994 != nil:
    section.add "X-Amz-Content-Sha256", valid_773994
  var valid_773995 = header.getOrDefault("X-Amz-Algorithm")
  valid_773995 = validateParameter(valid_773995, JString, required = false,
                                 default = nil)
  if valid_773995 != nil:
    section.add "X-Amz-Algorithm", valid_773995
  var valid_773996 = header.getOrDefault("X-Amz-Signature")
  valid_773996 = validateParameter(valid_773996, JString, required = false,
                                 default = nil)
  if valid_773996 != nil:
    section.add "X-Amz-Signature", valid_773996
  var valid_773997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773997 = validateParameter(valid_773997, JString, required = false,
                                 default = nil)
  if valid_773997 != nil:
    section.add "X-Amz-SignedHeaders", valid_773997
  var valid_773998 = header.getOrDefault("X-Amz-Credential")
  valid_773998 = validateParameter(valid_773998, JString, required = false,
                                 default = nil)
  if valid_773998 != nil:
    section.add "X-Amz-Credential", valid_773998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774000: Call_ListTagsForResource_773987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_774000.validator(path, query, header, formData, body)
  let scheme = call_774000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774000.url(scheme.get, call_774000.host, call_774000.base,
                         call_774000.route, valid.getOrDefault("path"))
  result = hook(call_774000, url, valid)

proc call*(call_774001: Call_ListTagsForResource_773987; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774002 = newJObject()
  var body_774003 = newJObject()
  add(query_774002, "NextToken", newJString(NextToken))
  if body != nil:
    body_774003 = body
  add(query_774002, "MaxResults", newJString(MaxResults))
  result = call_774001.call(nil, query_774002, nil, nil, body_774003)

var listTagsForResource* = Call_ListTagsForResource_773987(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_773988, base: "/",
    url: url_ListTagsForResource_773989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_774004 = ref object of OpenApiRestCall_772597
proc url_ListTypedLinkFacetAttributes_774006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTypedLinkFacetAttributes_774005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
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
  var valid_774007 = query.getOrDefault("NextToken")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "NextToken", valid_774007
  var valid_774008 = query.getOrDefault("MaxResults")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "MaxResults", valid_774008
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
  var valid_774009 = header.getOrDefault("X-Amz-Date")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "X-Amz-Date", valid_774009
  var valid_774010 = header.getOrDefault("X-Amz-Security-Token")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "X-Amz-Security-Token", valid_774010
  var valid_774011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774011 = validateParameter(valid_774011, JString, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "X-Amz-Content-Sha256", valid_774011
  var valid_774012 = header.getOrDefault("X-Amz-Algorithm")
  valid_774012 = validateParameter(valid_774012, JString, required = false,
                                 default = nil)
  if valid_774012 != nil:
    section.add "X-Amz-Algorithm", valid_774012
  var valid_774013 = header.getOrDefault("X-Amz-Signature")
  valid_774013 = validateParameter(valid_774013, JString, required = false,
                                 default = nil)
  if valid_774013 != nil:
    section.add "X-Amz-Signature", valid_774013
  var valid_774014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774014 = validateParameter(valid_774014, JString, required = false,
                                 default = nil)
  if valid_774014 != nil:
    section.add "X-Amz-SignedHeaders", valid_774014
  var valid_774015 = header.getOrDefault("X-Amz-Credential")
  valid_774015 = validateParameter(valid_774015, JString, required = false,
                                 default = nil)
  if valid_774015 != nil:
    section.add "X-Amz-Credential", valid_774015
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774016 = header.getOrDefault("x-amz-data-partition")
  valid_774016 = validateParameter(valid_774016, JString, required = true,
                                 default = nil)
  if valid_774016 != nil:
    section.add "x-amz-data-partition", valid_774016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774018: Call_ListTypedLinkFacetAttributes_774004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_774018.validator(path, query, header, formData, body)
  let scheme = call_774018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774018.url(scheme.get, call_774018.host, call_774018.base,
                         call_774018.route, valid.getOrDefault("path"))
  result = hook(call_774018, url, valid)

proc call*(call_774019: Call_ListTypedLinkFacetAttributes_774004; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774020 = newJObject()
  var body_774021 = newJObject()
  add(query_774020, "NextToken", newJString(NextToken))
  if body != nil:
    body_774021 = body
  add(query_774020, "MaxResults", newJString(MaxResults))
  result = call_774019.call(nil, query_774020, nil, nil, body_774021)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_774004(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_774005, base: "/",
    url: url_ListTypedLinkFacetAttributes_774006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_774022 = ref object of OpenApiRestCall_772597
proc url_ListTypedLinkFacetNames_774024(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTypedLinkFacetNames_774023(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
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
  var valid_774025 = query.getOrDefault("NextToken")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "NextToken", valid_774025
  var valid_774026 = query.getOrDefault("MaxResults")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "MaxResults", valid_774026
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
  var valid_774027 = header.getOrDefault("X-Amz-Date")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Date", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Security-Token")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Security-Token", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Content-Sha256", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-Algorithm")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-Algorithm", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Signature")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Signature", valid_774031
  var valid_774032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774032 = validateParameter(valid_774032, JString, required = false,
                                 default = nil)
  if valid_774032 != nil:
    section.add "X-Amz-SignedHeaders", valid_774032
  var valid_774033 = header.getOrDefault("X-Amz-Credential")
  valid_774033 = validateParameter(valid_774033, JString, required = false,
                                 default = nil)
  if valid_774033 != nil:
    section.add "X-Amz-Credential", valid_774033
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774034 = header.getOrDefault("x-amz-data-partition")
  valid_774034 = validateParameter(valid_774034, JString, required = true,
                                 default = nil)
  if valid_774034 != nil:
    section.add "x-amz-data-partition", valid_774034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774036: Call_ListTypedLinkFacetNames_774022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_774036.validator(path, query, header, formData, body)
  let scheme = call_774036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774036.url(scheme.get, call_774036.host, call_774036.base,
                         call_774036.route, valid.getOrDefault("path"))
  result = hook(call_774036, url, valid)

proc call*(call_774037: Call_ListTypedLinkFacetNames_774022; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774038 = newJObject()
  var body_774039 = newJObject()
  add(query_774038, "NextToken", newJString(NextToken))
  if body != nil:
    body_774039 = body
  add(query_774038, "MaxResults", newJString(MaxResults))
  result = call_774037.call(nil, query_774038, nil, nil, body_774039)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_774022(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_774023, base: "/",
    url: url_ListTypedLinkFacetNames_774024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_774040 = ref object of OpenApiRestCall_772597
proc url_LookupPolicy_774042(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LookupPolicy_774041(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
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
  var valid_774043 = query.getOrDefault("NextToken")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "NextToken", valid_774043
  var valid_774044 = query.getOrDefault("MaxResults")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "MaxResults", valid_774044
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
  var valid_774045 = header.getOrDefault("X-Amz-Date")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-Date", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Security-Token")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Security-Token", valid_774046
  var valid_774047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "X-Amz-Content-Sha256", valid_774047
  var valid_774048 = header.getOrDefault("X-Amz-Algorithm")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "X-Amz-Algorithm", valid_774048
  var valid_774049 = header.getOrDefault("X-Amz-Signature")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "X-Amz-Signature", valid_774049
  var valid_774050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774050 = validateParameter(valid_774050, JString, required = false,
                                 default = nil)
  if valid_774050 != nil:
    section.add "X-Amz-SignedHeaders", valid_774050
  var valid_774051 = header.getOrDefault("X-Amz-Credential")
  valid_774051 = validateParameter(valid_774051, JString, required = false,
                                 default = nil)
  if valid_774051 != nil:
    section.add "X-Amz-Credential", valid_774051
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774052 = header.getOrDefault("x-amz-data-partition")
  valid_774052 = validateParameter(valid_774052, JString, required = true,
                                 default = nil)
  if valid_774052 != nil:
    section.add "x-amz-data-partition", valid_774052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774054: Call_LookupPolicy_774040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ## 
  let valid = call_774054.validator(path, query, header, formData, body)
  let scheme = call_774054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774054.url(scheme.get, call_774054.host, call_774054.base,
                         call_774054.route, valid.getOrDefault("path"))
  result = hook(call_774054, url, valid)

proc call*(call_774055: Call_LookupPolicy_774040; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_774056 = newJObject()
  var body_774057 = newJObject()
  add(query_774056, "NextToken", newJString(NextToken))
  if body != nil:
    body_774057 = body
  add(query_774056, "MaxResults", newJString(MaxResults))
  result = call_774055.call(nil, query_774056, nil, nil, body_774057)

var lookupPolicy* = Call_LookupPolicy_774040(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_774041, base: "/", url: url_LookupPolicy_774042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_774058 = ref object of OpenApiRestCall_772597
proc url_PublishSchema_774060(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PublishSchema_774059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774061 = header.getOrDefault("X-Amz-Date")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "X-Amz-Date", valid_774061
  var valid_774062 = header.getOrDefault("X-Amz-Security-Token")
  valid_774062 = validateParameter(valid_774062, JString, required = false,
                                 default = nil)
  if valid_774062 != nil:
    section.add "X-Amz-Security-Token", valid_774062
  var valid_774063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "X-Amz-Content-Sha256", valid_774063
  var valid_774064 = header.getOrDefault("X-Amz-Algorithm")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Algorithm", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Signature")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Signature", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-SignedHeaders", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Credential")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Credential", valid_774067
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774068 = header.getOrDefault("x-amz-data-partition")
  valid_774068 = validateParameter(valid_774068, JString, required = true,
                                 default = nil)
  if valid_774068 != nil:
    section.add "x-amz-data-partition", valid_774068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774070: Call_PublishSchema_774058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_774070.validator(path, query, header, formData, body)
  let scheme = call_774070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774070.url(scheme.get, call_774070.host, call_774070.base,
                         call_774070.route, valid.getOrDefault("path"))
  result = hook(call_774070, url, valid)

proc call*(call_774071: Call_PublishSchema_774058; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_774072 = newJObject()
  if body != nil:
    body_774072 = body
  result = call_774071.call(nil, nil, nil, nil, body_774072)

var publishSchema* = Call_PublishSchema_774058(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_774059, base: "/", url: url_PublishSchema_774060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_774073 = ref object of OpenApiRestCall_772597
proc url_RemoveFacetFromObject_774075(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveFacetFromObject_774074(path: JsonNode; query: JsonNode;
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
  var valid_774076 = header.getOrDefault("X-Amz-Date")
  valid_774076 = validateParameter(valid_774076, JString, required = false,
                                 default = nil)
  if valid_774076 != nil:
    section.add "X-Amz-Date", valid_774076
  var valid_774077 = header.getOrDefault("X-Amz-Security-Token")
  valid_774077 = validateParameter(valid_774077, JString, required = false,
                                 default = nil)
  if valid_774077 != nil:
    section.add "X-Amz-Security-Token", valid_774077
  var valid_774078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Content-Sha256", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Algorithm")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Algorithm", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Signature")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Signature", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-SignedHeaders", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Credential")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Credential", valid_774082
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774083 = header.getOrDefault("x-amz-data-partition")
  valid_774083 = validateParameter(valid_774083, JString, required = true,
                                 default = nil)
  if valid_774083 != nil:
    section.add "x-amz-data-partition", valid_774083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774085: Call_RemoveFacetFromObject_774073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_774085.validator(path, query, header, formData, body)
  let scheme = call_774085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774085.url(scheme.get, call_774085.host, call_774085.base,
                         call_774085.route, valid.getOrDefault("path"))
  result = hook(call_774085, url, valid)

proc call*(call_774086: Call_RemoveFacetFromObject_774073; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_774087 = newJObject()
  if body != nil:
    body_774087 = body
  result = call_774086.call(nil, nil, nil, nil, body_774087)

var removeFacetFromObject* = Call_RemoveFacetFromObject_774073(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_774074, base: "/",
    url: url_RemoveFacetFromObject_774075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_774088 = ref object of OpenApiRestCall_772597
proc url_TagResource_774090(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_774089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774091 = header.getOrDefault("X-Amz-Date")
  valid_774091 = validateParameter(valid_774091, JString, required = false,
                                 default = nil)
  if valid_774091 != nil:
    section.add "X-Amz-Date", valid_774091
  var valid_774092 = header.getOrDefault("X-Amz-Security-Token")
  valid_774092 = validateParameter(valid_774092, JString, required = false,
                                 default = nil)
  if valid_774092 != nil:
    section.add "X-Amz-Security-Token", valid_774092
  var valid_774093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774093 = validateParameter(valid_774093, JString, required = false,
                                 default = nil)
  if valid_774093 != nil:
    section.add "X-Amz-Content-Sha256", valid_774093
  var valid_774094 = header.getOrDefault("X-Amz-Algorithm")
  valid_774094 = validateParameter(valid_774094, JString, required = false,
                                 default = nil)
  if valid_774094 != nil:
    section.add "X-Amz-Algorithm", valid_774094
  var valid_774095 = header.getOrDefault("X-Amz-Signature")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "X-Amz-Signature", valid_774095
  var valid_774096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774096 = validateParameter(valid_774096, JString, required = false,
                                 default = nil)
  if valid_774096 != nil:
    section.add "X-Amz-SignedHeaders", valid_774096
  var valid_774097 = header.getOrDefault("X-Amz-Credential")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "X-Amz-Credential", valid_774097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774099: Call_TagResource_774088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_774099.validator(path, query, header, formData, body)
  let scheme = call_774099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774099.url(scheme.get, call_774099.host, call_774099.base,
                         call_774099.route, valid.getOrDefault("path"))
  result = hook(call_774099, url, valid)

proc call*(call_774100: Call_TagResource_774088; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_774101 = newJObject()
  if body != nil:
    body_774101 = body
  result = call_774100.call(nil, nil, nil, nil, body_774101)

var tagResource* = Call_TagResource_774088(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_774089,
                                        base: "/", url: url_TagResource_774090,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_774102 = ref object of OpenApiRestCall_772597
proc url_UntagResource_774104(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_774103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774105 = header.getOrDefault("X-Amz-Date")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Date", valid_774105
  var valid_774106 = header.getOrDefault("X-Amz-Security-Token")
  valid_774106 = validateParameter(valid_774106, JString, required = false,
                                 default = nil)
  if valid_774106 != nil:
    section.add "X-Amz-Security-Token", valid_774106
  var valid_774107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774107 = validateParameter(valid_774107, JString, required = false,
                                 default = nil)
  if valid_774107 != nil:
    section.add "X-Amz-Content-Sha256", valid_774107
  var valid_774108 = header.getOrDefault("X-Amz-Algorithm")
  valid_774108 = validateParameter(valid_774108, JString, required = false,
                                 default = nil)
  if valid_774108 != nil:
    section.add "X-Amz-Algorithm", valid_774108
  var valid_774109 = header.getOrDefault("X-Amz-Signature")
  valid_774109 = validateParameter(valid_774109, JString, required = false,
                                 default = nil)
  if valid_774109 != nil:
    section.add "X-Amz-Signature", valid_774109
  var valid_774110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774110 = validateParameter(valid_774110, JString, required = false,
                                 default = nil)
  if valid_774110 != nil:
    section.add "X-Amz-SignedHeaders", valid_774110
  var valid_774111 = header.getOrDefault("X-Amz-Credential")
  valid_774111 = validateParameter(valid_774111, JString, required = false,
                                 default = nil)
  if valid_774111 != nil:
    section.add "X-Amz-Credential", valid_774111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774113: Call_UntagResource_774102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_774113.validator(path, query, header, formData, body)
  let scheme = call_774113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774113.url(scheme.get, call_774113.host, call_774113.base,
                         call_774113.route, valid.getOrDefault("path"))
  result = hook(call_774113, url, valid)

proc call*(call_774114: Call_UntagResource_774102; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_774115 = newJObject()
  if body != nil:
    body_774115 = body
  result = call_774114.call(nil, nil, nil, nil, body_774115)

var untagResource* = Call_UntagResource_774102(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_774103, base: "/", url: url_UntagResource_774104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_774116 = ref object of OpenApiRestCall_772597
proc url_UpdateLinkAttributes_774118(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateLinkAttributes_774117(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-data-partition: JString (required)
  ##                       : The Amazon Resource Name (ARN) that is associated with the Directory where the updated typed link resides. For more information, see <a>arns</a> or <a 
  ## href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  section = newJObject()
  var valid_774119 = header.getOrDefault("X-Amz-Date")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-Date", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Security-Token")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Security-Token", valid_774120
  var valid_774121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "X-Amz-Content-Sha256", valid_774121
  var valid_774122 = header.getOrDefault("X-Amz-Algorithm")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "X-Amz-Algorithm", valid_774122
  var valid_774123 = header.getOrDefault("X-Amz-Signature")
  valid_774123 = validateParameter(valid_774123, JString, required = false,
                                 default = nil)
  if valid_774123 != nil:
    section.add "X-Amz-Signature", valid_774123
  var valid_774124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774124 = validateParameter(valid_774124, JString, required = false,
                                 default = nil)
  if valid_774124 != nil:
    section.add "X-Amz-SignedHeaders", valid_774124
  var valid_774125 = header.getOrDefault("X-Amz-Credential")
  valid_774125 = validateParameter(valid_774125, JString, required = false,
                                 default = nil)
  if valid_774125 != nil:
    section.add "X-Amz-Credential", valid_774125
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774126 = header.getOrDefault("x-amz-data-partition")
  valid_774126 = validateParameter(valid_774126, JString, required = true,
                                 default = nil)
  if valid_774126 != nil:
    section.add "x-amz-data-partition", valid_774126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774128: Call_UpdateLinkAttributes_774116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_774128.validator(path, query, header, formData, body)
  let scheme = call_774128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774128.url(scheme.get, call_774128.host, call_774128.base,
                         call_774128.route, valid.getOrDefault("path"))
  result = hook(call_774128, url, valid)

proc call*(call_774129: Call_UpdateLinkAttributes_774116; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_774130 = newJObject()
  if body != nil:
    body_774130 = body
  result = call_774129.call(nil, nil, nil, nil, body_774130)

var updateLinkAttributes* = Call_UpdateLinkAttributes_774116(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_774117, base: "/",
    url: url_UpdateLinkAttributes_774118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_774131 = ref object of OpenApiRestCall_772597
proc url_UpdateObjectAttributes_774133(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateObjectAttributes_774132(path: JsonNode; query: JsonNode;
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
  var valid_774134 = header.getOrDefault("X-Amz-Date")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "X-Amz-Date", valid_774134
  var valid_774135 = header.getOrDefault("X-Amz-Security-Token")
  valid_774135 = validateParameter(valid_774135, JString, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "X-Amz-Security-Token", valid_774135
  var valid_774136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774136 = validateParameter(valid_774136, JString, required = false,
                                 default = nil)
  if valid_774136 != nil:
    section.add "X-Amz-Content-Sha256", valid_774136
  var valid_774137 = header.getOrDefault("X-Amz-Algorithm")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "X-Amz-Algorithm", valid_774137
  var valid_774138 = header.getOrDefault("X-Amz-Signature")
  valid_774138 = validateParameter(valid_774138, JString, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "X-Amz-Signature", valid_774138
  var valid_774139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774139 = validateParameter(valid_774139, JString, required = false,
                                 default = nil)
  if valid_774139 != nil:
    section.add "X-Amz-SignedHeaders", valid_774139
  var valid_774140 = header.getOrDefault("X-Amz-Credential")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Credential", valid_774140
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774141 = header.getOrDefault("x-amz-data-partition")
  valid_774141 = validateParameter(valid_774141, JString, required = true,
                                 default = nil)
  if valid_774141 != nil:
    section.add "x-amz-data-partition", valid_774141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774143: Call_UpdateObjectAttributes_774131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_774143.validator(path, query, header, formData, body)
  let scheme = call_774143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774143.url(scheme.get, call_774143.host, call_774143.base,
                         call_774143.route, valid.getOrDefault("path"))
  result = hook(call_774143, url, valid)

proc call*(call_774144: Call_UpdateObjectAttributes_774131; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_774145 = newJObject()
  if body != nil:
    body_774145 = body
  result = call_774144.call(nil, nil, nil, nil, body_774145)

var updateObjectAttributes* = Call_UpdateObjectAttributes_774131(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_774132, base: "/",
    url: url_UpdateObjectAttributes_774133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_774146 = ref object of OpenApiRestCall_772597
proc url_UpdateSchema_774148(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSchema_774147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_774149 = header.getOrDefault("X-Amz-Date")
  valid_774149 = validateParameter(valid_774149, JString, required = false,
                                 default = nil)
  if valid_774149 != nil:
    section.add "X-Amz-Date", valid_774149
  var valid_774150 = header.getOrDefault("X-Amz-Security-Token")
  valid_774150 = validateParameter(valid_774150, JString, required = false,
                                 default = nil)
  if valid_774150 != nil:
    section.add "X-Amz-Security-Token", valid_774150
  var valid_774151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774151 = validateParameter(valid_774151, JString, required = false,
                                 default = nil)
  if valid_774151 != nil:
    section.add "X-Amz-Content-Sha256", valid_774151
  var valid_774152 = header.getOrDefault("X-Amz-Algorithm")
  valid_774152 = validateParameter(valid_774152, JString, required = false,
                                 default = nil)
  if valid_774152 != nil:
    section.add "X-Amz-Algorithm", valid_774152
  var valid_774153 = header.getOrDefault("X-Amz-Signature")
  valid_774153 = validateParameter(valid_774153, JString, required = false,
                                 default = nil)
  if valid_774153 != nil:
    section.add "X-Amz-Signature", valid_774153
  var valid_774154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774154 = validateParameter(valid_774154, JString, required = false,
                                 default = nil)
  if valid_774154 != nil:
    section.add "X-Amz-SignedHeaders", valid_774154
  var valid_774155 = header.getOrDefault("X-Amz-Credential")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Credential", valid_774155
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774156 = header.getOrDefault("x-amz-data-partition")
  valid_774156 = validateParameter(valid_774156, JString, required = true,
                                 default = nil)
  if valid_774156 != nil:
    section.add "x-amz-data-partition", valid_774156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774158: Call_UpdateSchema_774146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_774158.validator(path, query, header, formData, body)
  let scheme = call_774158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774158.url(scheme.get, call_774158.host, call_774158.base,
                         call_774158.route, valid.getOrDefault("path"))
  result = hook(call_774158, url, valid)

proc call*(call_774159: Call_UpdateSchema_774146; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_774160 = newJObject()
  if body != nil:
    body_774160 = body
  result = call_774159.call(nil, nil, nil, nil, body_774160)

var updateSchema* = Call_UpdateSchema_774146(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_774147, base: "/", url: url_UpdateSchema_774148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_774161 = ref object of OpenApiRestCall_772597
proc url_UpdateTypedLinkFacet_774163(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTypedLinkFacet_774162(path: JsonNode; query: JsonNode;
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
  var valid_774164 = header.getOrDefault("X-Amz-Date")
  valid_774164 = validateParameter(valid_774164, JString, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "X-Amz-Date", valid_774164
  var valid_774165 = header.getOrDefault("X-Amz-Security-Token")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "X-Amz-Security-Token", valid_774165
  var valid_774166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "X-Amz-Content-Sha256", valid_774166
  var valid_774167 = header.getOrDefault("X-Amz-Algorithm")
  valid_774167 = validateParameter(valid_774167, JString, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "X-Amz-Algorithm", valid_774167
  var valid_774168 = header.getOrDefault("X-Amz-Signature")
  valid_774168 = validateParameter(valid_774168, JString, required = false,
                                 default = nil)
  if valid_774168 != nil:
    section.add "X-Amz-Signature", valid_774168
  var valid_774169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774169 = validateParameter(valid_774169, JString, required = false,
                                 default = nil)
  if valid_774169 != nil:
    section.add "X-Amz-SignedHeaders", valid_774169
  var valid_774170 = header.getOrDefault("X-Amz-Credential")
  valid_774170 = validateParameter(valid_774170, JString, required = false,
                                 default = nil)
  if valid_774170 != nil:
    section.add "X-Amz-Credential", valid_774170
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_774171 = header.getOrDefault("x-amz-data-partition")
  valid_774171 = validateParameter(valid_774171, JString, required = true,
                                 default = nil)
  if valid_774171 != nil:
    section.add "x-amz-data-partition", valid_774171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774173: Call_UpdateTypedLinkFacet_774161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_774173.validator(path, query, header, formData, body)
  let scheme = call_774173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774173.url(scheme.get, call_774173.host, call_774173.base,
                         call_774173.route, valid.getOrDefault("path"))
  result = hook(call_774173, url, valid)

proc call*(call_774174: Call_UpdateTypedLinkFacet_774161; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_774175 = newJObject()
  if body != nil:
    body_774175 = body
  result = call_774174.call(nil, nil, nil, nil, body_774175)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_774161(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_774162, base: "/",
    url: url_UpdateTypedLinkFacet_774163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_774176 = ref object of OpenApiRestCall_772597
proc url_UpgradeAppliedSchema_774178(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradeAppliedSchema_774177(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774179 = header.getOrDefault("X-Amz-Date")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "X-Amz-Date", valid_774179
  var valid_774180 = header.getOrDefault("X-Amz-Security-Token")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "X-Amz-Security-Token", valid_774180
  var valid_774181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "X-Amz-Content-Sha256", valid_774181
  var valid_774182 = header.getOrDefault("X-Amz-Algorithm")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "X-Amz-Algorithm", valid_774182
  var valid_774183 = header.getOrDefault("X-Amz-Signature")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "X-Amz-Signature", valid_774183
  var valid_774184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774184 = validateParameter(valid_774184, JString, required = false,
                                 default = nil)
  if valid_774184 != nil:
    section.add "X-Amz-SignedHeaders", valid_774184
  var valid_774185 = header.getOrDefault("X-Amz-Credential")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "X-Amz-Credential", valid_774185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774187: Call_UpgradeAppliedSchema_774176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_774187.validator(path, query, header, formData, body)
  let scheme = call_774187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774187.url(scheme.get, call_774187.host, call_774187.base,
                         call_774187.route, valid.getOrDefault("path"))
  result = hook(call_774187, url, valid)

proc call*(call_774188: Call_UpgradeAppliedSchema_774176; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_774189 = newJObject()
  if body != nil:
    body_774189 = body
  result = call_774188.call(nil, nil, nil, nil, body_774189)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_774176(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_774177, base: "/",
    url: url_UpgradeAppliedSchema_774178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_774190 = ref object of OpenApiRestCall_772597
proc url_UpgradePublishedSchema_774192(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradePublishedSchema_774191(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774193 = header.getOrDefault("X-Amz-Date")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Date", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Security-Token")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Security-Token", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Content-Sha256", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-Algorithm")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-Algorithm", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Signature")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Signature", valid_774197
  var valid_774198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774198 = validateParameter(valid_774198, JString, required = false,
                                 default = nil)
  if valid_774198 != nil:
    section.add "X-Amz-SignedHeaders", valid_774198
  var valid_774199 = header.getOrDefault("X-Amz-Credential")
  valid_774199 = validateParameter(valid_774199, JString, required = false,
                                 default = nil)
  if valid_774199 != nil:
    section.add "X-Amz-Credential", valid_774199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_774201: Call_UpgradePublishedSchema_774190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_774201.validator(path, query, header, formData, body)
  let scheme = call_774201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774201.url(scheme.get, call_774201.host, call_774201.base,
                         call_774201.route, valid.getOrDefault("path"))
  result = hook(call_774201, url, valid)

proc call*(call_774202: Call_UpgradePublishedSchema_774190; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_774203 = newJObject()
  if body != nil:
    body_774203 = body
  result = call_774202.call(nil, nil, nil, nil, body_774203)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_774190(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_774191, base: "/",
    url: url_UpgradePublishedSchema_774192, schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
