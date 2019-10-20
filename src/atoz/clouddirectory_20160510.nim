
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddFacetToObject_592703 = ref object of OpenApiRestCall_592364
proc url_AddFacetToObject_592705(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddFacetToObject_592704(path: JsonNode; query: JsonNode;
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
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_592822 = header.getOrDefault("x-amz-data-partition")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "x-amz-data-partition", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Algorithm")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Algorithm", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-SignedHeaders", valid_592824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592848: Call_AddFacetToObject_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ## 
  let valid = call_592848.validator(path, query, header, formData, body)
  let scheme = call_592848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592848.url(scheme.get, call_592848.host, call_592848.base,
                         call_592848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592848, url, valid)

proc call*(call_592919: Call_AddFacetToObject_592703; body: JsonNode): Recallable =
  ## addFacetToObject
  ## Adds a new <a>Facet</a> to an object. An object can have more than one facet applied on it.
  ##   body: JObject (required)
  var body_592920 = newJObject()
  if body != nil:
    body_592920 = body
  result = call_592919.call(nil, nil, nil, nil, body_592920)

var addFacetToObject* = Call_AddFacetToObject_592703(name: "addFacetToObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets#x-amz-data-partition",
    validator: validate_AddFacetToObject_592704, base: "/",
    url: url_AddFacetToObject_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplySchema_592959 = ref object of OpenApiRestCall_592364
proc url_ApplySchema_592961(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApplySchema_592960(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592962 = header.getOrDefault("X-Amz-Signature")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Signature", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Content-Sha256", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Date")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Date", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Credential")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Credential", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Security-Token")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Security-Token", valid_592966
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_592967 = header.getOrDefault("x-amz-data-partition")
  valid_592967 = validateParameter(valid_592967, JString, required = true,
                                 default = nil)
  if valid_592967 != nil:
    section.add "x-amz-data-partition", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Algorithm")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Algorithm", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-SignedHeaders", valid_592969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_ApplySchema_592959; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_ApplySchema_592959; body: JsonNode): Recallable =
  ## applySchema
  ## Copies the input published schema, at the specified version, into the <a>Directory</a> with the same name and version as that of the published schema.
  ##   body: JObject (required)
  var body_592973 = newJObject()
  if body != nil:
    body_592973 = body
  result = call_592972.call(nil, nil, nil, nil, body_592973)

var applySchema* = Call_ApplySchema_592959(name: "applySchema",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/apply#x-amz-data-partition",
                                        validator: validate_ApplySchema_592960,
                                        base: "/", url: url_ApplySchema_592961,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachObject_592974 = ref object of OpenApiRestCall_592364
proc url_AttachObject_592976(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachObject_592975(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592977 = header.getOrDefault("X-Amz-Signature")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Signature", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Content-Sha256", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Date")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Date", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Credential")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Credential", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Security-Token")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Security-Token", valid_592981
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_592982 = header.getOrDefault("x-amz-data-partition")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = nil)
  if valid_592982 != nil:
    section.add "x-amz-data-partition", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Algorithm")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Algorithm", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-SignedHeaders", valid_592984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592986: Call_AttachObject_592974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ## 
  let valid = call_592986.validator(path, query, header, formData, body)
  let scheme = call_592986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592986.url(scheme.get, call_592986.host, call_592986.base,
                         call_592986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592986, url, valid)

proc call*(call_592987: Call_AttachObject_592974; body: JsonNode): Recallable =
  ## attachObject
  ## <p>Attaches an existing object to another object. An object can be accessed in two ways:</p> <ol> <li> <p>Using the path</p> </li> <li> <p>Using <code>ObjectIdentifier</code> </p> </li> </ol>
  ##   body: JObject (required)
  var body_592988 = newJObject()
  if body != nil:
    body_592988 = body
  result = call_592987.call(nil, nil, nil, nil, body_592988)

var attachObject* = Call_AttachObject_592974(name: "attachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attach#x-amz-data-partition",
    validator: validate_AttachObject_592975, base: "/", url: url_AttachObject_592976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachPolicy_592989 = ref object of OpenApiRestCall_592364
proc url_AttachPolicy_592991(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachPolicy_592990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592992 = header.getOrDefault("X-Amz-Signature")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Signature", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Content-Sha256", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Date")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Date", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Credential")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Credential", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Security-Token")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Security-Token", valid_592996
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_592997 = header.getOrDefault("x-amz-data-partition")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "x-amz-data-partition", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Algorithm")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Algorithm", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-SignedHeaders", valid_592999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593001: Call_AttachPolicy_592989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ## 
  let valid = call_593001.validator(path, query, header, formData, body)
  let scheme = call_593001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593001.url(scheme.get, call_593001.host, call_593001.base,
                         call_593001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593001, url, valid)

proc call*(call_593002: Call_AttachPolicy_592989; body: JsonNode): Recallable =
  ## attachPolicy
  ## Attaches a policy object to a regular object. An object can have a limited number of attached policies.
  ##   body: JObject (required)
  var body_593003 = newJObject()
  if body != nil:
    body_593003 = body
  result = call_593002.call(nil, nil, nil, nil, body_593003)

var attachPolicy* = Call_AttachPolicy_592989(name: "attachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attach#x-amz-data-partition",
    validator: validate_AttachPolicy_592990, base: "/", url: url_AttachPolicy_592991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachToIndex_593004 = ref object of OpenApiRestCall_592364
proc url_AttachToIndex_593006(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachToIndex_593005(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593007 = header.getOrDefault("X-Amz-Signature")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Signature", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Content-Sha256", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Date")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Date", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Credential")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Credential", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Security-Token")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Security-Token", valid_593011
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593012 = header.getOrDefault("x-amz-data-partition")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = nil)
  if valid_593012 != nil:
    section.add "x-amz-data-partition", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Algorithm")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Algorithm", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-SignedHeaders", valid_593014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593016: Call_AttachToIndex_593004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches the specified object to the specified index.
  ## 
  let valid = call_593016.validator(path, query, header, formData, body)
  let scheme = call_593016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593016.url(scheme.get, call_593016.host, call_593016.base,
                         call_593016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593016, url, valid)

proc call*(call_593017: Call_AttachToIndex_593004; body: JsonNode): Recallable =
  ## attachToIndex
  ## Attaches the specified object to the specified index.
  ##   body: JObject (required)
  var body_593018 = newJObject()
  if body != nil:
    body_593018 = body
  result = call_593017.call(nil, nil, nil, nil, body_593018)

var attachToIndex* = Call_AttachToIndex_593004(name: "attachToIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/attach#x-amz-data-partition",
    validator: validate_AttachToIndex_593005, base: "/", url: url_AttachToIndex_593006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AttachTypedLink_593019 = ref object of OpenApiRestCall_592364
proc url_AttachTypedLink_593021(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AttachTypedLink_593020(path: JsonNode; query: JsonNode;
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
  var valid_593022 = header.getOrDefault("X-Amz-Signature")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Signature", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Content-Sha256", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Date")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Date", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Credential")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Credential", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Security-Token")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Security-Token", valid_593026
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593027 = header.getOrDefault("x-amz-data-partition")
  valid_593027 = validateParameter(valid_593027, JString, required = true,
                                 default = nil)
  if valid_593027 != nil:
    section.add "x-amz-data-partition", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Algorithm")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Algorithm", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-SignedHeaders", valid_593029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_AttachTypedLink_593019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_AttachTypedLink_593019; body: JsonNode): Recallable =
  ## attachTypedLink
  ## Attaches a typed link to a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593033 = newJObject()
  if body != nil:
    body_593033 = body
  result = call_593032.call(nil, nil, nil, nil, body_593033)

var attachTypedLink* = Call_AttachTypedLink_593019(name: "attachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attach#x-amz-data-partition",
    validator: validate_AttachTypedLink_593020, base: "/", url: url_AttachTypedLink_593021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchRead_593034 = ref object of OpenApiRestCall_592364
proc url_BatchRead_593036(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchRead_593035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593050 = header.getOrDefault("x-amz-consistency-level")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593050 != nil:
    section.add "x-amz-consistency-level", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Signature")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Signature", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Content-Sha256", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Date")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Date", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Credential")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Credential", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Security-Token")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Security-Token", valid_593055
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593056 = header.getOrDefault("x-amz-data-partition")
  valid_593056 = validateParameter(valid_593056, JString, required = true,
                                 default = nil)
  if valid_593056 != nil:
    section.add "x-amz-data-partition", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_BatchRead_593034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the read operations in a batch. 
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_BatchRead_593034; body: JsonNode): Recallable =
  ## batchRead
  ## Performs all the read operations in a batch. 
  ##   body: JObject (required)
  var body_593062 = newJObject()
  if body != nil:
    body_593062 = body
  result = call_593061.call(nil, nil, nil, nil, body_593062)

var batchRead* = Call_BatchRead_593034(name: "batchRead", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchread#x-amz-data-partition",
                                    validator: validate_BatchRead_593035,
                                    base: "/", url: url_BatchRead_593036,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchWrite_593063 = ref object of OpenApiRestCall_592364
proc url_BatchWrite_593065(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchWrite_593064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593066 = header.getOrDefault("X-Amz-Signature")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Signature", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Content-Sha256", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Date")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Date", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Credential")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Credential", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Security-Token")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Security-Token", valid_593070
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593071 = header.getOrDefault("x-amz-data-partition")
  valid_593071 = validateParameter(valid_593071, JString, required = true,
                                 default = nil)
  if valid_593071 != nil:
    section.add "x-amz-data-partition", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Algorithm")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Algorithm", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-SignedHeaders", valid_593073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_BatchWrite_593063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_BatchWrite_593063; body: JsonNode): Recallable =
  ## batchWrite
  ## Performs all the write operations in a batch. Either all the operations succeed or none.
  ##   body: JObject (required)
  var body_593077 = newJObject()
  if body != nil:
    body_593077 = body
  result = call_593076.call(nil, nil, nil, nil, body_593077)

var batchWrite* = Call_BatchWrite_593063(name: "batchWrite",
                                      meth: HttpMethod.HttpPut,
                                      host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/batchwrite#x-amz-data-partition",
                                      validator: validate_BatchWrite_593064,
                                      base: "/", url: url_BatchWrite_593065,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_593078 = ref object of OpenApiRestCall_592364
proc url_CreateDirectory_593080(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDirectory_593079(path: JsonNode; query: JsonNode;
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
  var valid_593081 = header.getOrDefault("X-Amz-Signature")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Signature", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Content-Sha256", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Date")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Date", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Credential")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Credential", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Security-Token")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Security-Token", valid_593085
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593086 = header.getOrDefault("x-amz-data-partition")
  valid_593086 = validateParameter(valid_593086, JString, required = true,
                                 default = nil)
  if valid_593086 != nil:
    section.add "x-amz-data-partition", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Algorithm")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Algorithm", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-SignedHeaders", valid_593088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593090: Call_CreateDirectory_593078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ## 
  let valid = call_593090.validator(path, query, header, formData, body)
  let scheme = call_593090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593090.url(scheme.get, call_593090.host, call_593090.base,
                         call_593090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593090, url, valid)

proc call*(call_593091: Call_CreateDirectory_593078; body: JsonNode): Recallable =
  ## createDirectory
  ## Creates a <a>Directory</a> by copying the published schema into the directory. A directory cannot be created without a schema.
  ##   body: JObject (required)
  var body_593092 = newJObject()
  if body != nil:
    body_593092 = body
  result = call_593091.call(nil, nil, nil, nil, body_593092)

var createDirectory* = Call_CreateDirectory_593078(name: "createDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/create#x-amz-data-partition",
    validator: validate_CreateDirectory_593079, base: "/", url: url_CreateDirectory_593080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFacet_593093 = ref object of OpenApiRestCall_592364
proc url_CreateFacet_593095(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFacet_593094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593096 = header.getOrDefault("X-Amz-Signature")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Signature", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Content-Sha256", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Date")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Date", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Credential")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Credential", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Security-Token")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Security-Token", valid_593100
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593101 = header.getOrDefault("x-amz-data-partition")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = nil)
  if valid_593101 != nil:
    section.add "x-amz-data-partition", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Algorithm")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Algorithm", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-SignedHeaders", valid_593103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593105: Call_CreateFacet_593093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ## 
  let valid = call_593105.validator(path, query, header, formData, body)
  let scheme = call_593105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593105.url(scheme.get, call_593105.host, call_593105.base,
                         call_593105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593105, url, valid)

proc call*(call_593106: Call_CreateFacet_593093; body: JsonNode): Recallable =
  ## createFacet
  ## Creates a new <a>Facet</a> in a schema. Facet creation is allowed only in development or applied schemas.
  ##   body: JObject (required)
  var body_593107 = newJObject()
  if body != nil:
    body_593107 = body
  result = call_593106.call(nil, nil, nil, nil, body_593107)

var createFacet* = Call_CreateFacet_593093(name: "createFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/create#x-amz-data-partition",
                                        validator: validate_CreateFacet_593094,
                                        base: "/", url: url_CreateFacet_593095,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIndex_593108 = ref object of OpenApiRestCall_592364
proc url_CreateIndex_593110(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIndex_593109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593116 = header.getOrDefault("x-amz-data-partition")
  valid_593116 = validateParameter(valid_593116, JString, required = true,
                                 default = nil)
  if valid_593116 != nil:
    section.add "x-amz-data-partition", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Algorithm")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Algorithm", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-SignedHeaders", valid_593118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593120: Call_CreateIndex_593108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ## 
  let valid = call_593120.validator(path, query, header, formData, body)
  let scheme = call_593120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593120.url(scheme.get, call_593120.host, call_593120.base,
                         call_593120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593120, url, valid)

proc call*(call_593121: Call_CreateIndex_593108; body: JsonNode): Recallable =
  ## createIndex
  ## Creates an index object. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_indexing.html">Indexing</a> for more information.
  ##   body: JObject (required)
  var body_593122 = newJObject()
  if body != nil:
    body_593122 = body
  result = call_593121.call(nil, nil, nil, nil, body_593122)

var createIndex* = Call_CreateIndex_593108(name: "createIndex",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index#x-amz-data-partition",
                                        validator: validate_CreateIndex_593109,
                                        base: "/", url: url_CreateIndex_593110,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateObject_593123 = ref object of OpenApiRestCall_592364
proc url_CreateObject_593125(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateObject_593124(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593131 = header.getOrDefault("x-amz-data-partition")
  valid_593131 = validateParameter(valid_593131, JString, required = true,
                                 default = nil)
  if valid_593131 != nil:
    section.add "x-amz-data-partition", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Algorithm")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Algorithm", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-SignedHeaders", valid_593133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593135: Call_CreateObject_593123; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ## 
  let valid = call_593135.validator(path, query, header, formData, body)
  let scheme = call_593135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593135.url(scheme.get, call_593135.host, call_593135.base,
                         call_593135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593135, url, valid)

proc call*(call_593136: Call_CreateObject_593123; body: JsonNode): Recallable =
  ## createObject
  ## Creates an object in a <a>Directory</a>. Additionally attaches the object to a parent, if a parent reference and <code>LinkName</code> is specified. An object is simply a collection of <a>Facet</a> attributes. You can also use this API call to create a policy object, if the facet from which you create the object is a policy facet. 
  ##   body: JObject (required)
  var body_593137 = newJObject()
  if body != nil:
    body_593137 = body
  result = call_593136.call(nil, nil, nil, nil, body_593137)

var createObject* = Call_CreateObject_593123(name: "createObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/object#x-amz-data-partition",
    validator: validate_CreateObject_593124, base: "/", url: url_CreateObject_593125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSchema_593138 = ref object of OpenApiRestCall_592364
proc url_CreateSchema_593140(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSchema_593139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593141 = header.getOrDefault("X-Amz-Signature")
  valid_593141 = validateParameter(valid_593141, JString, required = false,
                                 default = nil)
  if valid_593141 != nil:
    section.add "X-Amz-Signature", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Content-Sha256", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Date")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Date", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Credential")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Credential", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Security-Token")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Security-Token", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Algorithm")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Algorithm", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-SignedHeaders", valid_593147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593149: Call_CreateSchema_593138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ## 
  let valid = call_593149.validator(path, query, header, formData, body)
  let scheme = call_593149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593149.url(scheme.get, call_593149.host, call_593149.base,
                         call_593149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593149, url, valid)

proc call*(call_593150: Call_CreateSchema_593138; body: JsonNode): Recallable =
  ## createSchema
  ## <p>Creates a new schema in a development state. A schema can exist in three phases:</p> <ul> <li> <p> <i>Development:</i> This is a mutable phase of the schema. All new schemas are in the development phase. Once the schema is finalized, it can be published.</p> </li> <li> <p> <i>Published:</i> Published schemas are immutable and have a version associated with them.</p> </li> <li> <p> <i>Applied:</i> Applied schemas are mutable in a way that allows you to add new schema facets. You can also add new, nonrequired attributes to existing schema facets. You can apply only published schemas to directories. </p> </li> </ul>
  ##   body: JObject (required)
  var body_593151 = newJObject()
  if body != nil:
    body_593151 = body
  result = call_593150.call(nil, nil, nil, nil, body_593151)

var createSchema* = Call_CreateSchema_593138(name: "createSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/create",
    validator: validate_CreateSchema_593139, base: "/", url: url_CreateSchema_593140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTypedLinkFacet_593152 = ref object of OpenApiRestCall_592364
proc url_CreateTypedLinkFacet_593154(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTypedLinkFacet_593153(path: JsonNode; query: JsonNode;
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
  var valid_593155 = header.getOrDefault("X-Amz-Signature")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "X-Amz-Signature", valid_593155
  var valid_593156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "X-Amz-Content-Sha256", valid_593156
  var valid_593157 = header.getOrDefault("X-Amz-Date")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Date", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Credential")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Credential", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Security-Token")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Security-Token", valid_593159
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593160 = header.getOrDefault("x-amz-data-partition")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "x-amz-data-partition", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Algorithm")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Algorithm", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-SignedHeaders", valid_593162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593164: Call_CreateTypedLinkFacet_593152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593164.validator(path, query, header, formData, body)
  let scheme = call_593164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593164.url(scheme.get, call_593164.host, call_593164.base,
                         call_593164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593164, url, valid)

proc call*(call_593165: Call_CreateTypedLinkFacet_593152; body: JsonNode): Recallable =
  ## createTypedLinkFacet
  ## Creates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593166 = newJObject()
  if body != nil:
    body_593166 = body
  result = call_593165.call(nil, nil, nil, nil, body_593166)

var createTypedLinkFacet* = Call_CreateTypedLinkFacet_593152(
    name: "createTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/create#x-amz-data-partition",
    validator: validate_CreateTypedLinkFacet_593153, base: "/",
    url: url_CreateTypedLinkFacet_593154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_593167 = ref object of OpenApiRestCall_592364
proc url_DeleteDirectory_593169(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDirectory_593168(path: JsonNode; query: JsonNode;
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
  var valid_593170 = header.getOrDefault("X-Amz-Signature")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Signature", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Content-Sha256", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Date")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Date", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Credential")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Credential", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Security-Token")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Security-Token", valid_593174
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593175 = header.getOrDefault("x-amz-data-partition")
  valid_593175 = validateParameter(valid_593175, JString, required = true,
                                 default = nil)
  if valid_593175 != nil:
    section.add "x-amz-data-partition", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593178: Call_DeleteDirectory_593167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  ## 
  let valid = call_593178.validator(path, query, header, formData, body)
  let scheme = call_593178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593178.url(scheme.get, call_593178.host, call_593178.base,
                         call_593178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593178, url, valid)

proc call*(call_593179: Call_DeleteDirectory_593167): Recallable =
  ## deleteDirectory
  ## Deletes a directory. Only disabled directories can be deleted. A deleted directory cannot be undone. Exercise extreme caution when deleting directories.
  result = call_593179.call(nil, nil, nil, nil, nil)

var deleteDirectory* = Call_DeleteDirectory_593167(name: "deleteDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory#x-amz-data-partition",
    validator: validate_DeleteDirectory_593168, base: "/", url: url_DeleteDirectory_593169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFacet_593180 = ref object of OpenApiRestCall_592364
proc url_DeleteFacet_593182(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFacet_593181(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593183 = header.getOrDefault("X-Amz-Signature")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Signature", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Content-Sha256", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Date")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Date", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Credential")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Credential", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Security-Token")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Security-Token", valid_593187
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593188 = header.getOrDefault("x-amz-data-partition")
  valid_593188 = validateParameter(valid_593188, JString, required = true,
                                 default = nil)
  if valid_593188 != nil:
    section.add "x-amz-data-partition", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Algorithm")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Algorithm", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-SignedHeaders", valid_593190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593192: Call_DeleteFacet_593180; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ## 
  let valid = call_593192.validator(path, query, header, formData, body)
  let scheme = call_593192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593192.url(scheme.get, call_593192.host, call_593192.base,
                         call_593192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593192, url, valid)

proc call*(call_593193: Call_DeleteFacet_593180; body: JsonNode): Recallable =
  ## deleteFacet
  ## Deletes a given <a>Facet</a>. All attributes and <a>Rule</a>s that are associated with the facet will be deleted. Only development schema facets are allowed deletion.
  ##   body: JObject (required)
  var body_593194 = newJObject()
  if body != nil:
    body_593194 = body
  result = call_593193.call(nil, nil, nil, nil, body_593194)

var deleteFacet* = Call_DeleteFacet_593180(name: "deleteFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/delete#x-amz-data-partition",
                                        validator: validate_DeleteFacet_593181,
                                        base: "/", url: url_DeleteFacet_593182,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteObject_593195 = ref object of OpenApiRestCall_592364
proc url_DeleteObject_593197(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteObject_593196(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593198 = header.getOrDefault("X-Amz-Signature")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Signature", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Content-Sha256", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Date")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Date", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Credential")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Credential", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Security-Token")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Security-Token", valid_593202
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593203 = header.getOrDefault("x-amz-data-partition")
  valid_593203 = validateParameter(valid_593203, JString, required = true,
                                 default = nil)
  if valid_593203 != nil:
    section.add "x-amz-data-partition", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_DeleteObject_593195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_DeleteObject_593195; body: JsonNode): Recallable =
  ## deleteObject
  ## Deletes an object and its associated attributes. Only objects with no children and no parents can be deleted.
  ##   body: JObject (required)
  var body_593209 = newJObject()
  if body != nil:
    body_593209 = body
  result = call_593208.call(nil, nil, nil, nil, body_593209)

var deleteObject* = Call_DeleteObject_593195(name: "deleteObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/delete#x-amz-data-partition",
    validator: validate_DeleteObject_593196, base: "/", url: url_DeleteObject_593197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchema_593210 = ref object of OpenApiRestCall_592364
proc url_DeleteSchema_593212(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSchema_593211(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593213 = header.getOrDefault("X-Amz-Signature")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Signature", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Content-Sha256", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Date")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Date", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Credential")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Credential", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Security-Token")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Security-Token", valid_593217
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593218 = header.getOrDefault("x-amz-data-partition")
  valid_593218 = validateParameter(valid_593218, JString, required = true,
                                 default = nil)
  if valid_593218 != nil:
    section.add "x-amz-data-partition", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Algorithm")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Algorithm", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-SignedHeaders", valid_593220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593221: Call_DeleteSchema_593210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  ## 
  let valid = call_593221.validator(path, query, header, formData, body)
  let scheme = call_593221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593221.url(scheme.get, call_593221.host, call_593221.base,
                         call_593221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593221, url, valid)

proc call*(call_593222: Call_DeleteSchema_593210): Recallable =
  ## deleteSchema
  ## Deletes a given schema. Schemas in a development and published state can only be deleted. 
  result = call_593222.call(nil, nil, nil, nil, nil)

var deleteSchema* = Call_DeleteSchema_593210(name: "deleteSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema#x-amz-data-partition",
    validator: validate_DeleteSchema_593211, base: "/", url: url_DeleteSchema_593212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTypedLinkFacet_593223 = ref object of OpenApiRestCall_592364
proc url_DeleteTypedLinkFacet_593225(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTypedLinkFacet_593224(path: JsonNode; query: JsonNode;
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
  var valid_593226 = header.getOrDefault("X-Amz-Signature")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Signature", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Content-Sha256", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Date")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Date", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Credential")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Credential", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Security-Token")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Security-Token", valid_593230
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593231 = header.getOrDefault("x-amz-data-partition")
  valid_593231 = validateParameter(valid_593231, JString, required = true,
                                 default = nil)
  if valid_593231 != nil:
    section.add "x-amz-data-partition", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Algorithm")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Algorithm", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-SignedHeaders", valid_593233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593235: Call_DeleteTypedLinkFacet_593223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593235.validator(path, query, header, formData, body)
  let scheme = call_593235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593235.url(scheme.get, call_593235.host, call_593235.base,
                         call_593235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593235, url, valid)

proc call*(call_593236: Call_DeleteTypedLinkFacet_593223; body: JsonNode): Recallable =
  ## deleteTypedLinkFacet
  ## Deletes a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593237 = newJObject()
  if body != nil:
    body_593237 = body
  result = call_593236.call(nil, nil, nil, nil, body_593237)

var deleteTypedLinkFacet* = Call_DeleteTypedLinkFacet_593223(
    name: "deleteTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/delete#x-amz-data-partition",
    validator: validate_DeleteTypedLinkFacet_593224, base: "/",
    url: url_DeleteTypedLinkFacet_593225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachFromIndex_593238 = ref object of OpenApiRestCall_592364
proc url_DetachFromIndex_593240(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachFromIndex_593239(path: JsonNode; query: JsonNode;
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
  var valid_593241 = header.getOrDefault("X-Amz-Signature")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Signature", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Content-Sha256", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Date")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Date", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Credential")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Credential", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Security-Token")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Security-Token", valid_593245
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593246 = header.getOrDefault("x-amz-data-partition")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = nil)
  if valid_593246 != nil:
    section.add "x-amz-data-partition", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Algorithm")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Algorithm", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-SignedHeaders", valid_593248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593250: Call_DetachFromIndex_593238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches the specified object from the specified index.
  ## 
  let valid = call_593250.validator(path, query, header, formData, body)
  let scheme = call_593250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593250.url(scheme.get, call_593250.host, call_593250.base,
                         call_593250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593250, url, valid)

proc call*(call_593251: Call_DetachFromIndex_593238; body: JsonNode): Recallable =
  ## detachFromIndex
  ## Detaches the specified object from the specified index.
  ##   body: JObject (required)
  var body_593252 = newJObject()
  if body != nil:
    body_593252 = body
  result = call_593251.call(nil, nil, nil, nil, body_593252)

var detachFromIndex* = Call_DetachFromIndex_593238(name: "detachFromIndex",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/detach#x-amz-data-partition",
    validator: validate_DetachFromIndex_593239, base: "/", url: url_DetachFromIndex_593240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachObject_593253 = ref object of OpenApiRestCall_592364
proc url_DetachObject_593255(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachObject_593254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593256 = header.getOrDefault("X-Amz-Signature")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-Signature", valid_593256
  var valid_593257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Content-Sha256", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Date")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Date", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Credential")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Credential", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Security-Token")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Security-Token", valid_593260
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593261 = header.getOrDefault("x-amz-data-partition")
  valid_593261 = validateParameter(valid_593261, JString, required = true,
                                 default = nil)
  if valid_593261 != nil:
    section.add "x-amz-data-partition", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Algorithm")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Algorithm", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-SignedHeaders", valid_593263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593265: Call_DetachObject_593253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ## 
  let valid = call_593265.validator(path, query, header, formData, body)
  let scheme = call_593265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593265.url(scheme.get, call_593265.host, call_593265.base,
                         call_593265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593265, url, valid)

proc call*(call_593266: Call_DetachObject_593253; body: JsonNode): Recallable =
  ## detachObject
  ## Detaches a given object from the parent object. The object that is to be detached from the parent is specified by the link name.
  ##   body: JObject (required)
  var body_593267 = newJObject()
  if body != nil:
    body_593267 = body
  result = call_593266.call(nil, nil, nil, nil, body_593267)

var detachObject* = Call_DetachObject_593253(name: "detachObject",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/detach#x-amz-data-partition",
    validator: validate_DetachObject_593254, base: "/", url: url_DetachObject_593255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachPolicy_593268 = ref object of OpenApiRestCall_592364
proc url_DetachPolicy_593270(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachPolicy_593269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593271 = header.getOrDefault("X-Amz-Signature")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Signature", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Content-Sha256", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Date")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Date", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Credential")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Credential", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Security-Token")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Security-Token", valid_593275
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593276 = header.getOrDefault("x-amz-data-partition")
  valid_593276 = validateParameter(valid_593276, JString, required = true,
                                 default = nil)
  if valid_593276 != nil:
    section.add "x-amz-data-partition", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Algorithm")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Algorithm", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-SignedHeaders", valid_593278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593280: Call_DetachPolicy_593268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a policy from an object.
  ## 
  let valid = call_593280.validator(path, query, header, formData, body)
  let scheme = call_593280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593280.url(scheme.get, call_593280.host, call_593280.base,
                         call_593280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593280, url, valid)

proc call*(call_593281: Call_DetachPolicy_593268; body: JsonNode): Recallable =
  ## detachPolicy
  ## Detaches a policy from an object.
  ##   body: JObject (required)
  var body_593282 = newJObject()
  if body != nil:
    body_593282 = body
  result = call_593281.call(nil, nil, nil, nil, body_593282)

var detachPolicy* = Call_DetachPolicy_593268(name: "detachPolicy",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/detach#x-amz-data-partition",
    validator: validate_DetachPolicy_593269, base: "/", url: url_DetachPolicy_593270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetachTypedLink_593283 = ref object of OpenApiRestCall_592364
proc url_DetachTypedLink_593285(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DetachTypedLink_593284(path: JsonNode; query: JsonNode;
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
  var valid_593286 = header.getOrDefault("X-Amz-Signature")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Signature", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Content-Sha256", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Date")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Date", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Credential")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Credential", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Security-Token")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Security-Token", valid_593290
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593291 = header.getOrDefault("x-amz-data-partition")
  valid_593291 = validateParameter(valid_593291, JString, required = true,
                                 default = nil)
  if valid_593291 != nil:
    section.add "x-amz-data-partition", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Algorithm")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Algorithm", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-SignedHeaders", valid_593293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593295: Call_DetachTypedLink_593283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593295.validator(path, query, header, formData, body)
  let scheme = call_593295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593295.url(scheme.get, call_593295.host, call_593295.base,
                         call_593295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593295, url, valid)

proc call*(call_593296: Call_DetachTypedLink_593283; body: JsonNode): Recallable =
  ## detachTypedLink
  ## Detaches a typed link from a specified source and target object. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593297 = newJObject()
  if body != nil:
    body_593297 = body
  result = call_593296.call(nil, nil, nil, nil, body_593297)

var detachTypedLink* = Call_DetachTypedLink_593283(name: "detachTypedLink",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/detach#x-amz-data-partition",
    validator: validate_DetachTypedLink_593284, base: "/", url: url_DetachTypedLink_593285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDirectory_593298 = ref object of OpenApiRestCall_592364
proc url_DisableDirectory_593300(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableDirectory_593299(path: JsonNode; query: JsonNode;
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
  var valid_593301 = header.getOrDefault("X-Amz-Signature")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Signature", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Content-Sha256", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Date")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Date", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Credential")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Credential", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Security-Token")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Security-Token", valid_593305
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593306 = header.getOrDefault("x-amz-data-partition")
  valid_593306 = validateParameter(valid_593306, JString, required = true,
                                 default = nil)
  if valid_593306 != nil:
    section.add "x-amz-data-partition", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Algorithm")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Algorithm", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-SignedHeaders", valid_593308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593309: Call_DisableDirectory_593298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  ## 
  let valid = call_593309.validator(path, query, header, formData, body)
  let scheme = call_593309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593309.url(scheme.get, call_593309.host, call_593309.base,
                         call_593309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593309, url, valid)

proc call*(call_593310: Call_DisableDirectory_593298): Recallable =
  ## disableDirectory
  ## Disables the specified directory. Disabled directories cannot be read or written to. Only enabled directories can be disabled. Disabled directories may be reenabled.
  result = call_593310.call(nil, nil, nil, nil, nil)

var disableDirectory* = Call_DisableDirectory_593298(name: "disableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/disable#x-amz-data-partition",
    validator: validate_DisableDirectory_593299, base: "/",
    url: url_DisableDirectory_593300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDirectory_593311 = ref object of OpenApiRestCall_592364
proc url_EnableDirectory_593313(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableDirectory_593312(path: JsonNode; query: JsonNode;
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
  var valid_593314 = header.getOrDefault("X-Amz-Signature")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Signature", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Content-Sha256", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Date")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Date", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Credential")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Credential", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Security-Token")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Security-Token", valid_593318
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593319 = header.getOrDefault("x-amz-data-partition")
  valid_593319 = validateParameter(valid_593319, JString, required = true,
                                 default = nil)
  if valid_593319 != nil:
    section.add "x-amz-data-partition", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Algorithm")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Algorithm", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-SignedHeaders", valid_593321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593322: Call_EnableDirectory_593311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  ## 
  let valid = call_593322.validator(path, query, header, formData, body)
  let scheme = call_593322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593322.url(scheme.get, call_593322.host, call_593322.base,
                         call_593322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593322, url, valid)

proc call*(call_593323: Call_EnableDirectory_593311): Recallable =
  ## enableDirectory
  ## Enables the specified directory. Only disabled directories can be enabled. Once enabled, the directory can then be read and written to.
  result = call_593323.call(nil, nil, nil, nil, nil)

var enableDirectory* = Call_EnableDirectory_593311(name: "enableDirectory",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/enable#x-amz-data-partition",
    validator: validate_EnableDirectory_593312, base: "/", url: url_EnableDirectory_593313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppliedSchemaVersion_593324 = ref object of OpenApiRestCall_592364
proc url_GetAppliedSchemaVersion_593326(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAppliedSchemaVersion_593325(path: JsonNode; query: JsonNode;
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
  var valid_593327 = header.getOrDefault("X-Amz-Signature")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Signature", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Content-Sha256", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Date")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Date", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Credential")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Credential", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Security-Token")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Security-Token", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Algorithm")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Algorithm", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-SignedHeaders", valid_593333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593335: Call_GetAppliedSchemaVersion_593324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns current applied schema version ARN, including the minor version in use.
  ## 
  let valid = call_593335.validator(path, query, header, formData, body)
  let scheme = call_593335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593335.url(scheme.get, call_593335.host, call_593335.base,
                         call_593335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593335, url, valid)

proc call*(call_593336: Call_GetAppliedSchemaVersion_593324; body: JsonNode): Recallable =
  ## getAppliedSchemaVersion
  ## Returns current applied schema version ARN, including the minor version in use.
  ##   body: JObject (required)
  var body_593337 = newJObject()
  if body != nil:
    body_593337 = body
  result = call_593336.call(nil, nil, nil, nil, body_593337)

var getAppliedSchemaVersion* = Call_GetAppliedSchemaVersion_593324(
    name: "getAppliedSchemaVersion", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/getappliedschema",
    validator: validate_GetAppliedSchemaVersion_593325, base: "/",
    url: url_GetAppliedSchemaVersion_593326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectory_593338 = ref object of OpenApiRestCall_592364
proc url_GetDirectory_593340(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDirectory_593339(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593341 = header.getOrDefault("X-Amz-Signature")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "X-Amz-Signature", valid_593341
  var valid_593342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "X-Amz-Content-Sha256", valid_593342
  var valid_593343 = header.getOrDefault("X-Amz-Date")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Date", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Credential")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Credential", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Security-Token")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Security-Token", valid_593345
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593346 = header.getOrDefault("x-amz-data-partition")
  valid_593346 = validateParameter(valid_593346, JString, required = true,
                                 default = nil)
  if valid_593346 != nil:
    section.add "x-amz-data-partition", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Algorithm")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Algorithm", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-SignedHeaders", valid_593348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593349: Call_GetDirectory_593338; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about a directory.
  ## 
  let valid = call_593349.validator(path, query, header, formData, body)
  let scheme = call_593349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593349.url(scheme.get, call_593349.host, call_593349.base,
                         call_593349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593349, url, valid)

proc call*(call_593350: Call_GetDirectory_593338): Recallable =
  ## getDirectory
  ## Retrieves metadata about a directory.
  result = call_593350.call(nil, nil, nil, nil, nil)

var getDirectory* = Call_GetDirectory_593338(name: "getDirectory",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/directory/get#x-amz-data-partition",
    validator: validate_GetDirectory_593339, base: "/", url: url_GetDirectory_593340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFacet_593351 = ref object of OpenApiRestCall_592364
proc url_UpdateFacet_593353(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFacet_593352(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593354 = header.getOrDefault("X-Amz-Signature")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Signature", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Content-Sha256", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Date")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Date", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-Credential")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-Credential", valid_593357
  var valid_593358 = header.getOrDefault("X-Amz-Security-Token")
  valid_593358 = validateParameter(valid_593358, JString, required = false,
                                 default = nil)
  if valid_593358 != nil:
    section.add "X-Amz-Security-Token", valid_593358
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593359 = header.getOrDefault("x-amz-data-partition")
  valid_593359 = validateParameter(valid_593359, JString, required = true,
                                 default = nil)
  if valid_593359 != nil:
    section.add "x-amz-data-partition", valid_593359
  var valid_593360 = header.getOrDefault("X-Amz-Algorithm")
  valid_593360 = validateParameter(valid_593360, JString, required = false,
                                 default = nil)
  if valid_593360 != nil:
    section.add "X-Amz-Algorithm", valid_593360
  var valid_593361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593361 = validateParameter(valid_593361, JString, required = false,
                                 default = nil)
  if valid_593361 != nil:
    section.add "X-Amz-SignedHeaders", valid_593361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593363: Call_UpdateFacet_593351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ## 
  let valid = call_593363.validator(path, query, header, formData, body)
  let scheme = call_593363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593363.url(scheme.get, call_593363.host, call_593363.base,
                         call_593363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593363, url, valid)

proc call*(call_593364: Call_UpdateFacet_593351; body: JsonNode): Recallable =
  ## updateFacet
  ## <p>Does the following:</p> <ol> <li> <p>Adds new <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Updates existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> <li> <p>Deletes existing <code>Attributes</code>, <code>Rules</code>, or <code>ObjectTypes</code>.</p> </li> </ol>
  ##   body: JObject (required)
  var body_593365 = newJObject()
  if body != nil:
    body_593365 = body
  result = call_593364.call(nil, nil, nil, nil, body_593365)

var updateFacet* = Call_UpdateFacet_593351(name: "updateFacet",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                        validator: validate_UpdateFacet_593352,
                                        base: "/", url: url_UpdateFacet_593353,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFacet_593366 = ref object of OpenApiRestCall_592364
proc url_GetFacet_593368(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFacet_593367(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593369 = header.getOrDefault("X-Amz-Signature")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Signature", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Content-Sha256", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Date")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Date", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Credential")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Credential", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-Security-Token")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Security-Token", valid_593373
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593374 = header.getOrDefault("x-amz-data-partition")
  valid_593374 = validateParameter(valid_593374, JString, required = true,
                                 default = nil)
  if valid_593374 != nil:
    section.add "x-amz-data-partition", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Algorithm")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Algorithm", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-SignedHeaders", valid_593376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593378: Call_GetFacet_593366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ## 
  let valid = call_593378.validator(path, query, header, formData, body)
  let scheme = call_593378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593378.url(scheme.get, call_593378.host, call_593378.base,
                         call_593378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593378, url, valid)

proc call*(call_593379: Call_GetFacet_593366; body: JsonNode): Recallable =
  ## getFacet
  ## Gets details of the <a>Facet</a>, such as facet name, attributes, <a>Rule</a>s, or <code>ObjectType</code>. You can call this on all kinds of schema facets -- published, development, or applied.
  ##   body: JObject (required)
  var body_593380 = newJObject()
  if body != nil:
    body_593380 = body
  result = call_593379.call(nil, nil, nil, nil, body_593380)

var getFacet* = Call_GetFacet_593366(name: "getFacet", meth: HttpMethod.HttpPost,
                                  host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet#x-amz-data-partition",
                                  validator: validate_GetFacet_593367, base: "/",
                                  url: url_GetFacet_593368,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLinkAttributes_593381 = ref object of OpenApiRestCall_592364
proc url_GetLinkAttributes_593383(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLinkAttributes_593382(path: JsonNode; query: JsonNode;
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
  var valid_593384 = header.getOrDefault("X-Amz-Signature")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Signature", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Content-Sha256", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Date")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Date", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Credential")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Credential", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Security-Token")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Security-Token", valid_593388
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593389 = header.getOrDefault("x-amz-data-partition")
  valid_593389 = validateParameter(valid_593389, JString, required = true,
                                 default = nil)
  if valid_593389 != nil:
    section.add "x-amz-data-partition", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Algorithm")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Algorithm", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-SignedHeaders", valid_593391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593393: Call_GetLinkAttributes_593381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes that are associated with a typed link.
  ## 
  let valid = call_593393.validator(path, query, header, formData, body)
  let scheme = call_593393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593393.url(scheme.get, call_593393.host, call_593393.base,
                         call_593393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593393, url, valid)

proc call*(call_593394: Call_GetLinkAttributes_593381; body: JsonNode): Recallable =
  ## getLinkAttributes
  ## Retrieves attributes that are associated with a typed link.
  ##   body: JObject (required)
  var body_593395 = newJObject()
  if body != nil:
    body_593395 = body
  result = call_593394.call(nil, nil, nil, nil, body_593395)

var getLinkAttributes* = Call_GetLinkAttributes_593381(name: "getLinkAttributes",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/get#x-amz-data-partition",
    validator: validate_GetLinkAttributes_593382, base: "/",
    url: url_GetLinkAttributes_593383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectAttributes_593396 = ref object of OpenApiRestCall_592364
proc url_GetObjectAttributes_593398(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetObjectAttributes_593397(path: JsonNode; query: JsonNode;
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
  var valid_593399 = header.getOrDefault("x-amz-consistency-level")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593399 != nil:
    section.add "x-amz-consistency-level", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Signature")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Signature", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Content-Sha256", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Date")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Date", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Credential")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Credential", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Security-Token")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Security-Token", valid_593404
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593405 = header.getOrDefault("x-amz-data-partition")
  valid_593405 = validateParameter(valid_593405, JString, required = true,
                                 default = nil)
  if valid_593405 != nil:
    section.add "x-amz-data-partition", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Algorithm")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Algorithm", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-SignedHeaders", valid_593407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593409: Call_GetObjectAttributes_593396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes within a facet that are associated with an object.
  ## 
  let valid = call_593409.validator(path, query, header, formData, body)
  let scheme = call_593409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593409.url(scheme.get, call_593409.host, call_593409.base,
                         call_593409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593409, url, valid)

proc call*(call_593410: Call_GetObjectAttributes_593396; body: JsonNode): Recallable =
  ## getObjectAttributes
  ## Retrieves attributes within a facet that are associated with an object.
  ##   body: JObject (required)
  var body_593411 = newJObject()
  if body != nil:
    body_593411 = body
  result = call_593410.call(nil, nil, nil, nil, body_593411)

var getObjectAttributes* = Call_GetObjectAttributes_593396(
    name: "getObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes/get#x-amz-data-partition",
    validator: validate_GetObjectAttributes_593397, base: "/",
    url: url_GetObjectAttributes_593398, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetObjectInformation_593412 = ref object of OpenApiRestCall_592364
proc url_GetObjectInformation_593414(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetObjectInformation_593413(path: JsonNode; query: JsonNode;
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
  var valid_593415 = header.getOrDefault("x-amz-consistency-level")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593415 != nil:
    section.add "x-amz-consistency-level", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Signature")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Signature", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Content-Sha256", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Date")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Date", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Credential")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Credential", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Security-Token")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Security-Token", valid_593420
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593421 = header.getOrDefault("x-amz-data-partition")
  valid_593421 = validateParameter(valid_593421, JString, required = true,
                                 default = nil)
  if valid_593421 != nil:
    section.add "x-amz-data-partition", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Algorithm")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Algorithm", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-SignedHeaders", valid_593423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593425: Call_GetObjectInformation_593412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata about an object.
  ## 
  let valid = call_593425.validator(path, query, header, formData, body)
  let scheme = call_593425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593425.url(scheme.get, call_593425.host, call_593425.base,
                         call_593425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593425, url, valid)

proc call*(call_593426: Call_GetObjectInformation_593412; body: JsonNode): Recallable =
  ## getObjectInformation
  ## Retrieves metadata about an object.
  ##   body: JObject (required)
  var body_593427 = newJObject()
  if body != nil:
    body_593427 = body
  result = call_593426.call(nil, nil, nil, nil, body_593427)

var getObjectInformation* = Call_GetObjectInformation_593412(
    name: "getObjectInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/information#x-amz-data-partition",
    validator: validate_GetObjectInformation_593413, base: "/",
    url: url_GetObjectInformation_593414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSchemaFromJson_593428 = ref object of OpenApiRestCall_592364
proc url_PutSchemaFromJson_593430(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutSchemaFromJson_593429(path: JsonNode; query: JsonNode;
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
  var valid_593431 = header.getOrDefault("X-Amz-Signature")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Signature", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Content-Sha256", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Date")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Date", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Credential")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Credential", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Security-Token")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Security-Token", valid_593435
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593436 = header.getOrDefault("x-amz-data-partition")
  valid_593436 = validateParameter(valid_593436, JString, required = true,
                                 default = nil)
  if valid_593436 != nil:
    section.add "x-amz-data-partition", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Algorithm")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Algorithm", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-SignedHeaders", valid_593438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593440: Call_PutSchemaFromJson_593428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_593440.validator(path, query, header, formData, body)
  let scheme = call_593440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593440.url(scheme.get, call_593440.host, call_593440.base,
                         call_593440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593440, url, valid)

proc call*(call_593441: Call_PutSchemaFromJson_593428; body: JsonNode): Recallable =
  ## putSchemaFromJson
  ## Allows a schema to be updated using JSON upload. Only available for development schemas. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ##   body: JObject (required)
  var body_593442 = newJObject()
  if body != nil:
    body_593442 = body
  result = call_593441.call(nil, nil, nil, nil, body_593442)

var putSchemaFromJson* = Call_PutSchemaFromJson_593428(name: "putSchemaFromJson",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_PutSchemaFromJson_593429, base: "/",
    url: url_PutSchemaFromJson_593430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSchemaAsJson_593443 = ref object of OpenApiRestCall_592364
proc url_GetSchemaAsJson_593445(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSchemaAsJson_593444(path: JsonNode; query: JsonNode;
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
  var valid_593446 = header.getOrDefault("X-Amz-Signature")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Signature", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Content-Sha256", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Date")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Date", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Credential")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Credential", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Security-Token")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Security-Token", valid_593450
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593451 = header.getOrDefault("x-amz-data-partition")
  valid_593451 = validateParameter(valid_593451, JString, required = true,
                                 default = nil)
  if valid_593451 != nil:
    section.add "x-amz-data-partition", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Algorithm")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Algorithm", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-SignedHeaders", valid_593453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593454: Call_GetSchemaAsJson_593443; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  ## 
  let valid = call_593454.validator(path, query, header, formData, body)
  let scheme = call_593454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593454.url(scheme.get, call_593454.host, call_593454.base,
                         call_593454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593454, url, valid)

proc call*(call_593455: Call_GetSchemaAsJson_593443): Recallable =
  ## getSchemaAsJson
  ## Retrieves a JSON representation of the schema. See <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_schemas.html#jsonformat">JSON Schema Format</a> for more information.
  result = call_593455.call(nil, nil, nil, nil, nil)

var getSchemaAsJson* = Call_GetSchemaAsJson_593443(name: "getSchemaAsJson",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/json#x-amz-data-partition",
    validator: validate_GetSchemaAsJson_593444, base: "/", url: url_GetSchemaAsJson_593445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTypedLinkFacetInformation_593456 = ref object of OpenApiRestCall_592364
proc url_GetTypedLinkFacetInformation_593458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTypedLinkFacetInformation_593457(path: JsonNode; query: JsonNode;
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
  var valid_593459 = header.getOrDefault("X-Amz-Signature")
  valid_593459 = validateParameter(valid_593459, JString, required = false,
                                 default = nil)
  if valid_593459 != nil:
    section.add "X-Amz-Signature", valid_593459
  var valid_593460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Content-Sha256", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Date")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Date", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Credential")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Credential", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Security-Token")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Security-Token", valid_593463
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593464 = header.getOrDefault("x-amz-data-partition")
  valid_593464 = validateParameter(valid_593464, JString, required = true,
                                 default = nil)
  if valid_593464 != nil:
    section.add "x-amz-data-partition", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Algorithm")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Algorithm", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-SignedHeaders", valid_593466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_GetTypedLinkFacetInformation_593456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_GetTypedLinkFacetInformation_593456; body: JsonNode): Recallable =
  ## getTypedLinkFacetInformation
  ## Returns the identity attribute order for a specific <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593470 = newJObject()
  if body != nil:
    body_593470 = body
  result = call_593469.call(nil, nil, nil, nil, body_593470)

var getTypedLinkFacetInformation* = Call_GetTypedLinkFacetInformation_593456(
    name: "getTypedLinkFacetInformation", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/get#x-amz-data-partition",
    validator: validate_GetTypedLinkFacetInformation_593457, base: "/",
    url: url_GetTypedLinkFacetInformation_593458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAppliedSchemaArns_593471 = ref object of OpenApiRestCall_592364
proc url_ListAppliedSchemaArns_593473(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAppliedSchemaArns_593472(path: JsonNode; query: JsonNode;
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
  var valid_593474 = query.getOrDefault("MaxResults")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "MaxResults", valid_593474
  var valid_593475 = query.getOrDefault("NextToken")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "NextToken", valid_593475
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
  var valid_593476 = header.getOrDefault("X-Amz-Signature")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Signature", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Content-Sha256", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Date")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Date", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Credential")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Credential", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-Security-Token")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-Security-Token", valid_593480
  var valid_593481 = header.getOrDefault("X-Amz-Algorithm")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Algorithm", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-SignedHeaders", valid_593482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593484: Call_ListAppliedSchemaArns_593471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ## 
  let valid = call_593484.validator(path, query, header, formData, body)
  let scheme = call_593484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593484.url(scheme.get, call_593484.host, call_593484.base,
                         call_593484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593484, url, valid)

proc call*(call_593485: Call_ListAppliedSchemaArns_593471; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAppliedSchemaArns
  ## Lists schema major versions applied to a directory. If <code>SchemaArn</code> is provided, lists the minor version.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593486 = newJObject()
  var body_593487 = newJObject()
  add(query_593486, "MaxResults", newJString(MaxResults))
  add(query_593486, "NextToken", newJString(NextToken))
  if body != nil:
    body_593487 = body
  result = call_593485.call(nil, query_593486, nil, nil, body_593487)

var listAppliedSchemaArns* = Call_ListAppliedSchemaArns_593471(
    name: "listAppliedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/applied",
    validator: validate_ListAppliedSchemaArns_593472, base: "/",
    url: url_ListAppliedSchemaArns_593473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttachedIndices_593489 = ref object of OpenApiRestCall_592364
proc url_ListAttachedIndices_593491(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAttachedIndices_593490(path: JsonNode; query: JsonNode;
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
  var valid_593492 = query.getOrDefault("MaxResults")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "MaxResults", valid_593492
  var valid_593493 = query.getOrDefault("NextToken")
  valid_593493 = validateParameter(valid_593493, JString, required = false,
                                 default = nil)
  if valid_593493 != nil:
    section.add "NextToken", valid_593493
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
  var valid_593494 = header.getOrDefault("x-amz-consistency-level")
  valid_593494 = validateParameter(valid_593494, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593494 != nil:
    section.add "x-amz-consistency-level", valid_593494
  var valid_593495 = header.getOrDefault("X-Amz-Signature")
  valid_593495 = validateParameter(valid_593495, JString, required = false,
                                 default = nil)
  if valid_593495 != nil:
    section.add "X-Amz-Signature", valid_593495
  var valid_593496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Content-Sha256", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Date")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Date", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Credential")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Credential", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Security-Token")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Security-Token", valid_593499
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593500 = header.getOrDefault("x-amz-data-partition")
  valid_593500 = validateParameter(valid_593500, JString, required = true,
                                 default = nil)
  if valid_593500 != nil:
    section.add "x-amz-data-partition", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Algorithm")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Algorithm", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-SignedHeaders", valid_593502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593504: Call_ListAttachedIndices_593489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists indices attached to the specified object.
  ## 
  let valid = call_593504.validator(path, query, header, formData, body)
  let scheme = call_593504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593504.url(scheme.get, call_593504.host, call_593504.base,
                         call_593504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593504, url, valid)

proc call*(call_593505: Call_ListAttachedIndices_593489; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAttachedIndices
  ## Lists indices attached to the specified object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593506 = newJObject()
  var body_593507 = newJObject()
  add(query_593506, "MaxResults", newJString(MaxResults))
  add(query_593506, "NextToken", newJString(NextToken))
  if body != nil:
    body_593507 = body
  result = call_593505.call(nil, query_593506, nil, nil, body_593507)

var listAttachedIndices* = Call_ListAttachedIndices_593489(
    name: "listAttachedIndices", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/indices#x-amz-data-partition",
    validator: validate_ListAttachedIndices_593490, base: "/",
    url: url_ListAttachedIndices_593491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevelopmentSchemaArns_593508 = ref object of OpenApiRestCall_592364
proc url_ListDevelopmentSchemaArns_593510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDevelopmentSchemaArns_593509(path: JsonNode; query: JsonNode;
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
  var valid_593511 = query.getOrDefault("MaxResults")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "MaxResults", valid_593511
  var valid_593512 = query.getOrDefault("NextToken")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "NextToken", valid_593512
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
  var valid_593513 = header.getOrDefault("X-Amz-Signature")
  valid_593513 = validateParameter(valid_593513, JString, required = false,
                                 default = nil)
  if valid_593513 != nil:
    section.add "X-Amz-Signature", valid_593513
  var valid_593514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593514 = validateParameter(valid_593514, JString, required = false,
                                 default = nil)
  if valid_593514 != nil:
    section.add "X-Amz-Content-Sha256", valid_593514
  var valid_593515 = header.getOrDefault("X-Amz-Date")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Date", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Credential")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Credential", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Security-Token")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Security-Token", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Algorithm")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Algorithm", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-SignedHeaders", valid_593519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593521: Call_ListDevelopmentSchemaArns_593508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ## 
  let valid = call_593521.validator(path, query, header, formData, body)
  let scheme = call_593521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593521.url(scheme.get, call_593521.host, call_593521.base,
                         call_593521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593521, url, valid)

proc call*(call_593522: Call_ListDevelopmentSchemaArns_593508; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevelopmentSchemaArns
  ## Retrieves each Amazon Resource Name (ARN) of schemas in the development state.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593523 = newJObject()
  var body_593524 = newJObject()
  add(query_593523, "MaxResults", newJString(MaxResults))
  add(query_593523, "NextToken", newJString(NextToken))
  if body != nil:
    body_593524 = body
  result = call_593522.call(nil, query_593523, nil, nil, body_593524)

var listDevelopmentSchemaArns* = Call_ListDevelopmentSchemaArns_593508(
    name: "listDevelopmentSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/development",
    validator: validate_ListDevelopmentSchemaArns_593509, base: "/",
    url: url_ListDevelopmentSchemaArns_593510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDirectories_593525 = ref object of OpenApiRestCall_592364
proc url_ListDirectories_593527(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDirectories_593526(path: JsonNode; query: JsonNode;
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
  var valid_593528 = query.getOrDefault("MaxResults")
  valid_593528 = validateParameter(valid_593528, JString, required = false,
                                 default = nil)
  if valid_593528 != nil:
    section.add "MaxResults", valid_593528
  var valid_593529 = query.getOrDefault("NextToken")
  valid_593529 = validateParameter(valid_593529, JString, required = false,
                                 default = nil)
  if valid_593529 != nil:
    section.add "NextToken", valid_593529
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
  var valid_593530 = header.getOrDefault("X-Amz-Signature")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Signature", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Content-Sha256", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Date")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Date", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Credential")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Credential", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Security-Token")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Security-Token", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Algorithm")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Algorithm", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-SignedHeaders", valid_593536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593538: Call_ListDirectories_593525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists directories created within an account.
  ## 
  let valid = call_593538.validator(path, query, header, formData, body)
  let scheme = call_593538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593538.url(scheme.get, call_593538.host, call_593538.base,
                         call_593538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593538, url, valid)

proc call*(call_593539: Call_ListDirectories_593525; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDirectories
  ## Lists directories created within an account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593540 = newJObject()
  var body_593541 = newJObject()
  add(query_593540, "MaxResults", newJString(MaxResults))
  add(query_593540, "NextToken", newJString(NextToken))
  if body != nil:
    body_593541 = body
  result = call_593539.call(nil, query_593540, nil, nil, body_593541)

var listDirectories* = Call_ListDirectories_593525(name: "listDirectories",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/directory/list",
    validator: validate_ListDirectories_593526, base: "/", url: url_ListDirectories_593527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetAttributes_593542 = ref object of OpenApiRestCall_592364
proc url_ListFacetAttributes_593544(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFacetAttributes_593543(path: JsonNode; query: JsonNode;
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
  var valid_593545 = query.getOrDefault("MaxResults")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "MaxResults", valid_593545
  var valid_593546 = query.getOrDefault("NextToken")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "NextToken", valid_593546
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
  var valid_593547 = header.getOrDefault("X-Amz-Signature")
  valid_593547 = validateParameter(valid_593547, JString, required = false,
                                 default = nil)
  if valid_593547 != nil:
    section.add "X-Amz-Signature", valid_593547
  var valid_593548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Content-Sha256", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Date")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Date", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Credential")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Credential", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Security-Token")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Security-Token", valid_593551
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593552 = header.getOrDefault("x-amz-data-partition")
  valid_593552 = validateParameter(valid_593552, JString, required = true,
                                 default = nil)
  if valid_593552 != nil:
    section.add "x-amz-data-partition", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Algorithm")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Algorithm", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-SignedHeaders", valid_593554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593556: Call_ListFacetAttributes_593542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves attributes attached to the facet.
  ## 
  let valid = call_593556.validator(path, query, header, formData, body)
  let scheme = call_593556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593556.url(scheme.get, call_593556.host, call_593556.base,
                         call_593556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593556, url, valid)

proc call*(call_593557: Call_ListFacetAttributes_593542; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetAttributes
  ## Retrieves attributes attached to the facet.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593558 = newJObject()
  var body_593559 = newJObject()
  add(query_593558, "MaxResults", newJString(MaxResults))
  add(query_593558, "NextToken", newJString(NextToken))
  if body != nil:
    body_593559 = body
  result = call_593557.call(nil, query_593558, nil, nil, body_593559)

var listFacetAttributes* = Call_ListFacetAttributes_593542(
    name: "listFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/facet/attributes#x-amz-data-partition",
    validator: validate_ListFacetAttributes_593543, base: "/",
    url: url_ListFacetAttributes_593544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFacetNames_593560 = ref object of OpenApiRestCall_592364
proc url_ListFacetNames_593562(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFacetNames_593561(path: JsonNode; query: JsonNode;
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
  var valid_593563 = query.getOrDefault("MaxResults")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "MaxResults", valid_593563
  var valid_593564 = query.getOrDefault("NextToken")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "NextToken", valid_593564
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
  var valid_593565 = header.getOrDefault("X-Amz-Signature")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Signature", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Content-Sha256", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Date")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Date", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Credential")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Credential", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Security-Token")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Security-Token", valid_593569
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593570 = header.getOrDefault("x-amz-data-partition")
  valid_593570 = validateParameter(valid_593570, JString, required = true,
                                 default = nil)
  if valid_593570 != nil:
    section.add "x-amz-data-partition", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Algorithm")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Algorithm", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-SignedHeaders", valid_593572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593574: Call_ListFacetNames_593560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the names of facets that exist in a schema.
  ## 
  let valid = call_593574.validator(path, query, header, formData, body)
  let scheme = call_593574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593574.url(scheme.get, call_593574.host, call_593574.base,
                         call_593574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593574, url, valid)

proc call*(call_593575: Call_ListFacetNames_593560; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFacetNames
  ## Retrieves the names of facets that exist in a schema.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593576 = newJObject()
  var body_593577 = newJObject()
  add(query_593576, "MaxResults", newJString(MaxResults))
  add(query_593576, "NextToken", newJString(NextToken))
  if body != nil:
    body_593577 = body
  result = call_593575.call(nil, query_593576, nil, nil, body_593577)

var listFacetNames* = Call_ListFacetNames_593560(name: "listFacetNames",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/facet/list#x-amz-data-partition",
    validator: validate_ListFacetNames_593561, base: "/", url: url_ListFacetNames_593562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIncomingTypedLinks_593578 = ref object of OpenApiRestCall_592364
proc url_ListIncomingTypedLinks_593580(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIncomingTypedLinks_593579(path: JsonNode; query: JsonNode;
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
  var valid_593581 = header.getOrDefault("X-Amz-Signature")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Signature", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Content-Sha256", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Date")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Date", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Credential")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Credential", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Security-Token")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Security-Token", valid_593585
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593586 = header.getOrDefault("x-amz-data-partition")
  valid_593586 = validateParameter(valid_593586, JString, required = true,
                                 default = nil)
  if valid_593586 != nil:
    section.add "x-amz-data-partition", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-Algorithm")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Algorithm", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-SignedHeaders", valid_593588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593590: Call_ListIncomingTypedLinks_593578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593590.validator(path, query, header, formData, body)
  let scheme = call_593590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593590.url(scheme.get, call_593590.host, call_593590.base,
                         call_593590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593590, url, valid)

proc call*(call_593591: Call_ListIncomingTypedLinks_593578; body: JsonNode): Recallable =
  ## listIncomingTypedLinks
  ## Returns a paginated list of all the incoming <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593592 = newJObject()
  if body != nil:
    body_593592 = body
  result = call_593591.call(nil, nil, nil, nil, body_593592)

var listIncomingTypedLinks* = Call_ListIncomingTypedLinks_593578(
    name: "listIncomingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/incoming#x-amz-data-partition",
    validator: validate_ListIncomingTypedLinks_593579, base: "/",
    url: url_ListIncomingTypedLinks_593580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIndex_593593 = ref object of OpenApiRestCall_592364
proc url_ListIndex_593595(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIndex_593594(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593596 = query.getOrDefault("MaxResults")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "MaxResults", valid_593596
  var valid_593597 = query.getOrDefault("NextToken")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "NextToken", valid_593597
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
  var valid_593598 = header.getOrDefault("x-amz-consistency-level")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593598 != nil:
    section.add "x-amz-consistency-level", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Signature")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Signature", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Content-Sha256", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Date")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Date", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-Credential")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Credential", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Security-Token")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Security-Token", valid_593603
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593604 = header.getOrDefault("x-amz-data-partition")
  valid_593604 = validateParameter(valid_593604, JString, required = true,
                                 default = nil)
  if valid_593604 != nil:
    section.add "x-amz-data-partition", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Algorithm")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Algorithm", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-SignedHeaders", valid_593606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593608: Call_ListIndex_593593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists objects attached to the specified index.
  ## 
  let valid = call_593608.validator(path, query, header, formData, body)
  let scheme = call_593608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593608.url(scheme.get, call_593608.host, call_593608.base,
                         call_593608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593608, url, valid)

proc call*(call_593609: Call_ListIndex_593593; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listIndex
  ## Lists objects attached to the specified index.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593610 = newJObject()
  var body_593611 = newJObject()
  add(query_593610, "MaxResults", newJString(MaxResults))
  add(query_593610, "NextToken", newJString(NextToken))
  if body != nil:
    body_593611 = body
  result = call_593609.call(nil, query_593610, nil, nil, body_593611)

var listIndex* = Call_ListIndex_593593(name: "listIndex", meth: HttpMethod.HttpPost,
                                    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/index/targets#x-amz-data-partition",
                                    validator: validate_ListIndex_593594,
                                    base: "/", url: url_ListIndex_593595,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectAttributes_593612 = ref object of OpenApiRestCall_592364
proc url_ListObjectAttributes_593614(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectAttributes_593613(path: JsonNode; query: JsonNode;
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
  var valid_593615 = query.getOrDefault("MaxResults")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "MaxResults", valid_593615
  var valid_593616 = query.getOrDefault("NextToken")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "NextToken", valid_593616
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
  var valid_593617 = header.getOrDefault("x-amz-consistency-level")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593617 != nil:
    section.add "x-amz-consistency-level", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Signature")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Signature", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Content-Sha256", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Date")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Date", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-Credential")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Credential", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Security-Token")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Security-Token", valid_593622
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593623 = header.getOrDefault("x-amz-data-partition")
  valid_593623 = validateParameter(valid_593623, JString, required = true,
                                 default = nil)
  if valid_593623 != nil:
    section.add "x-amz-data-partition", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Algorithm")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Algorithm", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-SignedHeaders", valid_593625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593627: Call_ListObjectAttributes_593612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all attributes that are associated with an object. 
  ## 
  let valid = call_593627.validator(path, query, header, formData, body)
  let scheme = call_593627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593627.url(scheme.get, call_593627.host, call_593627.base,
                         call_593627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593627, url, valid)

proc call*(call_593628: Call_ListObjectAttributes_593612; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectAttributes
  ## Lists all attributes that are associated with an object. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593629 = newJObject()
  var body_593630 = newJObject()
  add(query_593629, "MaxResults", newJString(MaxResults))
  add(query_593629, "NextToken", newJString(NextToken))
  if body != nil:
    body_593630 = body
  result = call_593628.call(nil, query_593629, nil, nil, body_593630)

var listObjectAttributes* = Call_ListObjectAttributes_593612(
    name: "listObjectAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/attributes#x-amz-data-partition",
    validator: validate_ListObjectAttributes_593613, base: "/",
    url: url_ListObjectAttributes_593614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectChildren_593631 = ref object of OpenApiRestCall_592364
proc url_ListObjectChildren_593633(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectChildren_593632(path: JsonNode; query: JsonNode;
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
  var valid_593634 = query.getOrDefault("MaxResults")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "MaxResults", valid_593634
  var valid_593635 = query.getOrDefault("NextToken")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "NextToken", valid_593635
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
  var valid_593636 = header.getOrDefault("x-amz-consistency-level")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593636 != nil:
    section.add "x-amz-consistency-level", valid_593636
  var valid_593637 = header.getOrDefault("X-Amz-Signature")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Signature", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Content-Sha256", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Date")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Date", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Credential")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Credential", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Security-Token")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Security-Token", valid_593641
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593642 = header.getOrDefault("x-amz-data-partition")
  valid_593642 = validateParameter(valid_593642, JString, required = true,
                                 default = nil)
  if valid_593642 != nil:
    section.add "x-amz-data-partition", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Algorithm")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Algorithm", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-SignedHeaders", valid_593644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593646: Call_ListObjectChildren_593631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of child objects that are associated with a given object.
  ## 
  let valid = call_593646.validator(path, query, header, formData, body)
  let scheme = call_593646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593646.url(scheme.get, call_593646.host, call_593646.base,
                         call_593646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593646, url, valid)

proc call*(call_593647: Call_ListObjectChildren_593631; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectChildren
  ## Returns a paginated list of child objects that are associated with a given object.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593648 = newJObject()
  var body_593649 = newJObject()
  add(query_593648, "MaxResults", newJString(MaxResults))
  add(query_593648, "NextToken", newJString(NextToken))
  if body != nil:
    body_593649 = body
  result = call_593647.call(nil, query_593648, nil, nil, body_593649)

var listObjectChildren* = Call_ListObjectChildren_593631(
    name: "listObjectChildren", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/children#x-amz-data-partition",
    validator: validate_ListObjectChildren_593632, base: "/",
    url: url_ListObjectChildren_593633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParentPaths_593650 = ref object of OpenApiRestCall_592364
proc url_ListObjectParentPaths_593652(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectParentPaths_593651(path: JsonNode; query: JsonNode;
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
  var valid_593653 = query.getOrDefault("MaxResults")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "MaxResults", valid_593653
  var valid_593654 = query.getOrDefault("NextToken")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "NextToken", valid_593654
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
  var valid_593655 = header.getOrDefault("X-Amz-Signature")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-Signature", valid_593655
  var valid_593656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593656 = validateParameter(valid_593656, JString, required = false,
                                 default = nil)
  if valid_593656 != nil:
    section.add "X-Amz-Content-Sha256", valid_593656
  var valid_593657 = header.getOrDefault("X-Amz-Date")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Date", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Credential")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Credential", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Security-Token")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Security-Token", valid_593659
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593660 = header.getOrDefault("x-amz-data-partition")
  valid_593660 = validateParameter(valid_593660, JString, required = true,
                                 default = nil)
  if valid_593660 != nil:
    section.add "x-amz-data-partition", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Algorithm")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Algorithm", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-SignedHeaders", valid_593662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593664: Call_ListObjectParentPaths_593650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ## 
  let valid = call_593664.validator(path, query, header, formData, body)
  let scheme = call_593664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593664.url(scheme.get, call_593664.host, call_593664.base,
                         call_593664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593664, url, valid)

proc call*(call_593665: Call_ListObjectParentPaths_593650; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParentPaths
  ## <p>Retrieves all available parent paths for any object type such as node, leaf node, policy node, and index node objects. For more information about objects, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#dirstructure">Directory Structure</a>.</p> <p>Use this API to evaluate all parents for an object. The call returns all objects from the root of the directory up to the requested object. The API returns the number of paths based on user-defined <code>MaxResults</code>, in case there are multiple paths to the parent. The order of the paths and nodes returned is consistent among multiple API calls unless the objects are deleted or moved. Paths not leading to the directory root are ignored from the target object.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593666 = newJObject()
  var body_593667 = newJObject()
  add(query_593666, "MaxResults", newJString(MaxResults))
  add(query_593666, "NextToken", newJString(NextToken))
  if body != nil:
    body_593667 = body
  result = call_593665.call(nil, query_593666, nil, nil, body_593667)

var listObjectParentPaths* = Call_ListObjectParentPaths_593650(
    name: "listObjectParentPaths", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parentpaths#x-amz-data-partition",
    validator: validate_ListObjectParentPaths_593651, base: "/",
    url: url_ListObjectParentPaths_593652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectParents_593668 = ref object of OpenApiRestCall_592364
proc url_ListObjectParents_593670(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectParents_593669(path: JsonNode; query: JsonNode;
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
  var valid_593671 = query.getOrDefault("MaxResults")
  valid_593671 = validateParameter(valid_593671, JString, required = false,
                                 default = nil)
  if valid_593671 != nil:
    section.add "MaxResults", valid_593671
  var valid_593672 = query.getOrDefault("NextToken")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "NextToken", valid_593672
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
  var valid_593673 = header.getOrDefault("x-amz-consistency-level")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593673 != nil:
    section.add "x-amz-consistency-level", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Signature")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Signature", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Content-Sha256", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Date")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Date", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Credential")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Credential", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-Security-Token")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-Security-Token", valid_593678
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593679 = header.getOrDefault("x-amz-data-partition")
  valid_593679 = validateParameter(valid_593679, JString, required = true,
                                 default = nil)
  if valid_593679 != nil:
    section.add "x-amz-data-partition", valid_593679
  var valid_593680 = header.getOrDefault("X-Amz-Algorithm")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Algorithm", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-SignedHeaders", valid_593681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593683: Call_ListObjectParents_593668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ## 
  let valid = call_593683.validator(path, query, header, formData, body)
  let scheme = call_593683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593683.url(scheme.get, call_593683.host, call_593683.base,
                         call_593683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593683, url, valid)

proc call*(call_593684: Call_ListObjectParents_593668; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectParents
  ## Lists parent objects that are associated with a given object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593685 = newJObject()
  var body_593686 = newJObject()
  add(query_593685, "MaxResults", newJString(MaxResults))
  add(query_593685, "NextToken", newJString(NextToken))
  if body != nil:
    body_593686 = body
  result = call_593684.call(nil, query_593685, nil, nil, body_593686)

var listObjectParents* = Call_ListObjectParents_593668(name: "listObjectParents",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/parent#x-amz-data-partition",
    validator: validate_ListObjectParents_593669, base: "/",
    url: url_ListObjectParents_593670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListObjectPolicies_593687 = ref object of OpenApiRestCall_592364
proc url_ListObjectPolicies_593689(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListObjectPolicies_593688(path: JsonNode; query: JsonNode;
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
  var valid_593690 = query.getOrDefault("MaxResults")
  valid_593690 = validateParameter(valid_593690, JString, required = false,
                                 default = nil)
  if valid_593690 != nil:
    section.add "MaxResults", valid_593690
  var valid_593691 = query.getOrDefault("NextToken")
  valid_593691 = validateParameter(valid_593691, JString, required = false,
                                 default = nil)
  if valid_593691 != nil:
    section.add "NextToken", valid_593691
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
  var valid_593692 = header.getOrDefault("x-amz-consistency-level")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593692 != nil:
    section.add "x-amz-consistency-level", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Signature")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Signature", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Content-Sha256", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Date")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Date", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Credential")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Credential", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Security-Token")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Security-Token", valid_593697
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593698 = header.getOrDefault("x-amz-data-partition")
  valid_593698 = validateParameter(valid_593698, JString, required = true,
                                 default = nil)
  if valid_593698 != nil:
    section.add "x-amz-data-partition", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Algorithm")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Algorithm", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-SignedHeaders", valid_593700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593702: Call_ListObjectPolicies_593687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns policies attached to an object in pagination fashion.
  ## 
  let valid = call_593702.validator(path, query, header, formData, body)
  let scheme = call_593702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593702.url(scheme.get, call_593702.host, call_593702.base,
                         call_593702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593702, url, valid)

proc call*(call_593703: Call_ListObjectPolicies_593687; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listObjectPolicies
  ## Returns policies attached to an object in pagination fashion.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593704 = newJObject()
  var body_593705 = newJObject()
  add(query_593704, "MaxResults", newJString(MaxResults))
  add(query_593704, "NextToken", newJString(NextToken))
  if body != nil:
    body_593705 = body
  result = call_593703.call(nil, query_593704, nil, nil, body_593705)

var listObjectPolicies* = Call_ListObjectPolicies_593687(
    name: "listObjectPolicies", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/policy#x-amz-data-partition",
    validator: validate_ListObjectPolicies_593688, base: "/",
    url: url_ListObjectPolicies_593689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutgoingTypedLinks_593706 = ref object of OpenApiRestCall_592364
proc url_ListOutgoingTypedLinks_593708(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOutgoingTypedLinks_593707(path: JsonNode; query: JsonNode;
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
  var valid_593709 = header.getOrDefault("X-Amz-Signature")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Signature", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Content-Sha256", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Date")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Date", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Credential")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Credential", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-Security-Token")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-Security-Token", valid_593713
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593714 = header.getOrDefault("x-amz-data-partition")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = nil)
  if valid_593714 != nil:
    section.add "x-amz-data-partition", valid_593714
  var valid_593715 = header.getOrDefault("X-Amz-Algorithm")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Algorithm", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-SignedHeaders", valid_593716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593718: Call_ListOutgoingTypedLinks_593706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593718.validator(path, query, header, formData, body)
  let scheme = call_593718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593718.url(scheme.get, call_593718.host, call_593718.base,
                         call_593718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593718, url, valid)

proc call*(call_593719: Call_ListOutgoingTypedLinks_593706; body: JsonNode): Recallable =
  ## listOutgoingTypedLinks
  ## Returns a paginated list of all the outgoing <a>TypedLinkSpecifier</a> information for an object. It also supports filtering by typed link facet and identity attributes. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593720 = newJObject()
  if body != nil:
    body_593720 = body
  result = call_593719.call(nil, nil, nil, nil, body_593720)

var listOutgoingTypedLinks* = Call_ListOutgoingTypedLinks_593706(
    name: "listOutgoingTypedLinks", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/outgoing#x-amz-data-partition",
    validator: validate_ListOutgoingTypedLinks_593707, base: "/",
    url: url_ListOutgoingTypedLinks_593708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPolicyAttachments_593721 = ref object of OpenApiRestCall_592364
proc url_ListPolicyAttachments_593723(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPolicyAttachments_593722(path: JsonNode; query: JsonNode;
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
  var valid_593724 = query.getOrDefault("MaxResults")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "MaxResults", valid_593724
  var valid_593725 = query.getOrDefault("NextToken")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "NextToken", valid_593725
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
  var valid_593726 = header.getOrDefault("x-amz-consistency-level")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = newJString("SERIALIZABLE"))
  if valid_593726 != nil:
    section.add "x-amz-consistency-level", valid_593726
  var valid_593727 = header.getOrDefault("X-Amz-Signature")
  valid_593727 = validateParameter(valid_593727, JString, required = false,
                                 default = nil)
  if valid_593727 != nil:
    section.add "X-Amz-Signature", valid_593727
  var valid_593728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593728 = validateParameter(valid_593728, JString, required = false,
                                 default = nil)
  if valid_593728 != nil:
    section.add "X-Amz-Content-Sha256", valid_593728
  var valid_593729 = header.getOrDefault("X-Amz-Date")
  valid_593729 = validateParameter(valid_593729, JString, required = false,
                                 default = nil)
  if valid_593729 != nil:
    section.add "X-Amz-Date", valid_593729
  var valid_593730 = header.getOrDefault("X-Amz-Credential")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Credential", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Security-Token")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Security-Token", valid_593731
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593732 = header.getOrDefault("x-amz-data-partition")
  valid_593732 = validateParameter(valid_593732, JString, required = true,
                                 default = nil)
  if valid_593732 != nil:
    section.add "x-amz-data-partition", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Algorithm")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Algorithm", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-SignedHeaders", valid_593734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593736: Call_ListPolicyAttachments_593721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ## 
  let valid = call_593736.validator(path, query, header, formData, body)
  let scheme = call_593736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593736.url(scheme.get, call_593736.host, call_593736.base,
                         call_593736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593736, url, valid)

proc call*(call_593737: Call_ListPolicyAttachments_593721; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPolicyAttachments
  ## Returns all of the <code>ObjectIdentifiers</code> to which a given policy is attached.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593738 = newJObject()
  var body_593739 = newJObject()
  add(query_593738, "MaxResults", newJString(MaxResults))
  add(query_593738, "NextToken", newJString(NextToken))
  if body != nil:
    body_593739 = body
  result = call_593737.call(nil, query_593738, nil, nil, body_593739)

var listPolicyAttachments* = Call_ListPolicyAttachments_593721(
    name: "listPolicyAttachments", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/attachment#x-amz-data-partition",
    validator: validate_ListPolicyAttachments_593722, base: "/",
    url: url_ListPolicyAttachments_593723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishedSchemaArns_593740 = ref object of OpenApiRestCall_592364
proc url_ListPublishedSchemaArns_593742(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPublishedSchemaArns_593741(path: JsonNode; query: JsonNode;
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
  var valid_593743 = query.getOrDefault("MaxResults")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "MaxResults", valid_593743
  var valid_593744 = query.getOrDefault("NextToken")
  valid_593744 = validateParameter(valid_593744, JString, required = false,
                                 default = nil)
  if valid_593744 != nil:
    section.add "NextToken", valid_593744
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
  var valid_593745 = header.getOrDefault("X-Amz-Signature")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "X-Amz-Signature", valid_593745
  var valid_593746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "X-Amz-Content-Sha256", valid_593746
  var valid_593747 = header.getOrDefault("X-Amz-Date")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "X-Amz-Date", valid_593747
  var valid_593748 = header.getOrDefault("X-Amz-Credential")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "X-Amz-Credential", valid_593748
  var valid_593749 = header.getOrDefault("X-Amz-Security-Token")
  valid_593749 = validateParameter(valid_593749, JString, required = false,
                                 default = nil)
  if valid_593749 != nil:
    section.add "X-Amz-Security-Token", valid_593749
  var valid_593750 = header.getOrDefault("X-Amz-Algorithm")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "X-Amz-Algorithm", valid_593750
  var valid_593751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593751 = validateParameter(valid_593751, JString, required = false,
                                 default = nil)
  if valid_593751 != nil:
    section.add "X-Amz-SignedHeaders", valid_593751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593753: Call_ListPublishedSchemaArns_593740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ## 
  let valid = call_593753.validator(path, query, header, formData, body)
  let scheme = call_593753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593753.url(scheme.get, call_593753.host, call_593753.base,
                         call_593753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593753, url, valid)

proc call*(call_593754: Call_ListPublishedSchemaArns_593740; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishedSchemaArns
  ## Lists the major version families of each published schema. If a major version ARN is provided as <code>SchemaArn</code>, the minor version revisions in that family are listed instead.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593755 = newJObject()
  var body_593756 = newJObject()
  add(query_593755, "MaxResults", newJString(MaxResults))
  add(query_593755, "NextToken", newJString(NextToken))
  if body != nil:
    body_593756 = body
  result = call_593754.call(nil, query_593755, nil, nil, body_593756)

var listPublishedSchemaArns* = Call_ListPublishedSchemaArns_593740(
    name: "listPublishedSchemaArns", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/published",
    validator: validate_ListPublishedSchemaArns_593741, base: "/",
    url: url_ListPublishedSchemaArns_593742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593757 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593759(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_593758(path: JsonNode; query: JsonNode;
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
  var valid_593760 = query.getOrDefault("MaxResults")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "MaxResults", valid_593760
  var valid_593761 = query.getOrDefault("NextToken")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "NextToken", valid_593761
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
  var valid_593762 = header.getOrDefault("X-Amz-Signature")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Signature", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Content-Sha256", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Date")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Date", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-Credential")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-Credential", valid_593765
  var valid_593766 = header.getOrDefault("X-Amz-Security-Token")
  valid_593766 = validateParameter(valid_593766, JString, required = false,
                                 default = nil)
  if valid_593766 != nil:
    section.add "X-Amz-Security-Token", valid_593766
  var valid_593767 = header.getOrDefault("X-Amz-Algorithm")
  valid_593767 = validateParameter(valid_593767, JString, required = false,
                                 default = nil)
  if valid_593767 != nil:
    section.add "X-Amz-Algorithm", valid_593767
  var valid_593768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593768 = validateParameter(valid_593768, JString, required = false,
                                 default = nil)
  if valid_593768 != nil:
    section.add "X-Amz-SignedHeaders", valid_593768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593770: Call_ListTagsForResource_593757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ## 
  let valid = call_593770.validator(path, query, header, formData, body)
  let scheme = call_593770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593770.url(scheme.get, call_593770.host, call_593770.base,
                         call_593770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593770, url, valid)

proc call*(call_593771: Call_ListTagsForResource_593757; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns tags for a resource. Tagging is currently supported only for directories with a limit of 50 tags per directory. All 50 tags are returned for a given directory with this API call.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593772 = newJObject()
  var body_593773 = newJObject()
  add(query_593772, "MaxResults", newJString(MaxResults))
  add(query_593772, "NextToken", newJString(NextToken))
  if body != nil:
    body_593773 = body
  result = call_593771.call(nil, query_593772, nil, nil, body_593773)

var listTagsForResource* = Call_ListTagsForResource_593757(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags",
    validator: validate_ListTagsForResource_593758, base: "/",
    url: url_ListTagsForResource_593759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetAttributes_593774 = ref object of OpenApiRestCall_592364
proc url_ListTypedLinkFacetAttributes_593776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTypedLinkFacetAttributes_593775(path: JsonNode; query: JsonNode;
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
  var valid_593777 = query.getOrDefault("MaxResults")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "MaxResults", valid_593777
  var valid_593778 = query.getOrDefault("NextToken")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "NextToken", valid_593778
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
  var valid_593779 = header.getOrDefault("X-Amz-Signature")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "X-Amz-Signature", valid_593779
  var valid_593780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-Content-Sha256", valid_593780
  var valid_593781 = header.getOrDefault("X-Amz-Date")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "X-Amz-Date", valid_593781
  var valid_593782 = header.getOrDefault("X-Amz-Credential")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "X-Amz-Credential", valid_593782
  var valid_593783 = header.getOrDefault("X-Amz-Security-Token")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "X-Amz-Security-Token", valid_593783
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593784 = header.getOrDefault("x-amz-data-partition")
  valid_593784 = validateParameter(valid_593784, JString, required = true,
                                 default = nil)
  if valid_593784 != nil:
    section.add "x-amz-data-partition", valid_593784
  var valid_593785 = header.getOrDefault("X-Amz-Algorithm")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "X-Amz-Algorithm", valid_593785
  var valid_593786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "X-Amz-SignedHeaders", valid_593786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593788: Call_ListTypedLinkFacetAttributes_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593788.validator(path, query, header, formData, body)
  let scheme = call_593788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593788.url(scheme.get, call_593788.host, call_593788.base,
                         call_593788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593788, url, valid)

proc call*(call_593789: Call_ListTypedLinkFacetAttributes_593774; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetAttributes
  ## Returns a paginated list of all attribute definitions for a particular <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593790 = newJObject()
  var body_593791 = newJObject()
  add(query_593790, "MaxResults", newJString(MaxResults))
  add(query_593790, "NextToken", newJString(NextToken))
  if body != nil:
    body_593791 = body
  result = call_593789.call(nil, query_593790, nil, nil, body_593791)

var listTypedLinkFacetAttributes* = Call_ListTypedLinkFacetAttributes_593774(
    name: "listTypedLinkFacetAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/attributes#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetAttributes_593775, base: "/",
    url: url_ListTypedLinkFacetAttributes_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTypedLinkFacetNames_593792 = ref object of OpenApiRestCall_592364
proc url_ListTypedLinkFacetNames_593794(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTypedLinkFacetNames_593793(path: JsonNode; query: JsonNode;
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
  var valid_593795 = query.getOrDefault("MaxResults")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "MaxResults", valid_593795
  var valid_593796 = query.getOrDefault("NextToken")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "NextToken", valid_593796
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
  var valid_593797 = header.getOrDefault("X-Amz-Signature")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Signature", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Content-Sha256", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Date")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Date", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Credential")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Credential", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-Security-Token")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-Security-Token", valid_593801
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593802 = header.getOrDefault("x-amz-data-partition")
  valid_593802 = validateParameter(valid_593802, JString, required = true,
                                 default = nil)
  if valid_593802 != nil:
    section.add "x-amz-data-partition", valid_593802
  var valid_593803 = header.getOrDefault("X-Amz-Algorithm")
  valid_593803 = validateParameter(valid_593803, JString, required = false,
                                 default = nil)
  if valid_593803 != nil:
    section.add "X-Amz-Algorithm", valid_593803
  var valid_593804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-SignedHeaders", valid_593804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593806: Call_ListTypedLinkFacetNames_593792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593806.validator(path, query, header, formData, body)
  let scheme = call_593806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593806.url(scheme.get, call_593806.host, call_593806.base,
                         call_593806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593806, url, valid)

proc call*(call_593807: Call_ListTypedLinkFacetNames_593792; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTypedLinkFacetNames
  ## Returns a paginated list of <code>TypedLink</code> facet names for a particular schema. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593808 = newJObject()
  var body_593809 = newJObject()
  add(query_593808, "MaxResults", newJString(MaxResults))
  add(query_593808, "NextToken", newJString(NextToken))
  if body != nil:
    body_593809 = body
  result = call_593807.call(nil, query_593808, nil, nil, body_593809)

var listTypedLinkFacetNames* = Call_ListTypedLinkFacetNames_593792(
    name: "listTypedLinkFacetNames", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet/list#x-amz-data-partition",
    validator: validate_ListTypedLinkFacetNames_593793, base: "/",
    url: url_ListTypedLinkFacetNames_593794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupPolicy_593810 = ref object of OpenApiRestCall_592364
proc url_LookupPolicy_593812(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LookupPolicy_593811(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593813 = query.getOrDefault("MaxResults")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "MaxResults", valid_593813
  var valid_593814 = query.getOrDefault("NextToken")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "NextToken", valid_593814
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
  var valid_593815 = header.getOrDefault("X-Amz-Signature")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Signature", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-Content-Sha256", valid_593816
  var valid_593817 = header.getOrDefault("X-Amz-Date")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "X-Amz-Date", valid_593817
  var valid_593818 = header.getOrDefault("X-Amz-Credential")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "X-Amz-Credential", valid_593818
  var valid_593819 = header.getOrDefault("X-Amz-Security-Token")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Security-Token", valid_593819
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593820 = header.getOrDefault("x-amz-data-partition")
  valid_593820 = validateParameter(valid_593820, JString, required = true,
                                 default = nil)
  if valid_593820 != nil:
    section.add "x-amz-data-partition", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Algorithm")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Algorithm", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-SignedHeaders", valid_593822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593824: Call_LookupPolicy_593810; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ## 
  let valid = call_593824.validator(path, query, header, formData, body)
  let scheme = call_593824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593824.url(scheme.get, call_593824.host, call_593824.base,
                         call_593824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593824, url, valid)

proc call*(call_593825: Call_LookupPolicy_593810; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupPolicy
  ## Lists all policies from the root of the <a>Directory</a> to the object specified. If there are no policies present, an empty list is returned. If policies are present, and if some objects don't have the policies attached, it returns the <code>ObjectIdentifier</code> for such objects. If policies are present, it returns <code>ObjectIdentifier</code>, <code>policyId</code>, and <code>policyType</code>. Paths that don't lead to the root from the target object are ignored. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/cd_key_concepts.html#policies">Policies</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_593826 = newJObject()
  var body_593827 = newJObject()
  add(query_593826, "MaxResults", newJString(MaxResults))
  add(query_593826, "NextToken", newJString(NextToken))
  if body != nil:
    body_593827 = body
  result = call_593825.call(nil, query_593826, nil, nil, body_593827)

var lookupPolicy* = Call_LookupPolicy_593810(name: "lookupPolicy",
    meth: HttpMethod.HttpPost, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/policy/lookup#x-amz-data-partition",
    validator: validate_LookupPolicy_593811, base: "/", url: url_LookupPolicy_593812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishSchema_593828 = ref object of OpenApiRestCall_592364
proc url_PublishSchema_593830(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PublishSchema_593829(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593831 = header.getOrDefault("X-Amz-Signature")
  valid_593831 = validateParameter(valid_593831, JString, required = false,
                                 default = nil)
  if valid_593831 != nil:
    section.add "X-Amz-Signature", valid_593831
  var valid_593832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "X-Amz-Content-Sha256", valid_593832
  var valid_593833 = header.getOrDefault("X-Amz-Date")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-Date", valid_593833
  var valid_593834 = header.getOrDefault("X-Amz-Credential")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Credential", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Security-Token")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Security-Token", valid_593835
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593836 = header.getOrDefault("x-amz-data-partition")
  valid_593836 = validateParameter(valid_593836, JString, required = true,
                                 default = nil)
  if valid_593836 != nil:
    section.add "x-amz-data-partition", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Algorithm")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Algorithm", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-SignedHeaders", valid_593838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593840: Call_PublishSchema_593828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Publishes a development schema with a major version and a recommended minor version.
  ## 
  let valid = call_593840.validator(path, query, header, formData, body)
  let scheme = call_593840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593840.url(scheme.get, call_593840.host, call_593840.base,
                         call_593840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593840, url, valid)

proc call*(call_593841: Call_PublishSchema_593828; body: JsonNode): Recallable =
  ## publishSchema
  ## Publishes a development schema with a major version and a recommended minor version.
  ##   body: JObject (required)
  var body_593842 = newJObject()
  if body != nil:
    body_593842 = body
  result = call_593841.call(nil, nil, nil, nil, body_593842)

var publishSchema* = Call_PublishSchema_593828(name: "publishSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/publish#x-amz-data-partition",
    validator: validate_PublishSchema_593829, base: "/", url: url_PublishSchema_593830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFacetFromObject_593843 = ref object of OpenApiRestCall_592364
proc url_RemoveFacetFromObject_593845(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveFacetFromObject_593844(path: JsonNode; query: JsonNode;
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
  var valid_593846 = header.getOrDefault("X-Amz-Signature")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Signature", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Content-Sha256", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Date")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Date", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Credential")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Credential", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Security-Token")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Security-Token", valid_593850
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593851 = header.getOrDefault("x-amz-data-partition")
  valid_593851 = validateParameter(valid_593851, JString, required = true,
                                 default = nil)
  if valid_593851 != nil:
    section.add "x-amz-data-partition", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Algorithm")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Algorithm", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-SignedHeaders", valid_593853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593855: Call_RemoveFacetFromObject_593843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified facet from the specified object.
  ## 
  let valid = call_593855.validator(path, query, header, formData, body)
  let scheme = call_593855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593855.url(scheme.get, call_593855.host, call_593855.base,
                         call_593855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593855, url, valid)

proc call*(call_593856: Call_RemoveFacetFromObject_593843; body: JsonNode): Recallable =
  ## removeFacetFromObject
  ## Removes the specified facet from the specified object.
  ##   body: JObject (required)
  var body_593857 = newJObject()
  if body != nil:
    body_593857 = body
  result = call_593856.call(nil, nil, nil, nil, body_593857)

var removeFacetFromObject* = Call_RemoveFacetFromObject_593843(
    name: "removeFacetFromObject", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/facets/delete#x-amz-data-partition",
    validator: validate_RemoveFacetFromObject_593844, base: "/",
    url: url_RemoveFacetFromObject_593845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593858 = ref object of OpenApiRestCall_592364
proc url_TagResource_593860(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_593859(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593861 = header.getOrDefault("X-Amz-Signature")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Signature", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Content-Sha256", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Date")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Date", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Credential")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Credential", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-Security-Token")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-Security-Token", valid_593865
  var valid_593866 = header.getOrDefault("X-Amz-Algorithm")
  valid_593866 = validateParameter(valid_593866, JString, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "X-Amz-Algorithm", valid_593866
  var valid_593867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593867 = validateParameter(valid_593867, JString, required = false,
                                 default = nil)
  if valid_593867 != nil:
    section.add "X-Amz-SignedHeaders", valid_593867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593869: Call_TagResource_593858; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for adding tags to a resource.
  ## 
  let valid = call_593869.validator(path, query, header, formData, body)
  let scheme = call_593869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593869.url(scheme.get, call_593869.host, call_593869.base,
                         call_593869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593869, url, valid)

proc call*(call_593870: Call_TagResource_593858; body: JsonNode): Recallable =
  ## tagResource
  ## An API operation for adding tags to a resource.
  ##   body: JObject (required)
  var body_593871 = newJObject()
  if body != nil:
    body_593871 = body
  result = call_593870.call(nil, nil, nil, nil, body_593871)

var tagResource* = Call_TagResource_593858(name: "tagResource",
                                        meth: HttpMethod.HttpPut,
                                        host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/tags/add",
                                        validator: validate_TagResource_593859,
                                        base: "/", url: url_TagResource_593860,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593872 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593874(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_593873(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593875 = header.getOrDefault("X-Amz-Signature")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Signature", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Content-Sha256", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-Date")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Date", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Credential")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Credential", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Security-Token")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Security-Token", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-Algorithm")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-Algorithm", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-SignedHeaders", valid_593881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593883: Call_UntagResource_593872; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An API operation for removing tags from a resource.
  ## 
  let valid = call_593883.validator(path, query, header, formData, body)
  let scheme = call_593883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593883.url(scheme.get, call_593883.host, call_593883.base,
                         call_593883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593883, url, valid)

proc call*(call_593884: Call_UntagResource_593872; body: JsonNode): Recallable =
  ## untagResource
  ## An API operation for removing tags from a resource.
  ##   body: JObject (required)
  var body_593885 = newJObject()
  if body != nil:
    body_593885 = body
  result = call_593884.call(nil, nil, nil, nil, body_593885)

var untagResource* = Call_UntagResource_593872(name: "untagResource",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/tags/remove",
    validator: validate_UntagResource_593873, base: "/", url: url_UntagResource_593874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLinkAttributes_593886 = ref object of OpenApiRestCall_592364
proc url_UpdateLinkAttributes_593888(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateLinkAttributes_593887(path: JsonNode; query: JsonNode;
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
  var valid_593889 = header.getOrDefault("X-Amz-Signature")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Signature", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Content-Sha256", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Date")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Date", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Credential")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Credential", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Security-Token")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Security-Token", valid_593893
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593894 = header.getOrDefault("x-amz-data-partition")
  valid_593894 = validateParameter(valid_593894, JString, required = true,
                                 default = nil)
  if valid_593894 != nil:
    section.add "x-amz-data-partition", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Algorithm")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Algorithm", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-SignedHeaders", valid_593896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593898: Call_UpdateLinkAttributes_593886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ## 
  let valid = call_593898.validator(path, query, header, formData, body)
  let scheme = call_593898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593898.url(scheme.get, call_593898.host, call_593898.base,
                         call_593898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593898, url, valid)

proc call*(call_593899: Call_UpdateLinkAttributes_593886; body: JsonNode): Recallable =
  ## updateLinkAttributes
  ## Updates a given typed link’s attributes. Attributes to be updated must not contribute to the typed link’s identity, as defined by its <code>IdentityAttributeOrder</code>.
  ##   body: JObject (required)
  var body_593900 = newJObject()
  if body != nil:
    body_593900 = body
  result = call_593899.call(nil, nil, nil, nil, body_593900)

var updateLinkAttributes* = Call_UpdateLinkAttributes_593886(
    name: "updateLinkAttributes", meth: HttpMethod.HttpPost,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/attributes/update#x-amz-data-partition",
    validator: validate_UpdateLinkAttributes_593887, base: "/",
    url: url_UpdateLinkAttributes_593888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateObjectAttributes_593901 = ref object of OpenApiRestCall_592364
proc url_UpdateObjectAttributes_593903(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateObjectAttributes_593902(path: JsonNode; query: JsonNode;
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
  var valid_593904 = header.getOrDefault("X-Amz-Signature")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Signature", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Date")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Date", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Credential")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Credential", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Security-Token")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Security-Token", valid_593908
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593909 = header.getOrDefault("x-amz-data-partition")
  valid_593909 = validateParameter(valid_593909, JString, required = true,
                                 default = nil)
  if valid_593909 != nil:
    section.add "x-amz-data-partition", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Algorithm")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Algorithm", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-SignedHeaders", valid_593911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593913: Call_UpdateObjectAttributes_593901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a given object's attributes.
  ## 
  let valid = call_593913.validator(path, query, header, formData, body)
  let scheme = call_593913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593913.url(scheme.get, call_593913.host, call_593913.base,
                         call_593913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593913, url, valid)

proc call*(call_593914: Call_UpdateObjectAttributes_593901; body: JsonNode): Recallable =
  ## updateObjectAttributes
  ## Updates a given object's attributes.
  ##   body: JObject (required)
  var body_593915 = newJObject()
  if body != nil:
    body_593915 = body
  result = call_593914.call(nil, nil, nil, nil, body_593915)

var updateObjectAttributes* = Call_UpdateObjectAttributes_593901(
    name: "updateObjectAttributes", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/object/update#x-amz-data-partition",
    validator: validate_UpdateObjectAttributes_593902, base: "/",
    url: url_UpdateObjectAttributes_593903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSchema_593916 = ref object of OpenApiRestCall_592364
proc url_UpdateSchema_593918(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSchema_593917(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593919 = header.getOrDefault("X-Amz-Signature")
  valid_593919 = validateParameter(valid_593919, JString, required = false,
                                 default = nil)
  if valid_593919 != nil:
    section.add "X-Amz-Signature", valid_593919
  var valid_593920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593920 = validateParameter(valid_593920, JString, required = false,
                                 default = nil)
  if valid_593920 != nil:
    section.add "X-Amz-Content-Sha256", valid_593920
  var valid_593921 = header.getOrDefault("X-Amz-Date")
  valid_593921 = validateParameter(valid_593921, JString, required = false,
                                 default = nil)
  if valid_593921 != nil:
    section.add "X-Amz-Date", valid_593921
  var valid_593922 = header.getOrDefault("X-Amz-Credential")
  valid_593922 = validateParameter(valid_593922, JString, required = false,
                                 default = nil)
  if valid_593922 != nil:
    section.add "X-Amz-Credential", valid_593922
  var valid_593923 = header.getOrDefault("X-Amz-Security-Token")
  valid_593923 = validateParameter(valid_593923, JString, required = false,
                                 default = nil)
  if valid_593923 != nil:
    section.add "X-Amz-Security-Token", valid_593923
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593924 = header.getOrDefault("x-amz-data-partition")
  valid_593924 = validateParameter(valid_593924, JString, required = true,
                                 default = nil)
  if valid_593924 != nil:
    section.add "x-amz-data-partition", valid_593924
  var valid_593925 = header.getOrDefault("X-Amz-Algorithm")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Algorithm", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-SignedHeaders", valid_593926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593928: Call_UpdateSchema_593916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ## 
  let valid = call_593928.validator(path, query, header, formData, body)
  let scheme = call_593928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593928.url(scheme.get, call_593928.host, call_593928.base,
                         call_593928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593928, url, valid)

proc call*(call_593929: Call_UpdateSchema_593916; body: JsonNode): Recallable =
  ## updateSchema
  ## Updates the schema name with a new name. Only development schema names can be updated.
  ##   body: JObject (required)
  var body_593930 = newJObject()
  if body != nil:
    body_593930 = body
  result = call_593929.call(nil, nil, nil, nil, body_593930)

var updateSchema* = Call_UpdateSchema_593916(name: "updateSchema",
    meth: HttpMethod.HttpPut, host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/schema/update#x-amz-data-partition",
    validator: validate_UpdateSchema_593917, base: "/", url: url_UpdateSchema_593918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTypedLinkFacet_593931 = ref object of OpenApiRestCall_592364
proc url_UpdateTypedLinkFacet_593933(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTypedLinkFacet_593932(path: JsonNode; query: JsonNode;
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
  var valid_593934 = header.getOrDefault("X-Amz-Signature")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Signature", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-Content-Sha256", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Date")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Date", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Credential")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Credential", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Security-Token")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Security-Token", valid_593938
  assert header != nil, "header argument is necessary due to required `x-amz-data-partition` field"
  var valid_593939 = header.getOrDefault("x-amz-data-partition")
  valid_593939 = validateParameter(valid_593939, JString, required = true,
                                 default = nil)
  if valid_593939 != nil:
    section.add "x-amz-data-partition", valid_593939
  var valid_593940 = header.getOrDefault("X-Amz-Algorithm")
  valid_593940 = validateParameter(valid_593940, JString, required = false,
                                 default = nil)
  if valid_593940 != nil:
    section.add "X-Amz-Algorithm", valid_593940
  var valid_593941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593941 = validateParameter(valid_593941, JString, required = false,
                                 default = nil)
  if valid_593941 != nil:
    section.add "X-Amz-SignedHeaders", valid_593941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593943: Call_UpdateTypedLinkFacet_593931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ## 
  let valid = call_593943.validator(path, query, header, formData, body)
  let scheme = call_593943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593943.url(scheme.get, call_593943.host, call_593943.base,
                         call_593943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593943, url, valid)

proc call*(call_593944: Call_UpdateTypedLinkFacet_593931; body: JsonNode): Recallable =
  ## updateTypedLinkFacet
  ## Updates a <a>TypedLinkFacet</a>. For more information, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/objectsandlinks.html#typedlink">Typed link</a>.
  ##   body: JObject (required)
  var body_593945 = newJObject()
  if body != nil:
    body_593945 = body
  result = call_593944.call(nil, nil, nil, nil, body_593945)

var updateTypedLinkFacet* = Call_UpdateTypedLinkFacet_593931(
    name: "updateTypedLinkFacet", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com", route: "/amazonclouddirectory/2017-01-11/typedlink/facet#x-amz-data-partition",
    validator: validate_UpdateTypedLinkFacet_593932, base: "/",
    url: url_UpdateTypedLinkFacet_593933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeAppliedSchema_593946 = ref object of OpenApiRestCall_592364
proc url_UpgradeAppliedSchema_593948(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpgradeAppliedSchema_593947(path: JsonNode; query: JsonNode;
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
  var valid_593949 = header.getOrDefault("X-Amz-Signature")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "X-Amz-Signature", valid_593949
  var valid_593950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "X-Amz-Content-Sha256", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Date")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Date", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Credential")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Credential", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Security-Token")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Security-Token", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-Algorithm")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-Algorithm", valid_593954
  var valid_593955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "X-Amz-SignedHeaders", valid_593955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593957: Call_UpgradeAppliedSchema_593946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ## 
  let valid = call_593957.validator(path, query, header, formData, body)
  let scheme = call_593957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593957.url(scheme.get, call_593957.host, call_593957.base,
                         call_593957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593957, url, valid)

proc call*(call_593958: Call_UpgradeAppliedSchema_593946; body: JsonNode): Recallable =
  ## upgradeAppliedSchema
  ## Upgrades a single directory in-place using the <code>PublishedSchemaArn</code> with schema updates found in <code>MinorVersion</code>. Backwards-compatible minor version upgrades are instantaneously available for readers on all objects in the directory. Note: This is a synchronous API call and upgrades only one schema on a given directory per call. To upgrade multiple directories from one schema, you would need to call this API on each directory.
  ##   body: JObject (required)
  var body_593959 = newJObject()
  if body != nil:
    body_593959 = body
  result = call_593958.call(nil, nil, nil, nil, body_593959)

var upgradeAppliedSchema* = Call_UpgradeAppliedSchema_593946(
    name: "upgradeAppliedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradeapplied",
    validator: validate_UpgradeAppliedSchema_593947, base: "/",
    url: url_UpgradeAppliedSchema_593948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradePublishedSchema_593960 = ref object of OpenApiRestCall_592364
proc url_UpgradePublishedSchema_593962(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpgradePublishedSchema_593961(path: JsonNode; query: JsonNode;
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
  var valid_593963 = header.getOrDefault("X-Amz-Signature")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-Signature", valid_593963
  var valid_593964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-Content-Sha256", valid_593964
  var valid_593965 = header.getOrDefault("X-Amz-Date")
  valid_593965 = validateParameter(valid_593965, JString, required = false,
                                 default = nil)
  if valid_593965 != nil:
    section.add "X-Amz-Date", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Credential")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Credential", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-Security-Token")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-Security-Token", valid_593967
  var valid_593968 = header.getOrDefault("X-Amz-Algorithm")
  valid_593968 = validateParameter(valid_593968, JString, required = false,
                                 default = nil)
  if valid_593968 != nil:
    section.add "X-Amz-Algorithm", valid_593968
  var valid_593969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "X-Amz-SignedHeaders", valid_593969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593971: Call_UpgradePublishedSchema_593960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ## 
  let valid = call_593971.validator(path, query, header, formData, body)
  let scheme = call_593971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593971.url(scheme.get, call_593971.host, call_593971.base,
                         call_593971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593971, url, valid)

proc call*(call_593972: Call_UpgradePublishedSchema_593960; body: JsonNode): Recallable =
  ## upgradePublishedSchema
  ## Upgrades a published schema under a new minor version revision using the current contents of <code>DevelopmentSchemaArn</code>.
  ##   body: JObject (required)
  var body_593973 = newJObject()
  if body != nil:
    body_593973 = body
  result = call_593972.call(nil, nil, nil, nil, body_593973)

var upgradePublishedSchema* = Call_UpgradePublishedSchema_593960(
    name: "upgradePublishedSchema", meth: HttpMethod.HttpPut,
    host: "clouddirectory.amazonaws.com",
    route: "/amazonclouddirectory/2017-01-11/schema/upgradepublished",
    validator: validate_UpgradePublishedSchema_593961, base: "/",
    url: url_UpgradePublishedSchema_593962, schemes: {Scheme.Https, Scheme.Http})
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
