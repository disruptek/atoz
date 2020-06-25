
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Ground Station
## version: 2019-05-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Welcome to the AWS Ground Station API Reference. AWS Ground Station is a fully managed service that enables you to control satellite communications, downlink and process satellite data, and scale your satellite operations efficiently and cost-effectively without having to build or manage your own ground station infrastructure.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/groundstation/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com", "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com", "us-west-2": "groundstation.us-west-2.amazonaws.com", "eu-west-2": "groundstation.eu-west-2.amazonaws.com", "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com", "eu-central-1": "groundstation.eu-central-1.amazonaws.com", "us-east-2": "groundstation.us-east-2.amazonaws.com", "us-east-1": "groundstation.us-east-1.amazonaws.com", "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "groundstation.ap-south-1.amazonaws.com", "eu-north-1": "groundstation.eu-north-1.amazonaws.com", "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com", "us-west-1": "groundstation.us-west-1.amazonaws.com", "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com", "eu-west-3": "groundstation.eu-west-3.amazonaws.com", "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn", "sa-east-1": "groundstation.sa-east-1.amazonaws.com", "eu-west-1": "groundstation.eu-west-1.amazonaws.com", "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com", "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com", "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com",
      "us-west-2": "groundstation.us-west-2.amazonaws.com",
      "eu-west-2": "groundstation.eu-west-2.amazonaws.com",
      "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com",
      "eu-central-1": "groundstation.eu-central-1.amazonaws.com",
      "us-east-2": "groundstation.us-east-2.amazonaws.com",
      "us-east-1": "groundstation.us-east-1.amazonaws.com",
      "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "groundstation.ap-south-1.amazonaws.com",
      "eu-north-1": "groundstation.eu-north-1.amazonaws.com",
      "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com",
      "us-west-1": "groundstation.us-west-1.amazonaws.com",
      "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com",
      "eu-west-3": "groundstation.eu-west-3.amazonaws.com",
      "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "groundstation.sa-east-1.amazonaws.com",
      "eu-west-1": "groundstation.eu-west-1.amazonaws.com",
      "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com",
      "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "groundstation"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_DescribeContact_21625779 = ref object of OpenApiRestCall_21625435
