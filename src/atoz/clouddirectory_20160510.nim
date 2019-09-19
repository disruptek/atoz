
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  Call_AddFacetToObject_600768 = ref object of OpenApiRestCall_600426
proc url_AddFacetToObject_600770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddFacetToObject_600769(path: JsonNode; query: JsonNode;
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600889 = header.getOrDefault("x-amz-data-partition")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = nil)
  if valid_600889 != nil:
    section.add "x-amz-data-partition", valid_600889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_AddFacetToObject_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"))
  result = hook(call_600913, url, valid)

proc call*(call_600984: Call_AddFacetToObject_600768; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_600985 = newJObject()
  if body != nil:
    body_600985 = body
  result = call_600984.call(nil, nil, nil, nil, body_600985)

var addFacetToObject* = Call_AddFacetToObject_600768(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_600769, base: "/",
    url: url_AddFacetToObject_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_601024 = ref object of OpenApiRestCall_600426
proc url_ApplySchema_601026(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApplySchema_601025(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601027 = header.getOrDefault("X-Amz-Date")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Date", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Security-Token")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Security-Token", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Content-Sha256", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Algorithm")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Algorithm", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Signature")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Signature", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-SignedHeaders", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Credential")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Credential", valid_601033
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601034 = header.getOrDefault("x-amz-data-partition")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "x-amz-data-partition", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_ApplySchema_601024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"))
  result = hook(call_601036, url, valid)

proc call*(call_601037: Call_ApplySchema_601024; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var applySchema* = Call_ApplySchema_601024(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_601025,
                                        base: "/", url: url_ApplySchema_601026,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_601039 = ref object of OpenApiRestCall_600426
proc url_AttachObject_601041(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachObject_601040(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601042 = header.getOrDefault("X-Amz-Date")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Date", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Security-Token")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Security-Token", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Content-Sha256", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Algorithm")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Algorithm", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Signature", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-SignedHeaders", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Credential")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Credential", valid_601048
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601049 = header.getOrDefault("x-amz-data-partition")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = nil)
  if valid_601049 != nil:
    section.add "x-amz-data-partition", valid_601049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_AttachObject_601039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"))
  result = hook(call_601051, url, valid)

proc call*(call_601052: Call_AttachObject_601039; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_601053 = newJObject()
  if body != nil:
    body_601053 = body
  result = call_601052.call(nil, nil, nil, nil, body_601053)

var attachObject* = Call_AttachObject_601039(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_601040, base: "/", url: url_AttachObject_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_601054 = ref object of OpenApiRestCall_600426
proc url_AttachPolicy_601056(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachPolicy_601055(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Content-Sha256", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Algorithm")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Algorithm", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Signature")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Signature", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-SignedHeaders", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Credential")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Credential", valid_601063
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601064 = header.getOrDefault("x-amz-data-partition")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "x-amz-data-partition", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_AttachPolicy_601054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_AttachPolicy_601054; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_601068 = newJObject()
  if body != nil:
    body_601068 = body
  result = call_601067.call(nil, nil, nil, nil, body_601068)

var attachPolicy* = Call_AttachPolicy_601054(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_601055, base: "/", url: url_AttachPolicy_601056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_601069 = ref object of OpenApiRestCall_600426
proc url_AttachToIndex_601071(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachToIndex_601070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601072 = header.getOrDefault("X-Amz-Date")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Date", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Security-Token")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Security-Token", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Content-Sha256", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Algorithm")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Algorithm", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Signature")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Signature", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-SignedHeaders", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Credential")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Credential", valid_601078
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601079 = header.getOrDefault("x-amz-data-partition")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = nil)
  if valid_601079 != nil:
    section.add "x-amz-data-partition", valid_601079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601081: Call_AttachToIndex_601069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_601081.validator(path, query, header, formData, body)
  let scheme = call_601081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601081.url(scheme.get, call_601081.host, call_601081.base,
                         call_601081.route, valid.getOrDefault("path"))
  result = hook(call_601081, url, valid)

proc call*(call_601082: Call_AttachToIndex_601069; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_601083 = newJObject()
  if body != nil:
    body_601083 = body
  result = call_601082.call(nil, nil, nil, nil, body_601083)

var attachToIndex* = Call_AttachToIndex_601069(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_601070, base: "/", url: url_AttachToIndex_601071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_601084 = ref object of OpenApiRestCall_600426
proc url_AttachTypedLink_601086(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AttachTypedLink_601085(path: JsonNode; query: JsonNode;
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601094 = header.getOrDefault("x-amz-data-partition")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = nil)
  if valid_601094 != nil:
    section.add "x-amz-data-partition", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_AttachTypedLink_601084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"))
  result = hook(call_601096, url, valid)

proc call*(call_601097: Call_AttachTypedLink_601084; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601098 = newJObject()
  if body != nil:
    body_601098 = body
  result = call_601097.call(nil, nil, nil, nil, body_601098)

var attachTypedLink* = Call_AttachTypedLink_601084(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_601085, base: "/", url: url_AttachTypedLink_601086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_601099 = ref object of OpenApiRestCall_600426
proc url_BatchRead_601101(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchRead_601100(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601121 = header.getOrDefault("x-amz-consistency-level")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601121 != nil:
    section.add "x-amz-consistency-level", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601123 = header.getOrDefault("x-amz-data-partition")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "x-amz-data-partition", valid_601123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601125: Call_BatchRead_601099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_601125.validator(path, query, header, formData, body)
  let scheme = call_601125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601125.url(scheme.get, call_601125.host, call_601125.base,
                         call_601125.route, valid.getOrDefault("path"))
  result = hook(call_601125, url, valid)

proc call*(call_601126: Call_BatchRead_601099; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_601127 = newJObject()
  if body != nil:
    body_601127 = body
  result = call_601126.call(nil, nil, nil, nil, body_601127)

var batchRead* = Call_BatchRead_601099(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_601100,
                                    base: "/", url: url_BatchRead_601101,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_601128 = ref object of OpenApiRestCall_600426
proc url_BatchWrite_601130(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchWrite_601129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601131 = header.getOrDefault("X-Amz-Date")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Date", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Security-Token")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Security-Token", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601138 = header.getOrDefault("x-amz-data-partition")
  valid_601138 = validateParameter(valid_601138, JString, required = true,
                                 default = nil)
  if valid_601138 != nil:
    section.add "x-amz-data-partition", valid_601138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_BatchWrite_601128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"))
  result = hook(call_601140, url, valid)

proc call*(call_601141: Call_BatchWrite_601128; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_601142 = newJObject()
  if body != nil:
    body_601142 = body
  result = call_601141.call(nil, nil, nil, nil, body_601142)

var batchWrite* = Call_BatchWrite_601128(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_601129,
                                      base: "/", url: url_BatchWrite_601130,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_601143 = ref object of OpenApiRestCall_600426
proc url_CreateDirectory_601145(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDirectory_601144(path: JsonNode; query: JsonNode;
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
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601153 = header.getOrDefault("x-amz-data-partition")
  valid_601153 = validateParameter(valid_601153, JString, required = true,
                                 default = nil)
  if valid_601153 != nil:
    section.add "x-amz-data-partition", valid_601153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601155: Call_CreateDirectory_601143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  let valid = call_601155.validator(path, query, header, formData, body)
  let scheme = call_601155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601155.url(scheme.get, call_601155.host, call_601155.base,
                         call_601155.route, valid.getOrDefault("path"))
  result = hook(call_601155, url, valid)

proc call*(call_601156: Call_CreateDirectory_601143; body: JsonNode): Recallable =
  ## createDirectory
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ##   body: JObject (required)
  var body_601157 = newJObject()
  if body != nil:
    body_601157 = body
  result = call_601156.call(nil, nil, nil, nil, body_601157)

var createDirectory* = Call_CreateDirectory_601143(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_601144, base: "/", url: url_CreateDirectory_601145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_601158 = ref object of OpenApiRestCall_600426
proc url_CreateFacet_601160(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFacet_601159(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601161 = header.getOrDefault("X-Amz-Date")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Date", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Security-Token")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Security-Token", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601168 = header.getOrDefault("x-amz-data-partition")
  valid_601168 = validateParameter(valid_601168, JString, required = true,
                                 default = nil)
  if valid_601168 != nil:
    section.add "x-amz-data-partition", valid_601168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601170: Call_CreateFacet_601158; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_601170.validator(path, query, header, formData, body)
  let scheme = call_601170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601170.url(scheme.get, call_601170.host, call_601170.base,
                         call_601170.route, valid.getOrDefault("path"))
  result = hook(call_601170, url, valid)

proc call*(call_601171: Call_CreateFacet_601158; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_601172 = newJObject()
  if body != nil:
    body_601172 = body
  result = call_601171.call(nil, nil, nil, nil, body_601172)

var createFacet* = Call_CreateFacet_601158(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_601159,
                                        base: "/", url: url_CreateFacet_601160,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_601173 = ref object of OpenApiRestCall_600426
proc url_CreateIndex_601175(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateIndex_601174(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601176 = header.getOrDefault("X-Amz-Date")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Date", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Security-Token")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Security-Token", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601183 = header.getOrDefault("x-amz-data-partition")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "x-amz-data-partition", valid_601183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601185: Call_CreateIndex_601173; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  let valid = call_601185.validator(path, query, header, formData, body)
  let scheme = call_601185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601185.url(scheme.get, call_601185.host, call_601185.base,
                         call_601185.route, valid.getOrDefault("path"))
  result = hook(call_601185, url, valid)

proc call*(call_601186: Call_CreateIndex_601173; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ##   body: JObject (required)
  var body_601187 = newJObject()
  if body != nil:
    body_601187 = body
  result = call_601186.call(nil, nil, nil, nil, body_601187)

var createIndex* = Call_CreateIndex_601173(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_601174,
                                        base: "/", url: url_CreateIndex_601175,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_601188 = ref object of OpenApiRestCall_600426
proc url_CreateObject_601190(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateObject_601189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601191 = header.getOrDefault("X-Amz-Date")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Date", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Security-Token")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Security-Token", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601198 = header.getOrDefault("x-amz-data-partition")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = nil)
  if valid_601198 != nil:
    section.add "x-amz-data-partition", valid_601198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601200: Call_CreateObject_601188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_601200.validator(path, query, header, formData, body)
  let scheme = call_601200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601200.url(scheme.get, call_601200.host, call_601200.base,
                         call_601200.route, valid.getOrDefault("path"))
  result = hook(call_601200, url, valid)

proc call*(call_601201: Call_CreateObject_601188; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_601202 = newJObject()
  if body != nil:
    body_601202 = body
  result = call_601201.call(nil, nil, nil, nil, body_601202)

var createObject* = Call_CreateObject_601188(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_601189, base: "/", url: url_CreateObject_601190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_601203 = ref object of OpenApiRestCall_600426
proc url_CreateSchema_601205(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSchema_601204(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601206 = header.getOrDefault("X-Amz-Date")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Date", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Security-Token")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Security-Token", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_CreateSchema_601203; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_CreateSchema_601203; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var createSchema* = Call_CreateSchema_601203(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_601204, base: "/", url: url_CreateSchema_601205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_601217 = ref object of OpenApiRestCall_600426
proc url_CreateTypedLinkFacet_601219(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTypedLinkFacet_601218(path: JsonNode; query: JsonNode;
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
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Content-Sha256", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Algorithm")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Algorithm", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Signature")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Signature", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-SignedHeaders", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Credential")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Credential", valid_601226
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601227 = header.getOrDefault("x-amz-data-partition")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "x-amz-data-partition", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_CreateTypedLinkFacet_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_CreateTypedLinkFacet_601217; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_601217(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_601218, base: "/",
    url: url_CreateTypedLinkFacet_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_601232 = ref object of OpenApiRestCall_600426
proc url_DeleteDirectory_601234(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDirectory_601233(path: JsonNode; query: JsonNode;
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
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Content-Sha256", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Algorithm")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Algorithm", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Signature")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Signature", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-SignedHeaders", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Credential")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Credential", valid_601241
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601242 = header.getOrDefault("x-amz-data-partition")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = nil)
  if valid_601242 != nil:
    section.add "x-amz-data-partition", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601243: Call_DeleteDirectory_601232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_601243.validator(path, query, header, formData, body)
  let scheme = call_601243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601243.url(scheme.get, call_601243.host, call_601243.base,
                         call_601243.route, valid.getOrDefault("path"))
  result = hook(call_601243, url, valid)

proc call*(call_601244: Call_DeleteDirectory_601232): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_601244.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_601232(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_601233, base: "/", url: url_DeleteDirectory_601234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_601245 = ref object of OpenApiRestCall_600426
proc url_DeleteFacet_601247(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFacet_601246(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601248 = header.getOrDefault("X-Amz-Date")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Date", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Security-Token")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Security-Token", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Content-Sha256", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Algorithm")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Algorithm", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Signature")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Signature", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-SignedHeaders", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Credential")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Credential", valid_601254
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601255 = header.getOrDefault("x-amz-data-partition")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = nil)
  if valid_601255 != nil:
    section.add "x-amz-data-partition", valid_601255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601257: Call_DeleteFacet_601245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_601257.validator(path, query, header, formData, body)
  let scheme = call_601257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601257.url(scheme.get, call_601257.host, call_601257.base,
                         call_601257.route, valid.getOrDefault("path"))
  result = hook(call_601257, url, valid)

proc call*(call_601258: Call_DeleteFacet_601245; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_601259 = newJObject()
  if body != nil:
    body_601259 = body
  result = call_601258.call(nil, nil, nil, nil, body_601259)

var deleteFacet* = Call_DeleteFacet_601245(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_601246,
                                        base: "/", url: url_DeleteFacet_601247,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_601260 = ref object of OpenApiRestCall_600426
proc url_DeleteObject_601262(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteObject_601261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601263 = header.getOrDefault("X-Amz-Date")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Date", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Security-Token")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Security-Token", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601270 = header.getOrDefault("x-amz-data-partition")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = nil)
  if valid_601270 != nil:
    section.add "x-amz-data-partition", valid_601270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_DeleteObject_601260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_DeleteObject_601260; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ##   body: JObject (required)
  var body_601274 = newJObject()
  if body != nil:
    body_601274 = body
  result = call_601273.call(nil, nil, nil, nil, body_601274)

var deleteObject* = Call_DeleteObject_601260(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_601261, base: "/", url: url_DeleteObject_601262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_601275 = ref object of OpenApiRestCall_600426
proc url_DeleteSchema_601277(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSchema_601276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601278 = header.getOrDefault("X-Amz-Date")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Date", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Security-Token")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Security-Token", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601285 = header.getOrDefault("x-amz-data-partition")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "x-amz-data-partition", valid_601285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_DeleteSchema_601275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_DeleteSchema_601275): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_601287.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_601275(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_601276, base: "/", url: url_DeleteSchema_601277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_601288 = ref object of OpenApiRestCall_600426
proc url_DeleteTypedLinkFacet_601290(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTypedLinkFacet_601289(path: JsonNode; query: JsonNode;
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
  var valid_601291 = header.getOrDefault("X-Amz-Date")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Date", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Security-Token")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Security-Token", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Content-Sha256", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Algorithm")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Algorithm", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Signature")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Signature", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-SignedHeaders", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Credential")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Credential", valid_601297
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601298 = header.getOrDefault("x-amz-data-partition")
  valid_601298 = validateParameter(valid_601298, JString, required = true,
                                 default = nil)
  if valid_601298 != nil:
    section.add "x-amz-data-partition", valid_601298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601300: Call_DeleteTypedLinkFacet_601288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601300.validator(path, query, header, formData, body)
  let scheme = call_601300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601300.url(scheme.get, call_601300.host, call_601300.base,
                         call_601300.route, valid.getOrDefault("path"))
  result = hook(call_601300, url, valid)

proc call*(call_601301: Call_DeleteTypedLinkFacet_601288; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601302 = newJObject()
  if body != nil:
    body_601302 = body
  result = call_601301.call(nil, nil, nil, nil, body_601302)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_601288(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_601289, base: "/",
    url: url_DeleteTypedLinkFacet_601290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_601303 = ref object of OpenApiRestCall_600426
proc url_DetachFromIndex_601305(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachFromIndex_601304(path: JsonNode; query: JsonNode;
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
  var valid_601306 = header.getOrDefault("X-Amz-Date")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Date", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Security-Token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Security-Token", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601313 = header.getOrDefault("x-amz-data-partition")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "x-amz-data-partition", valid_601313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601315: Call_DetachFromIndex_601303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_601315.validator(path, query, header, formData, body)
  let scheme = call_601315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601315.url(scheme.get, call_601315.host, call_601315.base,
                         call_601315.route, valid.getOrDefault("path"))
  result = hook(call_601315, url, valid)

proc call*(call_601316: Call_DetachFromIndex_601303; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_601317 = newJObject()
  if body != nil:
    body_601317 = body
  result = call_601316.call(nil, nil, nil, nil, body_601317)

var detachFromIndex* = Call_DetachFromIndex_601303(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_601304, base: "/", url: url_DetachFromIndex_601305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_601318 = ref object of OpenApiRestCall_600426
proc url_DetachObject_601320(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachObject_601319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601321 = header.getOrDefault("X-Amz-Date")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Date", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Security-Token")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Security-Token", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Content-Sha256", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Algorithm")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Algorithm", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Signature")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Signature", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-SignedHeaders", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Credential")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Credential", valid_601327
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601328 = header.getOrDefault("x-amz-data-partition")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = nil)
  if valid_601328 != nil:
    section.add "x-amz-data-partition", valid_601328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601330: Call_DetachObject_601318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_601330.validator(path, query, header, formData, body)
  let scheme = call_601330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601330.url(scheme.get, call_601330.host, call_601330.base,
                         call_601330.route, valid.getOrDefault("path"))
  result = hook(call_601330, url, valid)

proc call*(call_601331: Call_DetachObject_601318; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_601332 = newJObject()
  if body != nil:
    body_601332 = body
  result = call_601331.call(nil, nil, nil, nil, body_601332)

var detachObject* = Call_DetachObject_601318(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_601319, base: "/", url: url_DetachObject_601320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_601333 = ref object of OpenApiRestCall_600426
proc url_DetachPolicy_601335(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachPolicy_601334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601336 = header.getOrDefault("X-Amz-Date")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Date", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Security-Token")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Security-Token", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Content-Sha256", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Algorithm")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Algorithm", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Signature")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Signature", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-SignedHeaders", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Credential")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Credential", valid_601342
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601343 = header.getOrDefault("x-amz-data-partition")
  valid_601343 = validateParameter(valid_601343, JString, required = true,
                                 default = nil)
  if valid_601343 != nil:
    section.add "x-amz-data-partition", valid_601343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601345: Call_DetachPolicy_601333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_601345.validator(path, query, header, formData, body)
  let scheme = call_601345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601345.url(scheme.get, call_601345.host, call_601345.base,
                         call_601345.route, valid.getOrDefault("path"))
  result = hook(call_601345, url, valid)

proc call*(call_601346: Call_DetachPolicy_601333; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_601347 = newJObject()
  if body != nil:
    body_601347 = body
  result = call_601346.call(nil, nil, nil, nil, body_601347)

var detachPolicy* = Call_DetachPolicy_601333(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_601334, base: "/", url: url_DetachPolicy_601335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_601348 = ref object of OpenApiRestCall_600426
proc url_DetachTypedLink_601350(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DetachTypedLink_601349(path: JsonNode; query: JsonNode;
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
  var valid_601351 = header.getOrDefault("X-Amz-Date")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Date", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Security-Token")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Security-Token", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Content-Sha256", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Algorithm")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Algorithm", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Signature")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Signature", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-SignedHeaders", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Credential")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Credential", valid_601357
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601358 = header.getOrDefault("x-amz-data-partition")
  valid_601358 = validateParameter(valid_601358, JString, required = true,
                                 default = nil)
  if valid_601358 != nil:
    section.add "x-amz-data-partition", valid_601358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601360: Call_DetachTypedLink_601348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601360.validator(path, query, header, formData, body)
  let scheme = call_601360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601360.url(scheme.get, call_601360.host, call_601360.base,
                         call_601360.route, valid.getOrDefault("path"))
  result = hook(call_601360, url, valid)

proc call*(call_601361: Call_DetachTypedLink_601348; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601362 = newJObject()
  if body != nil:
    body_601362 = body
  result = call_601361.call(nil, nil, nil, nil, body_601362)

var detachTypedLink* = Call_DetachTypedLink_601348(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_601349, base: "/", url: url_DetachTypedLink_601350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_601363 = ref object of OpenApiRestCall_600426
proc url_DisableDirectory_601365(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDirectory_601364(path: JsonNode; query: JsonNode;
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
  var valid_601366 = header.getOrDefault("X-Amz-Date")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Date", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Security-Token")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Security-Token", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Content-Sha256", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Algorithm")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Algorithm", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Signature")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Signature", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-SignedHeaders", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Credential")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Credential", valid_601372
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601373 = header.getOrDefault("x-amz-data-partition")
  valid_601373 = validateParameter(valid_601373, JString, required = true,
                                 default = nil)
  if valid_601373 != nil:
    section.add "x-amz-data-partition", valid_601373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601374: Call_DisableDirectory_601363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_601374.validator(path, query, header, formData, body)
  let scheme = call_601374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601374.url(scheme.get, call_601374.host, call_601374.base,
                         call_601374.route, valid.getOrDefault("path"))
  result = hook(call_601374, url, valid)

proc call*(call_601375: Call_DisableDirectory_601363): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_601375.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_601363(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_601364, base: "/",
    url: url_DisableDirectory_601365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_601376 = ref object of OpenApiRestCall_600426
proc url_EnableDirectory_601378(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDirectory_601377(path: JsonNode; query: JsonNode;
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
  var valid_601379 = header.getOrDefault("X-Amz-Date")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Date", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Security-Token")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Security-Token", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Content-Sha256", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Algorithm")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Algorithm", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Signature")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Signature", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-SignedHeaders", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Credential")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Credential", valid_601385
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601386 = header.getOrDefault("x-amz-data-partition")
  valid_601386 = validateParameter(valid_601386, JString, required = true,
                                 default = nil)
  if valid_601386 != nil:
    section.add "x-amz-data-partition", valid_601386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601387: Call_EnableDirectory_601376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_601387.validator(path, query, header, formData, body)
  let scheme = call_601387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601387.url(scheme.get, call_601387.host, call_601387.base,
                         call_601387.route, valid.getOrDefault("path"))
  result = hook(call_601387, url, valid)

proc call*(call_601388: Call_EnableDirectory_601376): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_601388.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_601376(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_601377, base: "/", url: url_EnableDirectory_601378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_601389 = ref object of OpenApiRestCall_600426
proc url_GetAppliedSchemaVersion_601391(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppliedSchemaVersion_601390(path: JsonNode; query: JsonNode;
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
  var valid_601392 = header.getOrDefault("X-Amz-Date")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Date", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Security-Token")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Security-Token", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Content-Sha256", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Algorithm")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Algorithm", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Signature")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Signature", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-SignedHeaders", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Credential")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Credential", valid_601398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601400: Call_GetAppliedSchemaVersion_601389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_601400.validator(path, query, header, formData, body)
  let scheme = call_601400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601400.url(scheme.get, call_601400.host, call_601400.base,
                         call_601400.route, valid.getOrDefault("path"))
  result = hook(call_601400, url, valid)

proc call*(call_601401: Call_GetAppliedSchemaVersion_601389; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_601402 = newJObject()
  if body != nil:
    body_601402 = body
  result = call_601401.call(nil, nil, nil, nil, body_601402)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_601389(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_601390, base: "/",
    url: url_GetAppliedSchemaVersion_601391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_601403 = ref object of OpenApiRestCall_600426
proc url_GetDirectory_601405(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDirectory_601404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601406 = header.getOrDefault("X-Amz-Date")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Date", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Security-Token")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Security-Token", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Content-Sha256", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Algorithm")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Algorithm", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Signature")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Signature", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-SignedHeaders", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Credential")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Credential", valid_601412
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601413 = header.getOrDefault("x-amz-data-partition")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = nil)
  if valid_601413 != nil:
    section.add "x-amz-data-partition", valid_601413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601414: Call_GetDirectory_601403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_601414.validator(path, query, header, formData, body)
  let scheme = call_601414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601414.url(scheme.get, call_601414.host, call_601414.base,
                         call_601414.route, valid.getOrDefault("path"))
  result = hook(call_601414, url, valid)

proc call*(call_601415: Call_GetDirectory_601403): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_601415.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_601403(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_601404, base: "/", url: url_GetDirectory_601405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_601416 = ref object of OpenApiRestCall_600426
proc url_UpdateFacet_601418(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFacet_601417(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601419 = header.getOrDefault("X-Amz-Date")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Date", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Security-Token")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Security-Token", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Content-Sha256", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Algorithm")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Algorithm", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Signature")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Signature", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-SignedHeaders", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Credential")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Credential", valid_601425
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601426 = header.getOrDefault("x-amz-data-partition")
  valid_601426 = validateParameter(valid_601426, JString, required = true,
                                 default = nil)
  if valid_601426 != nil:
    section.add "x-amz-data-partition", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601428: Call_UpdateFacet_601416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_601428.validator(path, query, header, formData, body)
  let scheme = call_601428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601428.url(scheme.get, call_601428.host, call_601428.base,
                         call_601428.route, valid.getOrDefault("path"))
  result = hook(call_601428, url, valid)

proc call*(call_601429: Call_UpdateFacet_601416; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_601430 = newJObject()
  if body != nil:
    body_601430 = body
  result = call_601429.call(nil, nil, nil, nil, body_601430)

var updateFacet* = Call_UpdateFacet_601416(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_601417,
                                        base: "/", url: url_UpdateFacet_601418,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_601431 = ref object of OpenApiRestCall_600426
proc url_GetFacet_601433(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFacet_601432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601434 = header.getOrDefault("X-Amz-Date")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Date", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Security-Token")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Security-Token", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Content-Sha256", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Algorithm")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Algorithm", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Signature")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Signature", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-SignedHeaders", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Credential")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Credential", valid_601440
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601441 = header.getOrDefault("x-amz-data-partition")
  valid_601441 = validateParameter(valid_601441, JString, required = true,
                                 default = nil)
  if valid_601441 != nil:
    section.add "x-amz-data-partition", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_GetFacet_601431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_GetFacet_601431; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_601445 = newJObject()
  if body != nil:
    body_601445 = body
  result = call_601444.call(nil, nil, nil, nil, body_601445)

var getFacet* = Call_GetFacet_601431(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_601432, base: "/",
                                  url: url_GetFacet_601433,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_601446 = ref object of OpenApiRestCall_600426
proc url_GetLinkAttributes_601448(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLinkAttributes_601447(path: JsonNode; query: JsonNode;
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
  var valid_601449 = header.getOrDefault("X-Amz-Date")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Date", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Security-Token")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Security-Token", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Content-Sha256", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Algorithm")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Algorithm", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Signature")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Signature", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-SignedHeaders", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Credential")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Credential", valid_601455
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601456 = header.getOrDefault("x-amz-data-partition")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = nil)
  if valid_601456 != nil:
    section.add "x-amz-data-partition", valid_601456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_GetLinkAttributes_601446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_GetLinkAttributes_601446; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_601460 = newJObject()
  if body != nil:
    body_601460 = body
  result = call_601459.call(nil, nil, nil, nil, body_601460)

var getLinkAttributes* = Call_GetLinkAttributes_601446(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_601447, base: "/",
    url: url_GetLinkAttributes_601448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_601461 = ref object of OpenApiRestCall_600426
proc url_GetObjectAttributes_601463(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetObjectAttributes_601462(path: JsonNode; query: JsonNode;
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
  var valid_601464 = header.getOrDefault("X-Amz-Date")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Date", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Security-Token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Security-Token", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Content-Sha256", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Algorithm")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Algorithm", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Signature")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Signature", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-SignedHeaders", valid_601469
  var valid_601470 = header.getOrDefault("x-amz-consistency-level")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601470 != nil:
    section.add "x-amz-consistency-level", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Credential")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Credential", valid_601471
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601472 = header.getOrDefault("x-amz-data-partition")
  valid_601472 = validateParameter(valid_601472, JString, required = true,
                                 default = nil)
  if valid_601472 != nil:
    section.add "x-amz-data-partition", valid_601472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601474: Call_GetObjectAttributes_601461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_601474.validator(path, query, header, formData, body)
  let scheme = call_601474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601474.url(scheme.get, call_601474.host, call_601474.base,
                         call_601474.route, valid.getOrDefault("path"))
  result = hook(call_601474, url, valid)

proc call*(call_601475: Call_GetObjectAttributes_601461; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_601476 = newJObject()
  if body != nil:
    body_601476 = body
  result = call_601475.call(nil, nil, nil, nil, body_601476)

var getObjectAttributes* = Call_GetObjectAttributes_601461(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_601462, base: "/",
    url: url_GetObjectAttributes_601463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_601477 = ref object of OpenApiRestCall_600426
proc url_GetObjectInformation_601479(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetObjectInformation_601478(path: JsonNode; query: JsonNode;
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
  var valid_601480 = header.getOrDefault("X-Amz-Date")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Date", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Security-Token")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Security-Token", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Content-Sha256", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Algorithm")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Algorithm", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Signature")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Signature", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-SignedHeaders", valid_601485
  var valid_601486 = header.getOrDefault("x-amz-consistency-level")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601486 != nil:
    section.add "x-amz-consistency-level", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Credential")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Credential", valid_601487
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601488 = header.getOrDefault("x-amz-data-partition")
  valid_601488 = validateParameter(valid_601488, JString, required = true,
                                 default = nil)
  if valid_601488 != nil:
    section.add "x-amz-data-partition", valid_601488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601490: Call_GetObjectInformation_601477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_601490.validator(path, query, header, formData, body)
  let scheme = call_601490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601490.url(scheme.get, call_601490.host, call_601490.base,
                         call_601490.route, valid.getOrDefault("path"))
  result = hook(call_601490, url, valid)

proc call*(call_601491: Call_GetObjectInformation_601477; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_601492 = newJObject()
  if body != nil:
    body_601492 = body
  result = call_601491.call(nil, nil, nil, nil, body_601492)

var getObjectInformation* = Call_GetObjectInformation_601477(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_601478, base: "/",
    url: url_GetObjectInformation_601479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_601493 = ref object of OpenApiRestCall_600426
proc url_PutSchemaFromJson_601495(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutSchemaFromJson_601494(path: JsonNode; query: JsonNode;
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
  var valid_601496 = header.getOrDefault("X-Amz-Date")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Date", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Security-Token")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Security-Token", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Content-Sha256", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Algorithm")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Algorithm", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Signature")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Signature", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-SignedHeaders", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Credential")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Credential", valid_601502
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601503 = header.getOrDefault("x-amz-data-partition")
  valid_601503 = validateParameter(valid_601503, JString, required = true,
                                 default = nil)
  if valid_601503 != nil:
    section.add "x-amz-data-partition", valid_601503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601505: Call_PutSchemaFromJson_601493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_601505.validator(path, query, header, formData, body)
  let scheme = call_601505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601505.url(scheme.get, call_601505.host, call_601505.base,
                         call_601505.route, valid.getOrDefault("path"))
  result = hook(call_601505, url, valid)

proc call*(call_601506: Call_PutSchemaFromJson_601493; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_601507 = newJObject()
  if body != nil:
    body_601507 = body
  result = call_601506.call(nil, nil, nil, nil, body_601507)

var putSchemaFromJson* = Call_PutSchemaFromJson_601493(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_601494, base: "/",
    url: url_PutSchemaFromJson_601495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_601508 = ref object of OpenApiRestCall_600426
proc url_GetSchemaAsJson_601510(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSchemaAsJson_601509(path: JsonNode; query: JsonNode;
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
  var valid_601511 = header.getOrDefault("X-Amz-Date")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Date", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Security-Token")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Security-Token", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Content-Sha256", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Algorithm")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Algorithm", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Signature")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Signature", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-SignedHeaders", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Credential")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Credential", valid_601517
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601518 = header.getOrDefault("x-amz-data-partition")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "x-amz-data-partition", valid_601518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601519: Call_GetSchemaAsJson_601508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_601519.validator(path, query, header, formData, body)
  let scheme = call_601519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601519.url(scheme.get, call_601519.host, call_601519.base,
                         call_601519.route, valid.getOrDefault("path"))
  result = hook(call_601519, url, valid)

proc call*(call_601520: Call_GetSchemaAsJson_601508): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  result = call_601520.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_601508(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_601509, base: "/", url: url_GetSchemaAsJson_601510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_601521 = ref object of OpenApiRestCall_600426
proc url_GetTypedLinkFacetInformation_601523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTypedLinkFacetInformation_601522(path: JsonNode; query: JsonNode;
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
  var valid_601524 = header.getOrDefault("X-Amz-Date")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Date", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Security-Token")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Security-Token", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Content-Sha256", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Algorithm")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Algorithm", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Signature")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Signature", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-SignedHeaders", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Credential")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Credential", valid_601530
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601531 = header.getOrDefault("x-amz-data-partition")
  valid_601531 = validateParameter(valid_601531, JString, required = true,
                                 default = nil)
  if valid_601531 != nil:
    section.add "x-amz-data-partition", valid_601531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_GetTypedLinkFacetInformation_601521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_GetTypedLinkFacetInformation_601521; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601535 = newJObject()
  if body != nil:
    body_601535 = body
  result = call_601534.call(nil, nil, nil, nil, body_601535)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_601521(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_601522, base: "/",
    url: url_GetTypedLinkFacetInformation_601523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_601536 = ref object of OpenApiRestCall_600426
proc url_ListAppliedSchemaArns_601538(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAppliedSchemaArns_601537(path: JsonNode; query: JsonNode;
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
  var valid_601539 = query.getOrDefault("NextToken")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "NextToken", valid_601539
  var valid_601540 = query.getOrDefault("MaxResults")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "MaxResults", valid_601540
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
  var valid_601541 = header.getOrDefault("X-Amz-Date")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Date", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Security-Token")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Security-Token", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Content-Sha256", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Algorithm")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Algorithm", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Signature")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Signature", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-SignedHeaders", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Credential")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Credential", valid_601547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601549: Call_ListAppliedSchemaArns_601536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_601549.validator(path, query, header, formData, body)
  let scheme = call_601549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601549.url(scheme.get, call_601549.host, call_601549.base,
                         call_601549.route, valid.getOrDefault("path"))
  result = hook(call_601549, url, valid)

proc call*(call_601550: Call_ListAppliedSchemaArns_601536; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601551 = newJObject()
  var body_601552 = newJObject()
  add(query_601551, "NextToken", newJString(NextToken))
  if body != nil:
    body_601552 = body
  add(query_601551, "MaxResults", newJString(MaxResults))
  result = call_601550.call(nil, query_601551, nil, nil, body_601552)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_601536(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_601537, base: "/",
    url: url_ListAppliedSchemaArns_601538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_601554 = ref object of OpenApiRestCall_600426
proc url_ListAttachedIndices_601556(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAttachedIndices_601555(path: JsonNode; query: JsonNode;
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
  var valid_601557 = query.getOrDefault("NextToken")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "NextToken", valid_601557
  var valid_601558 = query.getOrDefault("MaxResults")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "MaxResults", valid_601558
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
  var valid_601559 = header.getOrDefault("X-Amz-Date")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Date", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Security-Token")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Security-Token", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Content-Sha256", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Algorithm")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Algorithm", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Signature")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Signature", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-SignedHeaders", valid_601564
  var valid_601565 = header.getOrDefault("x-amz-consistency-level")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601565 != nil:
    section.add "x-amz-consistency-level", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Credential")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Credential", valid_601566
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601567 = header.getOrDefault("x-amz-data-partition")
  valid_601567 = validateParameter(valid_601567, JString, required = true,
                                 default = nil)
  if valid_601567 != nil:
    section.add "x-amz-data-partition", valid_601567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601569: Call_ListAttachedIndices_601554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_601569.validator(path, query, header, formData, body)
  let scheme = call_601569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601569.url(scheme.get, call_601569.host, call_601569.base,
                         call_601569.route, valid.getOrDefault("path"))
  result = hook(call_601569, url, valid)

proc call*(call_601570: Call_ListAttachedIndices_601554; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601571 = newJObject()
  var body_601572 = newJObject()
  add(query_601571, "NextToken", newJString(NextToken))
  if body != nil:
    body_601572 = body
  add(query_601571, "MaxResults", newJString(MaxResults))
  result = call_601570.call(nil, query_601571, nil, nil, body_601572)

var listAttachedIndices* = Call_ListAttachedIndices_601554(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_601555, base: "/",
    url: url_ListAttachedIndices_601556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_601573 = ref object of OpenApiRestCall_600426
proc url_ListDevelopmentSchemaArns_601575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDevelopmentSchemaArns_601574(path: JsonNode; query: JsonNode;
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
  var valid_601576 = query.getOrDefault("NextToken")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "NextToken", valid_601576
  var valid_601577 = query.getOrDefault("MaxResults")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "MaxResults", valid_601577
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
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Content-Sha256", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Algorithm")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Algorithm", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Signature")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Signature", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-SignedHeaders", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Credential")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Credential", valid_601584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601586: Call_ListDevelopmentSchemaArns_601573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_601586.validator(path, query, header, formData, body)
  let scheme = call_601586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601586.url(scheme.get, call_601586.host, call_601586.base,
                         call_601586.route, valid.getOrDefault("path"))
  result = hook(call_601586, url, valid)

proc call*(call_601587: Call_ListDevelopmentSchemaArns_601573; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601588 = newJObject()
  var body_601589 = newJObject()
  add(query_601588, "NextToken", newJString(NextToken))
  if body != nil:
    body_601589 = body
  add(query_601588, "MaxResults", newJString(MaxResults))
  result = call_601587.call(nil, query_601588, nil, nil, body_601589)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_601573(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_601574, base: "/",
    url: url_ListDevelopmentSchemaArns_601575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_601590 = ref object of OpenApiRestCall_600426
proc url_ListDirectories_601592(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDirectories_601591(path: JsonNode; query: JsonNode;
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
  var valid_601593 = query.getOrDefault("NextToken")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "NextToken", valid_601593
  var valid_601594 = query.getOrDefault("MaxResults")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "MaxResults", valid_601594
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
  var valid_601595 = header.getOrDefault("X-Amz-Date")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Date", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Security-Token")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Security-Token", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Content-Sha256", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Algorithm")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Algorithm", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Signature")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Signature", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-SignedHeaders", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Credential")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Credential", valid_601601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601603: Call_ListDirectories_601590; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_601603.validator(path, query, header, formData, body)
  let scheme = call_601603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601603.url(scheme.get, call_601603.host, call_601603.base,
                         call_601603.route, valid.getOrDefault("path"))
  result = hook(call_601603, url, valid)

proc call*(call_601604: Call_ListDirectories_601590; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601605 = newJObject()
  var body_601606 = newJObject()
  add(query_601605, "NextToken", newJString(NextToken))
  if body != nil:
    body_601606 = body
  add(query_601605, "MaxResults", newJString(MaxResults))
  result = call_601604.call(nil, query_601605, nil, nil, body_601606)

var listDirectories* = Call_ListDirectories_601590(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_601591, base: "/", url: url_ListDirectories_601592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_601607 = ref object of OpenApiRestCall_600426
proc url_ListFacetAttributes_601609(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFacetAttributes_601608(path: JsonNode; query: JsonNode;
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
  var valid_601610 = query.getOrDefault("NextToken")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "NextToken", valid_601610
  var valid_601611 = query.getOrDefault("MaxResults")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "MaxResults", valid_601611
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
  var valid_601612 = header.getOrDefault("X-Amz-Date")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Date", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Security-Token")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Security-Token", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Content-Sha256", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Algorithm")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Algorithm", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Signature")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Signature", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-SignedHeaders", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Credential")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Credential", valid_601618
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601619 = header.getOrDefault("x-amz-data-partition")
  valid_601619 = validateParameter(valid_601619, JString, required = true,
                                 default = nil)
  if valid_601619 != nil:
    section.add "x-amz-data-partition", valid_601619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601621: Call_ListFacetAttributes_601607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_601621.validator(path, query, header, formData, body)
  let scheme = call_601621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601621.url(scheme.get, call_601621.host, call_601621.base,
                         call_601621.route, valid.getOrDefault("path"))
  result = hook(call_601621, url, valid)

proc call*(call_601622: Call_ListFacetAttributes_601607; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601623 = newJObject()
  var body_601624 = newJObject()
  add(query_601623, "NextToken", newJString(NextToken))
  if body != nil:
    body_601624 = body
  add(query_601623, "MaxResults", newJString(MaxResults))
  result = call_601622.call(nil, query_601623, nil, nil, body_601624)

var listFacetAttributes* = Call_ListFacetAttributes_601607(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_601608, base: "/",
    url: url_ListFacetAttributes_601609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_601625 = ref object of OpenApiRestCall_600426
proc url_ListFacetNames_601627(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFacetNames_601626(path: JsonNode; query: JsonNode;
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
  var valid_601628 = query.getOrDefault("NextToken")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "NextToken", valid_601628
  var valid_601629 = query.getOrDefault("MaxResults")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "MaxResults", valid_601629
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
  var valid_601630 = header.getOrDefault("X-Amz-Date")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Date", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Security-Token")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Security-Token", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Content-Sha256", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Algorithm")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Algorithm", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Signature")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Signature", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-SignedHeaders", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Credential")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Credential", valid_601636
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601637 = header.getOrDefault("x-amz-data-partition")
  valid_601637 = validateParameter(valid_601637, JString, required = true,
                                 default = nil)
  if valid_601637 != nil:
    section.add "x-amz-data-partition", valid_601637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601639: Call_ListFacetNames_601625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_601639.validator(path, query, header, formData, body)
  let scheme = call_601639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601639.url(scheme.get, call_601639.host, call_601639.base,
                         call_601639.route, valid.getOrDefault("path"))
  result = hook(call_601639, url, valid)

proc call*(call_601640: Call_ListFacetNames_601625; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601641 = newJObject()
  var body_601642 = newJObject()
  add(query_601641, "NextToken", newJString(NextToken))
  if body != nil:
    body_601642 = body
  add(query_601641, "MaxResults", newJString(MaxResults))
  result = call_601640.call(nil, query_601641, nil, nil, body_601642)

var listFacetNames* = Call_ListFacetNames_601625(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_601626, base: "/", url: url_ListFacetNames_601627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_601643 = ref object of OpenApiRestCall_600426
proc url_ListIncomingTypedLinks_601645(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIncomingTypedLinks_601644(path: JsonNode; query: JsonNode;
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
  var valid_601646 = header.getOrDefault("X-Amz-Date")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Date", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Security-Token")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Security-Token", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Content-Sha256", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Algorithm")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Algorithm", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Signature")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Signature", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-SignedHeaders", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Credential")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Credential", valid_601652
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601653 = header.getOrDefault("x-amz-data-partition")
  valid_601653 = validateParameter(valid_601653, JString, required = true,
                                 default = nil)
  if valid_601653 != nil:
    section.add "x-amz-data-partition", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601655: Call_ListIncomingTypedLinks_601643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"))
  result = hook(call_601655, url, valid)

proc call*(call_601656: Call_ListIncomingTypedLinks_601643; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601657 = newJObject()
  if body != nil:
    body_601657 = body
  result = call_601656.call(nil, nil, nil, nil, body_601657)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_601643(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_601644, base: "/",
    url: url_ListIncomingTypedLinks_601645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_601658 = ref object of OpenApiRestCall_600426
proc url_ListIndex_601660(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListIndex_601659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601661 = query.getOrDefault("NextToken")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "NextToken", valid_601661
  var valid_601662 = query.getOrDefault("MaxResults")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "MaxResults", valid_601662
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
  var valid_601663 = header.getOrDefault("X-Amz-Date")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Date", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Security-Token")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Security-Token", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Content-Sha256", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Algorithm")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Algorithm", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Signature")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Signature", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-SignedHeaders", valid_601668
  var valid_601669 = header.getOrDefault("x-amz-consistency-level")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601669 != nil:
    section.add "x-amz-consistency-level", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Credential")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Credential", valid_601670
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601671 = header.getOrDefault("x-amz-data-partition")
  valid_601671 = validateParameter(valid_601671, JString, required = true,
                                 default = nil)
  if valid_601671 != nil:
    section.add "x-amz-data-partition", valid_601671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601673: Call_ListIndex_601658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_601673.validator(path, query, header, formData, body)
  let scheme = call_601673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601673.url(scheme.get, call_601673.host, call_601673.base,
                         call_601673.route, valid.getOrDefault("path"))
  result = hook(call_601673, url, valid)

proc call*(call_601674: Call_ListIndex_601658; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601675 = newJObject()
  var body_601676 = newJObject()
  add(query_601675, "NextToken", newJString(NextToken))
  if body != nil:
    body_601676 = body
  add(query_601675, "MaxResults", newJString(MaxResults))
  result = call_601674.call(nil, query_601675, nil, nil, body_601676)

var listIndex* = Call_ListIndex_601658(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_601659,
                                    base: "/", url: url_ListIndex_601660,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_601677 = ref object of OpenApiRestCall_600426
proc url_ListObjectAttributes_601679(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectAttributes_601678(path: JsonNode; query: JsonNode;
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
  var valid_601680 = query.getOrDefault("NextToken")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "NextToken", valid_601680
  var valid_601681 = query.getOrDefault("MaxResults")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "MaxResults", valid_601681
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
  var valid_601682 = header.getOrDefault("X-Amz-Date")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Date", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Security-Token")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Security-Token", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Content-Sha256", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Algorithm")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Algorithm", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Signature")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Signature", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-SignedHeaders", valid_601687
  var valid_601688 = header.getOrDefault("x-amz-consistency-level")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601688 != nil:
    section.add "x-amz-consistency-level", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Credential")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Credential", valid_601689
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601690 = header.getOrDefault("x-amz-data-partition")
  valid_601690 = validateParameter(valid_601690, JString, required = true,
                                 default = nil)
  if valid_601690 != nil:
    section.add "x-amz-data-partition", valid_601690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601692: Call_ListObjectAttributes_601677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_601692.validator(path, query, header, formData, body)
  let scheme = call_601692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601692.url(scheme.get, call_601692.host, call_601692.base,
                         call_601692.route, valid.getOrDefault("path"))
  result = hook(call_601692, url, valid)

proc call*(call_601693: Call_ListObjectAttributes_601677; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601694 = newJObject()
  var body_601695 = newJObject()
  add(query_601694, "NextToken", newJString(NextToken))
  if body != nil:
    body_601695 = body
  add(query_601694, "MaxResults", newJString(MaxResults))
  result = call_601693.call(nil, query_601694, nil, nil, body_601695)

var listObjectAttributes* = Call_ListObjectAttributes_601677(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_601678, base: "/",
    url: url_ListObjectAttributes_601679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_601696 = ref object of OpenApiRestCall_600426
proc url_ListObjectChildren_601698(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectChildren_601697(path: JsonNode; query: JsonNode;
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
  var valid_601699 = query.getOrDefault("NextToken")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "NextToken", valid_601699
  var valid_601700 = query.getOrDefault("MaxResults")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "MaxResults", valid_601700
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
  var valid_601701 = header.getOrDefault("X-Amz-Date")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Date", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Security-Token")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Security-Token", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Content-Sha256", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Algorithm")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Algorithm", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Signature")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Signature", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-SignedHeaders", valid_601706
  var valid_601707 = header.getOrDefault("x-amz-consistency-level")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601707 != nil:
    section.add "x-amz-consistency-level", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Credential")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Credential", valid_601708
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601709 = header.getOrDefault("x-amz-data-partition")
  valid_601709 = validateParameter(valid_601709, JString, required = true,
                                 default = nil)
  if valid_601709 != nil:
    section.add "x-amz-data-partition", valid_601709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601711: Call_ListObjectChildren_601696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_601711.validator(path, query, header, formData, body)
  let scheme = call_601711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601711.url(scheme.get, call_601711.host, call_601711.base,
                         call_601711.route, valid.getOrDefault("path"))
  result = hook(call_601711, url, valid)

proc call*(call_601712: Call_ListObjectChildren_601696; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601713 = newJObject()
  var body_601714 = newJObject()
  add(query_601713, "NextToken", newJString(NextToken))
  if body != nil:
    body_601714 = body
  add(query_601713, "MaxResults", newJString(MaxResults))
  result = call_601712.call(nil, query_601713, nil, nil, body_601714)

var listObjectChildren* = Call_ListObjectChildren_601696(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_601697, base: "/",
    url: url_ListObjectChildren_601698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_601715 = ref object of OpenApiRestCall_600426
proc url_ListObjectParentPaths_601717(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectParentPaths_601716(path: JsonNode; query: JsonNode;
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
  var valid_601718 = query.getOrDefault("NextToken")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "NextToken", valid_601718
  var valid_601719 = query.getOrDefault("MaxResults")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "MaxResults", valid_601719
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
  var valid_601720 = header.getOrDefault("X-Amz-Date")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Date", valid_601720
  var valid_601721 = header.getOrDefault("X-Amz-Security-Token")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Security-Token", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Content-Sha256", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Algorithm")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Algorithm", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Signature")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Signature", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-SignedHeaders", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Credential")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Credential", valid_601726
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601727 = header.getOrDefault("x-amz-data-partition")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = nil)
  if valid_601727 != nil:
    section.add "x-amz-data-partition", valid_601727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601729: Call_ListObjectParentPaths_601715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_601729.validator(path, query, header, formData, body)
  let scheme = call_601729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601729.url(scheme.get, call_601729.host, call_601729.base,
                         call_601729.route, valid.getOrDefault("path"))
  result = hook(call_601729, url, valid)

proc call*(call_601730: Call_ListObjectParentPaths_601715; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601731 = newJObject()
  var body_601732 = newJObject()
  add(query_601731, "NextToken", newJString(NextToken))
  if body != nil:
    body_601732 = body
  add(query_601731, "MaxResults", newJString(MaxResults))
  result = call_601730.call(nil, query_601731, nil, nil, body_601732)

var listObjectParentPaths* = Call_ListObjectParentPaths_601715(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_601716, base: "/",
    url: url_ListObjectParentPaths_601717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_601733 = ref object of OpenApiRestCall_600426
proc url_ListObjectParents_601735(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectParents_601734(path: JsonNode; query: JsonNode;
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
  var valid_601736 = query.getOrDefault("NextToken")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "NextToken", valid_601736
  var valid_601737 = query.getOrDefault("MaxResults")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "MaxResults", valid_601737
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
  var valid_601738 = header.getOrDefault("X-Amz-Date")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Date", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Security-Token")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Security-Token", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Content-Sha256", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Algorithm")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Algorithm", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Signature")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Signature", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-SignedHeaders", valid_601743
  var valid_601744 = header.getOrDefault("x-amz-consistency-level")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601744 != nil:
    section.add "x-amz-consistency-level", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Credential")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Credential", valid_601745
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601746 = header.getOrDefault("x-amz-data-partition")
  valid_601746 = validateParameter(valid_601746, JString, required = true,
                                 default = nil)
  if valid_601746 != nil:
    section.add "x-amz-data-partition", valid_601746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601748: Call_ListObjectParents_601733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_601748.validator(path, query, header, formData, body)
  let scheme = call_601748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601748.url(scheme.get, call_601748.host, call_601748.base,
                         call_601748.route, valid.getOrDefault("path"))
  result = hook(call_601748, url, valid)

proc call*(call_601749: Call_ListObjectParents_601733; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601750 = newJObject()
  var body_601751 = newJObject()
  add(query_601750, "NextToken", newJString(NextToken))
  if body != nil:
    body_601751 = body
  add(query_601750, "MaxResults", newJString(MaxResults))
  result = call_601749.call(nil, query_601750, nil, nil, body_601751)

var listObjectParents* = Call_ListObjectParents_601733(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_601734, base: "/",
    url: url_ListObjectParents_601735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_601752 = ref object of OpenApiRestCall_600426
proc url_ListObjectPolicies_601754(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListObjectPolicies_601753(path: JsonNode; query: JsonNode;
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
  var valid_601755 = query.getOrDefault("NextToken")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "NextToken", valid_601755
  var valid_601756 = query.getOrDefault("MaxResults")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "MaxResults", valid_601756
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
  var valid_601757 = header.getOrDefault("X-Amz-Date")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Date", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Security-Token")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Security-Token", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Content-Sha256", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Algorithm")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Algorithm", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Signature")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Signature", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-SignedHeaders", valid_601762
  var valid_601763 = header.getOrDefault("x-amz-consistency-level")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601763 != nil:
    section.add "x-amz-consistency-level", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Credential")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Credential", valid_601764
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601765 = header.getOrDefault("x-amz-data-partition")
  valid_601765 = validateParameter(valid_601765, JString, required = true,
                                 default = nil)
  if valid_601765 != nil:
    section.add "x-amz-data-partition", valid_601765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601767: Call_ListObjectPolicies_601752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_601767.validator(path, query, header, formData, body)
  let scheme = call_601767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601767.url(scheme.get, call_601767.host, call_601767.base,
                         call_601767.route, valid.getOrDefault("path"))
  result = hook(call_601767, url, valid)

proc call*(call_601768: Call_ListObjectPolicies_601752; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601769 = newJObject()
  var body_601770 = newJObject()
  add(query_601769, "NextToken", newJString(NextToken))
  if body != nil:
    body_601770 = body
  add(query_601769, "MaxResults", newJString(MaxResults))
  result = call_601768.call(nil, query_601769, nil, nil, body_601770)

var listObjectPolicies* = Call_ListObjectPolicies_601752(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_601753, base: "/",
    url: url_ListObjectPolicies_601754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_601771 = ref object of OpenApiRestCall_600426
proc url_ListOutgoingTypedLinks_601773(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOutgoingTypedLinks_601772(path: JsonNode; query: JsonNode;
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
  var valid_601774 = header.getOrDefault("X-Amz-Date")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Date", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Security-Token")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Security-Token", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Content-Sha256", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Algorithm")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Algorithm", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Signature")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Signature", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-SignedHeaders", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Credential")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Credential", valid_601780
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601781 = header.getOrDefault("x-amz-data-partition")
  valid_601781 = validateParameter(valid_601781, JString, required = true,
                                 default = nil)
  if valid_601781 != nil:
    section.add "x-amz-data-partition", valid_601781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601783: Call_ListOutgoingTypedLinks_601771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601783.validator(path, query, header, formData, body)
  let scheme = call_601783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601783.url(scheme.get, call_601783.host, call_601783.base,
                         call_601783.route, valid.getOrDefault("path"))
  result = hook(call_601783, url, valid)

proc call*(call_601784: Call_ListOutgoingTypedLinks_601771; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_601785 = newJObject()
  if body != nil:
    body_601785 = body
  result = call_601784.call(nil, nil, nil, nil, body_601785)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_601771(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_601772, base: "/",
    url: url_ListOutgoingTypedLinks_601773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_601786 = ref object of OpenApiRestCall_600426
proc url_ListPolicyAttachments_601788(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPolicyAttachments_601787(path: JsonNode; query: JsonNode;
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
  var valid_601789 = query.getOrDefault("NextToken")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "NextToken", valid_601789
  var valid_601790 = query.getOrDefault("MaxResults")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "MaxResults", valid_601790
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
  var valid_601791 = header.getOrDefault("X-Amz-Date")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Date", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Security-Token")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Security-Token", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Content-Sha256", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Algorithm")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Algorithm", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Signature")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Signature", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-SignedHeaders", valid_601796
  var valid_601797 = header.getOrDefault("x-amz-consistency-level")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601797 != nil:
    section.add "x-amz-consistency-level", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Credential")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Credential", valid_601798
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601799 = header.getOrDefault("x-amz-data-partition")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = nil)
  if valid_601799 != nil:
    section.add "x-amz-data-partition", valid_601799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601801: Call_ListPolicyAttachments_601786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_601801.validator(path, query, header, formData, body)
  let scheme = call_601801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601801.url(scheme.get, call_601801.host, call_601801.base,
                         call_601801.route, valid.getOrDefault("path"))
  result = hook(call_601801, url, valid)

proc call*(call_601802: Call_ListPolicyAttachments_601786; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601803 = newJObject()
  var body_601804 = newJObject()
  add(query_601803, "NextToken", newJString(NextToken))
  if body != nil:
    body_601804 = body
  add(query_601803, "MaxResults", newJString(MaxResults))
  result = call_601802.call(nil, query_601803, nil, nil, body_601804)

var listPolicyAttachments* = Call_ListPolicyAttachments_601786(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_601787, base: "/",
    url: url_ListPolicyAttachments_601788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_601805 = ref object of OpenApiRestCall_600426
proc url_ListPublishedSchemaArns_601807(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPublishedSchemaArns_601806(path: JsonNode; query: JsonNode;
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
  var valid_601808 = query.getOrDefault("NextToken")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "NextToken", valid_601808
  var valid_601809 = query.getOrDefault("MaxResults")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "MaxResults", valid_601809
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
  var valid_601810 = header.getOrDefault("X-Amz-Date")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Date", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Security-Token")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Security-Token", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Content-Sha256", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Algorithm")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Algorithm", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Signature")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Signature", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-SignedHeaders", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Credential")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Credential", valid_601816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601818: Call_ListPublishedSchemaArns_601805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_601818.validator(path, query, header, formData, body)
  let scheme = call_601818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601818.url(scheme.get, call_601818.host, call_601818.base,
                         call_601818.route, valid.getOrDefault("path"))
  result = hook(call_601818, url, valid)

proc call*(call_601819: Call_ListPublishedSchemaArns_601805; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601820 = newJObject()
  var body_601821 = newJObject()
  add(query_601820, "NextToken", newJString(NextToken))
  if body != nil:
    body_601821 = body
  add(query_601820, "MaxResults", newJString(MaxResults))
  result = call_601819.call(nil, query_601820, nil, nil, body_601821)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_601805(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_601806, base: "/",
    url: url_ListPublishedSchemaArns_601807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601822 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601824(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601823(path: JsonNode; query: JsonNode;
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
  var valid_601825 = query.getOrDefault("NextToken")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "NextToken", valid_601825
  var valid_601826 = query.getOrDefault("MaxResults")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "MaxResults", valid_601826
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
  var valid_601827 = header.getOrDefault("X-Amz-Date")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Date", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Security-Token")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Security-Token", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Content-Sha256", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Algorithm")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Algorithm", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Signature")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Signature", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-SignedHeaders", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Credential")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Credential", valid_601833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601835: Call_ListTagsForResource_601822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_601835.validator(path, query, header, formData, body)
  let scheme = call_601835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601835.url(scheme.get, call_601835.host, call_601835.base,
                         call_601835.route, valid.getOrDefault("path"))
  result = hook(call_601835, url, valid)

proc call*(call_601836: Call_ListTagsForResource_601822; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601837 = newJObject()
  var body_601838 = newJObject()
  add(query_601837, "NextToken", newJString(NextToken))
  if body != nil:
    body_601838 = body
  add(query_601837, "MaxResults", newJString(MaxResults))
  result = call_601836.call(nil, query_601837, nil, nil, body_601838)

var listTagsForResource* = Call_ListTagsForResource_601822(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_601823, base: "/",
    url: url_ListTagsForResource_601824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_601839 = ref object of OpenApiRestCall_600426
proc url_ListTypedLinkFacetAttributes_601841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTypedLinkFacetAttributes_601840(path: JsonNode; query: JsonNode;
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
  var valid_601842 = query.getOrDefault("NextToken")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "NextToken", valid_601842
  var valid_601843 = query.getOrDefault("MaxResults")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "MaxResults", valid_601843
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
  var valid_601844 = header.getOrDefault("X-Amz-Date")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Date", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Content-Sha256", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Algorithm")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Algorithm", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Signature")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Signature", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Credential")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Credential", valid_601850
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601851 = header.getOrDefault("x-amz-data-partition")
  valid_601851 = validateParameter(valid_601851, JString, required = true,
                                 default = nil)
  if valid_601851 != nil:
    section.add "x-amz-data-partition", valid_601851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601853: Call_ListTypedLinkFacetAttributes_601839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601853.validator(path, query, header, formData, body)
  let scheme = call_601853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601853.url(scheme.get, call_601853.host, call_601853.base,
                         call_601853.route, valid.getOrDefault("path"))
  result = hook(call_601853, url, valid)

proc call*(call_601854: Call_ListTypedLinkFacetAttributes_601839; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601855 = newJObject()
  var body_601856 = newJObject()
  add(query_601855, "NextToken", newJString(NextToken))
  if body != nil:
    body_601856 = body
  add(query_601855, "MaxResults", newJString(MaxResults))
  result = call_601854.call(nil, query_601855, nil, nil, body_601856)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_601839(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_601840, base: "/",
    url: url_ListTypedLinkFacetAttributes_601841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_601857 = ref object of OpenApiRestCall_600426
proc url_ListTypedLinkFacetNames_601859(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTypedLinkFacetNames_601858(path: JsonNode; query: JsonNode;
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
  var valid_601860 = query.getOrDefault("NextToken")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "NextToken", valid_601860
  var valid_601861 = query.getOrDefault("MaxResults")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "MaxResults", valid_601861
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
  var valid_601862 = header.getOrDefault("X-Amz-Date")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Date", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Security-Token")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Security-Token", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Content-Sha256", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Algorithm")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Algorithm", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Signature")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Signature", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-SignedHeaders", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Credential")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Credential", valid_601868
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601869 = header.getOrDefault("x-amz-data-partition")
  valid_601869 = validateParameter(valid_601869, JString, required = true,
                                 default = nil)
  if valid_601869 != nil:
    section.add "x-amz-data-partition", valid_601869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_ListTypedLinkFacetNames_601857; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"))
  result = hook(call_601871, url, valid)

proc call*(call_601872: Call_ListTypedLinkFacetNames_601857; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601873 = newJObject()
  var body_601874 = newJObject()
  add(query_601873, "NextToken", newJString(NextToken))
  if body != nil:
    body_601874 = body
  add(query_601873, "MaxResults", newJString(MaxResults))
  result = call_601872.call(nil, query_601873, nil, nil, body_601874)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_601857(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_601858, base: "/",
    url: url_ListTypedLinkFacetNames_601859, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_601875 = ref object of OpenApiRestCall_600426
proc url_LookupPolicy_601877(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LookupPolicy_601876(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601878 = query.getOrDefault("NextToken")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "NextToken", valid_601878
  var valid_601879 = query.getOrDefault("MaxResults")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "MaxResults", valid_601879
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
  var valid_601880 = header.getOrDefault("X-Amz-Date")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-Date", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-Security-Token")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Security-Token", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Content-Sha256", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Algorithm")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Algorithm", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Signature")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Signature", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-SignedHeaders", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Credential")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Credential", valid_601886
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601887 = header.getOrDefault("x-amz-data-partition")
  valid_601887 = validateParameter(valid_601887, JString, required = true,
                                 default = nil)
  if valid_601887 != nil:
    section.add "x-amz-data-partition", valid_601887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_LookupPolicy_601875; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ## 
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"))
  result = hook(call_601889, url, valid)

proc call*(call_601890: Call_LookupPolicy_601875; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601891 = newJObject()
  var body_601892 = newJObject()
  add(query_601891, "NextToken", newJString(NextToken))
  if body != nil:
    body_601892 = body
  add(query_601891, "MaxResults", newJString(MaxResults))
  result = call_601890.call(nil, query_601891, nil, nil, body_601892)

var lookupPolicy* = Call_LookupPolicy_601875(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_601876, base: "/", url: url_LookupPolicy_601877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_601893 = ref object of OpenApiRestCall_600426
proc url_PublishSchema_601895(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PublishSchema_601894(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601896 = header.getOrDefault("X-Amz-Date")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Date", valid_601896
  var valid_601897 = header.getOrDefault("X-Amz-Security-Token")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "X-Amz-Security-Token", valid_601897
  var valid_601898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Content-Sha256", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Algorithm")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Algorithm", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Signature")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Signature", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-SignedHeaders", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Credential")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Credential", valid_601902
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601903 = header.getOrDefault("x-amz-data-partition")
  valid_601903 = validateParameter(valid_601903, JString, required = true,
                                 default = nil)
  if valid_601903 != nil:
    section.add "x-amz-data-partition", valid_601903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601905: Call_PublishSchema_601893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_601905.validator(path, query, header, formData, body)
  let scheme = call_601905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601905.url(scheme.get, call_601905.host, call_601905.base,
                         call_601905.route, valid.getOrDefault("path"))
  result = hook(call_601905, url, valid)

proc call*(call_601906: Call_PublishSchema_601893; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_601907 = newJObject()
  if body != nil:
    body_601907 = body
  result = call_601906.call(nil, nil, nil, nil, body_601907)

var publishSchema* = Call_PublishSchema_601893(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_601894, base: "/", url: url_PublishSchema_601895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_601908 = ref object of OpenApiRestCall_600426
proc url_RemoveFacetFromObject_601910(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveFacetFromObject_601909(path: JsonNode; query: JsonNode;
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
  var valid_601911 = header.getOrDefault("X-Amz-Date")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Date", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Security-Token")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Security-Token", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Content-Sha256", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Algorithm")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Algorithm", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Signature")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Signature", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-SignedHeaders", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Credential")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Credential", valid_601917
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601918 = header.getOrDefault("x-amz-data-partition")
  valid_601918 = validateParameter(valid_601918, JString, required = true,
                                 default = nil)
  if valid_601918 != nil:
    section.add "x-amz-data-partition", valid_601918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601920: Call_RemoveFacetFromObject_601908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_601920.validator(path, query, header, formData, body)
  let scheme = call_601920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601920.url(scheme.get, call_601920.host, call_601920.base,
                         call_601920.route, valid.getOrDefault("path"))
  result = hook(call_601920, url, valid)

proc call*(call_601921: Call_RemoveFacetFromObject_601908; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_601922 = newJObject()
  if body != nil:
    body_601922 = body
  result = call_601921.call(nil, nil, nil, nil, body_601922)

var removeFacetFromObject* = Call_RemoveFacetFromObject_601908(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_601909, base: "/",
    url: url_RemoveFacetFromObject_601910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601923 = ref object of OpenApiRestCall_600426
proc url_TagResource_601925(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601924(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601926 = header.getOrDefault("X-Amz-Date")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-Date", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Security-Token")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Security-Token", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Content-Sha256", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Algorithm")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Algorithm", valid_601929
  var valid_601930 = header.getOrDefault("X-Amz-Signature")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Signature", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-SignedHeaders", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-Credential")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Credential", valid_601932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601934: Call_TagResource_601923; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_601934.validator(path, query, header, formData, body)
  let scheme = call_601934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601934.url(scheme.get, call_601934.host, call_601934.base,
                         call_601934.route, valid.getOrDefault("path"))
  result = hook(call_601934, url, valid)

proc call*(call_601935: Call_TagResource_601923; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_601936 = newJObject()
  if body != nil:
    body_601936 = body
  result = call_601935.call(nil, nil, nil, nil, body_601936)

var tagResource* = Call_TagResource_601923(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_601924,
                                        base: "/", url: url_TagResource_601925,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601937 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601939(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601938(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601940 = header.getOrDefault("X-Amz-Date")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-Date", valid_601940
  var valid_601941 = header.getOrDefault("X-Amz-Security-Token")
  valid_601941 = validateParameter(valid_601941, JString, required = false,
                                 default = nil)
  if valid_601941 != nil:
    section.add "X-Amz-Security-Token", valid_601941
  var valid_601942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "X-Amz-Content-Sha256", valid_601942
  var valid_601943 = header.getOrDefault("X-Amz-Algorithm")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "X-Amz-Algorithm", valid_601943
  var valid_601944 = header.getOrDefault("X-Amz-Signature")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "X-Amz-Signature", valid_601944
  var valid_601945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "X-Amz-SignedHeaders", valid_601945
  var valid_601946 = header.getOrDefault("X-Amz-Credential")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Credential", valid_601946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601948: Call_UntagResource_601937; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_601948.validator(path, query, header, formData, body)
  let scheme = call_601948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601948.url(scheme.get, call_601948.host, call_601948.base,
                         call_601948.route, valid.getOrDefault("path"))
  result = hook(call_601948, url, valid)

proc call*(call_601949: Call_UntagResource_601937; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_601950 = newJObject()
  if body != nil:
    body_601950 = body
  result = call_601949.call(nil, nil, nil, nil, body_601950)

var untagResource* = Call_UntagResource_601937(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_601938, base: "/", url: url_UntagResource_601939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_601951 = ref object of OpenApiRestCall_600426
proc url_UpdateLinkAttributes_601953(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateLinkAttributes_601952(path: JsonNode; query: JsonNode;
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
  var valid_601954 = header.getOrDefault("X-Amz-Date")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Date", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Security-Token")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Security-Token", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Content-Sha256", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Algorithm")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Algorithm", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Signature")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Signature", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-SignedHeaders", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-Credential")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Credential", valid_601960
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601961 = header.getOrDefault("x-amz-data-partition")
  valid_601961 = validateParameter(valid_601961, JString, required = true,
                                 default = nil)
  if valid_601961 != nil:
    section.add "x-amz-data-partition", valid_601961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601963: Call_UpdateLinkAttributes_601951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_601963.validator(path, query, header, formData, body)
  let scheme = call_601963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601963.url(scheme.get, call_601963.host, call_601963.base,
                         call_601963.route, valid.getOrDefault("path"))
  result = hook(call_601963, url, valid)

proc call*(call_601964: Call_UpdateLinkAttributes_601951; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_601965 = newJObject()
  if body != nil:
    body_601965 = body
  result = call_601964.call(nil, nil, nil, nil, body_601965)

var updateLinkAttributes* = Call_UpdateLinkAttributes_601951(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_601952, base: "/",
    url: url_UpdateLinkAttributes_601953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_601966 = ref object of OpenApiRestCall_600426
proc url_UpdateObjectAttributes_601968(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateObjectAttributes_601967(path: JsonNode; query: JsonNode;
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
  var valid_601969 = header.getOrDefault("X-Amz-Date")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Date", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Security-Token")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Security-Token", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Content-Sha256", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Algorithm")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Algorithm", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Signature")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Signature", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-SignedHeaders", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Credential")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Credential", valid_601975
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601976 = header.getOrDefault("x-amz-data-partition")
  valid_601976 = validateParameter(valid_601976, JString, required = true,
                                 default = nil)
  if valid_601976 != nil:
    section.add "x-amz-data-partition", valid_601976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601978: Call_UpdateObjectAttributes_601966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_601978.validator(path, query, header, formData, body)
  let scheme = call_601978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601978.url(scheme.get, call_601978.host, call_601978.base,
                         call_601978.route, valid.getOrDefault("path"))
  result = hook(call_601978, url, valid)

proc call*(call_601979: Call_UpdateObjectAttributes_601966; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_601980 = newJObject()
  if body != nil:
    body_601980 = body
  result = call_601979.call(nil, nil, nil, nil, body_601980)

var updateObjectAttributes* = Call_UpdateObjectAttributes_601966(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_601967, base: "/",
    url: url_UpdateObjectAttributes_601968, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_601981 = ref object of OpenApiRestCall_600426
proc url_UpdateSchema_601983(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSchema_601982(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601984 = header.getOrDefault("X-Amz-Date")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Date", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Security-Token")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Security-Token", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Content-Sha256", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Algorithm")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Algorithm", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Signature")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Signature", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-SignedHeaders", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601991 = header.getOrDefault("x-amz-data-partition")
  valid_601991 = validateParameter(valid_601991, JString, required = true,
                                 default = nil)
  if valid_601991 != nil:
    section.add "x-amz-data-partition", valid_601991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_UpdateSchema_601981; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"))
  result = hook(call_601993, url, valid)

proc call*(call_601994: Call_UpdateSchema_601981; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_601995 = newJObject()
  if body != nil:
    body_601995 = body
  result = call_601994.call(nil, nil, nil, nil, body_601995)

var updateSchema* = Call_UpdateSchema_601981(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_601982, base: "/", url: url_UpdateSchema_601983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_601996 = ref object of OpenApiRestCall_600426
proc url_UpdateTypedLinkFacet_601998(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTypedLinkFacet_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Date")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Date", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Security-Token")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Security-Token", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Algorithm")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Algorithm", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-SignedHeaders", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Credential")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Credential", valid_602005
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602006 = header.getOrDefault("x-amz-data-partition")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "x-amz-data-partition", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_UpdateTypedLinkFacet_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"))
  result = hook(call_602008, url, valid)

proc call*(call_602009: Call_UpdateTypedLinkFacet_601996; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_601996(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_601997, base: "/",
    url: url_UpdateTypedLinkFacet_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_602011 = ref object of OpenApiRestCall_600426
proc url_UpgradeAppliedSchema_602013(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradeAppliedSchema_602012(path: JsonNode; query: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Date")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Date", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Security-Token")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Security-Token", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Algorithm")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Algorithm", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Signature")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Signature", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-SignedHeaders", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Credential")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Credential", valid_602020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602022: Call_UpgradeAppliedSchema_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_602022.validator(path, query, header, formData, body)
  let scheme = call_602022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602022.url(scheme.get, call_602022.host, call_602022.base,
                         call_602022.route, valid.getOrDefault("path"))
  result = hook(call_602022, url, valid)

proc call*(call_602023: Call_UpgradeAppliedSchema_602011; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_602024 = newJObject()
  if body != nil:
    body_602024 = body
  result = call_602023.call(nil, nil, nil, nil, body_602024)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_602011(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_602012, base: "/",
    url: url_UpgradeAppliedSchema_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_602025 = ref object of OpenApiRestCall_600426
proc url_UpgradePublishedSchema_602027(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradePublishedSchema_602026(path: JsonNode; query: JsonNode;
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
  var valid_602028 = header.getOrDefault("X-Amz-Date")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Date", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Security-Token")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Security-Token", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Content-Sha256", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Algorithm")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Algorithm", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Signature")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Signature", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602036: Call_UpgradePublishedSchema_602025; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_602036.validator(path, query, header, formData, body)
  let scheme = call_602036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602036.url(scheme.get, call_602036.host, call_602036.base,
                         call_602036.route, valid.getOrDefault("path"))
  result = hook(call_602036, url, valid)

proc call*(call_602037: Call_UpgradePublishedSchema_602025; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_602038 = newJObject()
  if body != nil:
    body_602038 = body
  result = call_602037.call(nil, nil, nil, nil, body_602038)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_602025(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_602026, base: "/",
    url: url_UpgradePublishedSchema_602027, schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
