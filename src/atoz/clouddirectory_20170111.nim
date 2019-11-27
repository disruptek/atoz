
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AddFacetToObject_599705 = ref object of OpenApiRestCall_599368
proc url_AddFacetToObject_599707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddFacetToObject_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_599826 = header.getOrDefault("x-amz-data-partition")
  valid_599826 = validateParameter(valid_599826, JString, required = true,
                                 default = nil)
  if valid_599826 != nil:
    section.add "x-amz-data-partition", valid_599826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599850: Call_AddFacetToObject_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_599850.validator(path, query, header, formData, body)
  let scheme = call_599850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599850.url(scheme.get, call_599850.host, call_599850.base,
                         call_599850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599850, url, valid)

proc call*(call_599921: Call_AddFacetToObject_599705; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_599922 = newJObject()
  if body != nil:
    body_599922 = body
  result = call_599921.call(nil, nil, nil, nil, body_599922)

var addFacetToObject* = Call_AddFacetToObject_599705(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_599706, base: "/",
    url: url_AddFacetToObject_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_599961 = ref object of OpenApiRestCall_599368
proc url_ApplySchema_599963(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApplySchema_599962(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599964 = header.getOrDefault("X-Amz-Date")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Date", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Security-Token")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Security-Token", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Content-Sha256", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Algorithm")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Algorithm", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Signature")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Signature", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-SignedHeaders", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Credential")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Credential", valid_599970
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_599971 = header.getOrDefault("x-amz-data-partition")
  valid_599971 = validateParameter(valid_599971, JString, required = true,
                                 default = nil)
  if valid_599971 != nil:
    section.add "x-amz-data-partition", valid_599971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_ApplySchema_599961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_ApplySchema_599961; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_599975 = newJObject()
  if body != nil:
    body_599975 = body
  result = call_599974.call(nil, nil, nil, nil, body_599975)

var applySchema* = Call_ApplySchema_599961(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_599962,
                                        base: "/", url: url_ApplySchema_599963,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_599976 = ref object of OpenApiRestCall_599368
proc url_AttachObject_599978(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachObject_599977(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_599986 = header.getOrDefault("x-amz-data-partition")
  valid_599986 = validateParameter(valid_599986, JString, required = true,
                                 default = nil)
  if valid_599986 != nil:
    section.add "x-amz-data-partition", valid_599986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599988: Call_AttachObject_599976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_599988.validator(path, query, header, formData, body)
  let scheme = call_599988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599988.url(scheme.get, call_599988.host, call_599988.base,
                         call_599988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599988, url, valid)

proc call*(call_599989: Call_AttachObject_599976; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_599990 = newJObject()
  if body != nil:
    body_599990 = body
  result = call_599989.call(nil, nil, nil, nil, body_599990)

var attachObject* = Call_AttachObject_599976(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_599977, base: "/", url: url_AttachObject_599978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_599991 = ref object of OpenApiRestCall_599368
proc url_AttachPolicy_599993(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachPolicy_599992(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599994 = header.getOrDefault("X-Amz-Date")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Date", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Security-Token")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Security-Token", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Content-Sha256", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Algorithm")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Algorithm", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Signature")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Signature", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-SignedHeaders", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Credential")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Credential", valid_600000
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600001 = header.getOrDefault("x-amz-data-partition")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = nil)
  if valid_600001 != nil:
    section.add "x-amz-data-partition", valid_600001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600003: Call_AttachPolicy_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_600003.validator(path, query, header, formData, body)
  let scheme = call_600003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600003.url(scheme.get, call_600003.host, call_600003.base,
                         call_600003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600003, url, valid)

proc call*(call_600004: Call_AttachPolicy_599991; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_600005 = newJObject()
  if body != nil:
    body_600005 = body
  result = call_600004.call(nil, nil, nil, nil, body_600005)

var attachPolicy* = Call_AttachPolicy_599991(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_599992, base: "/", url: url_AttachPolicy_599993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_600006 = ref object of OpenApiRestCall_599368
proc url_AttachToIndex_600008(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachToIndex_600007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600009 = header.getOrDefault("X-Amz-Date")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Date", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Security-Token")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Security-Token", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Content-Sha256", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Algorithm")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Algorithm", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Signature")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Signature", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-SignedHeaders", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Credential")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Credential", valid_600015
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600016 = header.getOrDefault("x-amz-data-partition")
  valid_600016 = validateParameter(valid_600016, JString, required = true,
                                 default = nil)
  if valid_600016 != nil:
    section.add "x-amz-data-partition", valid_600016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600018: Call_AttachToIndex_600006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_600018.validator(path, query, header, formData, body)
  let scheme = call_600018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600018.url(scheme.get, call_600018.host, call_600018.base,
                         call_600018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600018, url, valid)

proc call*(call_600019: Call_AttachToIndex_600006; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_600020 = newJObject()
  if body != nil:
    body_600020 = body
  result = call_600019.call(nil, nil, nil, nil, body_600020)

var attachToIndex* = Call_AttachToIndex_600006(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_600007, base: "/", url: url_AttachToIndex_600008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_600021 = ref object of OpenApiRestCall_599368
proc url_AttachTypedLink_600023(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AttachTypedLink_600022(path: JsonNode; query: JsonNode;
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
  var valid_600024 = header.getOrDefault("X-Amz-Date")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Date", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Security-Token")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Security-Token", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600031 = header.getOrDefault("x-amz-data-partition")
  valid_600031 = validateParameter(valid_600031, JString, required = true,
                                 default = nil)
  if valid_600031 != nil:
    section.add "x-amz-data-partition", valid_600031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600033: Call_AttachTypedLink_600021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600033.validator(path, query, header, formData, body)
  let scheme = call_600033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600033.url(scheme.get, call_600033.host, call_600033.base,
                         call_600033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600033, url, valid)

proc call*(call_600034: Call_AttachTypedLink_600021; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600035 = newJObject()
  if body != nil:
    body_600035 = body
  result = call_600034.call(nil, nil, nil, nil, body_600035)

var attachTypedLink* = Call_AttachTypedLink_600021(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_600022, base: "/", url: url_AttachTypedLink_600023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_600036 = ref object of OpenApiRestCall_599368
proc url_BatchRead_600038(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchRead_600037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600058 = header.getOrDefault("x-amz-consistency-level")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600058 != nil:
    section.add "x-amz-consistency-level", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600060 = header.getOrDefault("x-amz-data-partition")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "x-amz-data-partition", valid_600060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_BatchRead_600036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_BatchRead_600036; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_600064 = newJObject()
  if body != nil:
    body_600064 = body
  result = call_600063.call(nil, nil, nil, nil, body_600064)

var batchRead* = Call_BatchRead_600036(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_600037,
                                    base: "/", url: url_BatchRead_600038,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_600065 = ref object of OpenApiRestCall_599368
proc url_BatchWrite_600067(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchWrite_600066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600068 = header.getOrDefault("X-Amz-Date")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Date", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Security-Token")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Security-Token", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600075 = header.getOrDefault("x-amz-data-partition")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = nil)
  if valid_600075 != nil:
    section.add "x-amz-data-partition", valid_600075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600077: Call_BatchWrite_600065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_600077.validator(path, query, header, formData, body)
  let scheme = call_600077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600077.url(scheme.get, call_600077.host, call_600077.base,
                         call_600077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600077, url, valid)

proc call*(call_600078: Call_BatchWrite_600065; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_600079 = newJObject()
  if body != nil:
    body_600079 = body
  result = call_600078.call(nil, nil, nil, nil, body_600079)

var batchWrite* = Call_BatchWrite_600065(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_600066,
                                      base: "/", url: url_BatchWrite_600067,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_600080 = ref object of OpenApiRestCall_599368
proc url_CreateDirectory_600082(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDirectory_600081(path: JsonNode; query: JsonNode;
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600090 = header.getOrDefault("x-amz-data-partition")
  valid_600090 = validateParameter(valid_600090, JString, required = true,
                                 default = nil)
  if valid_600090 != nil:
    section.add "x-amz-data-partition", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_CreateDirectory_600080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_CreateDirectory_600080; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.</p> <p>You can also quickly create a directory using a managed schema, called the <code>QuickStartSchema</code>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_managed.html">Managed Schema</a> in the <i>Amazon Cloud Directory Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_600094 = newJObject()
  if body != nil:
    body_600094 = body
  result = call_600093.call(nil, nil, nil, nil, body_600094)

var createDirectory* = Call_CreateDirectory_600080(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_600081, base: "/", url: url_CreateDirectory_600082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_600095 = ref object of OpenApiRestCall_599368
proc url_CreateFacet_600097(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFacet_600096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600098 = header.getOrDefault("X-Amz-Date")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Date", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Security-Token")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Security-Token", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600105 = header.getOrDefault("x-amz-data-partition")
  valid_600105 = validateParameter(valid_600105, JString, required = true,
                                 default = nil)
  if valid_600105 != nil:
    section.add "x-amz-data-partition", valid_600105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600107: Call_CreateFacet_600095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_600107.validator(path, query, header, formData, body)
  let scheme = call_600107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600107.url(scheme.get, call_600107.host, call_600107.base,
                         call_600107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600107, url, valid)

proc call*(call_600108: Call_CreateFacet_600095; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_600109 = newJObject()
  if body != nil:
    body_600109 = body
  result = call_600108.call(nil, nil, nil, nil, body_600109)

var createFacet* = Call_CreateFacet_600095(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_600096,
                                        base: "/", url: url_CreateFacet_600097,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_600110 = ref object of OpenApiRestCall_599368
proc url_CreateIndex_600112(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIndex_600111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600113 = header.getOrDefault("X-Amz-Date")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Date", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Security-Token")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Security-Token", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600120 = header.getOrDefault("x-amz-data-partition")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "x-amz-data-partition", valid_600120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600122: Call_CreateIndex_600110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ## 
  let valid = call_600122.validator(path, query, header, formData, body)
  let scheme = call_600122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600122.url(scheme.get, call_600122.host, call_600122.base,
                         call_600122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600122, url, valid)

proc call*(call_600123: Call_CreateIndex_600110; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/indexing_search.html">Indexing and search</a> for more information.
  ##   body: JObject (required)
  var body_600124 = newJObject()
  if body != nil:
    body_600124 = body
  result = call_600123.call(nil, nil, nil, nil, body_600124)

var createIndex* = Call_CreateIndex_600110(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_600111,
                                        base: "/", url: url_CreateIndex_600112,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_600125 = ref object of OpenApiRestCall_599368
proc url_CreateObject_600127(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateObject_600126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600135 = header.getOrDefault("x-amz-data-partition")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "x-amz-data-partition", valid_600135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_CreateObject_600125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_CreateObject_600125; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_600139 = newJObject()
  if body != nil:
    body_600139 = body
  result = call_600138.call(nil, nil, nil, nil, body_600139)

var createObject* = Call_CreateObject_600125(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_600126, base: "/", url: url_CreateObject_600127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_600140 = ref object of OpenApiRestCall_599368
proc url_CreateSchema_600142(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSchema_600141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateSchema_600140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateSchema_600140; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var createSchema* = Call_CreateSchema_600140(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_600141, base: "/", url: url_CreateSchema_600142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_600154 = ref object of OpenApiRestCall_599368
proc url_CreateTypedLinkFacet_600156(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTypedLinkFacet_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600164 = header.getOrDefault("x-amz-data-partition")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = nil)
  if valid_600164 != nil:
    section.add "x-amz-data-partition", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_CreateTypedLinkFacet_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_CreateTypedLinkFacet_600154; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_600154(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_600155, base: "/",
    url: url_CreateTypedLinkFacet_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_600169 = ref object of OpenApiRestCall_599368
proc url_DeleteDirectory_600171(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDirectory_600170(path: JsonNode; query: JsonNode;
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Content-Sha256", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Algorithm")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Algorithm", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Signature")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Signature", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-SignedHeaders", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Credential")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Credential", valid_600178
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600179 = header.getOrDefault("x-amz-data-partition")
  valid_600179 = validateParameter(valid_600179, JString, required = true,
                                 default = nil)
  if valid_600179 != nil:
    section.add "x-amz-data-partition", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_DeleteDirectory_600169; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_DeleteDirectory_600169): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_600181.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_600169(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_600170, base: "/", url: url_DeleteDirectory_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_600182 = ref object of OpenApiRestCall_599368
proc url_DeleteFacet_600184(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFacet_600183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600185 = header.getOrDefault("X-Amz-Date")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Date", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Security-Token")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Security-Token", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Content-Sha256", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Algorithm")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Algorithm", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Signature")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Signature", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-SignedHeaders", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Credential")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Credential", valid_600191
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600192 = header.getOrDefault("x-amz-data-partition")
  valid_600192 = validateParameter(valid_600192, JString, required = true,
                                 default = nil)
  if valid_600192 != nil:
    section.add "x-amz-data-partition", valid_600192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600194: Call_DeleteFacet_600182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_600194.validator(path, query, header, formData, body)
  let scheme = call_600194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600194.url(scheme.get, call_600194.host, call_600194.base,
                         call_600194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600194, url, valid)

proc call*(call_600195: Call_DeleteFacet_600182; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_600196 = newJObject()
  if body != nil:
    body_600196 = body
  result = call_600195.call(nil, nil, nil, nil, body_600196)

var deleteFacet* = Call_DeleteFacet_600182(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_600183,
                                        base: "/", url: url_DeleteFacet_600184,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_600197 = ref object of OpenApiRestCall_599368
proc url_DeleteObject_600199(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteObject_600198(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600200 = header.getOrDefault("X-Amz-Date")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Date", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Security-Token")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Security-Token", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Content-Sha256", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Algorithm")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Algorithm", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Signature")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Signature", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-SignedHeaders", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Credential")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Credential", valid_600206
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600207 = header.getOrDefault("x-amz-data-partition")
  valid_600207 = validateParameter(valid_600207, JString, required = true,
                                 default = nil)
  if valid_600207 != nil:
    section.add "x-amz-data-partition", valid_600207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600209: Call_DeleteObject_600197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ## 
  let valid = call_600209.validator(path, query, header, formData, body)
  let scheme = call_600209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600209.url(scheme.get, call_600209.host, call_600209.base,
                         call_600209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600209, url, valid)

proc call*(call_600210: Call_DeleteObject_600197; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted. The maximum number of attributes that can be deleted during an object deletion is 30. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/limits.html">Amazon Cloud Directory Limits</a>.
  ##   body: JObject (required)
  var body_600211 = newJObject()
  if body != nil:
    body_600211 = body
  result = call_600210.call(nil, nil, nil, nil, body_600211)

var deleteObject* = Call_DeleteObject_600197(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_600198, base: "/", url: url_DeleteObject_600199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_600212 = ref object of OpenApiRestCall_599368
proc url_DeleteSchema_600214(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSchema_600213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600215 = header.getOrDefault("X-Amz-Date")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Date", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Security-Token")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Security-Token", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Content-Sha256", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Algorithm")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Algorithm", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Signature")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Signature", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-SignedHeaders", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Credential")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Credential", valid_600221
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600222 = header.getOrDefault("x-amz-data-partition")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "x-amz-data-partition", valid_600222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600223: Call_DeleteSchema_600212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_600223.validator(path, query, header, formData, body)
  let scheme = call_600223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600223.url(scheme.get, call_600223.host, call_600223.base,
                         call_600223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600223, url, valid)

proc call*(call_600224: Call_DeleteSchema_600212): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_600224.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_600212(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_600213, base: "/", url: url_DeleteSchema_600214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_600225 = ref object of OpenApiRestCall_599368
proc url_DeleteTypedLinkFacet_600227(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTypedLinkFacet_600226(path: JsonNode; query: JsonNode;
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
  var valid_600228 = header.getOrDefault("X-Amz-Date")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Date", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Security-Token")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Security-Token", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600235 = header.getOrDefault("x-amz-data-partition")
  valid_600235 = validateParameter(valid_600235, JString, required = true,
                                 default = nil)
  if valid_600235 != nil:
    section.add "x-amz-data-partition", valid_600235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600237: Call_DeleteTypedLinkFacet_600225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600237.validator(path, query, header, formData, body)
  let scheme = call_600237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600237.url(scheme.get, call_600237.host, call_600237.base,
                         call_600237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600237, url, valid)

proc call*(call_600238: Call_DeleteTypedLinkFacet_600225; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600239 = newJObject()
  if body != nil:
    body_600239 = body
  result = call_600238.call(nil, nil, nil, nil, body_600239)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_600225(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_600226, base: "/",
    url: url_DeleteTypedLinkFacet_600227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_600240 = ref object of OpenApiRestCall_599368
proc url_DetachFromIndex_600242(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachFromIndex_600241(path: JsonNode; query: JsonNode;
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
  var valid_600243 = header.getOrDefault("X-Amz-Date")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Date", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Security-Token")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Security-Token", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Content-Sha256", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-Algorithm")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-Algorithm", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Signature")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Signature", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-SignedHeaders", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Credential")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Credential", valid_600249
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600250 = header.getOrDefault("x-amz-data-partition")
  valid_600250 = validateParameter(valid_600250, JString, required = true,
                                 default = nil)
  if valid_600250 != nil:
    section.add "x-amz-data-partition", valid_600250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600252: Call_DetachFromIndex_600240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_600252.validator(path, query, header, formData, body)
  let scheme = call_600252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600252.url(scheme.get, call_600252.host, call_600252.base,
                         call_600252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600252, url, valid)

proc call*(call_600253: Call_DetachFromIndex_600240; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_600254 = newJObject()
  if body != nil:
    body_600254 = body
  result = call_600253.call(nil, nil, nil, nil, body_600254)

var detachFromIndex* = Call_DetachFromIndex_600240(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_600241, base: "/", url: url_DetachFromIndex_600242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_600255 = ref object of OpenApiRestCall_599368
proc url_DetachObject_600257(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachObject_600256(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600258 = header.getOrDefault("X-Amz-Date")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Date", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Security-Token")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Security-Token", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Content-Sha256", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Algorithm")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Algorithm", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Signature")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Signature", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-SignedHeaders", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Credential")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Credential", valid_600264
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600265 = header.getOrDefault("x-amz-data-partition")
  valid_600265 = validateParameter(valid_600265, JString, required = true,
                                 default = nil)
  if valid_600265 != nil:
    section.add "x-amz-data-partition", valid_600265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600267: Call_DetachObject_600255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_600267.validator(path, query, header, formData, body)
  let scheme = call_600267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600267.url(scheme.get, call_600267.host, call_600267.base,
                         call_600267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600267, url, valid)

proc call*(call_600268: Call_DetachObject_600255; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_600269 = newJObject()
  if body != nil:
    body_600269 = body
  result = call_600268.call(nil, nil, nil, nil, body_600269)

var detachObject* = Call_DetachObject_600255(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_600256, base: "/", url: url_DetachObject_600257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_600270 = ref object of OpenApiRestCall_599368
proc url_DetachPolicy_600272(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachPolicy_600271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600273 = header.getOrDefault("X-Amz-Date")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Date", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Security-Token")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Security-Token", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Content-Sha256", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Algorithm")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Algorithm", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Signature")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Signature", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-SignedHeaders", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Credential")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Credential", valid_600279
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600280 = header.getOrDefault("x-amz-data-partition")
  valid_600280 = validateParameter(valid_600280, JString, required = true,
                                 default = nil)
  if valid_600280 != nil:
    section.add "x-amz-data-partition", valid_600280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600282: Call_DetachPolicy_600270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_600282.validator(path, query, header, formData, body)
  let scheme = call_600282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600282.url(scheme.get, call_600282.host, call_600282.base,
                         call_600282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600282, url, valid)

proc call*(call_600283: Call_DetachPolicy_600270; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_600284 = newJObject()
  if body != nil:
    body_600284 = body
  result = call_600283.call(nil, nil, nil, nil, body_600284)

var detachPolicy* = Call_DetachPolicy_600270(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_600271, base: "/", url: url_DetachPolicy_600272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_600285 = ref object of OpenApiRestCall_599368
proc url_DetachTypedLink_600287(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetachTypedLink_600286(path: JsonNode; query: JsonNode;
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
  var valid_600288 = header.getOrDefault("X-Amz-Date")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Date", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Security-Token")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Security-Token", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Content-Sha256", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Algorithm")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Algorithm", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Signature")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Signature", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-SignedHeaders", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Credential")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Credential", valid_600294
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600295 = header.getOrDefault("x-amz-data-partition")
  valid_600295 = validateParameter(valid_600295, JString, required = true,
                                 default = nil)
  if valid_600295 != nil:
    section.add "x-amz-data-partition", valid_600295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600297: Call_DetachTypedLink_600285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600297.validator(path, query, header, formData, body)
  let scheme = call_600297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600297.url(scheme.get, call_600297.host, call_600297.base,
                         call_600297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600297, url, valid)

proc call*(call_600298: Call_DetachTypedLink_600285; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600299 = newJObject()
  if body != nil:
    body_600299 = body
  result = call_600298.call(nil, nil, nil, nil, body_600299)

var detachTypedLink* = Call_DetachTypedLink_600285(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_600286, base: "/", url: url_DetachTypedLink_600287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_600300 = ref object of OpenApiRestCall_599368
proc url_DisableDirectory_600302(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableDirectory_600301(path: JsonNode; query: JsonNode;
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
  var valid_600303 = header.getOrDefault("X-Amz-Date")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Date", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-Security-Token")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Security-Token", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Content-Sha256", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Algorithm")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Algorithm", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Signature")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Signature", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-SignedHeaders", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Credential")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Credential", valid_600309
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600310 = header.getOrDefault("x-amz-data-partition")
  valid_600310 = validateParameter(valid_600310, JString, required = true,
                                 default = nil)
  if valid_600310 != nil:
    section.add "x-amz-data-partition", valid_600310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600311: Call_DisableDirectory_600300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_600311.validator(path, query, header, formData, body)
  let scheme = call_600311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600311.url(scheme.get, call_600311.host, call_600311.base,
                         call_600311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600311, url, valid)

proc call*(call_600312: Call_DisableDirectory_600300): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_600312.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_600300(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_600301, base: "/",
    url: url_DisableDirectory_600302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_600313 = ref object of OpenApiRestCall_599368
proc url_EnableDirectory_600315(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableDirectory_600314(path: JsonNode; query: JsonNode;
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
  var valid_600316 = header.getOrDefault("X-Amz-Date")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Date", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Security-Token")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Security-Token", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Content-Sha256", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Algorithm")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Algorithm", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Signature")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Signature", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-SignedHeaders", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Credential")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Credential", valid_600322
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600323 = header.getOrDefault("x-amz-data-partition")
  valid_600323 = validateParameter(valid_600323, JString, required = true,
                                 default = nil)
  if valid_600323 != nil:
    section.add "x-amz-data-partition", valid_600323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600324: Call_EnableDirectory_600313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_600324.validator(path, query, header, formData, body)
  let scheme = call_600324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600324.url(scheme.get, call_600324.host, call_600324.base,
                         call_600324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600324, url, valid)

proc call*(call_600325: Call_EnableDirectory_600313): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_600325.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_600313(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_600314, base: "/", url: url_EnableDirectory_600315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_600326 = ref object of OpenApiRestCall_599368
proc url_GetAppliedSchemaVersion_600328(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppliedSchemaVersion_600327(path: JsonNode; query: JsonNode;
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
  var valid_600329 = header.getOrDefault("X-Amz-Date")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Date", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Security-Token")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Security-Token", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Content-Sha256", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Algorithm")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Algorithm", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Signature")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Signature", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-SignedHeaders", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Credential")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Credential", valid_600335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600337: Call_GetAppliedSchemaVersion_600326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_600337.validator(path, query, header, formData, body)
  let scheme = call_600337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600337.url(scheme.get, call_600337.host, call_600337.base,
                         call_600337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600337, url, valid)

proc call*(call_600338: Call_GetAppliedSchemaVersion_600326; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_600339 = newJObject()
  if body != nil:
    body_600339 = body
  result = call_600338.call(nil, nil, nil, nil, body_600339)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_600326(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_600327, base: "/",
    url: url_GetAppliedSchemaVersion_600328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_600340 = ref object of OpenApiRestCall_599368
proc url_GetDirectory_600342(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDirectory_600341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600343 = header.getOrDefault("X-Amz-Date")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Date", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Security-Token")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Security-Token", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Content-Sha256", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Algorithm")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Algorithm", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Signature")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Signature", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-SignedHeaders", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Credential")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Credential", valid_600349
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600350 = header.getOrDefault("x-amz-data-partition")
  valid_600350 = validateParameter(valid_600350, JString, required = true,
                                 default = nil)
  if valid_600350 != nil:
    section.add "x-amz-data-partition", valid_600350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600351: Call_GetDirectory_600340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_600351.validator(path, query, header, formData, body)
  let scheme = call_600351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600351.url(scheme.get, call_600351.host, call_600351.base,
                         call_600351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600351, url, valid)

proc call*(call_600352: Call_GetDirectory_600340): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_600352.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_600340(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_600341, base: "/", url: url_GetDirectory_600342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_600353 = ref object of OpenApiRestCall_599368
proc url_UpdateFacet_600355(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFacet_600354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600356 = header.getOrDefault("X-Amz-Date")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Date", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Security-Token")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Security-Token", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Content-Sha256", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Algorithm")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Algorithm", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Signature")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Signature", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-SignedHeaders", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Credential")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Credential", valid_600362
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600363 = header.getOrDefault("x-amz-data-partition")
  valid_600363 = validateParameter(valid_600363, JString, required = true,
                                 default = nil)
  if valid_600363 != nil:
    section.add "x-amz-data-partition", valid_600363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600365: Call_UpdateFacet_600353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_600365.validator(path, query, header, formData, body)
  let scheme = call_600365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600365.url(scheme.get, call_600365.host, call_600365.base,
                         call_600365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600365, url, valid)

proc call*(call_600366: Call_UpdateFacet_600353; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600367 = newJObject()
  if body != nil:
    body_600367 = body
  result = call_600366.call(nil, nil, nil, nil, body_600367)

var updateFacet* = Call_UpdateFacet_600353(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_600354,
                                        base: "/", url: url_UpdateFacet_600355,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_600368 = ref object of OpenApiRestCall_599368
proc url_GetFacet_600370(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFacet_600369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600371 = header.getOrDefault("X-Amz-Date")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Date", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Security-Token")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Security-Token", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Content-Sha256", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Algorithm")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Algorithm", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Signature")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Signature", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-SignedHeaders", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Credential")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Credential", valid_600377
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600378 = header.getOrDefault("x-amz-data-partition")
  valid_600378 = validateParameter(valid_600378, JString, required = true,
                                 default = nil)
  if valid_600378 != nil:
    section.add "x-amz-data-partition", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600380: Call_GetFacet_600368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_GetFacet_600368; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_600382 = newJObject()
  if body != nil:
    body_600382 = body
  result = call_600381.call(nil, nil, nil, nil, body_600382)

var getFacet* = Call_GetFacet_600368(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_600369, base: "/",
                                  url: url_GetFacet_600370,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_600383 = ref object of OpenApiRestCall_599368
proc url_GetLinkAttributes_600385(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLinkAttributes_600384(path: JsonNode; query: JsonNode;
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
  var valid_600386 = header.getOrDefault("X-Amz-Date")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Date", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Security-Token")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Security-Token", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Content-Sha256", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Algorithm")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Algorithm", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Signature")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Signature", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-SignedHeaders", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Credential")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Credential", valid_600392
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600393 = header.getOrDefault("x-amz-data-partition")
  valid_600393 = validateParameter(valid_600393, JString, required = true,
                                 default = nil)
  if valid_600393 != nil:
    section.add "x-amz-data-partition", valid_600393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600395: Call_GetLinkAttributes_600383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_600395.validator(path, query, header, formData, body)
  let scheme = call_600395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600395.url(scheme.get, call_600395.host, call_600395.base,
                         call_600395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600395, url, valid)

proc call*(call_600396: Call_GetLinkAttributes_600383; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_600397 = newJObject()
  if body != nil:
    body_600397 = body
  result = call_600396.call(nil, nil, nil, nil, body_600397)

var getLinkAttributes* = Call_GetLinkAttributes_600383(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_600384, base: "/",
    url: url_GetLinkAttributes_600385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_600398 = ref object of OpenApiRestCall_599368
proc url_GetObjectAttributes_600400(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectAttributes_600399(path: JsonNode; query: JsonNode;
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
  var valid_600401 = header.getOrDefault("X-Amz-Date")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Date", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Security-Token")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Security-Token", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Content-Sha256", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Algorithm")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Algorithm", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Signature")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Signature", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-SignedHeaders", valid_600406
  var valid_600407 = header.getOrDefault("x-amz-consistency-level")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600407 != nil:
    section.add "x-amz-consistency-level", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Credential")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Credential", valid_600408
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600409 = header.getOrDefault("x-amz-data-partition")
  valid_600409 = validateParameter(valid_600409, JString, required = true,
                                 default = nil)
  if valid_600409 != nil:
    section.add "x-amz-data-partition", valid_600409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600411: Call_GetObjectAttributes_600398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_600411.validator(path, query, header, formData, body)
  let scheme = call_600411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600411.url(scheme.get, call_600411.host, call_600411.base,
                         call_600411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600411, url, valid)

proc call*(call_600412: Call_GetObjectAttributes_600398; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_600413 = newJObject()
  if body != nil:
    body_600413 = body
  result = call_600412.call(nil, nil, nil, nil, body_600413)

var getObjectAttributes* = Call_GetObjectAttributes_600398(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_600399, base: "/",
    url: url_GetObjectAttributes_600400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_600414 = ref object of OpenApiRestCall_599368
proc url_GetObjectInformation_600416(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetObjectInformation_600415(path: JsonNode; query: JsonNode;
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
  var valid_600417 = header.getOrDefault("X-Amz-Date")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Date", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Security-Token")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Security-Token", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Content-Sha256", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Algorithm")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Algorithm", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Signature")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Signature", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-SignedHeaders", valid_600422
  var valid_600423 = header.getOrDefault("x-amz-consistency-level")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600423 != nil:
    section.add "x-amz-consistency-level", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Credential")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Credential", valid_600424
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600425 = header.getOrDefault("x-amz-data-partition")
  valid_600425 = validateParameter(valid_600425, JString, required = true,
                                 default = nil)
  if valid_600425 != nil:
    section.add "x-amz-data-partition", valid_600425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600427: Call_GetObjectInformation_600414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_600427.validator(path, query, header, formData, body)
  let scheme = call_600427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600427.url(scheme.get, call_600427.host, call_600427.base,
                         call_600427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600427, url, valid)

proc call*(call_600428: Call_GetObjectInformation_600414; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_600429 = newJObject()
  if body != nil:
    body_600429 = body
  result = call_600428.call(nil, nil, nil, nil, body_600429)

var getObjectInformation* = Call_GetObjectInformation_600414(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_600415, base: "/",
    url: url_GetObjectInformation_600416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_600430 = ref object of OpenApiRestCall_599368
proc url_PutSchemaFromJson_600432(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSchemaFromJson_600431(path: JsonNode; query: JsonNode;
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
  var valid_600433 = header.getOrDefault("X-Amz-Date")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Date", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Security-Token")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Security-Token", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Content-Sha256", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Algorithm")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Algorithm", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Signature")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Signature", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-SignedHeaders", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Credential")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Credential", valid_600439
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600440 = header.getOrDefault("x-amz-data-partition")
  valid_600440 = validateParameter(valid_600440, JString, required = true,
                                 default = nil)
  if valid_600440 != nil:
    section.add "x-amz-data-partition", valid_600440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600442: Call_PutSchemaFromJson_600430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_600442.validator(path, query, header, formData, body)
  let scheme = call_600442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600442.url(scheme.get, call_600442.host, call_600442.base,
                         call_600442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600442, url, valid)

proc call*(call_600443: Call_PutSchemaFromJson_600430; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_600444 = newJObject()
  if body != nil:
    body_600444 = body
  result = call_600443.call(nil, nil, nil, nil, body_600444)

var putSchemaFromJson* = Call_PutSchemaFromJson_600430(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_600431, base: "/",
    url: url_PutSchemaFromJson_600432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_600445 = ref object of OpenApiRestCall_599368
proc url_GetSchemaAsJson_600447(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSchemaAsJson_600446(path: JsonNode; query: JsonNode;
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
  var valid_600448 = header.getOrDefault("X-Amz-Date")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Date", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Security-Token")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Security-Token", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Content-Sha256", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Algorithm")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Algorithm", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Signature")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Signature", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-SignedHeaders", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Credential")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Credential", valid_600454
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600455 = header.getOrDefault("x-amz-data-partition")
  valid_600455 = validateParameter(valid_600455, JString, required = true,
                                 default = nil)
  if valid_600455 != nil:
    section.add "x-amz-data-partition", valid_600455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600456: Call_GetSchemaAsJson_600445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  ## 
  let valid = call_600456.validator(path, query, header, formData, body)
  let scheme = call_600456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600456.url(scheme.get, call_600456.host, call_600456.base,
                         call_600456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600456, url, valid)

proc call*(call_600457: Call_GetSchemaAsJson_600445): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/schemas_jsonformat.html#schemas_json">JSON Schema Format</a> for more information.
  result = call_600457.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_600445(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_600446, base: "/", url: url_GetSchemaAsJson_600447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_600458 = ref object of OpenApiRestCall_599368
proc url_GetTypedLinkFacetInformation_600460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTypedLinkFacetInformation_600459(path: JsonNode; query: JsonNode;
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
  var valid_600461 = header.getOrDefault("X-Amz-Date")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Date", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Security-Token")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Security-Token", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-Content-Sha256", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Algorithm")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Algorithm", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Signature")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Signature", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-SignedHeaders", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Credential")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Credential", valid_600467
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600468 = header.getOrDefault("x-amz-data-partition")
  valid_600468 = validateParameter(valid_600468, JString, required = true,
                                 default = nil)
  if valid_600468 != nil:
    section.add "x-amz-data-partition", valid_600468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600470: Call_GetTypedLinkFacetInformation_600458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600470.validator(path, query, header, formData, body)
  let scheme = call_600470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600470.url(scheme.get, call_600470.host, call_600470.base,
                         call_600470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600470, url, valid)

proc call*(call_600471: Call_GetTypedLinkFacetInformation_600458; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600472 = newJObject()
  if body != nil:
    body_600472 = body
  result = call_600471.call(nil, nil, nil, nil, body_600472)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_600458(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_600459, base: "/",
    url: url_GetTypedLinkFacetInformation_600460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_600473 = ref object of OpenApiRestCall_599368
proc url_ListAppliedSchemaArns_600475(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAppliedSchemaArns_600474(path: JsonNode; query: JsonNode;
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
  var valid_600476 = query.getOrDefault("NextToken")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "NextToken", valid_600476
  var valid_600477 = query.getOrDefault("MaxResults")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "MaxResults", valid_600477
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
  var valid_600478 = header.getOrDefault("X-Amz-Date")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Date", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Security-Token")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Security-Token", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Content-Sha256", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Algorithm")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Algorithm", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Signature")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Signature", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-SignedHeaders", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Credential")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Credential", valid_600484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600486: Call_ListAppliedSchemaArns_600473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_600486.validator(path, query, header, formData, body)
  let scheme = call_600486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600486.url(scheme.get, call_600486.host, call_600486.base,
                         call_600486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600486, url, valid)

proc call*(call_600487: Call_ListAppliedSchemaArns_600473; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600488 = newJObject()
  var body_600489 = newJObject()
  add(query_600488, "NextToken", newJString(NextToken))
  if body != nil:
    body_600489 = body
  add(query_600488, "MaxResults", newJString(MaxResults))
  result = call_600487.call(nil, query_600488, nil, nil, body_600489)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_600473(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_600474, base: "/",
    url: url_ListAppliedSchemaArns_600475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_600491 = ref object of OpenApiRestCall_599368
proc url_ListAttachedIndices_600493(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAttachedIndices_600492(path: JsonNode; query: JsonNode;
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
  var valid_600494 = query.getOrDefault("NextToken")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "NextToken", valid_600494
  var valid_600495 = query.getOrDefault("MaxResults")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "MaxResults", valid_600495
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
  var valid_600496 = header.getOrDefault("X-Amz-Date")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Date", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Security-Token")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Security-Token", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Content-Sha256", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Algorithm")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Algorithm", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Signature")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Signature", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-SignedHeaders", valid_600501
  var valid_600502 = header.getOrDefault("x-amz-consistency-level")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600502 != nil:
    section.add "x-amz-consistency-level", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Credential")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Credential", valid_600503
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600504 = header.getOrDefault("x-amz-data-partition")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = nil)
  if valid_600504 != nil:
    section.add "x-amz-data-partition", valid_600504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600506: Call_ListAttachedIndices_600491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_600506.validator(path, query, header, formData, body)
  let scheme = call_600506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600506.url(scheme.get, call_600506.host, call_600506.base,
                         call_600506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600506, url, valid)

proc call*(call_600507: Call_ListAttachedIndices_600491; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600508 = newJObject()
  var body_600509 = newJObject()
  add(query_600508, "NextToken", newJString(NextToken))
  if body != nil:
    body_600509 = body
  add(query_600508, "MaxResults", newJString(MaxResults))
  result = call_600507.call(nil, query_600508, nil, nil, body_600509)

var listAttachedIndices* = Call_ListAttachedIndices_600491(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_600492, base: "/",
    url: url_ListAttachedIndices_600493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_600510 = ref object of OpenApiRestCall_599368
proc url_ListDevelopmentSchemaArns_600512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDevelopmentSchemaArns_600511(path: JsonNode; query: JsonNode;
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
  var valid_600513 = query.getOrDefault("NextToken")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "NextToken", valid_600513
  var valid_600514 = query.getOrDefault("MaxResults")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "MaxResults", valid_600514
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
  var valid_600515 = header.getOrDefault("X-Amz-Date")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Date", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Security-Token")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Security-Token", valid_600516
  var valid_600517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Content-Sha256", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Algorithm")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Algorithm", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Signature")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Signature", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-SignedHeaders", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Credential")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Credential", valid_600521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600523: Call_ListDevelopmentSchemaArns_600510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_600523.validator(path, query, header, formData, body)
  let scheme = call_600523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600523.url(scheme.get, call_600523.host, call_600523.base,
                         call_600523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600523, url, valid)

proc call*(call_600524: Call_ListDevelopmentSchemaArns_600510; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600525 = newJObject()
  var body_600526 = newJObject()
  add(query_600525, "NextToken", newJString(NextToken))
  if body != nil:
    body_600526 = body
  add(query_600525, "MaxResults", newJString(MaxResults))
  result = call_600524.call(nil, query_600525, nil, nil, body_600526)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_600510(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_600511, base: "/",
    url: url_ListDevelopmentSchemaArns_600512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_600527 = ref object of OpenApiRestCall_599368
proc url_ListDirectories_600529(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDirectories_600528(path: JsonNode; query: JsonNode;
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
  var valid_600530 = query.getOrDefault("NextToken")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "NextToken", valid_600530
  var valid_600531 = query.getOrDefault("MaxResults")
  valid_600531 = validateParameter(valid_600531, JString, required = false,
                                 default = nil)
  if valid_600531 != nil:
    section.add "MaxResults", valid_600531
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
  var valid_600532 = header.getOrDefault("X-Amz-Date")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Date", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Security-Token")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Security-Token", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Content-Sha256", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Algorithm")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Algorithm", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Signature")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Signature", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-SignedHeaders", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Credential")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Credential", valid_600538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600540: Call_ListDirectories_600527; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_600540.validator(path, query, header, formData, body)
  let scheme = call_600540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600540.url(scheme.get, call_600540.host, call_600540.base,
                         call_600540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600540, url, valid)

proc call*(call_600541: Call_ListDirectories_600527; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600542 = newJObject()
  var body_600543 = newJObject()
  add(query_600542, "NextToken", newJString(NextToken))
  if body != nil:
    body_600543 = body
  add(query_600542, "MaxResults", newJString(MaxResults))
  result = call_600541.call(nil, query_600542, nil, nil, body_600543)

var listDirectories* = Call_ListDirectories_600527(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_600528, base: "/", url: url_ListDirectories_600529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_600544 = ref object of OpenApiRestCall_599368
proc url_ListFacetAttributes_600546(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetAttributes_600545(path: JsonNode; query: JsonNode;
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
  var valid_600547 = query.getOrDefault("NextToken")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "NextToken", valid_600547
  var valid_600548 = query.getOrDefault("MaxResults")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "MaxResults", valid_600548
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
  var valid_600549 = header.getOrDefault("X-Amz-Date")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Date", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Security-Token")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Security-Token", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Content-Sha256", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Algorithm")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Algorithm", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Signature")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Signature", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-SignedHeaders", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Credential")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Credential", valid_600555
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600556 = header.getOrDefault("x-amz-data-partition")
  valid_600556 = validateParameter(valid_600556, JString, required = true,
                                 default = nil)
  if valid_600556 != nil:
    section.add "x-amz-data-partition", valid_600556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600558: Call_ListFacetAttributes_600544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_600558.validator(path, query, header, formData, body)
  let scheme = call_600558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600558.url(scheme.get, call_600558.host, call_600558.base,
                         call_600558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600558, url, valid)

proc call*(call_600559: Call_ListFacetAttributes_600544; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600560 = newJObject()
  var body_600561 = newJObject()
  add(query_600560, "NextToken", newJString(NextToken))
  if body != nil:
    body_600561 = body
  add(query_600560, "MaxResults", newJString(MaxResults))
  result = call_600559.call(nil, query_600560, nil, nil, body_600561)

var listFacetAttributes* = Call_ListFacetAttributes_600544(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_600545, base: "/",
    url: url_ListFacetAttributes_600546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_600562 = ref object of OpenApiRestCall_599368
proc url_ListFacetNames_600564(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFacetNames_600563(path: JsonNode; query: JsonNode;
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
  var valid_600565 = query.getOrDefault("NextToken")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "NextToken", valid_600565
  var valid_600566 = query.getOrDefault("MaxResults")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "MaxResults", valid_600566
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
  var valid_600567 = header.getOrDefault("X-Amz-Date")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Date", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Security-Token")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Security-Token", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Content-Sha256", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Algorithm")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Algorithm", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Signature")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Signature", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-SignedHeaders", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Credential")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Credential", valid_600573
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600574 = header.getOrDefault("x-amz-data-partition")
  valid_600574 = validateParameter(valid_600574, JString, required = true,
                                 default = nil)
  if valid_600574 != nil:
    section.add "x-amz-data-partition", valid_600574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600576: Call_ListFacetNames_600562; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_600576.validator(path, query, header, formData, body)
  let scheme = call_600576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600576.url(scheme.get, call_600576.host, call_600576.base,
                         call_600576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600576, url, valid)

proc call*(call_600577: Call_ListFacetNames_600562; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600578 = newJObject()
  var body_600579 = newJObject()
  add(query_600578, "NextToken", newJString(NextToken))
  if body != nil:
    body_600579 = body
  add(query_600578, "MaxResults", newJString(MaxResults))
  result = call_600577.call(nil, query_600578, nil, nil, body_600579)

var listFacetNames* = Call_ListFacetNames_600562(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_600563, base: "/", url: url_ListFacetNames_600564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_600580 = ref object of OpenApiRestCall_599368
proc url_ListIncomingTypedLinks_600582(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIncomingTypedLinks_600581(path: JsonNode; query: JsonNode;
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
  var valid_600583 = header.getOrDefault("X-Amz-Date")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Date", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Security-Token")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Security-Token", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Content-Sha256", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Algorithm")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Algorithm", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Signature")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Signature", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-SignedHeaders", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Credential")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Credential", valid_600589
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600590 = header.getOrDefault("x-amz-data-partition")
  valid_600590 = validateParameter(valid_600590, JString, required = true,
                                 default = nil)
  if valid_600590 != nil:
    section.add "x-amz-data-partition", valid_600590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600592: Call_ListIncomingTypedLinks_600580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600592.validator(path, query, header, formData, body)
  let scheme = call_600592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600592.url(scheme.get, call_600592.host, call_600592.base,
                         call_600592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600592, url, valid)

proc call*(call_600593: Call_ListIncomingTypedLinks_600580; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600594 = newJObject()
  if body != nil:
    body_600594 = body
  result = call_600593.call(nil, nil, nil, nil, body_600594)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_600580(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_600581, base: "/",
    url: url_ListIncomingTypedLinks_600582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_600595 = ref object of OpenApiRestCall_599368
proc url_ListIndex_600597(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIndex_600596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600598 = query.getOrDefault("NextToken")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "NextToken", valid_600598
  var valid_600599 = query.getOrDefault("MaxResults")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "MaxResults", valid_600599
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
  var valid_600600 = header.getOrDefault("X-Amz-Date")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Date", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Security-Token")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Security-Token", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Content-Sha256", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Algorithm")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Algorithm", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Signature")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Signature", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-SignedHeaders", valid_600605
  var valid_600606 = header.getOrDefault("x-amz-consistency-level")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600606 != nil:
    section.add "x-amz-consistency-level", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Credential")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Credential", valid_600607
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600608 = header.getOrDefault("x-amz-data-partition")
  valid_600608 = validateParameter(valid_600608, JString, required = true,
                                 default = nil)
  if valid_600608 != nil:
    section.add "x-amz-data-partition", valid_600608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600610: Call_ListIndex_600595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_600610.validator(path, query, header, formData, body)
  let scheme = call_600610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600610.url(scheme.get, call_600610.host, call_600610.base,
                         call_600610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600610, url, valid)

proc call*(call_600611: Call_ListIndex_600595; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600612 = newJObject()
  var body_600613 = newJObject()
  add(query_600612, "NextToken", newJString(NextToken))
  if body != nil:
    body_600613 = body
  add(query_600612, "MaxResults", newJString(MaxResults))
  result = call_600611.call(nil, query_600612, nil, nil, body_600613)

var listIndex* = Call_ListIndex_600595(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_600596,
                                    base: "/", url: url_ListIndex_600597,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListManagedSchemaArns_600614 = ref object of OpenApiRestCall_599368
proc url_ListManagedSchemaArns_600616(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListManagedSchemaArns_600615(path: JsonNode; query: JsonNode;
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
  var valid_600617 = query.getOrDefault("NextToken")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "NextToken", valid_600617
  var valid_600618 = query.getOrDefault("MaxResults")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "MaxResults", valid_600618
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
  var valid_600619 = header.getOrDefault("X-Amz-Date")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Date", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Security-Token")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Security-Token", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Content-Sha256", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Algorithm")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Algorithm", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Signature")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Signature", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-SignedHeaders", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Credential")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Credential", valid_600625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600627: Call_ListManagedSchemaArns_600614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_600627.validator(path, query, header, formData, body)
  let scheme = call_600627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600627.url(scheme.get, call_600627.host, call_600627.base,
                         call_600627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600627, url, valid)

proc call*(call_600628: Call_ListManagedSchemaArns_600614; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listManagedSchemaArns
  ## Lists the major version families of each managed schema. If a major version ARN is provided as SchemaArn, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600629 = newJObject()
  var body_600630 = newJObject()
  add(query_600629, "NextToken", newJString(NextToken))
  if body != nil:
    body_600630 = body
  add(query_600629, "MaxResults", newJString(MaxResults))
  result = call_600628.call(nil, query_600629, nil, nil, body_600630)

var listManagedSchemaArns* = Call_ListManagedSchemaArns_600614(
    name: "listManagedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/managed",
    validator: validate_ListManagedSchemaArns_600615, base: "/",
    url: url_ListManagedSchemaArns_600616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_600631 = ref object of OpenApiRestCall_599368
proc url_ListObjectAttributes_600633(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectAttributes_600632(path: JsonNode; query: JsonNode;
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
  var valid_600634 = query.getOrDefault("NextToken")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "NextToken", valid_600634
  var valid_600635 = query.getOrDefault("MaxResults")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "MaxResults", valid_600635
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
  var valid_600636 = header.getOrDefault("X-Amz-Date")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Date", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Security-Token")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Security-Token", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Content-Sha256", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Algorithm")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Algorithm", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Signature")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Signature", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-SignedHeaders", valid_600641
  var valid_600642 = header.getOrDefault("x-amz-consistency-level")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600642 != nil:
    section.add "x-amz-consistency-level", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Credential")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Credential", valid_600643
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600644 = header.getOrDefault("x-amz-data-partition")
  valid_600644 = validateParameter(valid_600644, JString, required = true,
                                 default = nil)
  if valid_600644 != nil:
    section.add "x-amz-data-partition", valid_600644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600646: Call_ListObjectAttributes_600631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_600646.validator(path, query, header, formData, body)
  let scheme = call_600646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600646.url(scheme.get, call_600646.host, call_600646.base,
                         call_600646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600646, url, valid)

proc call*(call_600647: Call_ListObjectAttributes_600631; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600648 = newJObject()
  var body_600649 = newJObject()
  add(query_600648, "NextToken", newJString(NextToken))
  if body != nil:
    body_600649 = body
  add(query_600648, "MaxResults", newJString(MaxResults))
  result = call_600647.call(nil, query_600648, nil, nil, body_600649)

var listObjectAttributes* = Call_ListObjectAttributes_600631(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_600632, base: "/",
    url: url_ListObjectAttributes_600633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_600650 = ref object of OpenApiRestCall_599368
proc url_ListObjectChildren_600652(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectChildren_600651(path: JsonNode; query: JsonNode;
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
  var valid_600653 = query.getOrDefault("NextToken")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "NextToken", valid_600653
  var valid_600654 = query.getOrDefault("MaxResults")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "MaxResults", valid_600654
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
  var valid_600655 = header.getOrDefault("X-Amz-Date")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Date", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Security-Token")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Security-Token", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Content-Sha256", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Algorithm")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Algorithm", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Signature")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Signature", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-SignedHeaders", valid_600660
  var valid_600661 = header.getOrDefault("x-amz-consistency-level")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600661 != nil:
    section.add "x-amz-consistency-level", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Credential")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Credential", valid_600662
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600663 = header.getOrDefault("x-amz-data-partition")
  valid_600663 = validateParameter(valid_600663, JString, required = true,
                                 default = nil)
  if valid_600663 != nil:
    section.add "x-amz-data-partition", valid_600663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600665: Call_ListObjectChildren_600650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_600665.validator(path, query, header, formData, body)
  let scheme = call_600665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600665.url(scheme.get, call_600665.host, call_600665.base,
                         call_600665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600665, url, valid)

proc call*(call_600666: Call_ListObjectChildren_600650; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600667 = newJObject()
  var body_600668 = newJObject()
  add(query_600667, "NextToken", newJString(NextToken))
  if body != nil:
    body_600668 = body
  add(query_600667, "MaxResults", newJString(MaxResults))
  result = call_600666.call(nil, query_600667, nil, nil, body_600668)

var listObjectChildren* = Call_ListObjectChildren_600650(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_600651, base: "/",
    url: url_ListObjectChildren_600652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_600669 = ref object of OpenApiRestCall_599368
proc url_ListObjectParentPaths_600671(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParentPaths_600670(path: JsonNode; query: JsonNode;
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
  var valid_600672 = query.getOrDefault("NextToken")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "NextToken", valid_600672
  var valid_600673 = query.getOrDefault("MaxResults")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "MaxResults", valid_600673
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
  var valid_600674 = header.getOrDefault("X-Amz-Date")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Date", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Security-Token")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Security-Token", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Content-Sha256", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Algorithm")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Algorithm", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Signature")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Signature", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-SignedHeaders", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Credential")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Credential", valid_600680
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600681 = header.getOrDefault("x-amz-data-partition")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "x-amz-data-partition", valid_600681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600683: Call_ListObjectParentPaths_600669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_ListObjectParentPaths_600669; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directorystructure.html">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600685 = newJObject()
  var body_600686 = newJObject()
  add(query_600685, "NextToken", newJString(NextToken))
  if body != nil:
    body_600686 = body
  add(query_600685, "MaxResults", newJString(MaxResults))
  result = call_600684.call(nil, query_600685, nil, nil, body_600686)

var listObjectParentPaths* = Call_ListObjectParentPaths_600669(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_600670, base: "/",
    url: url_ListObjectParentPaths_600671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_600687 = ref object of OpenApiRestCall_599368
proc url_ListObjectParents_600689(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectParents_600688(path: JsonNode; query: JsonNode;
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
  var valid_600690 = query.getOrDefault("NextToken")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "NextToken", valid_600690
  var valid_600691 = query.getOrDefault("MaxResults")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "MaxResults", valid_600691
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
  var valid_600692 = header.getOrDefault("X-Amz-Date")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Date", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Security-Token")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Security-Token", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Content-Sha256", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Algorithm")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Algorithm", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Signature")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Signature", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-SignedHeaders", valid_600697
  var valid_600698 = header.getOrDefault("x-amz-consistency-level")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600698 != nil:
    section.add "x-amz-consistency-level", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Credential")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Credential", valid_600699
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600700 = header.getOrDefault("x-amz-data-partition")
  valid_600700 = validateParameter(valid_600700, JString, required = true,
                                 default = nil)
  if valid_600700 != nil:
    section.add "x-amz-data-partition", valid_600700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600702: Call_ListObjectParents_600687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_600702.validator(path, query, header, formData, body)
  let scheme = call_600702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600702.url(scheme.get, call_600702.host, call_600702.base,
                         call_600702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600702, url, valid)

proc call*(call_600703: Call_ListObjectParents_600687; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600704 = newJObject()
  var body_600705 = newJObject()
  add(query_600704, "NextToken", newJString(NextToken))
  if body != nil:
    body_600705 = body
  add(query_600704, "MaxResults", newJString(MaxResults))
  result = call_600703.call(nil, query_600704, nil, nil, body_600705)

var listObjectParents* = Call_ListObjectParents_600687(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_600688, base: "/",
    url: url_ListObjectParents_600689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_600706 = ref object of OpenApiRestCall_599368
proc url_ListObjectPolicies_600708(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListObjectPolicies_600707(path: JsonNode; query: JsonNode;
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
  var valid_600709 = query.getOrDefault("NextToken")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "NextToken", valid_600709
  var valid_600710 = query.getOrDefault("MaxResults")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "MaxResults", valid_600710
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
  var valid_600711 = header.getOrDefault("X-Amz-Date")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Date", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Security-Token")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Security-Token", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Content-Sha256", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-Algorithm")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Algorithm", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Signature")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Signature", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-SignedHeaders", valid_600716
  var valid_600717 = header.getOrDefault("x-amz-consistency-level")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600717 != nil:
    section.add "x-amz-consistency-level", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Credential")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Credential", valid_600718
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600719 = header.getOrDefault("x-amz-data-partition")
  valid_600719 = validateParameter(valid_600719, JString, required = true,
                                 default = nil)
  if valid_600719 != nil:
    section.add "x-amz-data-partition", valid_600719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600721: Call_ListObjectPolicies_600706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_600721.validator(path, query, header, formData, body)
  let scheme = call_600721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600721.url(scheme.get, call_600721.host, call_600721.base,
                         call_600721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600721, url, valid)

proc call*(call_600722: Call_ListObjectPolicies_600706; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600723 = newJObject()
  var body_600724 = newJObject()
  add(query_600723, "NextToken", newJString(NextToken))
  if body != nil:
    body_600724 = body
  add(query_600723, "MaxResults", newJString(MaxResults))
  result = call_600722.call(nil, query_600723, nil, nil, body_600724)

var listObjectPolicies* = Call_ListObjectPolicies_600706(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_600707, base: "/",
    url: url_ListObjectPolicies_600708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_600725 = ref object of OpenApiRestCall_599368
proc url_ListOutgoingTypedLinks_600727(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutgoingTypedLinks_600726(path: JsonNode; query: JsonNode;
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
  var valid_600728 = header.getOrDefault("X-Amz-Date")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Date", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Security-Token")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Security-Token", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Content-Sha256", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Algorithm")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Algorithm", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Signature")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Signature", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-SignedHeaders", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Credential")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Credential", valid_600734
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600735 = header.getOrDefault("x-amz-data-partition")
  valid_600735 = validateParameter(valid_600735, JString, required = true,
                                 default = nil)
  if valid_600735 != nil:
    section.add "x-amz-data-partition", valid_600735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600737: Call_ListOutgoingTypedLinks_600725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600737.validator(path, query, header, formData, body)
  let scheme = call_600737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600737.url(scheme.get, call_600737.host, call_600737.base,
                         call_600737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600737, url, valid)

proc call*(call_600738: Call_ListOutgoingTypedLinks_600725; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600739 = newJObject()
  if body != nil:
    body_600739 = body
  result = call_600738.call(nil, nil, nil, nil, body_600739)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_600725(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_600726, base: "/",
    url: url_ListOutgoingTypedLinks_600727, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_600740 = ref object of OpenApiRestCall_599368
proc url_ListPolicyAttachments_600742(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPolicyAttachments_600741(path: JsonNode; query: JsonNode;
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
  var valid_600743 = query.getOrDefault("NextToken")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "NextToken", valid_600743
  var valid_600744 = query.getOrDefault("MaxResults")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "MaxResults", valid_600744
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
  var valid_600745 = header.getOrDefault("X-Amz-Date")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Date", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Security-Token")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Security-Token", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Content-Sha256", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Algorithm")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Algorithm", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Signature")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Signature", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-SignedHeaders", valid_600750
  var valid_600751 = header.getOrDefault("x-amz-consistency-level")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_600751 != nil:
    section.add "x-amz-consistency-level", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Credential")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Credential", valid_600752
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600753 = header.getOrDefault("x-amz-data-partition")
  valid_600753 = validateParameter(valid_600753, JString, required = true,
                                 default = nil)
  if valid_600753 != nil:
    section.add "x-amz-data-partition", valid_600753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600755: Call_ListPolicyAttachments_600740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_600755.validator(path, query, header, formData, body)
  let scheme = call_600755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600755.url(scheme.get, call_600755.host, call_600755.base,
                         call_600755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600755, url, valid)

proc call*(call_600756: Call_ListPolicyAttachments_600740; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600757 = newJObject()
  var body_600758 = newJObject()
  add(query_600757, "NextToken", newJString(NextToken))
  if body != nil:
    body_600758 = body
  add(query_600757, "MaxResults", newJString(MaxResults))
  result = call_600756.call(nil, query_600757, nil, nil, body_600758)

var listPolicyAttachments* = Call_ListPolicyAttachments_600740(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_600741, base: "/",
    url: url_ListPolicyAttachments_600742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_600759 = ref object of OpenApiRestCall_599368
proc url_ListPublishedSchemaArns_600761(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublishedSchemaArns_600760(path: JsonNode; query: JsonNode;
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
  var valid_600762 = query.getOrDefault("NextToken")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "NextToken", valid_600762
  var valid_600763 = query.getOrDefault("MaxResults")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "MaxResults", valid_600763
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
  var valid_600764 = header.getOrDefault("X-Amz-Date")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Date", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Security-Token")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Security-Token", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-Content-Sha256", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Algorithm")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Algorithm", valid_600767
  var valid_600768 = header.getOrDefault("X-Amz-Signature")
  valid_600768 = validateParameter(valid_600768, JString, required = false,
                                 default = nil)
  if valid_600768 != nil:
    section.add "X-Amz-Signature", valid_600768
  var valid_600769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "X-Amz-SignedHeaders", valid_600769
  var valid_600770 = header.getOrDefault("X-Amz-Credential")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Credential", valid_600770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600772: Call_ListPublishedSchemaArns_600759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_600772.validator(path, query, header, formData, body)
  let scheme = call_600772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600772.url(scheme.get, call_600772.host, call_600772.base,
                         call_600772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600772, url, valid)

proc call*(call_600773: Call_ListPublishedSchemaArns_600759; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600774 = newJObject()
  var body_600775 = newJObject()
  add(query_600774, "NextToken", newJString(NextToken))
  if body != nil:
    body_600775 = body
  add(query_600774, "MaxResults", newJString(MaxResults))
  result = call_600773.call(nil, query_600774, nil, nil, body_600775)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_600759(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_600760, base: "/",
    url: url_ListPublishedSchemaArns_600761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600776 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600778(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600777(path: JsonNode; query: JsonNode;
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
  var valid_600779 = query.getOrDefault("NextToken")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "NextToken", valid_600779
  var valid_600780 = query.getOrDefault("MaxResults")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "MaxResults", valid_600780
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
  var valid_600781 = header.getOrDefault("X-Amz-Date")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-Date", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Security-Token")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Security-Token", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Content-Sha256", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Algorithm")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Algorithm", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-Signature")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-Signature", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-SignedHeaders", valid_600786
  var valid_600787 = header.getOrDefault("X-Amz-Credential")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Credential", valid_600787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600789: Call_ListTagsForResource_600776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_600789.validator(path, query, header, formData, body)
  let scheme = call_600789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600789.url(scheme.get, call_600789.host, call_600789.base,
                         call_600789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600789, url, valid)

proc call*(call_600790: Call_ListTagsForResource_600776; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600791 = newJObject()
  var body_600792 = newJObject()
  add(query_600791, "NextToken", newJString(NextToken))
  if body != nil:
    body_600792 = body
  add(query_600791, "MaxResults", newJString(MaxResults))
  result = call_600790.call(nil, query_600791, nil, nil, body_600792)

var listTagsForResource* = Call_ListTagsForResource_600776(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_600777, base: "/",
    url: url_ListTagsForResource_600778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_600793 = ref object of OpenApiRestCall_599368
proc url_ListTypedLinkFacetAttributes_600795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetAttributes_600794(path: JsonNode; query: JsonNode;
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
  var valid_600796 = query.getOrDefault("NextToken")
  valid_600796 = validateParameter(valid_600796, JString, required = false,
                                 default = nil)
  if valid_600796 != nil:
    section.add "NextToken", valid_600796
  var valid_600797 = query.getOrDefault("MaxResults")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "MaxResults", valid_600797
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
  var valid_600798 = header.getOrDefault("X-Amz-Date")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Date", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Security-Token")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Security-Token", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Content-Sha256", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Algorithm")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Algorithm", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Signature")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Signature", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-SignedHeaders", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Credential")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Credential", valid_600804
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600805 = header.getOrDefault("x-amz-data-partition")
  valid_600805 = validateParameter(valid_600805, JString, required = true,
                                 default = nil)
  if valid_600805 != nil:
    section.add "x-amz-data-partition", valid_600805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600807: Call_ListTypedLinkFacetAttributes_600793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600807.validator(path, query, header, formData, body)
  let scheme = call_600807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600807.url(scheme.get, call_600807.host, call_600807.base,
                         call_600807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600807, url, valid)

proc call*(call_600808: Call_ListTypedLinkFacetAttributes_600793; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600809 = newJObject()
  var body_600810 = newJObject()
  add(query_600809, "NextToken", newJString(NextToken))
  if body != nil:
    body_600810 = body
  add(query_600809, "MaxResults", newJString(MaxResults))
  result = call_600808.call(nil, query_600809, nil, nil, body_600810)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_600793(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_600794, base: "/",
    url: url_ListTypedLinkFacetAttributes_600795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_600811 = ref object of OpenApiRestCall_599368
proc url_ListTypedLinkFacetNames_600813(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTypedLinkFacetNames_600812(path: JsonNode; query: JsonNode;
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
  var valid_600814 = query.getOrDefault("NextToken")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "NextToken", valid_600814
  var valid_600815 = query.getOrDefault("MaxResults")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "MaxResults", valid_600815
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
  var valid_600816 = header.getOrDefault("X-Amz-Date")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Date", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Security-Token")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Security-Token", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Content-Sha256", valid_600818
  var valid_600819 = header.getOrDefault("X-Amz-Algorithm")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-Algorithm", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Signature")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Signature", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-SignedHeaders", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Credential")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Credential", valid_600822
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600823 = header.getOrDefault("x-amz-data-partition")
  valid_600823 = validateParameter(valid_600823, JString, required = true,
                                 default = nil)
  if valid_600823 != nil:
    section.add "x-amz-data-partition", valid_600823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600825: Call_ListTypedLinkFacetNames_600811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600825.validator(path, query, header, formData, body)
  let scheme = call_600825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600825.url(scheme.get, call_600825.host, call_600825.base,
                         call_600825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600825, url, valid)

proc call*(call_600826: Call_ListTypedLinkFacetNames_600811; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600827 = newJObject()
  var body_600828 = newJObject()
  add(query_600827, "NextToken", newJString(NextToken))
  if body != nil:
    body_600828 = body
  add(query_600827, "MaxResults", newJString(MaxResults))
  result = call_600826.call(nil, query_600827, nil, nil, body_600828)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_600811(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_600812, base: "/",
    url: url_ListTypedLinkFacetNames_600813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_600829 = ref object of OpenApiRestCall_599368
proc url_LookupPolicy_600831(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LookupPolicy_600830(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600832 = query.getOrDefault("NextToken")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "NextToken", valid_600832
  var valid_600833 = query.getOrDefault("MaxResults")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "MaxResults", valid_600833
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
  var valid_600834 = header.getOrDefault("X-Amz-Date")
  valid_600834 = validateParameter(valid_600834, JString, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "X-Amz-Date", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Security-Token")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Security-Token", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Content-Sha256", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Algorithm")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Algorithm", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Signature")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Signature", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-SignedHeaders", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Credential")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Credential", valid_600840
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600841 = header.getOrDefault("x-amz-data-partition")
  valid_600841 = validateParameter(valid_600841, JString, required = true,
                                 default = nil)
  if valid_600841 != nil:
    section.add "x-amz-data-partition", valid_600841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600843: Call_LookupPolicy_600829; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ## 
  let valid = call_600843.validator(path, query, header, formData, body)
  let scheme = call_600843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600843.url(scheme.get, call_600843.host, call_600843.base,
                         call_600843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600843, url, valid)

proc call*(call_600844: Call_LookupPolicy_600829; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/key_concepts_directory.html#key_concepts_policies">Policies</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600845 = newJObject()
  var body_600846 = newJObject()
  add(query_600845, "NextToken", newJString(NextToken))
  if body != nil:
    body_600846 = body
  add(query_600845, "MaxResults", newJString(MaxResults))
  result = call_600844.call(nil, query_600845, nil, nil, body_600846)

var lookupPolicy* = Call_LookupPolicy_600829(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_600830, base: "/", url: url_LookupPolicy_600831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_600847 = ref object of OpenApiRestCall_599368
proc url_PublishSchema_600849(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PublishSchema_600848(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600857 = header.getOrDefault("x-amz-data-partition")
  valid_600857 = validateParameter(valid_600857, JString, required = true,
                                 default = nil)
  if valid_600857 != nil:
    section.add "x-amz-data-partition", valid_600857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600859: Call_PublishSchema_600847; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_600859.validator(path, query, header, formData, body)
  let scheme = call_600859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600859.url(scheme.get, call_600859.host, call_600859.base,
                         call_600859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600859, url, valid)

proc call*(call_600860: Call_PublishSchema_600847; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_600861 = newJObject()
  if body != nil:
    body_600861 = body
  result = call_600860.call(nil, nil, nil, nil, body_600861)

var publishSchema* = Call_PublishSchema_600847(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_600848, base: "/", url: url_PublishSchema_600849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_600862 = ref object of OpenApiRestCall_599368
proc url_RemoveFacetFromObject_600864(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveFacetFromObject_600863(path: JsonNode; query: JsonNode;
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
  var valid_600865 = header.getOrDefault("X-Amz-Date")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Date", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-Security-Token")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Security-Token", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Content-Sha256", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-Algorithm")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-Algorithm", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Signature")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Signature", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-SignedHeaders", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Credential")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Credential", valid_600871
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600872 = header.getOrDefault("x-amz-data-partition")
  valid_600872 = validateParameter(valid_600872, JString, required = true,
                                 default = nil)
  if valid_600872 != nil:
    section.add "x-amz-data-partition", valid_600872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600874: Call_RemoveFacetFromObject_600862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_600874.validator(path, query, header, formData, body)
  let scheme = call_600874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600874.url(scheme.get, call_600874.host, call_600874.base,
                         call_600874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600874, url, valid)

proc call*(call_600875: Call_RemoveFacetFromObject_600862; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_600876 = newJObject()
  if body != nil:
    body_600876 = body
  result = call_600875.call(nil, nil, nil, nil, body_600876)

var removeFacetFromObject* = Call_RemoveFacetFromObject_600862(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_600863, base: "/",
    url: url_RemoveFacetFromObject_600864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600877 = ref object of OpenApiRestCall_599368
proc url_TagResource_600879(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600878(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600880 = header.getOrDefault("X-Amz-Date")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Date", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Security-Token")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Security-Token", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Content-Sha256", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Algorithm")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Algorithm", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Signature")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Signature", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-SignedHeaders", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Credential")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Credential", valid_600886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600888: Call_TagResource_600877; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_600888.validator(path, query, header, formData, body)
  let scheme = call_600888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600888.url(scheme.get, call_600888.host, call_600888.base,
                         call_600888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600888, url, valid)

proc call*(call_600889: Call_TagResource_600877; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_600890 = newJObject()
  if body != nil:
    body_600890 = body
  result = call_600889.call(nil, nil, nil, nil, body_600890)

var tagResource* = Call_TagResource_600877(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_600878,
                                        base: "/", url: url_TagResource_600879,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600891 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600893(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600892(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600894 = header.getOrDefault("X-Amz-Date")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Date", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Security-Token")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Security-Token", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Content-Sha256", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Algorithm")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Algorithm", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Signature")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Signature", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-SignedHeaders", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Credential")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Credential", valid_600900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600902: Call_UntagResource_600891; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_600902.validator(path, query, header, formData, body)
  let scheme = call_600902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600902.url(scheme.get, call_600902.host, call_600902.base,
                         call_600902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600902, url, valid)

proc call*(call_600903: Call_UntagResource_600891; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_600904 = newJObject()
  if body != nil:
    body_600904 = body
  result = call_600903.call(nil, nil, nil, nil, body_600904)

var untagResource* = Call_UntagResource_600891(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_600892, base: "/", url: url_UntagResource_600893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_600905 = ref object of OpenApiRestCall_599368
proc url_UpdateLinkAttributes_600907(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLinkAttributes_600906(path: JsonNode; query: JsonNode;
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
  var valid_600908 = header.getOrDefault("X-Amz-Date")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Date", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Security-Token")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Security-Token", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Content-Sha256", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Algorithm")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Algorithm", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Signature")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Signature", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-SignedHeaders", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Credential")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Credential", valid_600914
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600915 = header.getOrDefault("x-amz-data-partition")
  valid_600915 = validateParameter(valid_600915, JString, required = true,
                                 default = nil)
  if valid_600915 != nil:
    section.add "x-amz-data-partition", valid_600915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600917: Call_UpdateLinkAttributes_600905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_600917.validator(path, query, header, formData, body)
  let scheme = call_600917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600917.url(scheme.get, call_600917.host, call_600917.base,
                         call_600917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600917, url, valid)

proc call*(call_600918: Call_UpdateLinkAttributes_600905; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_600919 = newJObject()
  if body != nil:
    body_600919 = body
  result = call_600918.call(nil, nil, nil, nil, body_600919)

var updateLinkAttributes* = Call_UpdateLinkAttributes_600905(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_600906, base: "/",
    url: url_UpdateLinkAttributes_600907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_600920 = ref object of OpenApiRestCall_599368
proc url_UpdateObjectAttributes_600922(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateObjectAttributes_600921(path: JsonNode; query: JsonNode;
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
  var valid_600923 = header.getOrDefault("X-Amz-Date")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Date", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-Security-Token")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-Security-Token", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Content-Sha256", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Algorithm")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Algorithm", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Signature")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Signature", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-SignedHeaders", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Credential")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Credential", valid_600929
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600930 = header.getOrDefault("x-amz-data-partition")
  valid_600930 = validateParameter(valid_600930, JString, required = true,
                                 default = nil)
  if valid_600930 != nil:
    section.add "x-amz-data-partition", valid_600930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_UpdateObjectAttributes_600920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600932, url, valid)

proc call*(call_600933: Call_UpdateObjectAttributes_600920; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_600934 = newJObject()
  if body != nil:
    body_600934 = body
  result = call_600933.call(nil, nil, nil, nil, body_600934)

var updateObjectAttributes* = Call_UpdateObjectAttributes_600920(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_600921, base: "/",
    url: url_UpdateObjectAttributes_600922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_600935 = ref object of OpenApiRestCall_599368
proc url_UpdateSchema_600937(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSchema_600936(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600938 = header.getOrDefault("X-Amz-Date")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Date", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Security-Token")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Security-Token", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Content-Sha256", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Algorithm")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Algorithm", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Signature")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Signature", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-SignedHeaders", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Credential")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Credential", valid_600944
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600945 = header.getOrDefault("x-amz-data-partition")
  valid_600945 = validateParameter(valid_600945, JString, required = true,
                                 default = nil)
  if valid_600945 != nil:
    section.add "x-amz-data-partition", valid_600945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600947: Call_UpdateSchema_600935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_600947.validator(path, query, header, formData, body)
  let scheme = call_600947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600947.url(scheme.get, call_600947.host, call_600947.base,
                         call_600947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600947, url, valid)

proc call*(call_600948: Call_UpdateSchema_600935; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_600949 = newJObject()
  if body != nil:
    body_600949 = body
  result = call_600948.call(nil, nil, nil, nil, body_600949)

var updateSchema* = Call_UpdateSchema_600935(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_600936, base: "/", url: url_UpdateSchema_600937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_600950 = ref object of OpenApiRestCall_599368
proc url_UpdateTypedLinkFacet_600952(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTypedLinkFacet_600951(path: JsonNode; query: JsonNode;
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
  var valid_600953 = header.getOrDefault("X-Amz-Date")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Date", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Security-Token")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Security-Token", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Content-Sha256", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Algorithm")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Algorithm", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-Signature")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-Signature", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-SignedHeaders", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-Credential")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Credential", valid_600959
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_600960 = header.getOrDefault("x-amz-data-partition")
  valid_600960 = validateParameter(valid_600960, JString, required = true,
                                 default = nil)
  if valid_600960 != nil:
    section.add "x-amz-data-partition", valid_600960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600962: Call_UpdateTypedLinkFacet_600950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ## 
  let valid = call_600962.validator(path, query, header, formData, body)
  let scheme = call_600962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600962.url(scheme.get, call_600962.host, call_600962.base,
                         call_600962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600962, url, valid)

proc call*(call_600963: Call_UpdateTypedLinkFacet_600950; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="https://docs.aws.amazon.com/clouddirectory/latest/developerguide/directory_objects_links.html#directory_objects_links_typedlink">Typed Links</a>.
  ##   body: JObject (required)
  var body_600964 = newJObject()
  if body != nil:
    body_600964 = body
  result = call_600963.call(nil, nil, nil, nil, body_600964)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_600950(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_600951, base: "/",
    url: url_UpdateTypedLinkFacet_600952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_600965 = ref object of OpenApiRestCall_599368
proc url_UpgradeAppliedSchema_600967(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeAppliedSchema_600966(path: JsonNode; query: JsonNode;
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
  var valid_600968 = header.getOrDefault("X-Amz-Date")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Date", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Security-Token")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Security-Token", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Content-Sha256", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Algorithm")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Algorithm", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Signature")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Signature", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-SignedHeaders", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Credential")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Credential", valid_600974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600976: Call_UpgradeAppliedSchema_600965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_600976.validator(path, query, header, formData, body)
  let scheme = call_600976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600976.url(scheme.get, call_600976.host, call_600976.base,
                         call_600976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600976, url, valid)

proc call*(call_600977: Call_UpgradeAppliedSchema_600965; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_600978 = newJObject()
  if body != nil:
    body_600978 = body
  result = call_600977.call(nil, nil, nil, nil, body_600978)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_600965(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_600966, base: "/",
    url: url_UpgradeAppliedSchema_600967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_600979 = ref object of OpenApiRestCall_599368
proc url_UpgradePublishedSchema_600981(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradePublishedSchema_600980(path: JsonNode; query: JsonNode;
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
  var valid_600982 = header.getOrDefault("X-Amz-Date")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Date", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Security-Token")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Security-Token", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Content-Sha256", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Algorithm")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Algorithm", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Signature")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Signature", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-SignedHeaders", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-Credential")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Credential", valid_600988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600990: Call_UpgradePublishedSchema_600979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_600990.validator(path, query, header, formData, body)
  let scheme = call_600990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600990.url(scheme.get, call_600990.host, call_600990.base,
                         call_600990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600990, url, valid)

proc call*(call_600991: Call_UpgradePublishedSchema_600979; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_600992 = newJObject()
  if body != nil:
    body_600992 = body
  result = call_600991.call(nil, nil, nil, nil, body_600992)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_600979(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_600980, base: "/",
    url: url_UpgradePublishedSchema_600981, schemes: {Scheme.Https, Scheme.Http})
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
