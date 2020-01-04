
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AddFacetToObject_601727 = ref object of OpenApiRestCall_601389
proc url_AddFacetToObject_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AddFacetToObject_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601846 = header.getOrDefault("x-amz-data-partition")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = nil)
  if valid_601846 != nil:
    section.add "x-amz-data-partition", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Algorithm")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Algorithm", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-SignedHeaders", valid_601848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_AddFacetToObject_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_AddFacetToObject_601727; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_601944 = newJObject()
  if body != nil:
    body_601944 = body
  result = call_601943.call(nil, nil, nil, nil, body_601944)

var addFacetToObject* = Call_AddFacetToObject_601727(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_601728, base: "/",
    url: url_AddFacetToObject_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_601983 = ref object of OpenApiRestCall_601389
proc url_ApplySchema_601985(protocol: Scheme; host: string; base: string;
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

proc validate_ApplySchema_601984(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601986 = header.getOrDefault("X-Amz-Signature")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Signature", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Content-Sha256", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Date")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Date", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Credential")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Credential", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Security-Token")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Security-Token", valid_601990
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_601991 = header.getOrDefault("x-amz-data-partition")
  valid_601991 = validateParameter(valid_601991, JString, required = true,
                                 default = nil)
  if valid_601991 != nil:
    section.add "x-amz-data-partition", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_ApplySchema_601983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_ApplySchema_601983; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var applySchema* = Call_ApplySchema_601983(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_601984,
                                        base: "/", url: url_ApplySchema_601985,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_601998 = ref object of OpenApiRestCall_601389
proc url_AttachObject_602000(protocol: Scheme; host: string; base: string;
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

proc validate_AttachObject_601999(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602006 = header.getOrDefault("x-amz-data-partition")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "x-amz-data-partition", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Algorithm")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Algorithm", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-SignedHeaders", valid_602008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602010: Call_AttachObject_601998; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_602010.validator(path, query, header, formData, body)
  let scheme = call_602010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602010.url(scheme.get, call_602010.host, call_602010.base,
                         call_602010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602010, url, valid)

proc call*(call_602011: Call_AttachObject_601998; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_602012 = newJObject()
  if body != nil:
    body_602012 = body
  result = call_602011.call(nil, nil, nil, nil, body_602012)

var attachObject* = Call_AttachObject_601998(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_601999, base: "/", url: url_AttachObject_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_602013 = ref object of OpenApiRestCall_601389
proc url_AttachPolicy_602015(protocol: Scheme; host: string; base: string;
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

proc validate_AttachPolicy_602014(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602021 = header.getOrDefault("x-amz-data-partition")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "x-amz-data-partition", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Algorithm")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Algorithm", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602025: Call_AttachPolicy_602013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_602025.validator(path, query, header, formData, body)
  let scheme = call_602025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602025.url(scheme.get, call_602025.host, call_602025.base,
                         call_602025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602025, url, valid)

proc call*(call_602026: Call_AttachPolicy_602013; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_602027 = newJObject()
  if body != nil:
    body_602027 = body
  result = call_602026.call(nil, nil, nil, nil, body_602027)

var attachPolicy* = Call_AttachPolicy_602013(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_602014, base: "/", url: url_AttachPolicy_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_602028 = ref object of OpenApiRestCall_601389
proc url_AttachToIndex_602030(protocol: Scheme; host: string; base: string;
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

proc validate_AttachToIndex_602029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602036 = header.getOrDefault("x-amz-data-partition")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = nil)
  if valid_602036 != nil:
    section.add "x-amz-data-partition", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-SignedHeaders", valid_602038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602040: Call_AttachToIndex_602028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_602040.validator(path, query, header, formData, body)
  let scheme = call_602040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602040.url(scheme.get, call_602040.host, call_602040.base,
                         call_602040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602040, url, valid)

proc call*(call_602041: Call_AttachToIndex_602028; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_602042 = newJObject()
  if body != nil:
    body_602042 = body
  result = call_602041.call(nil, nil, nil, nil, body_602042)

var attachToIndex* = Call_AttachToIndex_602028(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_602029, base: "/", url: url_AttachToIndex_602030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_602043 = ref object of OpenApiRestCall_601389
proc url_AttachTypedLink_602045(protocol: Scheme; host: string; base: string;
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

proc validate_AttachTypedLink_602044(path: JsonNode; query: JsonNode;
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
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602051 = header.getOrDefault("x-amz-data-partition")
  valid_602051 = validateParameter(valid_602051, JString, required = true,
                                 default = nil)
  if valid_602051 != nil:
    section.add "x-amz-data-partition", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-SignedHeaders", valid_602053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_AttachTypedLink_602043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602055, url, valid)

proc call*(call_602056: Call_AttachTypedLink_602043; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602057 = newJObject()
  if body != nil:
    body_602057 = body
  result = call_602056.call(nil, nil, nil, nil, body_602057)

var attachTypedLink* = Call_AttachTypedLink_602043(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_602044, base: "/", url: url_AttachTypedLink_602045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_602058 = ref object of OpenApiRestCall_601389
proc url_BatchRead_602060(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_BatchRead_602059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602074 = header.getOrDefault("x-amz-consistency-level")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602074 != nil:
    section.add "x-amz-consistency-level", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602080 = header.getOrDefault("x-amz-data-partition")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = nil)
  if valid_602080 != nil:
    section.add "x-amz-data-partition", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_BatchRead_602058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_BatchRead_602058; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_602086 = newJObject()
  if body != nil:
    body_602086 = body
  result = call_602085.call(nil, nil, nil, nil, body_602086)

var batchRead* = Call_BatchRead_602058(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_602059,
                                    base: "/", url: url_BatchRead_602060,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_602087 = ref object of OpenApiRestCall_601389
proc url_BatchWrite_602089(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_BatchWrite_602088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602095 = header.getOrDefault("x-amz-data-partition")
  valid_602095 = validateParameter(valid_602095, JString, required = true,
                                 default = nil)
  if valid_602095 != nil:
    section.add "x-amz-data-partition", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-SignedHeaders", valid_602097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_BatchWrite_602087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_BatchWrite_602087; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_602101 = newJObject()
  if body != nil:
    body_602101 = body
  result = call_602100.call(nil, nil, nil, nil, body_602101)

var batchWrite* = Call_BatchWrite_602087(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_602088,
                                      base: "/", url: url_BatchWrite_602089,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_602102 = ref object of OpenApiRestCall_601389
proc url_CreateDirectory_602104(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDirectory_602103(path: JsonNode; query: JsonNode;
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
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602110 = header.getOrDefault("x-amz-data-partition")
  valid_602110 = validateParameter(valid_602110, JString, required = true,
                                 default = nil)
  if valid_602110 != nil:
    section.add "x-amz-data-partition", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Algorithm")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Algorithm", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-SignedHeaders", valid_602112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602114: Call_CreateDirectory_602102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ## 
  let valid = call_602114.validator(path, query, header, formData, body)
  let scheme = call_602114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602114.url(scheme.get, call_602114.host, call_602114.base,
                         call_602114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602114, url, valid)

proc call*(call_602115: Call_CreateDirectory_602102; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_602116 = newJObject()
  if body != nil:
    body_602116 = body
  result = call_602115.call(nil, nil, nil, nil, body_602116)

var createDirectory* = Call_CreateDirectory_602102(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_602103, base: "/", url: url_CreateDirectory_602104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_602117 = ref object of OpenApiRestCall_601389
proc url_CreateFacet_602119(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFacet_602118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602125 = header.getOrDefault("x-amz-data-partition")
  valid_602125 = validateParameter(valid_602125, JString, required = true,
                                 default = nil)
  if valid_602125 != nil:
    section.add "x-amz-data-partition", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Algorithm")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Algorithm", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-SignedHeaders", valid_602127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602129: Call_CreateFacet_602117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_602129.validator(path, query, header, formData, body)
  let scheme = call_602129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602129.url(scheme.get, call_602129.host, call_602129.base,
                         call_602129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602129, url, valid)

proc call*(call_602130: Call_CreateFacet_602117; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_602131 = newJObject()
  if body != nil:
    body_602131 = body
  result = call_602130.call(nil, nil, nil, nil, body_602131)

var createFacet* = Call_CreateFacet_602117(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_602118,
                                        base: "/", url: url_CreateFacet_602119,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_602132 = ref object of OpenApiRestCall_601389
proc url_CreateIndex_602134(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIndex_602133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602140 = header.getOrDefault("x-amz-data-partition")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = nil)
  if valid_602140 != nil:
    section.add "x-amz-data-partition", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Algorithm")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Algorithm", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-SignedHeaders", valid_602142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602144: Call_CreateIndex_602132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ## 
  let valid = call_602144.validator(path, query, header, formData, body)
  let scheme = call_602144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602144.url(scheme.get, call_602144.host, call_602144.base,
                         call_602144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602144, url, valid)

proc call*(call_602145: Call_CreateIndex_602132; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ##   body: JObject (required)
  var body_602146 = newJObject()
  if body != nil:
    body_602146 = body
  result = call_602145.call(nil, nil, nil, nil, body_602146)

var createIndex* = Call_CreateIndex_602132(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_602133,
                                        base: "/", url: url_CreateIndex_602134,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_602147 = ref object of OpenApiRestCall_601389
proc url_CreateObject_602149(protocol: Scheme; host: string; base: string;
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

proc validate_CreateObject_602148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602155 = header.getOrDefault("x-amz-data-partition")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = nil)
  if valid_602155 != nil:
    section.add "x-amz-data-partition", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Algorithm")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Algorithm", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-SignedHeaders", valid_602157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602159: Call_CreateObject_602147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_602159.validator(path, query, header, formData, body)
  let scheme = call_602159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602159.url(scheme.get, call_602159.host, call_602159.base,
                         call_602159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602159, url, valid)

proc call*(call_602160: Call_CreateObject_602147; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_602161 = newJObject()
  if body != nil:
    body_602161 = body
  result = call_602160.call(nil, nil, nil, nil, body_602161)

var createObject* = Call_CreateObject_602147(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_602148, base: "/", url: url_CreateObject_602149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_602162 = ref object of OpenApiRestCall_601389
proc url_CreateSchema_602164(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSchema_602163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_CreateSchema_602162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_CreateSchema_602162; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var createSchema* = Call_CreateSchema_602162(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_602163, base: "/", url: url_CreateSchema_602164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_602176 = ref object of OpenApiRestCall_601389
proc url_CreateTypedLinkFacet_602178(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTypedLinkFacet_602177(path: JsonNode; query: JsonNode;
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
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Date")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Date", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Credential")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Credential", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Security-Token")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Security-Token", valid_602183
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602184 = header.getOrDefault("x-amz-data-partition")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "x-amz-data-partition", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_CreateTypedLinkFacet_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_CreateTypedLinkFacet_602176; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_602176(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_602177, base: "/",
    url: url_CreateTypedLinkFacet_602178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_602191 = ref object of OpenApiRestCall_601389
proc url_DeleteDirectory_602193(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDirectory_602192(path: JsonNode; query: JsonNode;
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
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602199 = header.getOrDefault("x-amz-data-partition")
  valid_602199 = validateParameter(valid_602199, JString, required = true,
                                 default = nil)
  if valid_602199 != nil:
    section.add "x-amz-data-partition", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_DeleteDirectory_602191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_DeleteDirectory_602191): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_602203.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_602191(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_602192, base: "/", url: url_DeleteDirectory_602193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_602204 = ref object of OpenApiRestCall_601389
proc url_DeleteFacet_602206(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFacet_602205(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602207 = header.getOrDefault("X-Amz-Signature")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Signature", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Content-Sha256", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Date")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Date", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Credential")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Credential", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Security-Token")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Security-Token", valid_602211
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602212 = header.getOrDefault("x-amz-data-partition")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "x-amz-data-partition", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Algorithm")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Algorithm", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-SignedHeaders", valid_602214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_DeleteFacet_602204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_DeleteFacet_602204; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_602218 = newJObject()
  if body != nil:
    body_602218 = body
  result = call_602217.call(nil, nil, nil, nil, body_602218)

var deleteFacet* = Call_DeleteFacet_602204(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_602205,
                                        base: "/", url: url_DeleteFacet_602206,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_602219 = ref object of OpenApiRestCall_601389
proc url_DeleteObject_602221(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteObject_602220(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602222 = header.getOrDefault("X-Amz-Signature")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Signature", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Content-Sha256", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Date")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Date", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Credential")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Credential", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Security-Token")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Security-Token", valid_602226
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602227 = header.getOrDefault("x-amz-data-partition")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "x-amz-data-partition", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Algorithm")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Algorithm", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-SignedHeaders", valid_602229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602231: Call_DeleteObject_602219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_DeleteObject_602219; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ##   body: JObject (required)
  var body_602233 = newJObject()
  if body != nil:
    body_602233 = body
  result = call_602232.call(nil, nil, nil, nil, body_602233)

var deleteObject* = Call_DeleteObject_602219(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_602220, base: "/", url: url_DeleteObject_602221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_602234 = ref object of OpenApiRestCall_601389
proc url_DeleteSchema_602236(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchema_602235(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602237 = header.getOrDefault("X-Amz-Signature")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Signature", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Content-Sha256", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Date")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Date", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Credential")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Credential", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Security-Token")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Security-Token", valid_602241
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602242 = header.getOrDefault("x-amz-data-partition")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = nil)
  if valid_602242 != nil:
    section.add "x-amz-data-partition", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Algorithm")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Algorithm", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-SignedHeaders", valid_602244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602245: Call_DeleteSchema_602234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_602245.validator(path, query, header, formData, body)
  let scheme = call_602245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602245.url(scheme.get, call_602245.host, call_602245.base,
                         call_602245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602245, url, valid)

proc call*(call_602246: Call_DeleteSchema_602234): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_602246.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_602234(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_602235, base: "/", url: url_DeleteSchema_602236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_602247 = ref object of OpenApiRestCall_601389
proc url_DeleteTypedLinkFacet_602249(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTypedLinkFacet_602248(path: JsonNode; query: JsonNode;
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
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602255 = header.getOrDefault("x-amz-data-partition")
  valid_602255 = validateParameter(valid_602255, JString, required = true,
                                 default = nil)
  if valid_602255 != nil:
    section.add "x-amz-data-partition", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Algorithm")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Algorithm", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-SignedHeaders", valid_602257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602259: Call_DeleteTypedLinkFacet_602247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602259.validator(path, query, header, formData, body)
  let scheme = call_602259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602259.url(scheme.get, call_602259.host, call_602259.base,
                         call_602259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602259, url, valid)

proc call*(call_602260: Call_DeleteTypedLinkFacet_602247; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602261 = newJObject()
  if body != nil:
    body_602261 = body
  result = call_602260.call(nil, nil, nil, nil, body_602261)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_602247(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_602248, base: "/",
    url: url_DeleteTypedLinkFacet_602249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_602262 = ref object of OpenApiRestCall_601389
proc url_DetachFromIndex_602264(protocol: Scheme; host: string; base: string;
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

proc validate_DetachFromIndex_602263(path: JsonNode; query: JsonNode;
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
  var valid_602265 = header.getOrDefault("X-Amz-Signature")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Signature", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Content-Sha256", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Date")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Date", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Credential")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Credential", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Security-Token")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Security-Token", valid_602269
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602270 = header.getOrDefault("x-amz-data-partition")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "x-amz-data-partition", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Algorithm")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Algorithm", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-SignedHeaders", valid_602272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602274: Call_DetachFromIndex_602262; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_602274.validator(path, query, header, formData, body)
  let scheme = call_602274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602274.url(scheme.get, call_602274.host, call_602274.base,
                         call_602274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602274, url, valid)

proc call*(call_602275: Call_DetachFromIndex_602262; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_602276 = newJObject()
  if body != nil:
    body_602276 = body
  result = call_602275.call(nil, nil, nil, nil, body_602276)

var detachFromIndex* = Call_DetachFromIndex_602262(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_602263, base: "/", url: url_DetachFromIndex_602264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_602277 = ref object of OpenApiRestCall_601389
proc url_DetachObject_602279(protocol: Scheme; host: string; base: string;
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

proc validate_DetachObject_602278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602280 = header.getOrDefault("X-Amz-Signature")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Signature", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Content-Sha256", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Date")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Date", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Credential")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Credential", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Security-Token")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Security-Token", valid_602284
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602285 = header.getOrDefault("x-amz-data-partition")
  valid_602285 = validateParameter(valid_602285, JString, required = true,
                                 default = nil)
  if valid_602285 != nil:
    section.add "x-amz-data-partition", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Algorithm")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Algorithm", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-SignedHeaders", valid_602287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602289: Call_DetachObject_602277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_602289.validator(path, query, header, formData, body)
  let scheme = call_602289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602289.url(scheme.get, call_602289.host, call_602289.base,
                         call_602289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602289, url, valid)

proc call*(call_602290: Call_DetachObject_602277; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_602291 = newJObject()
  if body != nil:
    body_602291 = body
  result = call_602290.call(nil, nil, nil, nil, body_602291)

var detachObject* = Call_DetachObject_602277(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_602278, base: "/", url: url_DetachObject_602279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_602292 = ref object of OpenApiRestCall_601389
proc url_DetachPolicy_602294(protocol: Scheme; host: string; base: string;
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

proc validate_DetachPolicy_602293(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602295 = header.getOrDefault("X-Amz-Signature")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Signature", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Date")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Date", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Credential")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Credential", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Security-Token")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Security-Token", valid_602299
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602300 = header.getOrDefault("x-amz-data-partition")
  valid_602300 = validateParameter(valid_602300, JString, required = true,
                                 default = nil)
  if valid_602300 != nil:
    section.add "x-amz-data-partition", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Algorithm")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Algorithm", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-SignedHeaders", valid_602302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602304: Call_DetachPolicy_602292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_602304.validator(path, query, header, formData, body)
  let scheme = call_602304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602304.url(scheme.get, call_602304.host, call_602304.base,
                         call_602304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602304, url, valid)

proc call*(call_602305: Call_DetachPolicy_602292; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_602306 = newJObject()
  if body != nil:
    body_602306 = body
  result = call_602305.call(nil, nil, nil, nil, body_602306)

var detachPolicy* = Call_DetachPolicy_602292(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_602293, base: "/", url: url_DetachPolicy_602294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_602307 = ref object of OpenApiRestCall_601389
proc url_DetachTypedLink_602309(protocol: Scheme; host: string; base: string;
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

proc validate_DetachTypedLink_602308(path: JsonNode; query: JsonNode;
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
  var valid_602310 = header.getOrDefault("X-Amz-Signature")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Signature", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Content-Sha256", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Date")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Date", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602315 = header.getOrDefault("x-amz-data-partition")
  valid_602315 = validateParameter(valid_602315, JString, required = true,
                                 default = nil)
  if valid_602315 != nil:
    section.add "x-amz-data-partition", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Algorithm")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Algorithm", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-SignedHeaders", valid_602317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602319: Call_DetachTypedLink_602307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602319.validator(path, query, header, formData, body)
  let scheme = call_602319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602319.url(scheme.get, call_602319.host, call_602319.base,
                         call_602319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602319, url, valid)

proc call*(call_602320: Call_DetachTypedLink_602307; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602321 = newJObject()
  if body != nil:
    body_602321 = body
  result = call_602320.call(nil, nil, nil, nil, body_602321)

var detachTypedLink* = Call_DetachTypedLink_602307(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_602308, base: "/", url: url_DetachTypedLink_602309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_602322 = ref object of OpenApiRestCall_601389
proc url_DisableDirectory_602324(protocol: Scheme; host: string; base: string;
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

proc validate_DisableDirectory_602323(path: JsonNode; query: JsonNode;
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
  var valid_602325 = header.getOrDefault("X-Amz-Signature")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Signature", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Content-Sha256", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Date")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Date", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Credential")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Credential", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Security-Token")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Security-Token", valid_602329
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602330 = header.getOrDefault("x-amz-data-partition")
  valid_602330 = validateParameter(valid_602330, JString, required = true,
                                 default = nil)
  if valid_602330 != nil:
    section.add "x-amz-data-partition", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Algorithm")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Algorithm", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-SignedHeaders", valid_602332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602333: Call_DisableDirectory_602322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_602333.validator(path, query, header, formData, body)
  let scheme = call_602333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602333.url(scheme.get, call_602333.host, call_602333.base,
                         call_602333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602333, url, valid)

proc call*(call_602334: Call_DisableDirectory_602322): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_602334.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_602322(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_602323, base: "/",
    url: url_DisableDirectory_602324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_602335 = ref object of OpenApiRestCall_601389
proc url_EnableDirectory_602337(protocol: Scheme; host: string; base: string;
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

proc validate_EnableDirectory_602336(path: JsonNode; query: JsonNode;
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
  var valid_602338 = header.getOrDefault("X-Amz-Signature")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Signature", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Content-Sha256", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Date")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Date", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Credential")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Credential", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Security-Token")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Security-Token", valid_602342
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602343 = header.getOrDefault("x-amz-data-partition")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = nil)
  if valid_602343 != nil:
    section.add "x-amz-data-partition", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Algorithm")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Algorithm", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-SignedHeaders", valid_602345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602346: Call_EnableDirectory_602335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_602346.validator(path, query, header, formData, body)
  let scheme = call_602346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602346.url(scheme.get, call_602346.host, call_602346.base,
                         call_602346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602346, url, valid)

proc call*(call_602347: Call_EnableDirectory_602335): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_602347.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_602335(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_602336, base: "/", url: url_EnableDirectory_602337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_602348 = ref object of OpenApiRestCall_601389
proc url_GetAppliedSchemaVersion_602350(protocol: Scheme; host: string; base: string;
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

proc validate_GetAppliedSchemaVersion_602349(path: JsonNode; query: JsonNode;
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
  var valid_602351 = header.getOrDefault("X-Amz-Signature")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Signature", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Content-Sha256", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Date")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Date", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Credential")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Credential", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Security-Token")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Security-Token", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Algorithm")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Algorithm", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-SignedHeaders", valid_602357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602359: Call_GetAppliedSchemaVersion_602348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_602359.validator(path, query, header, formData, body)
  let scheme = call_602359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602359.url(scheme.get, call_602359.host, call_602359.base,
                         call_602359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602359, url, valid)

proc call*(call_602360: Call_GetAppliedSchemaVersion_602348; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_602361 = newJObject()
  if body != nil:
    body_602361 = body
  result = call_602360.call(nil, nil, nil, nil, body_602361)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_602348(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_602349, base: "/",
    url: url_GetAppliedSchemaVersion_602350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_602362 = ref object of OpenApiRestCall_601389
proc url_GetDirectory_602364(protocol: Scheme; host: string; base: string;
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

proc validate_GetDirectory_602363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602365 = header.getOrDefault("X-Amz-Signature")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Signature", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Content-Sha256", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Credential")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Credential", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Security-Token")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Security-Token", valid_602369
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602370 = header.getOrDefault("x-amz-data-partition")
  valid_602370 = validateParameter(valid_602370, JString, required = true,
                                 default = nil)
  if valid_602370 != nil:
    section.add "x-amz-data-partition", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Algorithm")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Algorithm", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-SignedHeaders", valid_602372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602373: Call_GetDirectory_602362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_602373.validator(path, query, header, formData, body)
  let scheme = call_602373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602373.url(scheme.get, call_602373.host, call_602373.base,
                         call_602373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602373, url, valid)

proc call*(call_602374: Call_GetDirectory_602362): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_602374.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_602362(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_602363, base: "/", url: url_GetDirectory_602364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_602375 = ref object of OpenApiRestCall_601389
proc url_UpdateFacet_602377(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFacet_602376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602378 = header.getOrDefault("X-Amz-Signature")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Signature", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Content-Sha256", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Date")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Date", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Credential")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Credential", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Security-Token")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Security-Token", valid_602382
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602383 = header.getOrDefault("x-amz-data-partition")
  valid_602383 = validateParameter(valid_602383, JString, required = true,
                                 default = nil)
  if valid_602383 != nil:
    section.add "x-amz-data-partition", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602387: Call_UpdateFacet_602375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_602387.validator(path, query, header, formData, body)
  let scheme = call_602387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602387.url(scheme.get, call_602387.host, call_602387.base,
                         call_602387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602387, url, valid)

proc call*(call_602388: Call_UpdateFacet_602375; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_602389 = newJObject()
  if body != nil:
    body_602389 = body
  result = call_602388.call(nil, nil, nil, nil, body_602389)

var updateFacet* = Call_UpdateFacet_602375(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_602376,
                                        base: "/", url: url_UpdateFacet_602377,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_602390 = ref object of OpenApiRestCall_601389
proc url_GetFacet_602392(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFacet_602391(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602393 = header.getOrDefault("X-Amz-Signature")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Signature", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Content-Sha256", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Date")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Date", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Credential")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Credential", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Security-Token")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Security-Token", valid_602397
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602398 = header.getOrDefault("x-amz-data-partition")
  valid_602398 = validateParameter(valid_602398, JString, required = true,
                                 default = nil)
  if valid_602398 != nil:
    section.add "x-amz-data-partition", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602402: Call_GetFacet_602390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_602402.validator(path, query, header, formData, body)
  let scheme = call_602402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602402.url(scheme.get, call_602402.host, call_602402.base,
                         call_602402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602402, url, valid)

proc call*(call_602403: Call_GetFacet_602390; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_602404 = newJObject()
  if body != nil:
    body_602404 = body
  result = call_602403.call(nil, nil, nil, nil, body_602404)

var getFacet* = Call_GetFacet_602390(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_602391, base: "/",
                                  url: url_GetFacet_602392,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_602405 = ref object of OpenApiRestCall_601389
proc url_GetLinkAttributes_602407(protocol: Scheme; host: string; base: string;
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

proc validate_GetLinkAttributes_602406(path: JsonNode; query: JsonNode;
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
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602408 = header.getOrDefault("X-Amz-Signature")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Signature", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Content-Sha256", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Date")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Date", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Credential")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Credential", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Security-Token")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Security-Token", valid_602412
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602413 = header.getOrDefault("x-amz-data-partition")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = nil)
  if valid_602413 != nil:
    section.add "x-amz-data-partition", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Algorithm")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Algorithm", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-SignedHeaders", valid_602415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602417: Call_GetLinkAttributes_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_602417.validator(path, query, header, formData, body)
  let scheme = call_602417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602417.url(scheme.get, call_602417.host, call_602417.base,
                         call_602417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602417, url, valid)

proc call*(call_602418: Call_GetLinkAttributes_602405; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_602419 = newJObject()
  if body != nil:
    body_602419 = body
  result = call_602418.call(nil, nil, nil, nil, body_602419)

var getLinkAttributes* = Call_GetLinkAttributes_602405(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_602406, base: "/",
    url: url_GetLinkAttributes_602407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_602420 = ref object of OpenApiRestCall_601389
proc url_GetObjectAttributes_602422(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectAttributes_602421(path: JsonNode; query: JsonNode;
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
  var valid_602423 = header.getOrDefault("x-amz-consistency-level")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602423 != nil:
    section.add "x-amz-consistency-level", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Signature")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Signature", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Date")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Date", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Credential")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Credential", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Security-Token")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Security-Token", valid_602428
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602429 = header.getOrDefault("x-amz-data-partition")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = nil)
  if valid_602429 != nil:
    section.add "x-amz-data-partition", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Algorithm")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Algorithm", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-SignedHeaders", valid_602431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602433: Call_GetObjectAttributes_602420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_602433.validator(path, query, header, formData, body)
  let scheme = call_602433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602433.url(scheme.get, call_602433.host, call_602433.base,
                         call_602433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602433, url, valid)

proc call*(call_602434: Call_GetObjectAttributes_602420; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_602435 = newJObject()
  if body != nil:
    body_602435 = body
  result = call_602434.call(nil, nil, nil, nil, body_602435)

var getObjectAttributes* = Call_GetObjectAttributes_602420(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_602421, base: "/",
    url: url_GetObjectAttributes_602422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_602436 = ref object of OpenApiRestCall_601389
proc url_GetObjectInformation_602438(protocol: Scheme; host: string; base: string;
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

proc validate_GetObjectInformation_602437(path: JsonNode; query: JsonNode;
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
  var valid_602439 = header.getOrDefault("x-amz-consistency-level")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602439 != nil:
    section.add "x-amz-consistency-level", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Signature")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Signature", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Content-Sha256", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Date")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Date", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Credential")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Credential", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Security-Token")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Security-Token", valid_602444
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602445 = header.getOrDefault("x-amz-data-partition")
  valid_602445 = validateParameter(valid_602445, JString, required = true,
                                 default = nil)
  if valid_602445 != nil:
    section.add "x-amz-data-partition", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Algorithm")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Algorithm", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-SignedHeaders", valid_602447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602449: Call_GetObjectInformation_602436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_602449.validator(path, query, header, formData, body)
  let scheme = call_602449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602449.url(scheme.get, call_602449.host, call_602449.base,
                         call_602449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602449, url, valid)

proc call*(call_602450: Call_GetObjectInformation_602436; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_602451 = newJObject()
  if body != nil:
    body_602451 = body
  result = call_602450.call(nil, nil, nil, nil, body_602451)

var getObjectInformation* = Call_GetObjectInformation_602436(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_602437, base: "/",
    url: url_GetObjectInformation_602438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_602452 = ref object of OpenApiRestCall_601389
proc url_PutSchemaFromJson_602454(protocol: Scheme; host: string; base: string;
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

proc validate_PutSchemaFromJson_602453(path: JsonNode; query: JsonNode;
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
  var valid_602455 = header.getOrDefault("X-Amz-Signature")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Signature", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Content-Sha256", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Date")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Date", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Credential")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Credential", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Security-Token")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Security-Token", valid_602459
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602460 = header.getOrDefault("x-amz-data-partition")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = nil)
  if valid_602460 != nil:
    section.add "x-amz-data-partition", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Algorithm")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Algorithm", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-SignedHeaders", valid_602462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602464: Call_PutSchemaFromJson_602452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_602464.validator(path, query, header, formData, body)
  let scheme = call_602464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602464.url(scheme.get, call_602464.host, call_602464.base,
                         call_602464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602464, url, valid)

proc call*(call_602465: Call_PutSchemaFromJson_602452; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_602466 = newJObject()
  if body != nil:
    body_602466 = body
  result = call_602465.call(nil, nil, nil, nil, body_602466)

var putSchemaFromJson* = Call_PutSchemaFromJson_602452(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_602453, base: "/",
    url: url_PutSchemaFromJson_602454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_602467 = ref object of OpenApiRestCall_601389
proc url_GetSchemaAsJson_602469(protocol: Scheme; host: string; base: string;
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

proc validate_GetSchemaAsJson_602468(path: JsonNode; query: JsonNode;
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
  var valid_602470 = header.getOrDefault("X-Amz-Signature")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Signature", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Content-Sha256", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Date")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Date", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Credential")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Credential", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Security-Token")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Security-Token", valid_602474
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602475 = header.getOrDefault("x-amz-data-partition")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "x-amz-data-partition", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-SignedHeaders", valid_602477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602478: Call_GetSchemaAsJson_602467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_602478.validator(path, query, header, formData, body)
  let scheme = call_602478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602478.url(scheme.get, call_602478.host, call_602478.base,
                         call_602478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602478, url, valid)

proc call*(call_602479: Call_GetSchemaAsJson_602467): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  result = call_602479.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_602467(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_602468, base: "/", url: url_GetSchemaAsJson_602469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_602480 = ref object of OpenApiRestCall_601389
proc url_GetTypedLinkFacetInformation_602482(protocol: Scheme; host: string;
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

proc validate_GetTypedLinkFacetInformation_602481(path: JsonNode; query: JsonNode;
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
  var valid_602483 = header.getOrDefault("X-Amz-Signature")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Signature", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Content-Sha256", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Date")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Date", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Credential")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Credential", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Security-Token")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Security-Token", valid_602487
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602488 = header.getOrDefault("x-amz-data-partition")
  valid_602488 = validateParameter(valid_602488, JString, required = true,
                                 default = nil)
  if valid_602488 != nil:
    section.add "x-amz-data-partition", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Algorithm")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Algorithm", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-SignedHeaders", valid_602490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602492: Call_GetTypedLinkFacetInformation_602480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602492.validator(path, query, header, formData, body)
  let scheme = call_602492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602492.url(scheme.get, call_602492.host, call_602492.base,
                         call_602492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602492, url, valid)

proc call*(call_602493: Call_GetTypedLinkFacetInformation_602480; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602494 = newJObject()
  if body != nil:
    body_602494 = body
  result = call_602493.call(nil, nil, nil, nil, body_602494)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_602480(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_602481, base: "/",
    url: url_GetTypedLinkFacetInformation_602482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_602495 = ref object of OpenApiRestCall_601389
proc url_ListAppliedSchemaArns_602497(protocol: Scheme; host: string; base: string;
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

proc validate_ListAppliedSchemaArns_602496(path: JsonNode; query: JsonNode;
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
  var valid_602498 = query.getOrDefault("MaxResults")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "MaxResults", valid_602498
  var valid_602499 = query.getOrDefault("NextToken")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "NextToken", valid_602499
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
  var valid_602500 = header.getOrDefault("X-Amz-Signature")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Signature", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Content-Sha256", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Date")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Date", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Credential")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Credential", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Security-Token")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Security-Token", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Algorithm")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Algorithm", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-SignedHeaders", valid_602506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602508: Call_ListAppliedSchemaArns_602495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_602508.validator(path, query, header, formData, body)
  let scheme = call_602508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602508.url(scheme.get, call_602508.host, call_602508.base,
                         call_602508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602508, url, valid)

proc call*(call_602509: Call_ListAppliedSchemaArns_602495; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602510 = newJObject()
  var body_602511 = newJObject()
  add(query_602510, "MaxResults", newJString(MaxResults))
  add(query_602510, "NextToken", newJString(NextToken))
  if body != nil:
    body_602511 = body
  result = call_602509.call(nil, query_602510, nil, nil, body_602511)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_602495(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_602496, base: "/",
    url: url_ListAppliedSchemaArns_602497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_602513 = ref object of OpenApiRestCall_601389
proc url_ListAttachedIndices_602515(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttachedIndices_602514(path: JsonNode; query: JsonNode;
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
  var valid_602516 = query.getOrDefault("MaxResults")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "MaxResults", valid_602516
  var valid_602517 = query.getOrDefault("NextToken")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "NextToken", valid_602517
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
  var valid_602518 = header.getOrDefault("x-amz-consistency-level")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602518 != nil:
    section.add "x-amz-consistency-level", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Signature")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Signature", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Content-Sha256", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Date")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Date", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Credential")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Credential", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Security-Token")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Security-Token", valid_602523
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602524 = header.getOrDefault("x-amz-data-partition")
  valid_602524 = validateParameter(valid_602524, JString, required = true,
                                 default = nil)
  if valid_602524 != nil:
    section.add "x-amz-data-partition", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-SignedHeaders", valid_602526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602528: Call_ListAttachedIndices_602513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_602528.validator(path, query, header, formData, body)
  let scheme = call_602528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602528.url(scheme.get, call_602528.host, call_602528.base,
                         call_602528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602528, url, valid)

proc call*(call_602529: Call_ListAttachedIndices_602513; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602530 = newJObject()
  var body_602531 = newJObject()
  add(query_602530, "MaxResults", newJString(MaxResults))
  add(query_602530, "NextToken", newJString(NextToken))
  if body != nil:
    body_602531 = body
  result = call_602529.call(nil, query_602530, nil, nil, body_602531)

var listAttachedIndices* = Call_ListAttachedIndices_602513(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_602514, base: "/",
    url: url_ListAttachedIndices_602515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_602532 = ref object of OpenApiRestCall_601389
proc url_ListDevelopmentSchemaArns_602534(protocol: Scheme; host: string;
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

proc validate_ListDevelopmentSchemaArns_602533(path: JsonNode; query: JsonNode;
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
  var valid_602535 = query.getOrDefault("MaxResults")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "MaxResults", valid_602535
  var valid_602536 = query.getOrDefault("NextToken")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "NextToken", valid_602536
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
  var valid_602537 = header.getOrDefault("X-Amz-Signature")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Signature", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Content-Sha256", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Date")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Date", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Credential")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Credential", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Security-Token")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Security-Token", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Algorithm")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Algorithm", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-SignedHeaders", valid_602543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602545: Call_ListDevelopmentSchemaArns_602532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_602545.validator(path, query, header, formData, body)
  let scheme = call_602545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602545.url(scheme.get, call_602545.host, call_602545.base,
                         call_602545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602545, url, valid)

proc call*(call_602546: Call_ListDevelopmentSchemaArns_602532; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602547 = newJObject()
  var body_602548 = newJObject()
  add(query_602547, "MaxResults", newJString(MaxResults))
  add(query_602547, "NextToken", newJString(NextToken))
  if body != nil:
    body_602548 = body
  result = call_602546.call(nil, query_602547, nil, nil, body_602548)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_602532(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_602533, base: "/",
    url: url_ListDevelopmentSchemaArns_602534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_602549 = ref object of OpenApiRestCall_601389
proc url_ListDirectories_602551(protocol: Scheme; host: string; base: string;
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

proc validate_ListDirectories_602550(path: JsonNode; query: JsonNode;
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
  var valid_602552 = query.getOrDefault("MaxResults")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "MaxResults", valid_602552
  var valid_602553 = query.getOrDefault("NextToken")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "NextToken", valid_602553
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
  var valid_602554 = header.getOrDefault("X-Amz-Signature")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Signature", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Content-Sha256", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Date")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Date", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Credential")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Credential", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Security-Token")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Security-Token", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Algorithm")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Algorithm", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-SignedHeaders", valid_602560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602562: Call_ListDirectories_602549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_602562.validator(path, query, header, formData, body)
  let scheme = call_602562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602562.url(scheme.get, call_602562.host, call_602562.base,
                         call_602562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602562, url, valid)

proc call*(call_602563: Call_ListDirectories_602549; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602564 = newJObject()
  var body_602565 = newJObject()
  add(query_602564, "MaxResults", newJString(MaxResults))
  add(query_602564, "NextToken", newJString(NextToken))
  if body != nil:
    body_602565 = body
  result = call_602563.call(nil, query_602564, nil, nil, body_602565)

var listDirectories* = Call_ListDirectories_602549(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_602550, base: "/", url: url_ListDirectories_602551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_602566 = ref object of OpenApiRestCall_601389
proc url_ListFacetAttributes_602568(protocol: Scheme; host: string; base: string;
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

proc validate_ListFacetAttributes_602567(path: JsonNode; query: JsonNode;
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
  var valid_602569 = query.getOrDefault("MaxResults")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "MaxResults", valid_602569
  var valid_602570 = query.getOrDefault("NextToken")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "NextToken", valid_602570
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
  var valid_602571 = header.getOrDefault("X-Amz-Signature")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Signature", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Content-Sha256", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Date")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Date", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Credential")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Credential", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Security-Token")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Security-Token", valid_602575
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602576 = header.getOrDefault("x-amz-data-partition")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = nil)
  if valid_602576 != nil:
    section.add "x-amz-data-partition", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Algorithm")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Algorithm", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-SignedHeaders", valid_602578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602580: Call_ListFacetAttributes_602566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_602580.validator(path, query, header, formData, body)
  let scheme = call_602580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602580.url(scheme.get, call_602580.host, call_602580.base,
                         call_602580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602580, url, valid)

proc call*(call_602581: Call_ListFacetAttributes_602566; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602582 = newJObject()
  var body_602583 = newJObject()
  add(query_602582, "MaxResults", newJString(MaxResults))
  add(query_602582, "NextToken", newJString(NextToken))
  if body != nil:
    body_602583 = body
  result = call_602581.call(nil, query_602582, nil, nil, body_602583)

var listFacetAttributes* = Call_ListFacetAttributes_602566(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_602567, base: "/",
    url: url_ListFacetAttributes_602568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_602584 = ref object of OpenApiRestCall_601389
proc url_ListFacetNames_602586(protocol: Scheme; host: string; base: string;
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

proc validate_ListFacetNames_602585(path: JsonNode; query: JsonNode;
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
  var valid_602587 = query.getOrDefault("MaxResults")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "MaxResults", valid_602587
  var valid_602588 = query.getOrDefault("NextToken")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "NextToken", valid_602588
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
  var valid_602589 = header.getOrDefault("X-Amz-Signature")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Signature", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Content-Sha256", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Date")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Date", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Credential")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Credential", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Security-Token")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Security-Token", valid_602593
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602594 = header.getOrDefault("x-amz-data-partition")
  valid_602594 = validateParameter(valid_602594, JString, required = true,
                                 default = nil)
  if valid_602594 != nil:
    section.add "x-amz-data-partition", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Algorithm")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Algorithm", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-SignedHeaders", valid_602596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602598: Call_ListFacetNames_602584; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_602598.validator(path, query, header, formData, body)
  let scheme = call_602598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602598.url(scheme.get, call_602598.host, call_602598.base,
                         call_602598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602598, url, valid)

proc call*(call_602599: Call_ListFacetNames_602584; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602600 = newJObject()
  var body_602601 = newJObject()
  add(query_602600, "MaxResults", newJString(MaxResults))
  add(query_602600, "NextToken", newJString(NextToken))
  if body != nil:
    body_602601 = body
  result = call_602599.call(nil, query_602600, nil, nil, body_602601)

var listFacetNames* = Call_ListFacetNames_602584(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_602585, base: "/", url: url_ListFacetNames_602586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_602602 = ref object of OpenApiRestCall_601389
proc url_ListIncomingTypedLinks_602604(protocol: Scheme; host: string; base: string;
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

proc validate_ListIncomingTypedLinks_602603(path: JsonNode; query: JsonNode;
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
  var valid_602605 = header.getOrDefault("X-Amz-Signature")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Signature", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Content-Sha256", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Date")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Date", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Credential")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Credential", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Security-Token")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Security-Token", valid_602609
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602610 = header.getOrDefault("x-amz-data-partition")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = nil)
  if valid_602610 != nil:
    section.add "x-amz-data-partition", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Algorithm")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Algorithm", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-SignedHeaders", valid_602612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602614: Call_ListIncomingTypedLinks_602602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602614.validator(path, query, header, formData, body)
  let scheme = call_602614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602614.url(scheme.get, call_602614.host, call_602614.base,
                         call_602614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602614, url, valid)

proc call*(call_602615: Call_ListIncomingTypedLinks_602602; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602616 = newJObject()
  if body != nil:
    body_602616 = body
  result = call_602615.call(nil, nil, nil, nil, body_602616)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_602602(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_602603, base: "/",
    url: url_ListIncomingTypedLinks_602604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_602617 = ref object of OpenApiRestCall_601389
proc url_ListIndex_602619(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListIndex_602618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602620 = query.getOrDefault("MaxResults")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "MaxResults", valid_602620
  var valid_602621 = query.getOrDefault("NextToken")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "NextToken", valid_602621
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
  var valid_602622 = header.getOrDefault("x-amz-consistency-level")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602622 != nil:
    section.add "x-amz-consistency-level", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Signature")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Signature", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Content-Sha256", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Date")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Date", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Credential")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Credential", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Security-Token")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Security-Token", valid_602627
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602628 = header.getOrDefault("x-amz-data-partition")
  valid_602628 = validateParameter(valid_602628, JString, required = true,
                                 default = nil)
  if valid_602628 != nil:
    section.add "x-amz-data-partition", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Algorithm")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Algorithm", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-SignedHeaders", valid_602630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602632: Call_ListIndex_602617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_602632.validator(path, query, header, formData, body)
  let scheme = call_602632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602632.url(scheme.get, call_602632.host, call_602632.base,
                         call_602632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602632, url, valid)

proc call*(call_602633: Call_ListIndex_602617; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602634 = newJObject()
  var body_602635 = newJObject()
  add(query_602634, "MaxResults", newJString(MaxResults))
  add(query_602634, "NextToken", newJString(NextToken))
  if body != nil:
    body_602635 = body
  result = call_602633.call(nil, query_602634, nil, nil, body_602635)

var listIndex* = Call_ListIndex_602617(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_602618,
                                    base: "/", url: url_ListIndex_602619,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListManagedSchemaArns_602636 = ref object of OpenApiRestCall_601389
proc url_ListManagedSchemaArns_602638(protocol: Scheme; host: string; base: string;
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

proc validate_ListManagedSchemaArns_602637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602639 = query.getOrDefault("MaxResults")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "MaxResults", valid_602639
  var valid_602640 = query.getOrDefault("NextToken")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "NextToken", valid_602640
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
  var valid_602641 = header.getOrDefault("X-Amz-Signature")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Signature", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Date")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Date", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Credential")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Credential", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Security-Token")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Security-Token", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Algorithm")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Algorithm", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602649: Call_ListManagedSchemaArns_602636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_602649.validator(path, query, header, formData, body)
  let scheme = call_602649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602649.url(scheme.get, call_602649.host, call_602649.base,
                         call_602649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602649, url, valid)

proc call*(call_602650: Call_ListManagedSchemaArns_602636; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listManagedSchemaArns
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602651 = newJObject()
  var body_602652 = newJObject()
  add(query_602651, "MaxResults", newJString(MaxResults))
  add(query_602651, "NextToken", newJString(NextToken))
  if body != nil:
    body_602652 = body
  result = call_602650.call(nil, query_602651, nil, nil, body_602652)

var listManagedSchemaArns* = Call_ListManagedSchemaArns_602636(
    name: "listManagedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/managed",
    validator: validate_ListManagedSchemaArns_602637, base: "/",
    url: url_ListManagedSchemaArns_602638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_602653 = ref object of OpenApiRestCall_601389
proc url_ListObjectAttributes_602655(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectAttributes_602654(path: JsonNode; query: JsonNode;
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
  var valid_602656 = query.getOrDefault("MaxResults")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "MaxResults", valid_602656
  var valid_602657 = query.getOrDefault("NextToken")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "NextToken", valid_602657
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
  var valid_602658 = header.getOrDefault("x-amz-consistency-level")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602658 != nil:
    section.add "x-amz-consistency-level", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Signature")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Signature", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Content-Sha256", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Date")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Date", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Credential")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Credential", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Security-Token")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Security-Token", valid_602663
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602664 = header.getOrDefault("x-amz-data-partition")
  valid_602664 = validateParameter(valid_602664, JString, required = true,
                                 default = nil)
  if valid_602664 != nil:
    section.add "x-amz-data-partition", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Algorithm")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Algorithm", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-SignedHeaders", valid_602666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602668: Call_ListObjectAttributes_602653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_602668.validator(path, query, header, formData, body)
  let scheme = call_602668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602668.url(scheme.get, call_602668.host, call_602668.base,
                         call_602668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602668, url, valid)

proc call*(call_602669: Call_ListObjectAttributes_602653; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602670 = newJObject()
  var body_602671 = newJObject()
  add(query_602670, "MaxResults", newJString(MaxResults))
  add(query_602670, "NextToken", newJString(NextToken))
  if body != nil:
    body_602671 = body
  result = call_602669.call(nil, query_602670, nil, nil, body_602671)

var listObjectAttributes* = Call_ListObjectAttributes_602653(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_602654, base: "/",
    url: url_ListObjectAttributes_602655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_602672 = ref object of OpenApiRestCall_601389
proc url_ListObjectChildren_602674(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectChildren_602673(path: JsonNode; query: JsonNode;
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
  var valid_602675 = query.getOrDefault("MaxResults")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "MaxResults", valid_602675
  var valid_602676 = query.getOrDefault("NextToken")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "NextToken", valid_602676
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
  var valid_602677 = header.getOrDefault("x-amz-consistency-level")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602677 != nil:
    section.add "x-amz-consistency-level", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Signature")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Signature", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Content-Sha256", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Date")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Date", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Credential")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Credential", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Security-Token")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Security-Token", valid_602682
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602683 = header.getOrDefault("x-amz-data-partition")
  valid_602683 = validateParameter(valid_602683, JString, required = true,
                                 default = nil)
  if valid_602683 != nil:
    section.add "x-amz-data-partition", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Algorithm")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Algorithm", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-SignedHeaders", valid_602685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602687: Call_ListObjectChildren_602672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_602687.validator(path, query, header, formData, body)
  let scheme = call_602687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602687.url(scheme.get, call_602687.host, call_602687.base,
                         call_602687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602687, url, valid)

proc call*(call_602688: Call_ListObjectChildren_602672; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602689 = newJObject()
  var body_602690 = newJObject()
  add(query_602689, "MaxResults", newJString(MaxResults))
  add(query_602689, "NextToken", newJString(NextToken))
  if body != nil:
    body_602690 = body
  result = call_602688.call(nil, query_602689, nil, nil, body_602690)

var listObjectChildren* = Call_ListObjectChildren_602672(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_602673, base: "/",
    url: url_ListObjectChildren_602674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_602691 = ref object of OpenApiRestCall_601389
proc url_ListObjectParentPaths_602693(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectParentPaths_602692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602694 = query.getOrDefault("MaxResults")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "MaxResults", valid_602694
  var valid_602695 = query.getOrDefault("NextToken")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "NextToken", valid_602695
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
  var valid_602696 = header.getOrDefault("X-Amz-Signature")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Signature", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Content-Sha256", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Date")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Date", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Credential")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Credential", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Security-Token")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Security-Token", valid_602700
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602701 = header.getOrDefault("x-amz-data-partition")
  valid_602701 = validateParameter(valid_602701, JString, required = true,
                                 default = nil)
  if valid_602701 != nil:
    section.add "x-amz-data-partition", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Algorithm")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Algorithm", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-SignedHeaders", valid_602703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_ListObjectParentPaths_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602705, url, valid)

proc call*(call_602706: Call_ListObjectParentPaths_602691; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602707 = newJObject()
  var body_602708 = newJObject()
  add(query_602707, "MaxResults", newJString(MaxResults))
  add(query_602707, "NextToken", newJString(NextToken))
  if body != nil:
    body_602708 = body
  result = call_602706.call(nil, query_602707, nil, nil, body_602708)

var listObjectParentPaths* = Call_ListObjectParentPaths_602691(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_602692, base: "/",
    url: url_ListObjectParentPaths_602693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_602709 = ref object of OpenApiRestCall_601389
proc url_ListObjectParents_602711(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectParents_602710(path: JsonNode; query: JsonNode;
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
  var valid_602712 = query.getOrDefault("MaxResults")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "MaxResults", valid_602712
  var valid_602713 = query.getOrDefault("NextToken")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "NextToken", valid_602713
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
  var valid_602714 = header.getOrDefault("x-amz-consistency-level")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602714 != nil:
    section.add "x-amz-consistency-level", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Signature")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Signature", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Content-Sha256", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Date")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Date", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Credential")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Credential", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Security-Token")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Security-Token", valid_602719
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602720 = header.getOrDefault("x-amz-data-partition")
  valid_602720 = validateParameter(valid_602720, JString, required = true,
                                 default = nil)
  if valid_602720 != nil:
    section.add "x-amz-data-partition", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Algorithm")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Algorithm", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-SignedHeaders", valid_602722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602724: Call_ListObjectParents_602709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_602724.validator(path, query, header, formData, body)
  let scheme = call_602724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602724.url(scheme.get, call_602724.host, call_602724.base,
                         call_602724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602724, url, valid)

proc call*(call_602725: Call_ListObjectParents_602709; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602726 = newJObject()
  var body_602727 = newJObject()
  add(query_602726, "MaxResults", newJString(MaxResults))
  add(query_602726, "NextToken", newJString(NextToken))
  if body != nil:
    body_602727 = body
  result = call_602725.call(nil, query_602726, nil, nil, body_602727)

var listObjectParents* = Call_ListObjectParents_602709(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_602710, base: "/",
    url: url_ListObjectParents_602711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_602728 = ref object of OpenApiRestCall_601389
proc url_ListObjectPolicies_602730(protocol: Scheme; host: string; base: string;
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

proc validate_ListObjectPolicies_602729(path: JsonNode; query: JsonNode;
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
  var valid_602731 = query.getOrDefault("MaxResults")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "MaxResults", valid_602731
  var valid_602732 = query.getOrDefault("NextToken")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "NextToken", valid_602732
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
  var valid_602733 = header.getOrDefault("x-amz-consistency-level")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602733 != nil:
    section.add "x-amz-consistency-level", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Signature")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Signature", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Content-Sha256", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Date")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Date", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Credential")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Credential", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Security-Token")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Security-Token", valid_602738
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602739 = header.getOrDefault("x-amz-data-partition")
  valid_602739 = validateParameter(valid_602739, JString, required = true,
                                 default = nil)
  if valid_602739 != nil:
    section.add "x-amz-data-partition", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Algorithm")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Algorithm", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-SignedHeaders", valid_602741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602743: Call_ListObjectPolicies_602728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_602743.validator(path, query, header, formData, body)
  let scheme = call_602743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602743.url(scheme.get, call_602743.host, call_602743.base,
                         call_602743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602743, url, valid)

proc call*(call_602744: Call_ListObjectPolicies_602728; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602745 = newJObject()
  var body_602746 = newJObject()
  add(query_602745, "MaxResults", newJString(MaxResults))
  add(query_602745, "NextToken", newJString(NextToken))
  if body != nil:
    body_602746 = body
  result = call_602744.call(nil, query_602745, nil, nil, body_602746)

var listObjectPolicies* = Call_ListObjectPolicies_602728(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_602729, base: "/",
    url: url_ListObjectPolicies_602730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_602747 = ref object of OpenApiRestCall_601389
proc url_ListOutgoingTypedLinks_602749(protocol: Scheme; host: string; base: string;
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

proc validate_ListOutgoingTypedLinks_602748(path: JsonNode; query: JsonNode;
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
  var valid_602750 = header.getOrDefault("X-Amz-Signature")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Signature", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Content-Sha256", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Date")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Date", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Credential")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Credential", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Security-Token")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Security-Token", valid_602754
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602755 = header.getOrDefault("x-amz-data-partition")
  valid_602755 = validateParameter(valid_602755, JString, required = true,
                                 default = nil)
  if valid_602755 != nil:
    section.add "x-amz-data-partition", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Algorithm")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Algorithm", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-SignedHeaders", valid_602757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602759: Call_ListOutgoingTypedLinks_602747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602759.validator(path, query, header, formData, body)
  let scheme = call_602759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602759.url(scheme.get, call_602759.host, call_602759.base,
                         call_602759.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602759, url, valid)

proc call*(call_602760: Call_ListOutgoingTypedLinks_602747; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602761 = newJObject()
  if body != nil:
    body_602761 = body
  result = call_602760.call(nil, nil, nil, nil, body_602761)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_602747(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_602748, base: "/",
    url: url_ListOutgoingTypedLinks_602749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_602762 = ref object of OpenApiRestCall_601389
proc url_ListPolicyAttachments_602764(protocol: Scheme; host: string; base: string;
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

proc validate_ListPolicyAttachments_602763(path: JsonNode; query: JsonNode;
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
  var valid_602765 = query.getOrDefault("MaxResults")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "MaxResults", valid_602765
  var valid_602766 = query.getOrDefault("NextToken")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "NextToken", valid_602766
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
  var valid_602767 = header.getOrDefault("x-amz-consistency-level")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_602767 != nil:
    section.add "x-amz-consistency-level", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Signature")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Signature", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Content-Sha256", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Date")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Date", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Credential")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Credential", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Security-Token")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Security-Token", valid_602772
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602773 = header.getOrDefault("x-amz-data-partition")
  valid_602773 = validateParameter(valid_602773, JString, required = true,
                                 default = nil)
  if valid_602773 != nil:
    section.add "x-amz-data-partition", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Algorithm")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Algorithm", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-SignedHeaders", valid_602775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602777: Call_ListPolicyAttachments_602762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_602777.validator(path, query, header, formData, body)
  let scheme = call_602777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602777.url(scheme.get, call_602777.host, call_602777.base,
                         call_602777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602777, url, valid)

proc call*(call_602778: Call_ListPolicyAttachments_602762; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602779 = newJObject()
  var body_602780 = newJObject()
  add(query_602779, "MaxResults", newJString(MaxResults))
  add(query_602779, "NextToken", newJString(NextToken))
  if body != nil:
    body_602780 = body
  result = call_602778.call(nil, query_602779, nil, nil, body_602780)

var listPolicyAttachments* = Call_ListPolicyAttachments_602762(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_602763, base: "/",
    url: url_ListPolicyAttachments_602764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_602781 = ref object of OpenApiRestCall_601389
proc url_ListPublishedSchemaArns_602783(protocol: Scheme; host: string; base: string;
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

proc validate_ListPublishedSchemaArns_602782(path: JsonNode; query: JsonNode;
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
  var valid_602784 = query.getOrDefault("MaxResults")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "MaxResults", valid_602784
  var valid_602785 = query.getOrDefault("NextToken")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "NextToken", valid_602785
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
  var valid_602786 = header.getOrDefault("X-Amz-Signature")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Signature", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Content-Sha256", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Date")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Date", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Credential")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Credential", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Security-Token")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Security-Token", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Algorithm")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Algorithm", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-SignedHeaders", valid_602792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602794: Call_ListPublishedSchemaArns_602781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_602794.validator(path, query, header, formData, body)
  let scheme = call_602794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602794.url(scheme.get, call_602794.host, call_602794.base,
                         call_602794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602794, url, valid)

proc call*(call_602795: Call_ListPublishedSchemaArns_602781; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602796 = newJObject()
  var body_602797 = newJObject()
  add(query_602796, "MaxResults", newJString(MaxResults))
  add(query_602796, "NextToken", newJString(NextToken))
  if body != nil:
    body_602797 = body
  result = call_602795.call(nil, query_602796, nil, nil, body_602797)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_602781(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_602782, base: "/",
    url: url_ListPublishedSchemaArns_602783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602798 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602800(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602799(path: JsonNode; query: JsonNode;
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
  var valid_602801 = query.getOrDefault("MaxResults")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "MaxResults", valid_602801
  var valid_602802 = query.getOrDefault("NextToken")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "NextToken", valid_602802
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
  var valid_602803 = header.getOrDefault("X-Amz-Signature")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Signature", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Content-Sha256", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Date")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Date", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Credential")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Credential", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Security-Token")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Security-Token", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Algorithm")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Algorithm", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-SignedHeaders", valid_602809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602811: Call_ListTagsForResource_602798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_602811.validator(path, query, header, formData, body)
  let scheme = call_602811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602811.url(scheme.get, call_602811.host, call_602811.base,
                         call_602811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602811, url, valid)

proc call*(call_602812: Call_ListTagsForResource_602798; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602813 = newJObject()
  var body_602814 = newJObject()
  add(query_602813, "MaxResults", newJString(MaxResults))
  add(query_602813, "NextToken", newJString(NextToken))
  if body != nil:
    body_602814 = body
  result = call_602812.call(nil, query_602813, nil, nil, body_602814)

var listTagsForResource* = Call_ListTagsForResource_602798(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_602799, base: "/",
    url: url_ListTagsForResource_602800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_602815 = ref object of OpenApiRestCall_601389
proc url_ListTypedLinkFacetAttributes_602817(protocol: Scheme; host: string;
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

proc validate_ListTypedLinkFacetAttributes_602816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602818 = query.getOrDefault("MaxResults")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "MaxResults", valid_602818
  var valid_602819 = query.getOrDefault("NextToken")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "NextToken", valid_602819
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
  var valid_602820 = header.getOrDefault("X-Amz-Signature")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Signature", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Content-Sha256", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Date")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Date", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Credential")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Credential", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Security-Token")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Security-Token", valid_602824
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602825 = header.getOrDefault("x-amz-data-partition")
  valid_602825 = validateParameter(valid_602825, JString, required = true,
                                 default = nil)
  if valid_602825 != nil:
    section.add "x-amz-data-partition", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Algorithm")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Algorithm", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-SignedHeaders", valid_602827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602829: Call_ListTypedLinkFacetAttributes_602815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602829.validator(path, query, header, formData, body)
  let scheme = call_602829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602829.url(scheme.get, call_602829.host, call_602829.base,
                         call_602829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602829, url, valid)

proc call*(call_602830: Call_ListTypedLinkFacetAttributes_602815; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602831 = newJObject()
  var body_602832 = newJObject()
  add(query_602831, "MaxResults", newJString(MaxResults))
  add(query_602831, "NextToken", newJString(NextToken))
  if body != nil:
    body_602832 = body
  result = call_602830.call(nil, query_602831, nil, nil, body_602832)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_602815(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_602816, base: "/",
    url: url_ListTypedLinkFacetAttributes_602817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_602833 = ref object of OpenApiRestCall_601389
proc url_ListTypedLinkFacetNames_602835(protocol: Scheme; host: string; base: string;
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

proc validate_ListTypedLinkFacetNames_602834(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602836 = query.getOrDefault("MaxResults")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "MaxResults", valid_602836
  var valid_602837 = query.getOrDefault("NextToken")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "NextToken", valid_602837
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
  var valid_602838 = header.getOrDefault("X-Amz-Signature")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Signature", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Content-Sha256", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-Date")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Date", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-Credential")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Credential", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-Security-Token")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Security-Token", valid_602842
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602843 = header.getOrDefault("x-amz-data-partition")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = nil)
  if valid_602843 != nil:
    section.add "x-amz-data-partition", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Algorithm")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Algorithm", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-SignedHeaders", valid_602845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602847: Call_ListTypedLinkFacetNames_602833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602847.validator(path, query, header, formData, body)
  let scheme = call_602847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602847.url(scheme.get, call_602847.host, call_602847.base,
                         call_602847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602847, url, valid)

proc call*(call_602848: Call_ListTypedLinkFacetNames_602833; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602849 = newJObject()
  var body_602850 = newJObject()
  add(query_602849, "MaxResults", newJString(MaxResults))
  add(query_602849, "NextToken", newJString(NextToken))
  if body != nil:
    body_602850 = body
  result = call_602848.call(nil, query_602849, nil, nil, body_602850)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_602833(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_602834, base: "/",
    url: url_ListTypedLinkFacetNames_602835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_602851 = ref object of OpenApiRestCall_601389
proc url_LookupPolicy_602853(protocol: Scheme; host: string; base: string;
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

proc validate_LookupPolicy_602852(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602854 = query.getOrDefault("MaxResults")
  valid_602854 = validateParameter(valid_602854, JString, required = false,
                                 default = nil)
  if valid_602854 != nil:
    section.add "MaxResults", valid_602854
  var valid_602855 = query.getOrDefault("NextToken")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "NextToken", valid_602855
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
  var valid_602856 = header.getOrDefault("X-Amz-Signature")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Signature", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Content-Sha256", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Date")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Date", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Credential")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Credential", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Security-Token")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Security-Token", valid_602860
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602861 = header.getOrDefault("x-amz-data-partition")
  valid_602861 = validateParameter(valid_602861, JString, required = true,
                                 default = nil)
  if valid_602861 != nil:
    section.add "x-amz-data-partition", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Algorithm")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Algorithm", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-SignedHeaders", valid_602863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602865: Call_LookupPolicy_602851; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ## 
  let valid = call_602865.validator(path, query, header, formData, body)
  let scheme = call_602865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602865.url(scheme.get, call_602865.host, call_602865.base,
                         call_602865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602865, url, valid)

proc call*(call_602866: Call_LookupPolicy_602851; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602867 = newJObject()
  var body_602868 = newJObject()
  add(query_602867, "MaxResults", newJString(MaxResults))
  add(query_602867, "NextToken", newJString(NextToken))
  if body != nil:
    body_602868 = body
  result = call_602866.call(nil, query_602867, nil, nil, body_602868)

var lookupPolicy* = Call_LookupPolicy_602851(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_602852, base: "/", url: url_LookupPolicy_602853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_602869 = ref object of OpenApiRestCall_601389
proc url_PublishSchema_602871(protocol: Scheme; host: string; base: string;
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

proc validate_PublishSchema_602870(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Content-Sha256", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Date")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Date", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602877 = header.getOrDefault("x-amz-data-partition")
  valid_602877 = validateParameter(valid_602877, JString, required = true,
                                 default = nil)
  if valid_602877 != nil:
    section.add "x-amz-data-partition", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Algorithm")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Algorithm", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-SignedHeaders", valid_602879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602881: Call_PublishSchema_602869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_602881.validator(path, query, header, formData, body)
  let scheme = call_602881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602881.url(scheme.get, call_602881.host, call_602881.base,
                         call_602881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602881, url, valid)

proc call*(call_602882: Call_PublishSchema_602869; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_602883 = newJObject()
  if body != nil:
    body_602883 = body
  result = call_602882.call(nil, nil, nil, nil, body_602883)

var publishSchema* = Call_PublishSchema_602869(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_602870, base: "/", url: url_PublishSchema_602871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_602884 = ref object of OpenApiRestCall_601389
proc url_RemoveFacetFromObject_602886(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveFacetFromObject_602885(path: JsonNode; query: JsonNode;
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
  var valid_602887 = header.getOrDefault("X-Amz-Signature")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Signature", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Content-Sha256", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Date")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Date", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Security-Token")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Security-Token", valid_602891
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602892 = header.getOrDefault("x-amz-data-partition")
  valid_602892 = validateParameter(valid_602892, JString, required = true,
                                 default = nil)
  if valid_602892 != nil:
    section.add "x-amz-data-partition", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Algorithm")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Algorithm", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-SignedHeaders", valid_602894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602896: Call_RemoveFacetFromObject_602884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_602896.validator(path, query, header, formData, body)
  let scheme = call_602896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602896.url(scheme.get, call_602896.host, call_602896.base,
                         call_602896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602896, url, valid)

proc call*(call_602897: Call_RemoveFacetFromObject_602884; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_602898 = newJObject()
  if body != nil:
    body_602898 = body
  result = call_602897.call(nil, nil, nil, nil, body_602898)

var removeFacetFromObject* = Call_RemoveFacetFromObject_602884(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_602885, base: "/",
    url: url_RemoveFacetFromObject_602886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602899 = ref object of OpenApiRestCall_601389
proc url_TagResource_602901(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602900(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Content-Sha256", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Date")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Date", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Credential")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Credential", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Security-Token")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Security-Token", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Algorithm")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Algorithm", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-SignedHeaders", valid_602908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602910: Call_TagResource_602899; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_602910.validator(path, query, header, formData, body)
  let scheme = call_602910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602910.url(scheme.get, call_602910.host, call_602910.base,
                         call_602910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602910, url, valid)

proc call*(call_602911: Call_TagResource_602899; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_602912 = newJObject()
  if body != nil:
    body_602912 = body
  result = call_602911.call(nil, nil, nil, nil, body_602912)

var tagResource* = Call_TagResource_602899(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_602900,
                                        base: "/", url: url_TagResource_602901,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602913 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602915(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602914(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602916 = header.getOrDefault("X-Amz-Signature")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Signature", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Content-Sha256", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Credential")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Credential", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Security-Token")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Security-Token", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Algorithm")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Algorithm", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-SignedHeaders", valid_602922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602924: Call_UntagResource_602913; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_602924.validator(path, query, header, formData, body)
  let scheme = call_602924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602924.url(scheme.get, call_602924.host, call_602924.base,
                         call_602924.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602924, url, valid)

proc call*(call_602925: Call_UntagResource_602913; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_602926 = newJObject()
  if body != nil:
    body_602926 = body
  result = call_602925.call(nil, nil, nil, nil, body_602926)

var untagResource* = Call_UntagResource_602913(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_602914, base: "/", url: url_UntagResource_602915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_602927 = ref object of OpenApiRestCall_601389
proc url_UpdateLinkAttributes_602929(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLinkAttributes_602928(path: JsonNode; query: JsonNode;
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
  ## href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602930 = header.getOrDefault("X-Amz-Signature")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Signature", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Content-Sha256", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Credential")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Credential", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602935 = header.getOrDefault("x-amz-data-partition")
  valid_602935 = validateParameter(valid_602935, JString, required = true,
                                 default = nil)
  if valid_602935 != nil:
    section.add "x-amz-data-partition", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602939: Call_UpdateLinkAttributes_602927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_602939.validator(path, query, header, formData, body)
  let scheme = call_602939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602939.url(scheme.get, call_602939.host, call_602939.base,
                         call_602939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602939, url, valid)

proc call*(call_602940: Call_UpdateLinkAttributes_602927; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_602941 = newJObject()
  if body != nil:
    body_602941 = body
  result = call_602940.call(nil, nil, nil, nil, body_602941)

var updateLinkAttributes* = Call_UpdateLinkAttributes_602927(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_602928, base: "/",
    url: url_UpdateLinkAttributes_602929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_602942 = ref object of OpenApiRestCall_601389
proc url_UpdateObjectAttributes_602944(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateObjectAttributes_602943(path: JsonNode; query: JsonNode;
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
  var valid_602945 = header.getOrDefault("X-Amz-Signature")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Signature", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Content-Sha256", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Date")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Date", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-Credential")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Credential", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Security-Token")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Security-Token", valid_602949
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602950 = header.getOrDefault("x-amz-data-partition")
  valid_602950 = validateParameter(valid_602950, JString, required = true,
                                 default = nil)
  if valid_602950 != nil:
    section.add "x-amz-data-partition", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Algorithm")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Algorithm", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-SignedHeaders", valid_602952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602954: Call_UpdateObjectAttributes_602942; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_602954.validator(path, query, header, formData, body)
  let scheme = call_602954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602954.url(scheme.get, call_602954.host, call_602954.base,
                         call_602954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602954, url, valid)

proc call*(call_602955: Call_UpdateObjectAttributes_602942; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_602956 = newJObject()
  if body != nil:
    body_602956 = body
  result = call_602955.call(nil, nil, nil, nil, body_602956)

var updateObjectAttributes* = Call_UpdateObjectAttributes_602942(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_602943, base: "/",
    url: url_UpdateObjectAttributes_602944, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_602957 = ref object of OpenApiRestCall_601389
proc url_UpdateSchema_602959(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSchema_602958(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602960 = header.getOrDefault("X-Amz-Signature")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Signature", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Content-Sha256", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Date")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Date", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Credential")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Credential", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-Security-Token")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-Security-Token", valid_602964
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602965 = header.getOrDefault("x-amz-data-partition")
  valid_602965 = validateParameter(valid_602965, JString, required = true,
                                 default = nil)
  if valid_602965 != nil:
    section.add "x-amz-data-partition", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Algorithm")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Algorithm", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-SignedHeaders", valid_602967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602969: Call_UpdateSchema_602957; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_602969.validator(path, query, header, formData, body)
  let scheme = call_602969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602969.url(scheme.get, call_602969.host, call_602969.base,
                         call_602969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602969, url, valid)

proc call*(call_602970: Call_UpdateSchema_602957; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_602971 = newJObject()
  if body != nil:
    body_602971 = body
  result = call_602970.call(nil, nil, nil, nil, body_602971)

var updateSchema* = Call_UpdateSchema_602957(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_602958, base: "/", url: url_UpdateSchema_602959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_602972 = ref object of OpenApiRestCall_601389
proc url_UpdateTypedLinkFacet_602974(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTypedLinkFacet_602973(path: JsonNode; query: JsonNode;
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
  var valid_602975 = header.getOrDefault("X-Amz-Signature")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Signature", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Content-Sha256", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Date")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Date", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Credential")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Credential", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Security-Token")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Security-Token", valid_602979
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_602980 = header.getOrDefault("x-amz-data-partition")
  valid_602980 = validateParameter(valid_602980, JString, required = true,
                                 default = nil)
  if valid_602980 != nil:
    section.add "x-amz-data-partition", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-Algorithm")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Algorithm", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-SignedHeaders", valid_602982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602984: Call_UpdateTypedLinkFacet_602972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_602984.validator(path, query, header, formData, body)
  let scheme = call_602984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602984.url(scheme.get, call_602984.host, call_602984.base,
                         call_602984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602984, url, valid)

proc call*(call_602985: Call_UpdateTypedLinkFacet_602972; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_602986 = newJObject()
  if body != nil:
    body_602986 = body
  result = call_602985.call(nil, nil, nil, nil, body_602986)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_602972(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_602973, base: "/",
    url: url_UpdateTypedLinkFacet_602974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_602987 = ref object of OpenApiRestCall_601389
proc url_UpgradeAppliedSchema_602989(protocol: Scheme; host: string; base: string;
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

proc validate_UpgradeAppliedSchema_602988(path: JsonNode; query: JsonNode;
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
  var valid_602990 = header.getOrDefault("X-Amz-Signature")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Signature", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Content-Sha256", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Date")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Date", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Credential")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Credential", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Security-Token")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Security-Token", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Algorithm")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Algorithm", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-SignedHeaders", valid_602996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602998: Call_UpgradeAppliedSchema_602987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_602998.validator(path, query, header, formData, body)
  let scheme = call_602998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602998.url(scheme.get, call_602998.host, call_602998.base,
                         call_602998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602998, url, valid)

proc call*(call_602999: Call_UpgradeAppliedSchema_602987; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_602987(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_602988, base: "/",
    url: url_UpgradeAppliedSchema_602989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_603001 = ref object of OpenApiRestCall_601389
proc url_UpgradePublishedSchema_603003(protocol: Scheme; host: string; base: string;
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

proc validate_UpgradePublishedSchema_603002(path: JsonNode; query: JsonNode;
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
  var valid_603004 = header.getOrDefault("X-Amz-Signature")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Signature", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Content-Sha256", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Date")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Date", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Credential")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Credential", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Security-Token")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Security-Token", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-Algorithm")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-Algorithm", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-SignedHeaders", valid_603010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603012: Call_UpgradePublishedSchema_603001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_603012.validator(path, query, header, formData, body)
  let scheme = call_603012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603012.url(scheme.get, call_603012.host, call_603012.base,
                         call_603012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603012, url, valid)

proc call*(call_603013: Call_UpgradePublishedSchema_603001; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_603014 = newJObject()
  if body != nil:
    body_603014 = body
  result = call_603013.call(nil, nil, nil, nil, body_603014)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_603001(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_603002, base: "/",
    url: url_UpgradePublishedSchema_603003, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