proc url_DescribeContact_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
               (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeContact_21625780(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing contact.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
  ##            : UUID of a contact.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `contactId` field"
  var valid_21625895 = path.getOrDefault("contactId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "contactId", valid_21625895
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
  var valid_21625896 = header.getOrDefault("X-Amz-Date")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "X-Amz-Date", valid_21625896
  var valid_21625897 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Security-Token", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Algorithm", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Signature")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Signature", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Credential")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Credential", valid_21625902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625927: Call_DescribeContact_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing contact.
  ## 
  let valid = call_21625927.validator(path, query, header, formData, body, _)
  let scheme = call_21625927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625927.makeUrl(scheme.get, call_21625927.host, call_21625927.base,
                               call_21625927.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625927, uri, valid, _)

proc call*(call_21625990: Call_DescribeContact_21625779; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_21625992 = newJObject()
  add(path_21625992, "contactId", newJString(contactId))
  result = call_21625990.call(path_21625992, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_21625779(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_21625780,
    base: "/", makeUrl: url_DescribeContact_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_21626030 = ref object of OpenApiRestCall_21625435
proc url_CancelContact_21626032(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
               (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelContact_21626031(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Cancels a contact with a specified contact ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
  ##            : UUID of a contact.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `contactId` field"
  var valid_21626033 = path.getOrDefault("contactId")
  valid_21626033 = validateParameter(valid_21626033, JString, required = true,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "contactId", valid_21626033
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
  var valid_21626034 = header.getOrDefault("X-Amz-Date")
  valid_21626034 = validateParameter(valid_21626034, JString, required = false,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "X-Amz-Date", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Security-Token", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Algorithm", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Signature")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Signature", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Credential")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Credential", valid_21626040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_CancelContact_21626030; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels a contact with a specified contact ID.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_CancelContact_21626030; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
  ##            : UUID of a contact.
  var path_21626043 = newJObject()
  add(path_21626043, "contactId", newJString(contactId))
  result = call_21626042.call(path_21626043, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_21626030(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_21626031,
    base: "/", makeUrl: url_CancelContact_21626032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_21626060 = ref object of OpenApiRestCall_21625435
proc url_CreateConfig_21626062(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfig_21626061(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
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

proc call*(call_21626071: Call_CreateConfig_21626060; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CreateConfig_21626060; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var createConfig* = Call_CreateConfig_21626060(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_21626061, base: "/",
    makeUrl: url_CreateConfig_21626062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_21626044 = ref object of OpenApiRestCall_21625435
proc url_ListConfigs_21626046(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigs_21626045(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of <code>Config</code> objects.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of <code>Configs</code> returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_21626047 = query.getOrDefault("maxResults")
  valid_21626047 = validateParameter(valid_21626047, JInt, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "maxResults", valid_21626047
  var valid_21626048 = query.getOrDefault("nextToken")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "nextToken", valid_21626048
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
  var valid_21626049 = header.getOrDefault("X-Amz-Date")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Date", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Security-Token", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Algorithm", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Signature")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Signature", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Credential")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Credential", valid_21626055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_ListConfigs_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>Config</code> objects.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_ListConfigs_21626044; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   maxResults: int
  ##             : Maximum number of <code>Configs</code> returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListConfigs</code> call. Used to get the next page of results.
  var query_21626058 = newJObject()
  add(query_21626058, "maxResults", newJInt(maxResults))
  add(query_21626058, "nextToken", newJString(nextToken))
  result = call_21626057.call(nil, query_21626058, nil, nil, nil)

var listConfigs* = Call_ListConfigs_21626044(name: "listConfigs",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com", route: "/config",
    validator: validate_ListConfigs_21626045, base: "/", makeUrl: url_ListConfigs_21626046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_21626089 = ref object of OpenApiRestCall_21625435
proc url_CreateDataflowEndpointGroup_21626091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataflowEndpointGroup_21626090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Algorithm", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Signature")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Signature", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Credential")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Credential", valid_21626098
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

proc call*(call_21626100: Call_CreateDataflowEndpointGroup_21626089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ## 
  let valid = call_21626100.validator(path, query, header, formData, body, _)
  let scheme = call_21626100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626100.makeUrl(scheme.get, call_21626100.host, call_21626100.base,
                               call_21626100.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626100, uri, valid, _)

proc call*(call_21626101: Call_CreateDataflowEndpointGroup_21626089; body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   body: JObject (required)
  var body_21626102 = newJObject()
  if body != nil:
    body_21626102 = body
  result = call_21626101.call(nil, nil, nil, nil, body_21626102)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_21626089(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_21626090, base: "/",
    makeUrl: url_CreateDataflowEndpointGroup_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_21626074 = ref object of OpenApiRestCall_21625435
proc url_ListDataflowEndpointGroups_21626076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataflowEndpointGroups_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of dataflow endpoint groups returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_21626077 = query.getOrDefault("maxResults")
  valid_21626077 = validateParameter(valid_21626077, JInt, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "maxResults", valid_21626077
  var valid_21626078 = query.getOrDefault("nextToken")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "nextToken", valid_21626078
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
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Algorithm", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Signature")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Signature", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Credential")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Credential", valid_21626085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_ListDataflowEndpointGroups_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_ListDataflowEndpointGroups_21626074;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   maxResults: int
  ##             : Maximum number of dataflow endpoint groups returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListDataflowEndpointGroups</code> call. Used to get the next page of results.
  var query_21626088 = newJObject()
  add(query_21626088, "maxResults", newJInt(maxResults))
  add(query_21626088, "nextToken", newJString(nextToken))
  result = call_21626087.call(nil, query_21626088, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_21626074(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_21626075, base: "/",
    makeUrl: url_ListDataflowEndpointGroups_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_21626118 = ref object of OpenApiRestCall_21625435
proc url_CreateMissionProfile_21626120(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMissionProfile_21626119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
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
  var valid_21626121 = header.getOrDefault("X-Amz-Date")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Date", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Security-Token", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Algorithm", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Signature")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Signature", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Credential")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Credential", valid_21626127
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

proc call*(call_21626129: Call_CreateMissionProfile_21626118; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ## 
  let valid = call_21626129.validator(path, query, header, formData, body, _)
  let scheme = call_21626129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626129.makeUrl(scheme.get, call_21626129.host, call_21626129.base,
                               call_21626129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626129, uri, valid, _)

proc call*(call_21626130: Call_CreateMissionProfile_21626118; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ##   body: JObject (required)
  var body_21626131 = newJObject()
  if body != nil:
    body_21626131 = body
  result = call_21626130.call(nil, nil, nil, nil, body_21626131)

var createMissionProfile* = Call_CreateMissionProfile_21626118(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_21626119, base: "/",
    makeUrl: url_CreateMissionProfile_21626120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_21626103 = ref object of OpenApiRestCall_21625435
proc url_ListMissionProfiles_21626105(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMissionProfiles_21626104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of mission profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of mission profiles returned.
  ##   nextToken: JString
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  section = newJObject()
  var valid_21626106 = query.getOrDefault("maxResults")
  valid_21626106 = validateParameter(valid_21626106, JInt, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "maxResults", valid_21626106
  var valid_21626107 = query.getOrDefault("nextToken")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "nextToken", valid_21626107
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
  var valid_21626108 = header.getOrDefault("X-Amz-Date")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Date", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Security-Token", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626115: Call_ListMissionProfiles_21626103; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of mission profiles.
  ## 
  let valid = call_21626115.validator(path, query, header, formData, body, _)
  let scheme = call_21626115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626115.makeUrl(scheme.get, call_21626115.host, call_21626115.base,
                               call_21626115.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626115, uri, valid, _)

proc call*(call_21626116: Call_ListMissionProfiles_21626103; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   maxResults: int
  ##             : Maximum number of mission profiles returned.
  ##   nextToken: string
  ##            : Next token returned in the request of a previous <code>ListMissionProfiles</code> call. Used to get the next page of results.
  var query_21626117 = newJObject()
  add(query_21626117, "maxResults", newJInt(maxResults))
  add(query_21626117, "nextToken", newJString(nextToken))
  result = call_21626116.call(nil, query_21626117, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_21626103(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_21626104, base: "/",
    makeUrl: url_ListMissionProfiles_21626105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_21626162 = ref object of OpenApiRestCall_21625435
proc url_UpdateConfig_21626164(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfig_21626163(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_21626165 = path.getOrDefault("configId")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "configId", valid_21626165
  var valid_21626166 = path.getOrDefault("configType")
  valid_21626166 = validateParameter(valid_21626166, JString, required = true,
                                   default = newJString("antenna-downlink"))
  if valid_21626166 != nil:
    section.add "configType", valid_21626166
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Algorithm", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Signature")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Signature", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Credential")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Credential", valid_21626173
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

proc call*(call_21626175: Call_UpdateConfig_21626162; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ## 
  let valid = call_21626175.validator(path, query, header, formData, body, _)
  let scheme = call_21626175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626175.makeUrl(scheme.get, call_21626175.host, call_21626175.base,
                               call_21626175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626175, uri, valid, _)

proc call*(call_21626176: Call_UpdateConfig_21626162; configId: string;
          body: JsonNode; configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  ##   body: JObject (required)
  var path_21626177 = newJObject()
  var body_21626178 = newJObject()
  add(path_21626177, "configId", newJString(configId))
  add(path_21626177, "configType", newJString(configType))
  if body != nil:
    body_21626178 = body
  result = call_21626176.call(path_21626177, nil, nil, nil, body_21626178)

var updateConfig* = Call_UpdateConfig_21626162(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_21626163,
    base: "/", makeUrl: url_UpdateConfig_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_21626132 = ref object of OpenApiRestCall_21625435
proc url_GetConfig_21626134(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfig_21626133(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_21626135 = path.getOrDefault("configId")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "configId", valid_21626135
  var valid_21626150 = path.getOrDefault("configType")
  valid_21626150 = validateParameter(valid_21626150, JString, required = true,
                                   default = newJString("antenna-downlink"))
  if valid_21626150 != nil:
    section.add "configType", valid_21626150
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
  var valid_21626151 = header.getOrDefault("X-Amz-Date")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Date", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Security-Token", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Algorithm", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Signature")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Signature", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Credential")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Credential", valid_21626157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626158: Call_GetConfig_21626132; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ## 
  let valid = call_21626158.validator(path, query, header, formData, body, _)
  let scheme = call_21626158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626158.makeUrl(scheme.get, call_21626158.host, call_21626158.base,
                               call_21626158.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626158, uri, valid, _)

proc call*(call_21626159: Call_GetConfig_21626132; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_21626160 = newJObject()
  add(path_21626160, "configId", newJString(configId))
  add(path_21626160, "configType", newJString(configType))
  result = call_21626159.call(path_21626160, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_21626132(name: "getConfig", meth: HttpMethod.HttpGet,
                                      host: "groundstation.amazonaws.com",
                                      route: "/config/{configType}/{configId}",
                                      validator: validate_GetConfig_21626133,
                                      base: "/", makeUrl: url_GetConfig_21626134,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_21626179 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfig_21626181(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
               (kind: VariableSegment, value: "configType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfig_21626180(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a <code>Config</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: JString (required)
  ##             : Type of a <code>Config</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `configId` field"
  var valid_21626182 = path.getOrDefault("configId")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "configId", valid_21626182
  var valid_21626183 = path.getOrDefault("configType")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = newJString("antenna-downlink"))
  if valid_21626183 != nil:
    section.add "configType", valid_21626183
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
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Algorithm", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Signature")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Signature", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Credential")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Credential", valid_21626190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_DeleteConfig_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Config</code>.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_DeleteConfig_21626179; configId: string;
          configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
  ##           : UUID of a <code>Config</code>.
  ##   configType: string (required)
  ##             : Type of a <code>Config</code>.
  var path_21626193 = newJObject()
  add(path_21626193, "configId", newJString(configId))
  add(path_21626193, "configType", newJString(configType))
  result = call_21626192.call(path_21626193, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_21626179(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_21626180,
    base: "/", makeUrl: url_DeleteConfig_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_21626194 = ref object of OpenApiRestCall_21625435
proc url_GetDataflowEndpointGroup_21626196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
        "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
               (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataflowEndpointGroup_21626195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the dataflow endpoint group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
  ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_21626197 = path.getOrDefault("dataflowEndpointGroupId")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "dataflowEndpointGroupId", valid_21626197
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
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_GetDataflowEndpointGroup_21626194;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the dataflow endpoint group.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_GetDataflowEndpointGroup_21626194;
          dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_21626207 = newJObject()
  add(path_21626207, "dataflowEndpointGroupId",
      newJString(dataflowEndpointGroupId))
  result = call_21626206.call(path_21626207, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_21626194(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_21626195, base: "/",
    makeUrl: url_GetDataflowEndpointGroup_21626196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_21626208 = ref object of OpenApiRestCall_21625435
proc url_DeleteDataflowEndpointGroup_21626210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
        "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
               (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataflowEndpointGroup_21626209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a dataflow endpoint group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
  ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_21626211 = path.getOrDefault("dataflowEndpointGroupId")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "dataflowEndpointGroupId", valid_21626211
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
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_DeleteDataflowEndpointGroup_21626208;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a dataflow endpoint group.
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_DeleteDataflowEndpointGroup_21626208;
          dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
  ##                          : UUID of a dataflow endpoint group.
  var path_21626221 = newJObject()
  add(path_21626221, "dataflowEndpointGroupId",
      newJString(dataflowEndpointGroupId))
  result = call_21626220.call(path_21626221, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_21626208(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_21626209, base: "/",
    makeUrl: url_DeleteDataflowEndpointGroup_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_21626236 = ref object of OpenApiRestCall_21625435
proc url_UpdateMissionProfile_21626238(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMissionProfile_21626237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_21626239 = path.getOrDefault("missionProfileId")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "missionProfileId", valid_21626239
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

proc call*(call_21626248: Call_UpdateMissionProfile_21626236; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ## 
  let valid = call_21626248.validator(path, query, header, formData, body, _)
  let scheme = call_21626248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626248.makeUrl(scheme.get, call_21626248.host, call_21626248.base,
                               call_21626248.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626248, uri, valid, _)

proc call*(call_21626249: Call_UpdateMissionProfile_21626236;
          missionProfileId: string; body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  ##   body: JObject (required)
  var path_21626250 = newJObject()
  var body_21626251 = newJObject()
  add(path_21626250, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_21626251 = body
  result = call_21626249.call(path_21626250, nil, nil, nil, body_21626251)

var updateMissionProfile* = Call_UpdateMissionProfile_21626236(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_21626237, base: "/",
    makeUrl: url_UpdateMissionProfile_21626238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_21626222 = ref object of OpenApiRestCall_21625435
proc url_GetMissionProfile_21626224(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMissionProfile_21626223(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a mission profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_21626225 = path.getOrDefault("missionProfileId")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "missionProfileId", valid_21626225
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
  var valid_21626226 = header.getOrDefault("X-Amz-Date")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Date", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Security-Token", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626233: Call_GetMissionProfile_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a mission profile.
  ## 
  let valid = call_21626233.validator(path, query, header, formData, body, _)
  let scheme = call_21626233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626233.makeUrl(scheme.get, call_21626233.host, call_21626233.base,
                               call_21626233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626233, uri, valid, _)

proc call*(call_21626234: Call_GetMissionProfile_21626222; missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_21626235 = newJObject()
  add(path_21626235, "missionProfileId", newJString(missionProfileId))
  result = call_21626234.call(path_21626235, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_21626222(name: "getMissionProfile",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_21626223, base: "/",
    makeUrl: url_GetMissionProfile_21626224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_21626252 = ref object of OpenApiRestCall_21625435
proc url_DeleteMissionProfile_21626254(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
        "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
               (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMissionProfile_21626253(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a mission profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
  ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `missionProfileId` field"
  var valid_21626255 = path.getOrDefault("missionProfileId")
  valid_21626255 = validateParameter(valid_21626255, JString, required = true,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "missionProfileId", valid_21626255
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
  var valid_21626256 = header.getOrDefault("X-Amz-Date")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Date", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Security-Token", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Algorithm", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Signature")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Signature", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Credential")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Credential", valid_21626262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626263: Call_DeleteMissionProfile_21626252; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a mission profile.
  ## 
  let valid = call_21626263.validator(path, query, header, formData, body, _)
  let scheme = call_21626263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626263.makeUrl(scheme.get, call_21626263.host, call_21626263.base,
                               call_21626263.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626263, uri, valid, _)

proc call*(call_21626264: Call_DeleteMissionProfile_21626252;
          missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
  ##                   : UUID of a mission profile.
  var path_21626265 = newJObject()
  add(path_21626265, "missionProfileId", newJString(missionProfileId))
  result = call_21626264.call(path_21626265, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_21626252(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_21626253, base: "/",
    makeUrl: url_DeleteMissionProfile_21626254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_21626266 = ref object of OpenApiRestCall_21625435
proc url_GetMinuteUsage_21626268(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMinuteUsage_21626267(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the number of minutes used by account.
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
  var valid_21626269 = header.getOrDefault("X-Amz-Date")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Date", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Security-Token", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Algorithm", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Signature")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Signature", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Credential")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Credential", valid_21626275
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

proc call*(call_21626277: Call_GetMinuteUsage_21626266; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of minutes used by account.
  ## 
  let valid = call_21626277.validator(path, query, header, formData, body, _)
  let scheme = call_21626277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626277.makeUrl(scheme.get, call_21626277.host, call_21626277.base,
                               call_21626277.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626277, uri, valid, _)

proc call*(call_21626278: Call_GetMinuteUsage_21626266; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_21626279 = newJObject()
  if body != nil:
    body_21626279 = body
  result = call_21626278.call(nil, nil, nil, nil, body_21626279)

var getMinuteUsage* = Call_GetMinuteUsage_21626266(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_21626267, base: "/",
    makeUrl: url_GetMinuteUsage_21626268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_21626280 = ref object of OpenApiRestCall_21625435
proc url_GetSatellite_21626282(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "satelliteId" in path, "`satelliteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/satellite/"),
               (kind: VariableSegment, value: "satelliteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSatellite_21626281(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns a satellite.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   satelliteId: JString (required)
  ##              : UUID of a satellite.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `satelliteId` field"
  var valid_21626283 = path.getOrDefault("satelliteId")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "satelliteId", valid_21626283
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
  var valid_21626284 = header.getOrDefault("X-Amz-Date")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Date", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Security-Token", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626291: Call_GetSatellite_21626280; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a satellite.
  ## 
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_GetSatellite_21626280; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
  ##              : UUID of a satellite.
  var path_21626293 = newJObject()
  add(path_21626293, "satelliteId", newJString(satelliteId))
  result = call_21626292.call(path_21626293, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_21626280(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_21626281,
    base: "/", makeUrl: url_GetSatellite_21626282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_21626294 = ref object of OpenApiRestCall_21625435
proc url_ListContacts_21626296(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListContacts_21626295(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626297 = query.getOrDefault("maxResults")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "maxResults", valid_21626297
  var valid_21626298 = query.getOrDefault("nextToken")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "nextToken", valid_21626298
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
  var valid_21626299 = header.getOrDefault("X-Amz-Date")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Date", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Security-Token", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Algorithm", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Signature")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Signature", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Credential")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Credential", valid_21626305
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

proc call*(call_21626307: Call_ListContacts_21626294; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ## 
  let valid = call_21626307.validator(path, query, header, formData, body, _)
  let scheme = call_21626307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626307.makeUrl(scheme.get, call_21626307.host, call_21626307.base,
                               call_21626307.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626307, uri, valid, _)

proc call*(call_21626308: Call_ListContacts_21626294; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626309 = newJObject()
  var body_21626310 = newJObject()
  add(query_21626309, "maxResults", newJString(maxResults))
  add(query_21626309, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626310 = body
  result = call_21626308.call(nil, query_21626309, nil, nil, body_21626310)

var listContacts* = Call_ListContacts_21626294(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_21626295, base: "/",
    makeUrl: url_ListContacts_21626296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_21626311 = ref object of OpenApiRestCall_21625435
proc url_ListGroundStations_21626313(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroundStations_21626312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of ground stations. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of ground stations returned.
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   satelliteId: JString
  ##              : Satellite ID to retrieve on-boarded ground stations.
  section = newJObject()
  var valid_21626314 = query.getOrDefault("maxResults")
  valid_21626314 = validateParameter(valid_21626314, JInt, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "maxResults", valid_21626314
  var valid_21626315 = query.getOrDefault("nextToken")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "nextToken", valid_21626315
  var valid_21626316 = query.getOrDefault("satelliteId")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "satelliteId", valid_21626316
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Algorithm", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Signature")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Signature", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Credential")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Credential", valid_21626323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626324: Call_ListGroundStations_21626311; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of ground stations. 
  ## 
  let valid = call_21626324.validator(path, query, header, formData, body, _)
  let scheme = call_21626324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626324.makeUrl(scheme.get, call_21626324.host, call_21626324.base,
                               call_21626324.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626324, uri, valid, _)

proc call*(call_21626325: Call_ListGroundStations_21626311; maxResults: int = 0;
          nextToken: string = ""; satelliteId: string = ""): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   maxResults: int
  ##             : Maximum number of ground stations returned.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of ground stations.
  ##   satelliteId: string
  ##              : Satellite ID to retrieve on-boarded ground stations.
  var query_21626326 = newJObject()
  add(query_21626326, "maxResults", newJInt(maxResults))
  add(query_21626326, "nextToken", newJString(nextToken))
  add(query_21626326, "satelliteId", newJString(satelliteId))
  result = call_21626325.call(nil, query_21626326, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_21626311(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_21626312, base: "/",
    makeUrl: url_ListGroundStations_21626313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_21626327 = ref object of OpenApiRestCall_21625435
proc url_ListSatellites_21626329(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSatellites_21626328(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of satellites.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : Maximum number of satellites returned.
  ##   nextToken: JString
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  section = newJObject()
  var valid_21626330 = query.getOrDefault("maxResults")
  valid_21626330 = validateParameter(valid_21626330, JInt, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "maxResults", valid_21626330
  var valid_21626331 = query.getOrDefault("nextToken")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "nextToken", valid_21626331
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Algorithm", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Signature")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Signature", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Credential")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Credential", valid_21626338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_ListSatellites_21626327; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of satellites.
  ## 
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_ListSatellites_21626327; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   maxResults: int
  ##             : Maximum number of satellites returned.
  ##   nextToken: string
  ##            : Next token that can be supplied in the next call to get the next page of satellites.
  var query_21626341 = newJObject()
  add(query_21626341, "maxResults", newJInt(maxResults))
  add(query_21626341, "nextToken", newJString(nextToken))
  result = call_21626340.call(nil, query_21626341, nil, nil, nil)

var listSatellites* = Call_ListSatellites_21626327(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_21626328, base: "/",
    makeUrl: url_ListSatellites_21626329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626356 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626358(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_21626357(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns a tag to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626359 = path.getOrDefault("resourceArn")
  valid_21626359 = validateParameter(valid_21626359, JString, required = true,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "resourceArn", valid_21626359
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
  var valid_21626360 = header.getOrDefault("X-Amz-Date")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Date", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Security-Token", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Algorithm", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Signature")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Signature", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Credential")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Credential", valid_21626366
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

proc call*(call_21626368: Call_TagResource_21626356; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns a tag to a resource.
  ## 
  let valid = call_21626368.validator(path, query, header, formData, body, _)
  let scheme = call_21626368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626368.makeUrl(scheme.get, call_21626368.host, call_21626368.base,
                               call_21626368.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626368, uri, valid, _)

proc call*(call_21626369: Call_TagResource_21626356; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : ARN of a resource tag.
  var path_21626370 = newJObject()
  var body_21626371 = newJObject()
  if body != nil:
    body_21626371 = body
  add(path_21626370, "resourceArn", newJString(resourceArn))
  result = call_21626369.call(path_21626370, nil, nil, nil, body_21626371)

var tagResource* = Call_TagResource_21626356(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626357,
    base: "/", makeUrl: url_TagResource_21626358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626342 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626344(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of tags for a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626345 = path.getOrDefault("resourceArn")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "resourceArn", valid_21626345
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
  var valid_21626346 = header.getOrDefault("X-Amz-Date")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Date", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Security-Token", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Algorithm", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Signature")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Signature", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Credential")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Credential", valid_21626352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626353: Call_ListTagsForResource_21626342; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags for a specified resource.
  ## 
  let valid = call_21626353.validator(path, query, header, formData, body, _)
  let scheme = call_21626353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626353.makeUrl(scheme.get, call_21626353.host, call_21626353.base,
                               call_21626353.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626353, uri, valid, _)

proc call*(call_21626354: Call_ListTagsForResource_21626342; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags for a specified resource.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_21626355 = newJObject()
  add(path_21626355, "resourceArn", newJString(resourceArn))
  result = call_21626354.call(path_21626355, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626342(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626343, base: "/",
    makeUrl: url_ListTagsForResource_21626344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_21626372 = ref object of OpenApiRestCall_21625435
proc url_ReserveContact_21626374(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReserveContact_21626373(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Reserves a contact using specified parameters.
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
  var valid_21626375 = header.getOrDefault("X-Amz-Date")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Date", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Security-Token", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Algorithm", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Signature")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Signature", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Credential")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Credential", valid_21626381
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

proc call*(call_21626383: Call_ReserveContact_21626372; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Reserves a contact using specified parameters.
  ## 
  let valid = call_21626383.validator(path, query, header, formData, body, _)
  let scheme = call_21626383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626383.makeUrl(scheme.get, call_21626383.host, call_21626383.base,
                               call_21626383.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626383, uri, valid, _)

proc call*(call_21626384: Call_ReserveContact_21626372; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_21626385 = newJObject()
  if body != nil:
    body_21626385 = body
  result = call_21626384.call(nil, nil, nil, nil, body_21626385)

var reserveContact* = Call_ReserveContact_21626372(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_21626373, base: "/",
    makeUrl: url_ReserveContact_21626374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626386 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626388(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_21626387(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deassigns a resource tag.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626389 = path.getOrDefault("resourceArn")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "resourceArn", valid_21626389
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626390 = query.getOrDefault("tagKeys")
  valid_21626390 = validateParameter(valid_21626390, JArray, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "tagKeys", valid_21626390
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
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_UntagResource_21626386; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deassigns a resource tag.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_UntagResource_21626386; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   tagKeys: JArray (required)
  ##          : Keys of a resource tag.
  ##   resourceArn: string (required)
  ##              : ARN of a resource.
  var path_21626400 = newJObject()
  var query_21626401 = newJObject()
  if tagKeys != nil:
    query_21626401.add "tagKeys", tagKeys
  add(path_21626400, "resourceArn", newJString(resourceArn))
  result = call_21626399.call(path_21626400, query_21626401, nil, nil, nil)

var untagResource* = Call_UntagResource_21626386(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626387,
    base: "/", makeUrl: url_UntagResource_21626388,
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