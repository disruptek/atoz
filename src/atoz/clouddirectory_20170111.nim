
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFacetToObject_600774 = ref object of OpenApiRestCall_600437
proc url_AddFacetToObject_600776(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddFacetToObject_600775(path: JsonNode; query: JsonNode;
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
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Content-Sha256", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Algorithm")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Algorithm", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Signature")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Signature", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-SignedHeaders", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Credential")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Credential", valid_600894
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600895 = header.getOrDefault("x-amz-data-partition")
  valid_600895 = validateParameter(valid_600895, JString, required = true,
                                 default = nil)
  if valid_600895 != nil:
    section.add "x-amz-data-partition", valid_600895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600919: Call_AddFacetToObject_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_600919.validator(path, query, header, formData, body)
  let scheme = call_600919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600919.url(scheme.get, call_600919.host, call_600919.base,
                         call_600919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600919, url, valid)

proc call*(call_600990: Call_AddFacetToObject_600774; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_600991 = newJObject()
  if body != nil:
    body_600991 = body
  result = call_600990.call(nil, nil, nil, nil, body_600991)

var addFacetToObject* = Call_AddFacetToObject_600774(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_600775, base: "/",
    url: url_AddFacetToObject_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_601030 = ref object of OpenApiRestCall_600437
proc url_ApplySchema_601032(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApplySchema_601031(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601033 = header.getOrDefault("X-Amz-Date")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Date", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Security-Token")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Security-Token", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Content-Sha256", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Algorithm")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Algorithm", valid_601036
  var valid_601037 = header.getOrDefault("X-Amz-Signature")
  valid_601037 = validateParameter(valid_601037, JString, required = false,
                                 default = nil)
  if valid_601037 != nil:
    section.add "X-Amz-Signature", valid_601037
  var valid_601038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-SignedHeaders", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Credential")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Credential", valid_601039
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601040 = header.getOrDefault("x-amz-data-partition")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "x-amz-data-partition", valid_601040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601042: Call_ApplySchema_601030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_601042.validator(path, query, header, formData, body)
  let scheme = call_601042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601042.url(scheme.get, call_601042.host, call_601042.base,
                         call_601042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601042, url, valid)

proc call*(call_601043: Call_ApplySchema_601030; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_601044 = newJObject()
  if body != nil:
    body_601044 = body
  result = call_601043.call(nil, nil, nil, nil, body_601044)

var applySchema* = Call_ApplySchema_601030(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_601031,
                                        base: "/", url: url_ApplySchema_601032,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_601045 = ref object of OpenApiRestCall_600437
proc url_AttachObject_601047(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachObject_601046(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601048 = header.getOrDefault("X-Amz-Date")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Date", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Security-Token")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Security-Token", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Content-Sha256", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Algorithm")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Algorithm", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Signature")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Signature", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-SignedHeaders", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Credential")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Credential", valid_601054
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601055 = header.getOrDefault("x-amz-data-partition")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = nil)
  if valid_601055 != nil:
    section.add "x-amz-data-partition", valid_601055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601057: Call_AttachObject_601045; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_601057.validator(path, query, header, formData, body)
  let scheme = call_601057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601057.url(scheme.get, call_601057.host, call_601057.base,
                         call_601057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601057, url, valid)

proc call*(call_601058: Call_AttachObject_601045; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_601059 = newJObject()
  if body != nil:
    body_601059 = body
  result = call_601058.call(nil, nil, nil, nil, body_601059)

var attachObject* = Call_AttachObject_601045(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_601046, base: "/", url: url_AttachObject_601047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_601060 = ref object of OpenApiRestCall_600437
proc url_AttachPolicy_601062(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachPolicy_601061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601063 = header.getOrDefault("X-Amz-Date")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Date", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Security-Token")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Security-Token", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Content-Sha256", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Algorithm")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Algorithm", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Signature")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Signature", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-SignedHeaders", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Credential")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Credential", valid_601069
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601070 = header.getOrDefault("x-amz-data-partition")
  valid_601070 = validateParameter(valid_601070, JString, required = true,
                                 default = nil)
  if valid_601070 != nil:
    section.add "x-amz-data-partition", valid_601070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601072: Call_AttachPolicy_601060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_601072.validator(path, query, header, formData, body)
  let scheme = call_601072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601072.url(scheme.get, call_601072.host, call_601072.base,
                         call_601072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601072, url, valid)

proc call*(call_601073: Call_AttachPolicy_601060; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_601074 = newJObject()
  if body != nil:
    body_601074 = body
  result = call_601073.call(nil, nil, nil, nil, body_601074)

var attachPolicy* = Call_AttachPolicy_601060(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_601061, base: "/", url: url_AttachPolicy_601062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_601075 = ref object of OpenApiRestCall_600437
proc url_AttachToIndex_601077(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachToIndex_601076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601078 = header.getOrDefault("X-Amz-Date")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Date", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Security-Token")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Security-Token", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Content-Sha256", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Algorithm")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Algorithm", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Signature")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Signature", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-SignedHeaders", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Credential")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Credential", valid_601084
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601085 = header.getOrDefault("x-amz-data-partition")
  valid_601085 = validateParameter(valid_601085, JString, required = true,
                                 default = nil)
  if valid_601085 != nil:
    section.add "x-amz-data-partition", valid_601085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601087: Call_AttachToIndex_601075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_601087.validator(path, query, header, formData, body)
  let scheme = call_601087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601087.url(scheme.get, call_601087.host, call_601087.base,
                         call_601087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601087, url, valid)

proc call*(call_601088: Call_AttachToIndex_601075; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_601089 = newJObject()
  if body != nil:
    body_601089 = body
  result = call_601088.call(nil, nil, nil, nil, body_601089)

var attachToIndex* = Call_AttachToIndex_601075(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_601076, base: "/", url: url_AttachToIndex_601077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_601090 = ref object of OpenApiRestCall_600437
proc url_AttachTypedLink_601092(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachTypedLink_601091(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601100 = header.getOrDefault("x-amz-data-partition")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = nil)
  if valid_601100 != nil:
    section.add "x-amz-data-partition", valid_601100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_AttachTypedLink_601090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601102, url, valid)

proc call*(call_601103: Call_AttachTypedLink_601090; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601104 = newJObject()
  if body != nil:
    body_601104 = body
  result = call_601103.call(nil, nil, nil, nil, body_601104)

var attachTypedLink* = Call_AttachTypedLink_601090(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_601091, base: "/", url: url_AttachTypedLink_601092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_601105 = ref object of OpenApiRestCall_600437
proc url_BatchRead_601107(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchRead_601106(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601108 = header.getOrDefault("X-Amz-Date")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Date", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Security-Token")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Security-Token", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601127 = header.getOrDefault("x-amz-consistency-level")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601127 != nil:
    section.add "x-amz-consistency-level", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601129 = header.getOrDefault("x-amz-data-partition")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = nil)
  if valid_601129 != nil:
    section.add "x-amz-data-partition", valid_601129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601131: Call_BatchRead_601105; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_601131.validator(path, query, header, formData, body)
  let scheme = call_601131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601131.url(scheme.get, call_601131.host, call_601131.base,
                         call_601131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601131, url, valid)

proc call*(call_601132: Call_BatchRead_601105; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_601133 = newJObject()
  if body != nil:
    body_601133 = body
  result = call_601132.call(nil, nil, nil, nil, body_601133)

var batchRead* = Call_BatchRead_601105(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_601106,
                                    base: "/", url: url_BatchRead_601107,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_601134 = ref object of OpenApiRestCall_600437
proc url_BatchWrite_601136(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchWrite_601135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601144 = header.getOrDefault("x-amz-data-partition")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = nil)
  if valid_601144 != nil:
    section.add "x-amz-data-partition", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_BatchWrite_601134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_BatchWrite_601134; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_601148 = newJObject()
  if body != nil:
    body_601148 = body
  result = call_601147.call(nil, nil, nil, nil, body_601148)

var batchWrite* = Call_BatchWrite_601134(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_601135,
                                      base: "/", url: url_BatchWrite_601136,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_601149 = ref object of OpenApiRestCall_600437
proc url_CreateDirectory_601151(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDirectory_601150(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601159 = header.getOrDefault("x-amz-data-partition")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = nil)
  if valid_601159 != nil:
    section.add "x-amz-data-partition", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_CreateDirectory_601149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_CreateDirectory_601149; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601163 = newJObject()
  if body != nil:
    body_601163 = body
  result = call_601162.call(nil, nil, nil, nil, body_601163)

var createDirectory* = Call_CreateDirectory_601149(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_601150, base: "/", url: url_CreateDirectory_601151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_601164 = ref object of OpenApiRestCall_600437
proc url_CreateFacet_601166(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFacet_601165(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601174 = header.getOrDefault("x-amz-data-partition")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "x-amz-data-partition", valid_601174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_CreateFacet_601164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_CreateFacet_601164; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_601178 = newJObject()
  if body != nil:
    body_601178 = body
  result = call_601177.call(nil, nil, nil, nil, body_601178)

var createFacet* = Call_CreateFacet_601164(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_601165,
                                        base: "/", url: url_CreateFacet_601166,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_601179 = ref object of OpenApiRestCall_600437
proc url_CreateIndex_601181(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIndex_601180(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601189 = header.getOrDefault("x-amz-data-partition")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "x-amz-data-partition", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_CreateIndex_601179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_CreateIndex_601179; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ##   body: JObject (required)
  var body_601193 = newJObject()
  if body != nil:
    body_601193 = body
  result = call_601192.call(nil, nil, nil, nil, body_601193)

var createIndex* = Call_CreateIndex_601179(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_601180,
                                        base: "/", url: url_CreateIndex_601181,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_601194 = ref object of OpenApiRestCall_600437
proc url_CreateObject_601196(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateObject_601195(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601204 = header.getOrDefault("x-amz-data-partition")
  valid_601204 = validateParameter(valid_601204, JString, required = true,
                                 default = nil)
  if valid_601204 != nil:
    section.add "x-amz-data-partition", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_CreateObject_601194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_CreateObject_601194; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_601208 = newJObject()
  if body != nil:
    body_601208 = body
  result = call_601207.call(nil, nil, nil, nil, body_601208)

var createObject* = Call_CreateObject_601194(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_601195, base: "/", url: url_CreateObject_601196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_601209 = ref object of OpenApiRestCall_600437
proc url_CreateSchema_601211(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSchema_601210(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_CreateSchema_601209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_CreateSchema_601209; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_601222 = newJObject()
  if body != nil:
    body_601222 = body
  result = call_601221.call(nil, nil, nil, nil, body_601222)

var createSchema* = Call_CreateSchema_601209(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_601210, base: "/", url: url_CreateSchema_601211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_601223 = ref object of OpenApiRestCall_600437
proc url_CreateTypedLinkFacet_601225(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTypedLinkFacet_601224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Content-Sha256", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Algorithm")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Algorithm", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Signature")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Signature", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-SignedHeaders", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Credential")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Credential", valid_601232
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601233 = header.getOrDefault("x-amz-data-partition")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "x-amz-data-partition", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_CreateTypedLinkFacet_601223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_CreateTypedLinkFacet_601223; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601237 = newJObject()
  if body != nil:
    body_601237 = body
  result = call_601236.call(nil, nil, nil, nil, body_601237)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_601223(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_601224, base: "/",
    url: url_CreateTypedLinkFacet_601225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_601238 = ref object of OpenApiRestCall_600437
proc url_DeleteDirectory_601240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDirectory_601239(path: JsonNode; query: JsonNode;
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
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Content-Sha256", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Algorithm")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Algorithm", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Signature")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Signature", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-SignedHeaders", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Credential")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Credential", valid_601247
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601248 = header.getOrDefault("x-amz-data-partition")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = nil)
  if valid_601248 != nil:
    section.add "x-amz-data-partition", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601249: Call_DeleteDirectory_601238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_601249.validator(path, query, header, formData, body)
  let scheme = call_601249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601249.url(scheme.get, call_601249.host, call_601249.base,
                         call_601249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601249, url, valid)

proc call*(call_601250: Call_DeleteDirectory_601238): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_601250.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_601238(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_601239, base: "/", url: url_DeleteDirectory_601240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_601251 = ref object of OpenApiRestCall_600437
proc url_DeleteFacet_601253(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFacet_601252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601254 = header.getOrDefault("X-Amz-Date")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Date", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Security-Token")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Security-Token", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Content-Sha256", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Algorithm")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Algorithm", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Signature")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Signature", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-SignedHeaders", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Credential")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Credential", valid_601260
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601261 = header.getOrDefault("x-amz-data-partition")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = nil)
  if valid_601261 != nil:
    section.add "x-amz-data-partition", valid_601261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601263: Call_DeleteFacet_601251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_601263.validator(path, query, header, formData, body)
  let scheme = call_601263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601263.url(scheme.get, call_601263.host, call_601263.base,
                         call_601263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601263, url, valid)

proc call*(call_601264: Call_DeleteFacet_601251; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_601265 = newJObject()
  if body != nil:
    body_601265 = body
  result = call_601264.call(nil, nil, nil, nil, body_601265)

var deleteFacet* = Call_DeleteFacet_601251(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_601252,
                                        base: "/", url: url_DeleteFacet_601253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_601266 = ref object of OpenApiRestCall_600437
proc url_DeleteObject_601268(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteObject_601267(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601269 = header.getOrDefault("X-Amz-Date")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Date", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Security-Token")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Security-Token", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Content-Sha256", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Algorithm")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Algorithm", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Signature")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Signature", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-SignedHeaders", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Credential")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Credential", valid_601275
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601276 = header.getOrDefault("x-amz-data-partition")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = nil)
  if valid_601276 != nil:
    section.add "x-amz-data-partition", valid_601276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601278: Call_DeleteObject_601266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ## 
  let valid = call_601278.validator(path, query, header, formData, body)
  let scheme = call_601278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601278.url(scheme.get, call_601278.host, call_601278.base,
                         call_601278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601278, url, valid)

proc call*(call_601279: Call_DeleteObject_601266; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ##   body: JObject (required)
  var body_601280 = newJObject()
  if body != nil:
    body_601280 = body
  result = call_601279.call(nil, nil, nil, nil, body_601280)

var deleteObject* = Call_DeleteObject_601266(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_601267, base: "/", url: url_DeleteObject_601268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_601281 = ref object of OpenApiRestCall_600437
proc url_DeleteSchema_601283(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSchema_601282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601284 = header.getOrDefault("X-Amz-Date")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Date", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Security-Token")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Security-Token", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Content-Sha256", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Algorithm")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Algorithm", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Signature")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Signature", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-SignedHeaders", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Credential")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Credential", valid_601290
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601291 = header.getOrDefault("x-amz-data-partition")
  valid_601291 = validateParameter(valid_601291, JString, required = true,
                                 default = nil)
  if valid_601291 != nil:
    section.add "x-amz-data-partition", valid_601291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601292: Call_DeleteSchema_601281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_601292.validator(path, query, header, formData, body)
  let scheme = call_601292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601292.url(scheme.get, call_601292.host, call_601292.base,
                         call_601292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601292, url, valid)

proc call*(call_601293: Call_DeleteSchema_601281): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_601293.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_601281(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_601282, base: "/", url: url_DeleteSchema_601283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_601294 = ref object of OpenApiRestCall_600437
proc url_DeleteTypedLinkFacet_601296(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTypedLinkFacet_601295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601297 = header.getOrDefault("X-Amz-Date")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Date", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Security-Token")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Security-Token", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Content-Sha256", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Algorithm")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Algorithm", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Signature")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Signature", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-SignedHeaders", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Credential")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Credential", valid_601303
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601304 = header.getOrDefault("x-amz-data-partition")
  valid_601304 = validateParameter(valid_601304, JString, required = true,
                                 default = nil)
  if valid_601304 != nil:
    section.add "x-amz-data-partition", valid_601304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601306: Call_DeleteTypedLinkFacet_601294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601306.validator(path, query, header, formData, body)
  let scheme = call_601306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601306.url(scheme.get, call_601306.host, call_601306.base,
                         call_601306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601306, url, valid)

proc call*(call_601307: Call_DeleteTypedLinkFacet_601294; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601308 = newJObject()
  if body != nil:
    body_601308 = body
  result = call_601307.call(nil, nil, nil, nil, body_601308)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_601294(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_601295, base: "/",
    url: url_DeleteTypedLinkFacet_601296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_601309 = ref object of OpenApiRestCall_600437
proc url_DetachFromIndex_601311(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachFromIndex_601310(path: JsonNode; query: JsonNode;
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
  var valid_601312 = header.getOrDefault("X-Amz-Date")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Date", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Security-Token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Security-Token", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Content-Sha256", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Algorithm")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Algorithm", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Signature")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Signature", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-SignedHeaders", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Credential")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Credential", valid_601318
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601319 = header.getOrDefault("x-amz-data-partition")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "x-amz-data-partition", valid_601319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_DetachFromIndex_601309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_DetachFromIndex_601309; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_601323 = newJObject()
  if body != nil:
    body_601323 = body
  result = call_601322.call(nil, nil, nil, nil, body_601323)

var detachFromIndex* = Call_DetachFromIndex_601309(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_601310, base: "/", url: url_DetachFromIndex_601311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_601324 = ref object of OpenApiRestCall_600437
proc url_DetachObject_601326(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachObject_601325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601327 = header.getOrDefault("X-Amz-Date")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Date", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Security-Token")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Security-Token", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Content-Sha256", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Algorithm")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Algorithm", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Signature")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Signature", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-SignedHeaders", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Credential")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Credential", valid_601333
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601334 = header.getOrDefault("x-amz-data-partition")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "x-amz-data-partition", valid_601334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601336: Call_DetachObject_601324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_601336.validator(path, query, header, formData, body)
  let scheme = call_601336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601336.url(scheme.get, call_601336.host, call_601336.base,
                         call_601336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601336, url, valid)

proc call*(call_601337: Call_DetachObject_601324; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_601338 = newJObject()
  if body != nil:
    body_601338 = body
  result = call_601337.call(nil, nil, nil, nil, body_601338)

var detachObject* = Call_DetachObject_601324(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_601325, base: "/", url: url_DetachObject_601326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_601339 = ref object of OpenApiRestCall_600437
proc url_DetachPolicy_601341(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachPolicy_601340(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601342 = header.getOrDefault("X-Amz-Date")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Date", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Security-Token")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Security-Token", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Content-Sha256", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Algorithm")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Algorithm", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Signature")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Signature", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-SignedHeaders", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Credential")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Credential", valid_601348
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601349 = header.getOrDefault("x-amz-data-partition")
  valid_601349 = validateParameter(valid_601349, JString, required = true,
                                 default = nil)
  if valid_601349 != nil:
    section.add "x-amz-data-partition", valid_601349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601351: Call_DetachPolicy_601339; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_601351.validator(path, query, header, formData, body)
  let scheme = call_601351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601351.url(scheme.get, call_601351.host, call_601351.base,
                         call_601351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601351, url, valid)

proc call*(call_601352: Call_DetachPolicy_601339; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_601353 = newJObject()
  if body != nil:
    body_601353 = body
  result = call_601352.call(nil, nil, nil, nil, body_601353)

var detachPolicy* = Call_DetachPolicy_601339(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_601340, base: "/", url: url_DetachPolicy_601341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_601354 = ref object of OpenApiRestCall_600437
proc url_DetachTypedLink_601356(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachTypedLink_601355(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601364 = header.getOrDefault("x-amz-data-partition")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = nil)
  if valid_601364 != nil:
    section.add "x-amz-data-partition", valid_601364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_DetachTypedLink_601354; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601366, url, valid)

proc call*(call_601367: Call_DetachTypedLink_601354; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601368 = newJObject()
  if body != nil:
    body_601368 = body
  result = call_601367.call(nil, nil, nil, nil, body_601368)

var detachTypedLink* = Call_DetachTypedLink_601354(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_601355, base: "/", url: url_DetachTypedLink_601356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_601369 = ref object of OpenApiRestCall_600437
proc url_DisableDirectory_601371(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableDirectory_601370(path: JsonNode; query: JsonNode;
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
  var valid_601372 = header.getOrDefault("X-Amz-Date")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Date", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Security-Token")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Security-Token", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Content-Sha256", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Algorithm")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Algorithm", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Signature")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Signature", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-SignedHeaders", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Credential")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Credential", valid_601378
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601379 = header.getOrDefault("x-amz-data-partition")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = nil)
  if valid_601379 != nil:
    section.add "x-amz-data-partition", valid_601379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601380: Call_DisableDirectory_601369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_601380.validator(path, query, header, formData, body)
  let scheme = call_601380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601380.url(scheme.get, call_601380.host, call_601380.base,
                         call_601380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601380, url, valid)

proc call*(call_601381: Call_DisableDirectory_601369): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_601381.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_601369(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_601370, base: "/",
    url: url_DisableDirectory_601371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_601382 = ref object of OpenApiRestCall_600437
proc url_EnableDirectory_601384(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableDirectory_601383(path: JsonNode; query: JsonNode;
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
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Content-Sha256", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Algorithm")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Algorithm", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Signature")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Signature", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-SignedHeaders", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Credential")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Credential", valid_601391
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601392 = header.getOrDefault("x-amz-data-partition")
  valid_601392 = validateParameter(valid_601392, JString, required = true,
                                 default = nil)
  if valid_601392 != nil:
    section.add "x-amz-data-partition", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601393: Call_EnableDirectory_601382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_601393.validator(path, query, header, formData, body)
  let scheme = call_601393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601393.url(scheme.get, call_601393.host, call_601393.base,
                         call_601393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601393, url, valid)

proc call*(call_601394: Call_EnableDirectory_601382): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_601394.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_601382(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_601383, base: "/", url: url_EnableDirectory_601384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_601395 = ref object of OpenApiRestCall_600437
proc url_GetAppliedSchemaVersion_601397(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAppliedSchemaVersion_601396(path: JsonNode; query: JsonNode;
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
  var valid_601398 = header.getOrDefault("X-Amz-Date")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Date", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Security-Token")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Security-Token", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Content-Sha256", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Algorithm")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Algorithm", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Signature")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Signature", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-SignedHeaders", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Credential")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Credential", valid_601404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601406: Call_GetAppliedSchemaVersion_601395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_601406.validator(path, query, header, formData, body)
  let scheme = call_601406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601406.url(scheme.get, call_601406.host, call_601406.base,
                         call_601406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601406, url, valid)

proc call*(call_601407: Call_GetAppliedSchemaVersion_601395; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_601408 = newJObject()
  if body != nil:
    body_601408 = body
  result = call_601407.call(nil, nil, nil, nil, body_601408)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_601395(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_601396, base: "/",
    url: url_GetAppliedSchemaVersion_601397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_601409 = ref object of OpenApiRestCall_600437
proc url_GetDirectory_601411(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDirectory_601410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601412 = header.getOrDefault("X-Amz-Date")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Date", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Security-Token")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Security-Token", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Content-Sha256", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Algorithm")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Algorithm", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Signature")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Signature", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-SignedHeaders", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Credential")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Credential", valid_601418
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601419 = header.getOrDefault("x-amz-data-partition")
  valid_601419 = validateParameter(valid_601419, JString, required = true,
                                 default = nil)
  if valid_601419 != nil:
    section.add "x-amz-data-partition", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_GetDirectory_601409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601420, url, valid)

proc call*(call_601421: Call_GetDirectory_601409): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_601421.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_601409(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_601410, base: "/", url: url_GetDirectory_601411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_601422 = ref object of OpenApiRestCall_600437
proc url_UpdateFacet_601424(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFacet_601423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601425 = header.getOrDefault("X-Amz-Date")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Date", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Security-Token")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Security-Token", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Content-Sha256", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Algorithm")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Algorithm", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Signature")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Signature", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-SignedHeaders", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Credential")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Credential", valid_601431
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601432 = header.getOrDefault("x-amz-data-partition")
  valid_601432 = validateParameter(valid_601432, JString, required = true,
                                 default = nil)
  if valid_601432 != nil:
    section.add "x-amz-data-partition", valid_601432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601434: Call_UpdateFacet_601422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_601434.validator(path, query, header, formData, body)
  let scheme = call_601434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601434.url(scheme.get, call_601434.host, call_601434.base,
                         call_601434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601434, url, valid)

proc call*(call_601435: Call_UpdateFacet_601422; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_601436 = newJObject()
  if body != nil:
    body_601436 = body
  result = call_601435.call(nil, nil, nil, nil, body_601436)

var updateFacet* = Call_UpdateFacet_601422(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_601423,
                                        base: "/", url: url_UpdateFacet_601424,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_601437 = ref object of OpenApiRestCall_600437
proc url_GetFacet_601439(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFacet_601438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601440 = header.getOrDefault("X-Amz-Date")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Date", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Security-Token")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Security-Token", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Content-Sha256", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Algorithm")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Algorithm", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Signature")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Signature", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-SignedHeaders", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Credential")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Credential", valid_601446
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601447 = header.getOrDefault("x-amz-data-partition")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = nil)
  if valid_601447 != nil:
    section.add "x-amz-data-partition", valid_601447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601449: Call_GetFacet_601437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_601449.validator(path, query, header, formData, body)
  let scheme = call_601449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601449.url(scheme.get, call_601449.host, call_601449.base,
                         call_601449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601449, url, valid)

proc call*(call_601450: Call_GetFacet_601437; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_601451 = newJObject()
  if body != nil:
    body_601451 = body
  result = call_601450.call(nil, nil, nil, nil, body_601451)

var getFacet* = Call_GetFacet_601437(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_601438, base: "/",
                                  url: url_GetFacet_601439,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_601452 = ref object of OpenApiRestCall_600437
proc url_GetLinkAttributes_601454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLinkAttributes_601453(path: JsonNode; query: JsonNode;
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
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  section = newJObject()
  var valid_601455 = header.getOrDefault("X-Amz-Date")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Date", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Security-Token")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Security-Token", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Content-Sha256", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Algorithm")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Algorithm", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Signature")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Signature", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-SignedHeaders", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Credential")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Credential", valid_601461
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601462 = header.getOrDefault("x-amz-data-partition")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = nil)
  if valid_601462 != nil:
    section.add "x-amz-data-partition", valid_601462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601464: Call_GetLinkAttributes_601452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_601464.validator(path, query, header, formData, body)
  let scheme = call_601464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601464.url(scheme.get, call_601464.host, call_601464.base,
                         call_601464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601464, url, valid)

proc call*(call_601465: Call_GetLinkAttributes_601452; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_601466 = newJObject()
  if body != nil:
    body_601466 = body
  result = call_601465.call(nil, nil, nil, nil, body_601466)

var getLinkAttributes* = Call_GetLinkAttributes_601452(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_601453, base: "/",
    url: url_GetLinkAttributes_601454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_601467 = ref object of OpenApiRestCall_600437
proc url_GetObjectAttributes_601469(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetObjectAttributes_601468(path: JsonNode; query: JsonNode;
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
  var valid_601470 = header.getOrDefault("X-Amz-Date")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Date", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Security-Token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Security-Token", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Content-Sha256", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Algorithm")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Algorithm", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Signature")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Signature", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-SignedHeaders", valid_601475
  var valid_601476 = header.getOrDefault("x-amz-consistency-level")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601476 != nil:
    section.add "x-amz-consistency-level", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Credential")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Credential", valid_601477
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601478 = header.getOrDefault("x-amz-data-partition")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = nil)
  if valid_601478 != nil:
    section.add "x-amz-data-partition", valid_601478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601480: Call_GetObjectAttributes_601467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_601480.validator(path, query, header, formData, body)
  let scheme = call_601480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601480.url(scheme.get, call_601480.host, call_601480.base,
                         call_601480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601480, url, valid)

proc call*(call_601481: Call_GetObjectAttributes_601467; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_601482 = newJObject()
  if body != nil:
    body_601482 = body
  result = call_601481.call(nil, nil, nil, nil, body_601482)

var getObjectAttributes* = Call_GetObjectAttributes_601467(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_601468, base: "/",
    url: url_GetObjectAttributes_601469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_601483 = ref object of OpenApiRestCall_600437
proc url_GetObjectInformation_601485(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetObjectInformation_601484(path: JsonNode; query: JsonNode;
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
  var valid_601486 = header.getOrDefault("X-Amz-Date")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Date", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Security-Token")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Security-Token", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Content-Sha256", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Algorithm")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Algorithm", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Signature")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Signature", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-SignedHeaders", valid_601491
  var valid_601492 = header.getOrDefault("x-amz-consistency-level")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601492 != nil:
    section.add "x-amz-consistency-level", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Credential")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Credential", valid_601493
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601494 = header.getOrDefault("x-amz-data-partition")
  valid_601494 = validateParameter(valid_601494, JString, required = true,
                                 default = nil)
  if valid_601494 != nil:
    section.add "x-amz-data-partition", valid_601494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601496: Call_GetObjectInformation_601483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_601496.validator(path, query, header, formData, body)
  let scheme = call_601496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601496.url(scheme.get, call_601496.host, call_601496.base,
                         call_601496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601496, url, valid)

proc call*(call_601497: Call_GetObjectInformation_601483; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_601498 = newJObject()
  if body != nil:
    body_601498 = body
  result = call_601497.call(nil, nil, nil, nil, body_601498)

var getObjectInformation* = Call_GetObjectInformation_601483(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_601484, base: "/",
    url: url_GetObjectInformation_601485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_601499 = ref object of OpenApiRestCall_600437
proc url_PutSchemaFromJson_601501(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutSchemaFromJson_601500(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601502 = header.getOrDefault("X-Amz-Date")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Date", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Security-Token")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Security-Token", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Content-Sha256", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Algorithm")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Algorithm", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Signature")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Signature", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-SignedHeaders", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Credential")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Credential", valid_601508
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601509 = header.getOrDefault("x-amz-data-partition")
  valid_601509 = validateParameter(valid_601509, JString, required = true,
                                 default = nil)
  if valid_601509 != nil:
    section.add "x-amz-data-partition", valid_601509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601511: Call_PutSchemaFromJson_601499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_601511.validator(path, query, header, formData, body)
  let scheme = call_601511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601511.url(scheme.get, call_601511.host, call_601511.base,
                         call_601511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601511, url, valid)

proc call*(call_601512: Call_PutSchemaFromJson_601499; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_601513 = newJObject()
  if body != nil:
    body_601513 = body
  result = call_601512.call(nil, nil, nil, nil, body_601513)

var putSchemaFromJson* = Call_PutSchemaFromJson_601499(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_601500, base: "/",
    url: url_PutSchemaFromJson_601501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_601514 = ref object of OpenApiRestCall_600437
proc url_GetSchemaAsJson_601516(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSchemaAsJson_601515(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_601517 = header.getOrDefault("X-Amz-Date")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Date", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Security-Token")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Security-Token", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Content-Sha256", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Algorithm")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Algorithm", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Signature")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Signature", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-SignedHeaders", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Credential")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Credential", valid_601523
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601524 = header.getOrDefault("x-amz-data-partition")
  valid_601524 = validateParameter(valid_601524, JString, required = true,
                                 default = nil)
  if valid_601524 != nil:
    section.add "x-amz-data-partition", valid_601524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601525: Call_GetSchemaAsJson_601514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_601525.validator(path, query, header, formData, body)
  let scheme = call_601525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601525.url(scheme.get, call_601525.host, call_601525.base,
                         call_601525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601525, url, valid)

proc call*(call_601526: Call_GetSchemaAsJson_601514): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  result = call_601526.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_601514(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_601515, base: "/", url: url_GetSchemaAsJson_601516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_601527 = ref object of OpenApiRestCall_600437
proc url_GetTypedLinkFacetInformation_601529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTypedLinkFacetInformation_601528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601530 = header.getOrDefault("X-Amz-Date")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Date", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Security-Token")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Security-Token", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Content-Sha256", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Algorithm")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Algorithm", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Signature")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Signature", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-SignedHeaders", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Credential")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Credential", valid_601536
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601537 = header.getOrDefault("x-amz-data-partition")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = nil)
  if valid_601537 != nil:
    section.add "x-amz-data-partition", valid_601537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601539: Call_GetTypedLinkFacetInformation_601527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601539.validator(path, query, header, formData, body)
  let scheme = call_601539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601539.url(scheme.get, call_601539.host, call_601539.base,
                         call_601539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601539, url, valid)

proc call*(call_601540: Call_GetTypedLinkFacetInformation_601527; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601541 = newJObject()
  if body != nil:
    body_601541 = body
  result = call_601540.call(nil, nil, nil, nil, body_601541)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_601527(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_601528, base: "/",
    url: url_GetTypedLinkFacetInformation_601529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_601542 = ref object of OpenApiRestCall_600437
proc url_ListAppliedSchemaArns_601544(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAppliedSchemaArns_601543(path: JsonNode; query: JsonNode;
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
  var valid_601545 = query.getOrDefault("NextToken")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "NextToken", valid_601545
  var valid_601546 = query.getOrDefault("MaxResults")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "MaxResults", valid_601546
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
  var valid_601547 = header.getOrDefault("X-Amz-Date")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Date", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Security-Token")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Security-Token", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Content-Sha256", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Algorithm")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Algorithm", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Signature")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Signature", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-SignedHeaders", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Credential")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Credential", valid_601553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601555: Call_ListAppliedSchemaArns_601542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_601555.validator(path, query, header, formData, body)
  let scheme = call_601555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601555.url(scheme.get, call_601555.host, call_601555.base,
                         call_601555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601555, url, valid)

proc call*(call_601556: Call_ListAppliedSchemaArns_601542; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601557 = newJObject()
  var body_601558 = newJObject()
  add(query_601557, "NextToken", newJString(NextToken))
  if body != nil:
    body_601558 = body
  add(query_601557, "MaxResults", newJString(MaxResults))
  result = call_601556.call(nil, query_601557, nil, nil, body_601558)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_601542(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_601543, base: "/",
    url: url_ListAppliedSchemaArns_601544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_601560 = ref object of OpenApiRestCall_600437
proc url_ListAttachedIndices_601562(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAttachedIndices_601561(path: JsonNode; query: JsonNode;
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
  var valid_601563 = query.getOrDefault("NextToken")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "NextToken", valid_601563
  var valid_601564 = query.getOrDefault("MaxResults")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "MaxResults", valid_601564
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
  var valid_601565 = header.getOrDefault("X-Amz-Date")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Date", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Security-Token")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Security-Token", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Content-Sha256", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Algorithm")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Algorithm", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Signature")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Signature", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-SignedHeaders", valid_601570
  var valid_601571 = header.getOrDefault("x-amz-consistency-level")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601571 != nil:
    section.add "x-amz-consistency-level", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Credential")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Credential", valid_601572
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601573 = header.getOrDefault("x-amz-data-partition")
  valid_601573 = validateParameter(valid_601573, JString, required = true,
                                 default = nil)
  if valid_601573 != nil:
    section.add "x-amz-data-partition", valid_601573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601575: Call_ListAttachedIndices_601560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_601575.validator(path, query, header, formData, body)
  let scheme = call_601575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601575.url(scheme.get, call_601575.host, call_601575.base,
                         call_601575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601575, url, valid)

proc call*(call_601576: Call_ListAttachedIndices_601560; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601577 = newJObject()
  var body_601578 = newJObject()
  add(query_601577, "NextToken", newJString(NextToken))
  if body != nil:
    body_601578 = body
  add(query_601577, "MaxResults", newJString(MaxResults))
  result = call_601576.call(nil, query_601577, nil, nil, body_601578)

var listAttachedIndices* = Call_ListAttachedIndices_601560(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_601561, base: "/",
    url: url_ListAttachedIndices_601562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_601579 = ref object of OpenApiRestCall_600437
proc url_ListDevelopmentSchemaArns_601581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevelopmentSchemaArns_601580(path: JsonNode; query: JsonNode;
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
  var valid_601582 = query.getOrDefault("NextToken")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "NextToken", valid_601582
  var valid_601583 = query.getOrDefault("MaxResults")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "MaxResults", valid_601583
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
  var valid_601584 = header.getOrDefault("X-Amz-Date")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Date", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Security-Token")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Security-Token", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Content-Sha256", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Algorithm")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Algorithm", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Signature")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Signature", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-SignedHeaders", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Credential")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Credential", valid_601590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601592: Call_ListDevelopmentSchemaArns_601579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_601592.validator(path, query, header, formData, body)
  let scheme = call_601592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601592.url(scheme.get, call_601592.host, call_601592.base,
                         call_601592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601592, url, valid)

proc call*(call_601593: Call_ListDevelopmentSchemaArns_601579; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601594 = newJObject()
  var body_601595 = newJObject()
  add(query_601594, "NextToken", newJString(NextToken))
  if body != nil:
    body_601595 = body
  add(query_601594, "MaxResults", newJString(MaxResults))
  result = call_601593.call(nil, query_601594, nil, nil, body_601595)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_601579(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_601580, base: "/",
    url: url_ListDevelopmentSchemaArns_601581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_601596 = ref object of OpenApiRestCall_600437
proc url_ListDirectories_601598(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDirectories_601597(path: JsonNode; query: JsonNode;
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
  var valid_601599 = query.getOrDefault("NextToken")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "NextToken", valid_601599
  var valid_601600 = query.getOrDefault("MaxResults")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "MaxResults", valid_601600
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
  var valid_601601 = header.getOrDefault("X-Amz-Date")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Date", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Security-Token")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Security-Token", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Content-Sha256", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Algorithm")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Algorithm", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Signature")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Signature", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-SignedHeaders", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Credential")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Credential", valid_601607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601609: Call_ListDirectories_601596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_601609.validator(path, query, header, formData, body)
  let scheme = call_601609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601609.url(scheme.get, call_601609.host, call_601609.base,
                         call_601609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601609, url, valid)

proc call*(call_601610: Call_ListDirectories_601596; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601611 = newJObject()
  var body_601612 = newJObject()
  add(query_601611, "NextToken", newJString(NextToken))
  if body != nil:
    body_601612 = body
  add(query_601611, "MaxResults", newJString(MaxResults))
  result = call_601610.call(nil, query_601611, nil, nil, body_601612)

var listDirectories* = Call_ListDirectories_601596(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_601597, base: "/", url: url_ListDirectories_601598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_601613 = ref object of OpenApiRestCall_600437
proc url_ListFacetAttributes_601615(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFacetAttributes_601614(path: JsonNode; query: JsonNode;
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
  var valid_601616 = query.getOrDefault("NextToken")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "NextToken", valid_601616
  var valid_601617 = query.getOrDefault("MaxResults")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "MaxResults", valid_601617
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
  var valid_601618 = header.getOrDefault("X-Amz-Date")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Date", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Security-Token")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Security-Token", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Content-Sha256", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Algorithm")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Algorithm", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Signature")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Signature", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-SignedHeaders", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Credential")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Credential", valid_601624
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601625 = header.getOrDefault("x-amz-data-partition")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = nil)
  if valid_601625 != nil:
    section.add "x-amz-data-partition", valid_601625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601627: Call_ListFacetAttributes_601613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_601627.validator(path, query, header, formData, body)
  let scheme = call_601627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601627.url(scheme.get, call_601627.host, call_601627.base,
                         call_601627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601627, url, valid)

proc call*(call_601628: Call_ListFacetAttributes_601613; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601629 = newJObject()
  var body_601630 = newJObject()
  add(query_601629, "NextToken", newJString(NextToken))
  if body != nil:
    body_601630 = body
  add(query_601629, "MaxResults", newJString(MaxResults))
  result = call_601628.call(nil, query_601629, nil, nil, body_601630)

var listFacetAttributes* = Call_ListFacetAttributes_601613(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_601614, base: "/",
    url: url_ListFacetAttributes_601615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_601631 = ref object of OpenApiRestCall_600437
proc url_ListFacetNames_601633(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFacetNames_601632(path: JsonNode; query: JsonNode;
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
  var valid_601634 = query.getOrDefault("NextToken")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "NextToken", valid_601634
  var valid_601635 = query.getOrDefault("MaxResults")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "MaxResults", valid_601635
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
  var valid_601636 = header.getOrDefault("X-Amz-Date")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Date", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Security-Token")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Security-Token", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Content-Sha256", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Algorithm")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Algorithm", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Signature")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Signature", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-SignedHeaders", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Credential")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Credential", valid_601642
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601643 = header.getOrDefault("x-amz-data-partition")
  valid_601643 = validateParameter(valid_601643, JString, required = true,
                                 default = nil)
  if valid_601643 != nil:
    section.add "x-amz-data-partition", valid_601643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601645: Call_ListFacetNames_601631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_601645.validator(path, query, header, formData, body)
  let scheme = call_601645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601645.url(scheme.get, call_601645.host, call_601645.base,
                         call_601645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601645, url, valid)

proc call*(call_601646: Call_ListFacetNames_601631; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601647 = newJObject()
  var body_601648 = newJObject()
  add(query_601647, "NextToken", newJString(NextToken))
  if body != nil:
    body_601648 = body
  add(query_601647, "MaxResults", newJString(MaxResults))
  result = call_601646.call(nil, query_601647, nil, nil, body_601648)

var listFacetNames* = Call_ListFacetNames_601631(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_601632, base: "/", url: url_ListFacetNames_601633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_601649 = ref object of OpenApiRestCall_600437
proc url_ListIncomingTypedLinks_601651(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIncomingTypedLinks_601650(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601652 = header.getOrDefault("X-Amz-Date")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Date", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Security-Token")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Security-Token", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Algorithm")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Algorithm", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Signature")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Signature", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-SignedHeaders", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Credential")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Credential", valid_601658
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601659 = header.getOrDefault("x-amz-data-partition")
  valid_601659 = validateParameter(valid_601659, JString, required = true,
                                 default = nil)
  if valid_601659 != nil:
    section.add "x-amz-data-partition", valid_601659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601661: Call_ListIncomingTypedLinks_601649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601661.validator(path, query, header, formData, body)
  let scheme = call_601661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601661.url(scheme.get, call_601661.host, call_601661.base,
                         call_601661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601661, url, valid)

proc call*(call_601662: Call_ListIncomingTypedLinks_601649; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601663 = newJObject()
  if body != nil:
    body_601663 = body
  result = call_601662.call(nil, nil, nil, nil, body_601663)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_601649(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_601650, base: "/",
    url: url_ListIncomingTypedLinks_601651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_601664 = ref object of OpenApiRestCall_600437
proc url_ListIndex_601666(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIndex_601665(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601667 = query.getOrDefault("NextToken")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "NextToken", valid_601667
  var valid_601668 = query.getOrDefault("MaxResults")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "MaxResults", valid_601668
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
  var valid_601669 = header.getOrDefault("X-Amz-Date")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Date", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Security-Token")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Security-Token", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Content-Sha256", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Algorithm")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Algorithm", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Signature")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Signature", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-SignedHeaders", valid_601674
  var valid_601675 = header.getOrDefault("x-amz-consistency-level")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601675 != nil:
    section.add "x-amz-consistency-level", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-Credential")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-Credential", valid_601676
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601677 = header.getOrDefault("x-amz-data-partition")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = nil)
  if valid_601677 != nil:
    section.add "x-amz-data-partition", valid_601677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601679: Call_ListIndex_601664; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_601679.validator(path, query, header, formData, body)
  let scheme = call_601679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601679.url(scheme.get, call_601679.host, call_601679.base,
                         call_601679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601679, url, valid)

proc call*(call_601680: Call_ListIndex_601664; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601681 = newJObject()
  var body_601682 = newJObject()
  add(query_601681, "NextToken", newJString(NextToken))
  if body != nil:
    body_601682 = body
  add(query_601681, "MaxResults", newJString(MaxResults))
  result = call_601680.call(nil, query_601681, nil, nil, body_601682)

var listIndex* = Call_ListIndex_601664(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_601665,
                                    base: "/", url: url_ListIndex_601666,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListManagedSchemaArns_601683 = ref object of OpenApiRestCall_600437
proc url_ListManagedSchemaArns_601685(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListManagedSchemaArns_601684(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601686 = query.getOrDefault("NextToken")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "NextToken", valid_601686
  var valid_601687 = query.getOrDefault("MaxResults")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "MaxResults", valid_601687
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
  var valid_601688 = header.getOrDefault("X-Amz-Date")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Date", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Security-Token")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Security-Token", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Content-Sha256", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Algorithm")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Algorithm", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Signature")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Signature", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-SignedHeaders", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Credential")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Credential", valid_601694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601696: Call_ListManagedSchemaArns_601683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_601696.validator(path, query, header, formData, body)
  let scheme = call_601696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601696.url(scheme.get, call_601696.host, call_601696.base,
                         call_601696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601696, url, valid)

proc call*(call_601697: Call_ListManagedSchemaArns_601683; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listManagedSchemaArns
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601698 = newJObject()
  var body_601699 = newJObject()
  add(query_601698, "NextToken", newJString(NextToken))
  if body != nil:
    body_601699 = body
  add(query_601698, "MaxResults", newJString(MaxResults))
  result = call_601697.call(nil, query_601698, nil, nil, body_601699)

var listManagedSchemaArns* = Call_ListManagedSchemaArns_601683(
    name: "listManagedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/managed",
    validator: validate_ListManagedSchemaArns_601684, base: "/",
    url: url_ListManagedSchemaArns_601685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_601700 = ref object of OpenApiRestCall_600437
proc url_ListObjectAttributes_601702(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectAttributes_601701(path: JsonNode; query: JsonNode;
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
  var valid_601703 = query.getOrDefault("NextToken")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "NextToken", valid_601703
  var valid_601704 = query.getOrDefault("MaxResults")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "MaxResults", valid_601704
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
  var valid_601705 = header.getOrDefault("X-Amz-Date")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Date", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Security-Token")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Security-Token", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Content-Sha256", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Algorithm")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Algorithm", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Signature")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Signature", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-SignedHeaders", valid_601710
  var valid_601711 = header.getOrDefault("x-amz-consistency-level")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601711 != nil:
    section.add "x-amz-consistency-level", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Credential")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Credential", valid_601712
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601713 = header.getOrDefault("x-amz-data-partition")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = nil)
  if valid_601713 != nil:
    section.add "x-amz-data-partition", valid_601713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601715: Call_ListObjectAttributes_601700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_601715.validator(path, query, header, formData, body)
  let scheme = call_601715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601715.url(scheme.get, call_601715.host, call_601715.base,
                         call_601715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601715, url, valid)

proc call*(call_601716: Call_ListObjectAttributes_601700; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601717 = newJObject()
  var body_601718 = newJObject()
  add(query_601717, "NextToken", newJString(NextToken))
  if body != nil:
    body_601718 = body
  add(query_601717, "MaxResults", newJString(MaxResults))
  result = call_601716.call(nil, query_601717, nil, nil, body_601718)

var listObjectAttributes* = Call_ListObjectAttributes_601700(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_601701, base: "/",
    url: url_ListObjectAttributes_601702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_601719 = ref object of OpenApiRestCall_600437
proc url_ListObjectChildren_601721(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectChildren_601720(path: JsonNode; query: JsonNode;
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
  var valid_601722 = query.getOrDefault("NextToken")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "NextToken", valid_601722
  var valid_601723 = query.getOrDefault("MaxResults")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "MaxResults", valid_601723
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
  var valid_601724 = header.getOrDefault("X-Amz-Date")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Date", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Security-Token")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Security-Token", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Content-Sha256", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Algorithm")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Algorithm", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Signature")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Signature", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-SignedHeaders", valid_601729
  var valid_601730 = header.getOrDefault("x-amz-consistency-level")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601730 != nil:
    section.add "x-amz-consistency-level", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Credential")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Credential", valid_601731
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601732 = header.getOrDefault("x-amz-data-partition")
  valid_601732 = validateParameter(valid_601732, JString, required = true,
                                 default = nil)
  if valid_601732 != nil:
    section.add "x-amz-data-partition", valid_601732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601734: Call_ListObjectChildren_601719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_601734.validator(path, query, header, formData, body)
  let scheme = call_601734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601734.url(scheme.get, call_601734.host, call_601734.base,
                         call_601734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601734, url, valid)

proc call*(call_601735: Call_ListObjectChildren_601719; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601736 = newJObject()
  var body_601737 = newJObject()
  add(query_601736, "NextToken", newJString(NextToken))
  if body != nil:
    body_601737 = body
  add(query_601736, "MaxResults", newJString(MaxResults))
  result = call_601735.call(nil, query_601736, nil, nil, body_601737)

var listObjectChildren* = Call_ListObjectChildren_601719(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_601720, base: "/",
    url: url_ListObjectChildren_601721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_601738 = ref object of OpenApiRestCall_600437
proc url_ListObjectParentPaths_601740(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectParentPaths_601739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601741 = query.getOrDefault("NextToken")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "NextToken", valid_601741
  var valid_601742 = query.getOrDefault("MaxResults")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "MaxResults", valid_601742
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
  var valid_601743 = header.getOrDefault("X-Amz-Date")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Date", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Security-Token")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Security-Token", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Content-Sha256", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Algorithm")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Algorithm", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Signature")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Signature", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-SignedHeaders", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Credential")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Credential", valid_601749
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601750 = header.getOrDefault("x-amz-data-partition")
  valid_601750 = validateParameter(valid_601750, JString, required = true,
                                 default = nil)
  if valid_601750 != nil:
    section.add "x-amz-data-partition", valid_601750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601752: Call_ListObjectParentPaths_601738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_601752.validator(path, query, header, formData, body)
  let scheme = call_601752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601752.url(scheme.get, call_601752.host, call_601752.base,
                         call_601752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601752, url, valid)

proc call*(call_601753: Call_ListObjectParentPaths_601738; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601754 = newJObject()
  var body_601755 = newJObject()
  add(query_601754, "NextToken", newJString(NextToken))
  if body != nil:
    body_601755 = body
  add(query_601754, "MaxResults", newJString(MaxResults))
  result = call_601753.call(nil, query_601754, nil, nil, body_601755)

var listObjectParentPaths* = Call_ListObjectParentPaths_601738(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_601739, base: "/",
    url: url_ListObjectParentPaths_601740, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_601756 = ref object of OpenApiRestCall_600437
proc url_ListObjectParents_601758(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectParents_601757(path: JsonNode; query: JsonNode;
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
  var valid_601759 = query.getOrDefault("NextToken")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "NextToken", valid_601759
  var valid_601760 = query.getOrDefault("MaxResults")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "MaxResults", valid_601760
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
  var valid_601761 = header.getOrDefault("X-Amz-Date")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Date", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Security-Token")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Security-Token", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Content-Sha256", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Algorithm")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Algorithm", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Signature")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Signature", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-SignedHeaders", valid_601766
  var valid_601767 = header.getOrDefault("x-amz-consistency-level")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601767 != nil:
    section.add "x-amz-consistency-level", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Credential")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Credential", valid_601768
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601769 = header.getOrDefault("x-amz-data-partition")
  valid_601769 = validateParameter(valid_601769, JString, required = true,
                                 default = nil)
  if valid_601769 != nil:
    section.add "x-amz-data-partition", valid_601769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601771: Call_ListObjectParents_601756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_601771.validator(path, query, header, formData, body)
  let scheme = call_601771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601771.url(scheme.get, call_601771.host, call_601771.base,
                         call_601771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601771, url, valid)

proc call*(call_601772: Call_ListObjectParents_601756; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601773 = newJObject()
  var body_601774 = newJObject()
  add(query_601773, "NextToken", newJString(NextToken))
  if body != nil:
    body_601774 = body
  add(query_601773, "MaxResults", newJString(MaxResults))
  result = call_601772.call(nil, query_601773, nil, nil, body_601774)

var listObjectParents* = Call_ListObjectParents_601756(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_601757, base: "/",
    url: url_ListObjectParents_601758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_601775 = ref object of OpenApiRestCall_600437
proc url_ListObjectPolicies_601777(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectPolicies_601776(path: JsonNode; query: JsonNode;
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
  var valid_601778 = query.getOrDefault("NextToken")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "NextToken", valid_601778
  var valid_601779 = query.getOrDefault("MaxResults")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "MaxResults", valid_601779
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
  var valid_601780 = header.getOrDefault("X-Amz-Date")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Date", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Security-Token")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Security-Token", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Content-Sha256", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Algorithm")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Algorithm", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Signature")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Signature", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-SignedHeaders", valid_601785
  var valid_601786 = header.getOrDefault("x-amz-consistency-level")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601786 != nil:
    section.add "x-amz-consistency-level", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Credential")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Credential", valid_601787
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601788 = header.getOrDefault("x-amz-data-partition")
  valid_601788 = validateParameter(valid_601788, JString, required = true,
                                 default = nil)
  if valid_601788 != nil:
    section.add "x-amz-data-partition", valid_601788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601790: Call_ListObjectPolicies_601775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_601790.validator(path, query, header, formData, body)
  let scheme = call_601790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601790.url(scheme.get, call_601790.host, call_601790.base,
                         call_601790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601790, url, valid)

proc call*(call_601791: Call_ListObjectPolicies_601775; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601792 = newJObject()
  var body_601793 = newJObject()
  add(query_601792, "NextToken", newJString(NextToken))
  if body != nil:
    body_601793 = body
  add(query_601792, "MaxResults", newJString(MaxResults))
  result = call_601791.call(nil, query_601792, nil, nil, body_601793)

var listObjectPolicies* = Call_ListObjectPolicies_601775(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_601776, base: "/",
    url: url_ListObjectPolicies_601777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_601794 = ref object of OpenApiRestCall_600437
proc url_ListOutgoingTypedLinks_601796(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOutgoingTypedLinks_601795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601797 = header.getOrDefault("X-Amz-Date")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Date", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Security-Token")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Security-Token", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Content-Sha256", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Algorithm")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Algorithm", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Signature")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Signature", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-SignedHeaders", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Credential")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Credential", valid_601803
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601804 = header.getOrDefault("x-amz-data-partition")
  valid_601804 = validateParameter(valid_601804, JString, required = true,
                                 default = nil)
  if valid_601804 != nil:
    section.add "x-amz-data-partition", valid_601804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601806: Call_ListOutgoingTypedLinks_601794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601806.validator(path, query, header, formData, body)
  let scheme = call_601806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601806.url(scheme.get, call_601806.host, call_601806.base,
                         call_601806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601806, url, valid)

proc call*(call_601807: Call_ListOutgoingTypedLinks_601794; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_601808 = newJObject()
  if body != nil:
    body_601808 = body
  result = call_601807.call(nil, nil, nil, nil, body_601808)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_601794(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_601795, base: "/",
    url: url_ListOutgoingTypedLinks_601796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_601809 = ref object of OpenApiRestCall_600437
proc url_ListPolicyAttachments_601811(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPolicyAttachments_601810(path: JsonNode; query: JsonNode;
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
  var valid_601812 = query.getOrDefault("NextToken")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "NextToken", valid_601812
  var valid_601813 = query.getOrDefault("MaxResults")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "MaxResults", valid_601813
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
  var valid_601814 = header.getOrDefault("X-Amz-Date")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Date", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Security-Token")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Security-Token", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Content-Sha256", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Algorithm")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Algorithm", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Signature")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Signature", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-SignedHeaders", valid_601819
  var valid_601820 = header.getOrDefault("x-amz-consistency-level")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_601820 != nil:
    section.add "x-amz-consistency-level", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Credential")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Credential", valid_601821
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601822 = header.getOrDefault("x-amz-data-partition")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = nil)
  if valid_601822 != nil:
    section.add "x-amz-data-partition", valid_601822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601824: Call_ListPolicyAttachments_601809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_601824.validator(path, query, header, formData, body)
  let scheme = call_601824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601824.url(scheme.get, call_601824.host, call_601824.base,
                         call_601824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601824, url, valid)

proc call*(call_601825: Call_ListPolicyAttachments_601809; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601826 = newJObject()
  var body_601827 = newJObject()
  add(query_601826, "NextToken", newJString(NextToken))
  if body != nil:
    body_601827 = body
  add(query_601826, "MaxResults", newJString(MaxResults))
  result = call_601825.call(nil, query_601826, nil, nil, body_601827)

var listPolicyAttachments* = Call_ListPolicyAttachments_601809(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_601810, base: "/",
    url: url_ListPolicyAttachments_601811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_601828 = ref object of OpenApiRestCall_600437
proc url_ListPublishedSchemaArns_601830(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPublishedSchemaArns_601829(path: JsonNode; query: JsonNode;
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
  var valid_601831 = query.getOrDefault("NextToken")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "NextToken", valid_601831
  var valid_601832 = query.getOrDefault("MaxResults")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "MaxResults", valid_601832
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
  var valid_601833 = header.getOrDefault("X-Amz-Date")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Date", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Security-Token")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Security-Token", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Content-Sha256", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Algorithm")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Algorithm", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Signature")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Signature", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-SignedHeaders", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Credential")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Credential", valid_601839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601841: Call_ListPublishedSchemaArns_601828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_601841.validator(path, query, header, formData, body)
  let scheme = call_601841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601841.url(scheme.get, call_601841.host, call_601841.base,
                         call_601841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601841, url, valid)

proc call*(call_601842: Call_ListPublishedSchemaArns_601828; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601843 = newJObject()
  var body_601844 = newJObject()
  add(query_601843, "NextToken", newJString(NextToken))
  if body != nil:
    body_601844 = body
  add(query_601843, "MaxResults", newJString(MaxResults))
  result = call_601842.call(nil, query_601843, nil, nil, body_601844)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_601828(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_601829, base: "/",
    url: url_ListPublishedSchemaArns_601830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601845 = ref object of OpenApiRestCall_600437
proc url_ListTagsForResource_601847(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_601846(path: JsonNode; query: JsonNode;
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
  var valid_601848 = query.getOrDefault("NextToken")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "NextToken", valid_601848
  var valid_601849 = query.getOrDefault("MaxResults")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "MaxResults", valid_601849
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
  var valid_601850 = header.getOrDefault("X-Amz-Date")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Date", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Security-Token")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Security-Token", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Content-Sha256", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Algorithm")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Algorithm", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-Signature")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-Signature", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-SignedHeaders", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Credential")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Credential", valid_601856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601858: Call_ListTagsForResource_601845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_601858.validator(path, query, header, formData, body)
  let scheme = call_601858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601858.url(scheme.get, call_601858.host, call_601858.base,
                         call_601858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601858, url, valid)

proc call*(call_601859: Call_ListTagsForResource_601845; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601860 = newJObject()
  var body_601861 = newJObject()
  add(query_601860, "NextToken", newJString(NextToken))
  if body != nil:
    body_601861 = body
  add(query_601860, "MaxResults", newJString(MaxResults))
  result = call_601859.call(nil, query_601860, nil, nil, body_601861)

var listTagsForResource* = Call_ListTagsForResource_601845(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_601846, base: "/",
    url: url_ListTagsForResource_601847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_601862 = ref object of OpenApiRestCall_600437
proc url_ListTypedLinkFacetAttributes_601864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTypedLinkFacetAttributes_601863(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601865 = query.getOrDefault("NextToken")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "NextToken", valid_601865
  var valid_601866 = query.getOrDefault("MaxResults")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "MaxResults", valid_601866
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
  var valid_601867 = header.getOrDefault("X-Amz-Date")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Date", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Security-Token")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Security-Token", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Content-Sha256", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Algorithm")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Algorithm", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Signature")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Signature", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-SignedHeaders", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Credential")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Credential", valid_601873
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601874 = header.getOrDefault("x-amz-data-partition")
  valid_601874 = validateParameter(valid_601874, JString, required = true,
                                 default = nil)
  if valid_601874 != nil:
    section.add "x-amz-data-partition", valid_601874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_ListTypedLinkFacetAttributes_601862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601876, url, valid)

proc call*(call_601877: Call_ListTypedLinkFacetAttributes_601862; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601878 = newJObject()
  var body_601879 = newJObject()
  add(query_601878, "NextToken", newJString(NextToken))
  if body != nil:
    body_601879 = body
  add(query_601878, "MaxResults", newJString(MaxResults))
  result = call_601877.call(nil, query_601878, nil, nil, body_601879)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_601862(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_601863, base: "/",
    url: url_ListTypedLinkFacetAttributes_601864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_601880 = ref object of OpenApiRestCall_600437
proc url_ListTypedLinkFacetNames_601882(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTypedLinkFacetNames_601881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601883 = query.getOrDefault("NextToken")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "NextToken", valid_601883
  var valid_601884 = query.getOrDefault("MaxResults")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "MaxResults", valid_601884
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
  var valid_601885 = header.getOrDefault("X-Amz-Date")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Date", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Security-Token")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Security-Token", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Content-Sha256", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-Algorithm")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Algorithm", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Signature")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Signature", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-SignedHeaders", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Credential")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Credential", valid_601891
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601892 = header.getOrDefault("x-amz-data-partition")
  valid_601892 = validateParameter(valid_601892, JString, required = true,
                                 default = nil)
  if valid_601892 != nil:
    section.add "x-amz-data-partition", valid_601892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601894: Call_ListTypedLinkFacetNames_601880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_601894.validator(path, query, header, formData, body)
  let scheme = call_601894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601894.url(scheme.get, call_601894.host, call_601894.base,
                         call_601894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601894, url, valid)

proc call*(call_601895: Call_ListTypedLinkFacetNames_601880; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601896 = newJObject()
  var body_601897 = newJObject()
  add(query_601896, "NextToken", newJString(NextToken))
  if body != nil:
    body_601897 = body
  add(query_601896, "MaxResults", newJString(MaxResults))
  result = call_601895.call(nil, query_601896, nil, nil, body_601897)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_601880(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_601881, base: "/",
    url: url_ListTypedLinkFacetNames_601882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_601898 = ref object of OpenApiRestCall_600437
proc url_LookupPolicy_601900(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LookupPolicy_601899(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601901 = query.getOrDefault("NextToken")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "NextToken", valid_601901
  var valid_601902 = query.getOrDefault("MaxResults")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "MaxResults", valid_601902
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
  var valid_601903 = header.getOrDefault("X-Amz-Date")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Date", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Security-Token")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Security-Token", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Content-Sha256", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Algorithm")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Algorithm", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Signature")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Signature", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-SignedHeaders", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Credential")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Credential", valid_601909
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601910 = header.getOrDefault("x-amz-data-partition")
  valid_601910 = validateParameter(valid_601910, JString, required = true,
                                 default = nil)
  if valid_601910 != nil:
    section.add "x-amz-data-partition", valid_601910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601912: Call_LookupPolicy_601898; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ## 
  let valid = call_601912.validator(path, query, header, formData, body)
  let scheme = call_601912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601912.url(scheme.get, call_601912.host, call_601912.base,
                         call_601912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601912, url, valid)

proc call*(call_601913: Call_LookupPolicy_601898; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601914 = newJObject()
  var body_601915 = newJObject()
  add(query_601914, "NextToken", newJString(NextToken))
  if body != nil:
    body_601915 = body
  add(query_601914, "MaxResults", newJString(MaxResults))
  result = call_601913.call(nil, query_601914, nil, nil, body_601915)

var lookupPolicy* = Call_LookupPolicy_601898(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_601899, base: "/", url: url_LookupPolicy_601900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_601916 = ref object of OpenApiRestCall_600437
proc url_PublishSchema_601918(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PublishSchema_601917(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601919 = header.getOrDefault("X-Amz-Date")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Date", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Security-Token")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Security-Token", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Content-Sha256", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Algorithm")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Algorithm", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Signature")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Signature", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-SignedHeaders", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Credential")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Credential", valid_601925
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601926 = header.getOrDefault("x-amz-data-partition")
  valid_601926 = validateParameter(valid_601926, JString, required = true,
                                 default = nil)
  if valid_601926 != nil:
    section.add "x-amz-data-partition", valid_601926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601928: Call_PublishSchema_601916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_601928.validator(path, query, header, formData, body)
  let scheme = call_601928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601928.url(scheme.get, call_601928.host, call_601928.base,
                         call_601928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601928, url, valid)

proc call*(call_601929: Call_PublishSchema_601916; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_601930 = newJObject()
  if body != nil:
    body_601930 = body
  result = call_601929.call(nil, nil, nil, nil, body_601930)

var publishSchema* = Call_PublishSchema_601916(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_601917, base: "/", url: url_PublishSchema_601918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_601931 = ref object of OpenApiRestCall_600437
proc url_RemoveFacetFromObject_601933(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveFacetFromObject_601932(path: JsonNode; query: JsonNode;
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
  var valid_601934 = header.getOrDefault("X-Amz-Date")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Date", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Security-Token")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Security-Token", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Content-Sha256", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Algorithm")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Algorithm", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Signature")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Signature", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-SignedHeaders", valid_601939
  var valid_601940 = header.getOrDefault("X-Amz-Credential")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-Credential", valid_601940
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601941 = header.getOrDefault("x-amz-data-partition")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = nil)
  if valid_601941 != nil:
    section.add "x-amz-data-partition", valid_601941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601943: Call_RemoveFacetFromObject_601931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_601943.validator(path, query, header, formData, body)
  let scheme = call_601943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601943.url(scheme.get, call_601943.host, call_601943.base,
                         call_601943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601943, url, valid)

proc call*(call_601944: Call_RemoveFacetFromObject_601931; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_601945 = newJObject()
  if body != nil:
    body_601945 = body
  result = call_601944.call(nil, nil, nil, nil, body_601945)

var removeFacetFromObject* = Call_RemoveFacetFromObject_601931(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_601932, base: "/",
    url: url_RemoveFacetFromObject_601933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601946 = ref object of OpenApiRestCall_600437
proc url_TagResource_601948(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_601947(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601949 = header.getOrDefault("X-Amz-Date")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Date", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Security-Token")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Security-Token", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Content-Sha256", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Algorithm")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Algorithm", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Signature")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Signature", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-SignedHeaders", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Credential")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Credential", valid_601955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601957: Call_TagResource_601946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_601957.validator(path, query, header, formData, body)
  let scheme = call_601957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601957.url(scheme.get, call_601957.host, call_601957.base,
                         call_601957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601957, url, valid)

proc call*(call_601958: Call_TagResource_601946; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_601959 = newJObject()
  if body != nil:
    body_601959 = body
  result = call_601958.call(nil, nil, nil, nil, body_601959)

var tagResource* = Call_TagResource_601946(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_601947,
                                        base: "/", url: url_TagResource_601948,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601960 = ref object of OpenApiRestCall_600437
proc url_UntagResource_601962(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_601961(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601963 = header.getOrDefault("X-Amz-Date")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Date", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Security-Token")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Security-Token", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Content-Sha256", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Algorithm")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Algorithm", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Signature")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Signature", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-SignedHeaders", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Credential")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Credential", valid_601969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601971: Call_UntagResource_601960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_601971.validator(path, query, header, formData, body)
  let scheme = call_601971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601971.url(scheme.get, call_601971.host, call_601971.base,
                         call_601971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601971, url, valid)

proc call*(call_601972: Call_UntagResource_601960; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_601973 = newJObject()
  if body != nil:
    body_601973 = body
  result = call_601972.call(nil, nil, nil, nil, body_601973)

var untagResource* = Call_UntagResource_601960(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_601961, base: "/", url: url_UntagResource_601962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_601974 = ref object of OpenApiRestCall_600437
proc url_UpdateLinkAttributes_601976(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLinkAttributes_601975(path: JsonNode; query: JsonNode;
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
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  section = newJObject()
  var valid_601977 = header.getOrDefault("X-Amz-Date")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Date", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Security-Token")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Security-Token", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Content-Sha256", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Algorithm")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Algorithm", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Signature")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Signature", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-SignedHeaders", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Credential")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Credential", valid_601983
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601984 = header.getOrDefault("x-amz-data-partition")
  valid_601984 = validateParameter(valid_601984, JString, required = true,
                                 default = nil)
  if valid_601984 != nil:
    section.add "x-amz-data-partition", valid_601984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_UpdateLinkAttributes_601974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601986, url, valid)

proc call*(call_601987: Call_UpdateLinkAttributes_601974; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_601988 = newJObject()
  if body != nil:
    body_601988 = body
  result = call_601987.call(nil, nil, nil, nil, body_601988)

var updateLinkAttributes* = Call_UpdateLinkAttributes_601974(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_601975, base: "/",
    url: url_UpdateLinkAttributes_601976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_601989 = ref object of OpenApiRestCall_600437
proc url_UpdateObjectAttributes_601991(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateObjectAttributes_601990(path: JsonNode; query: JsonNode;
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
  var valid_601992 = header.getOrDefault("X-Amz-Date")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Date", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Content-Sha256", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-Algorithm")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-Algorithm", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Signature")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Signature", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-SignedHeaders", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Credential")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Credential", valid_601998
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601999 = header.getOrDefault("x-amz-data-partition")
  valid_601999 = validateParameter(valid_601999, JString, required = true,
                                 default = nil)
  if valid_601999 != nil:
    section.add "x-amz-data-partition", valid_601999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602001: Call_UpdateObjectAttributes_601989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_602001.validator(path, query, header, formData, body)
  let scheme = call_602001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602001.url(scheme.get, call_602001.host, call_602001.base,
                         call_602001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602001, url, valid)

proc call*(call_602002: Call_UpdateObjectAttributes_601989; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_602003 = newJObject()
  if body != nil:
    body_602003 = body
  result = call_602002.call(nil, nil, nil, nil, body_602003)

var updateObjectAttributes* = Call_UpdateObjectAttributes_601989(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_601990, base: "/",
    url: url_UpdateObjectAttributes_601991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_602004 = ref object of OpenApiRestCall_600437
proc url_UpdateSchema_602006(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSchema_602005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Content-Sha256", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Signature")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Signature", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Credential")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Credential", valid_602013
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602014 = header.getOrDefault("x-amz-data-partition")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "x-amz-data-partition", valid_602014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_UpdateSchema_602004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602016, url, valid)

proc call*(call_602017: Call_UpdateSchema_602004; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_602018 = newJObject()
  if body != nil:
    body_602018 = body
  result = call_602017.call(nil, nil, nil, nil, body_602018)

var updateSchema* = Call_UpdateSchema_602004(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_602005, base: "/", url: url_UpdateSchema_602006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_602019 = ref object of OpenApiRestCall_600437
proc url_UpdateTypedLinkFacet_602021(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTypedLinkFacet_602020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Security-Token")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Security-Token", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Signature")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Signature", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-SignedHeaders", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602029 = header.getOrDefault("x-amz-data-partition")
  valid_602029 = validateParameter(valid_602029, JString, required = true,
                                 default = nil)
  if valid_602029 != nil:
    section.add "x-amz-data-partition", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602031: Call_UpdateTypedLinkFacet_602019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602031.validator(path, query, header, formData, body)
  let scheme = call_602031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602031.url(scheme.get, call_602031.host, call_602031.base,
                         call_602031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602031, url, valid)

proc call*(call_602032: Call_UpdateTypedLinkFacet_602019; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602033 = newJObject()
  if body != nil:
    body_602033 = body
  result = call_602032.call(nil, nil, nil, nil, body_602033)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_602019(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_602020, base: "/",
    url: url_UpdateTypedLinkFacet_602021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_602034 = ref object of OpenApiRestCall_600437
proc url_UpgradeAppliedSchema_602036(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpgradeAppliedSchema_602035(path: JsonNode; query: JsonNode;
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
  var valid_602037 = header.getOrDefault("X-Amz-Date")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Date", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Security-Token")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Security-Token", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Algorithm")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Algorithm", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Credential")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Credential", valid_602043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_UpgradeAppliedSchema_602034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602045, url, valid)

proc call*(call_602046: Call_UpgradeAppliedSchema_602034; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_602047 = newJObject()
  if body != nil:
    body_602047 = body
  result = call_602046.call(nil, nil, nil, nil, body_602047)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_602034(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_602035, base: "/",
    url: url_UpgradeAppliedSchema_602036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_602048 = ref object of OpenApiRestCall_600437
proc url_UpgradePublishedSchema_602050(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpgradePublishedSchema_602049(path: JsonNode; query: JsonNode;
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
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Security-Token")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Security-Token", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Content-Sha256", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Signature")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Signature", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-SignedHeaders", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Credential")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Credential", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602059: Call_UpgradePublishedSchema_602048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_602059.validator(path, query, header, formData, body)
  let scheme = call_602059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602059.url(scheme.get, call_602059.host, call_602059.base,
                         call_602059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602059, url, valid)

proc call*(call_602060: Call_UpgradePublishedSchema_602048; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_602061 = newJObject()
  if body != nil:
    body_602061 = body
  result = call_602060.call(nil, nil, nil, nil, body_602061)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_602048(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_602049, base: "/",
    url: url_UpgradePublishedSchema_602050, schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
