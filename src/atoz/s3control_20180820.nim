
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS S3 Control
## version: 2018-08-20
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
##  AWS S3 Control provides access to Amazon S3 control plane operations. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/s3-control/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com", "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
                           "us-west-2": "s3-control.us-west-2.amazonaws.com",
                           "eu-west-2": "s3-control.eu-west-2.amazonaws.com", "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com", "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
                           "us-east-2": "s3-control.us-east-2.amazonaws.com",
                           "us-east-1": "s3-control.us-east-1.amazonaws.com", "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
                           "eu-north-1": "s3-control.eu-north-1.amazonaws.com", "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
                           "us-west-1": "s3-control.us-west-1.amazonaws.com", "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "s3-control.eu-west-3.amazonaws.com", "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
                           "eu-west-1": "s3-control.eu-west-1.amazonaws.com", "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com", "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com", "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "s3-control.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "s3-control.ap-southeast-1.amazonaws.com",
      "us-west-2": "s3-control.us-west-2.amazonaws.com",
      "eu-west-2": "s3-control.eu-west-2.amazonaws.com",
      "ap-northeast-3": "s3-control.ap-northeast-3.amazonaws.com",
      "eu-central-1": "s3-control.eu-central-1.amazonaws.com",
      "us-east-2": "s3-control.us-east-2.amazonaws.com",
      "us-east-1": "s3-control.us-east-1.amazonaws.com",
      "cn-northwest-1": "s3-control.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "s3-control.ap-south-1.amazonaws.com",
      "eu-north-1": "s3-control.eu-north-1.amazonaws.com",
      "ap-northeast-2": "s3-control.ap-northeast-2.amazonaws.com",
      "us-west-1": "s3-control.us-west-1.amazonaws.com",
      "us-gov-east-1": "s3-control.us-gov-east-1.amazonaws.com",
      "eu-west-3": "s3-control.eu-west-3.amazonaws.com",
      "cn-north-1": "s3-control.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "s3-control.sa-east-1.amazonaws.com",
      "eu-west-1": "s3-control.eu-west-1.amazonaws.com",
      "us-gov-west-1": "s3-control.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "s3-control.ap-southeast-2.amazonaws.com",
      "ca-central-1": "s3-control.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "s3control"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateAccessPoint_21626031 = ref object of OpenApiRestCall_21625435
proc url_CreateAccessPoint_21626033(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAccessPoint_21626032(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an access point and associates it with the specified bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name you want to assign to this access point.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626034 = path.getOrDefault("name")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "name", valid_21626034
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
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for the owner of the bucket for which you want to create an access point.
  section = newJObject()
  var valid_21626035 = header.getOrDefault("X-Amz-Date")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Date", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Security-Token", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Algorithm", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Signature")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Signature", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Credential")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Credential", valid_21626041
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626042 = header.getOrDefault("x-amz-account-id")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "x-amz-account-id", valid_21626042
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

proc call*(call_21626044: Call_CreateAccessPoint_21626031; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an access point and associates it with the specified bucket.
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

proc call*(call_21626045: Call_CreateAccessPoint_21626031; name: string;
          body: JsonNode): Recallable =
  ## createAccessPoint
  ## Creates an access point and associates it with the specified bucket.
  ##   name: string (required)
  ##       : The name you want to assign to this access point.
  ##   body: JObject (required)
  var path_21626046 = newJObject()
  var body_21626047 = newJObject()
  add(path_21626046, "name", newJString(name))
  if body != nil:
    body_21626047 = body
  result = call_21626045.call(path_21626046, nil, nil, nil, body_21626047)

var createAccessPoint* = Call_CreateAccessPoint_21626031(name: "createAccessPoint",
    meth: HttpMethod.HttpPut, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_CreateAccessPoint_21626032, base: "/",
    makeUrl: url_CreateAccessPoint_21626033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPoint_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetAccessPoint_21625781(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPoint_21625780(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns configuration information about the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose configuration information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21625895 = path.getOrDefault("name")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "name", valid_21625895
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
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
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21625903 = header.getOrDefault("x-amz-account-id")
  valid_21625903 = validateParameter(valid_21625903, JString, required = true,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "x-amz-account-id", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625928: Call_GetAccessPoint_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns configuration information about the specified access point.
  ## 
  let valid = call_21625928.validator(path, query, header, formData, body, _)
  let scheme = call_21625928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625928.makeUrl(scheme.get, call_21625928.host, call_21625928.base,
                               call_21625928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625928, uri, valid, _)

proc call*(call_21625991: Call_GetAccessPoint_21625779; name: string): Recallable =
  ## getAccessPoint
  ## Returns configuration information about the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose configuration information you want to retrieve.
  var path_21625993 = newJObject()
  add(path_21625993, "name", newJString(name))
  result = call_21625991.call(path_21625993, nil, nil, nil, nil)

var getAccessPoint* = Call_GetAccessPoint_21625779(name: "getAccessPoint",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_GetAccessPoint_21625780, base: "/",
    makeUrl: url_GetAccessPoint_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPoint_21626048 = ref object of OpenApiRestCall_21625435
proc url_DeleteAccessPoint_21626050(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPoint_21626049(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626051 = path.getOrDefault("name")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "name", valid_21626051
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  section = newJObject()
  var valid_21626052 = header.getOrDefault("X-Amz-Date")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Date", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Security-Token", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Algorithm", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Signature")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Signature", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Credential")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Credential", valid_21626058
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626059 = header.getOrDefault("x-amz-account-id")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "x-amz-account-id", valid_21626059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626060: Call_DeleteAccessPoint_21626048; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified access point.
  ## 
  let valid = call_21626060.validator(path, query, header, formData, body, _)
  let scheme = call_21626060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626060.makeUrl(scheme.get, call_21626060.host, call_21626060.base,
                               call_21626060.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626060, uri, valid, _)

proc call*(call_21626061: Call_DeleteAccessPoint_21626048; name: string): Recallable =
  ## deleteAccessPoint
  ## Deletes the specified access point.
  ##   name: string (required)
  ##       : The name of the access point you want to delete.
  var path_21626062 = newJObject()
  add(path_21626062, "name", newJString(name))
  result = call_21626061.call(path_21626062, nil, nil, nil, nil)

var deleteAccessPoint* = Call_DeleteAccessPoint_21626048(name: "deleteAccessPoint",
    meth: HttpMethod.HttpDelete, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}#x-amz-account-id",
    validator: validate_DeleteAccessPoint_21626049, base: "/",
    makeUrl: url_DeleteAccessPoint_21626050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_21626083 = ref object of OpenApiRestCall_21625435
proc url_CreateJob_21626085(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_21626084(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Amazon S3 batch operations job.
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626093 = header.getOrDefault("x-amz-account-id")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "x-amz-account-id", valid_21626093
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

proc call*(call_21626095: Call_CreateJob_21626083; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Amazon S3 batch operations job.
  ## 
  let valid = call_21626095.validator(path, query, header, formData, body, _)
  let scheme = call_21626095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626095.makeUrl(scheme.get, call_21626095.host, call_21626095.base,
                               call_21626095.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626095, uri, valid, _)

proc call*(call_21626096: Call_CreateJob_21626083; body: JsonNode): Recallable =
  ## createJob
  ## Creates an Amazon S3 batch operations job.
  ##   body: JObject (required)
  var body_21626097 = newJObject()
  if body != nil:
    body_21626097 = body
  result = call_21626096.call(nil, nil, nil, nil, body_21626097)

var createJob* = Call_CreateJob_21626083(name: "createJob",
                                      meth: HttpMethod.HttpPost,
                                      host: "s3-control.amazonaws.com", route: "/v20180820/jobs#x-amz-account-id",
                                      validator: validate_CreateJob_21626084,
                                      base: "/", makeUrl: url_CreateJob_21626085,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_21626063 = ref object of OpenApiRestCall_21625435
proc url_ListJobs_21626065(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_21626064(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: JString
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626066 = query.getOrDefault("jobStatuses")
  valid_21626066 = validateParameter(valid_21626066, JArray, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "jobStatuses", valid_21626066
  var valid_21626067 = query.getOrDefault("NextToken")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "NextToken", valid_21626067
  var valid_21626068 = query.getOrDefault("maxResults")
  valid_21626068 = validateParameter(valid_21626068, JInt, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "maxResults", valid_21626068
  var valid_21626069 = query.getOrDefault("nextToken")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "nextToken", valid_21626069
  var valid_21626070 = query.getOrDefault("MaxResults")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "MaxResults", valid_21626070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626078 = header.getOrDefault("x-amz-account-id")
  valid_21626078 = validateParameter(valid_21626078, JString, required = true,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "x-amz-account-id", valid_21626078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626079: Call_ListJobs_21626063; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ## 
  let valid = call_21626079.validator(path, query, header, formData, body, _)
  let scheme = call_21626079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626079.makeUrl(scheme.get, call_21626079.host, call_21626079.base,
                               call_21626079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626079, uri, valid, _)

proc call*(call_21626080: Call_ListJobs_21626063; jobStatuses: JsonNode = nil;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Lists current jobs and jobs that have ended within the last 30 days for the AWS account making the request.
  ##   jobStatuses: JArray
  ##              : The <code>List Jobs</code> request returns jobs that match the statuses listed in this element.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of jobs that Amazon S3 will include in the <code>List Jobs</code> response. If there are more jobs than this number, the response will include a pagination token in the <code>NextToken</code> field to enable you to retrieve the next page of results.
  ##   nextToken: string
  ##            : A pagination token to request the next page of results. Use the token that Amazon S3 returned in the <code>NextToken</code> element of the <code>ListJobsResult</code> from the previous <code>List Jobs</code> request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626081 = newJObject()
  if jobStatuses != nil:
    query_21626081.add "jobStatuses", jobStatuses
  add(query_21626081, "NextToken", newJString(NextToken))
  add(query_21626081, "maxResults", newJInt(maxResults))
  add(query_21626081, "nextToken", newJString(nextToken))
  add(query_21626081, "MaxResults", newJString(MaxResults))
  result = call_21626080.call(nil, query_21626081, nil, nil, nil)

var listJobs* = Call_ListJobs_21626063(name: "listJobs", meth: HttpMethod.HttpGet,
                                    host: "s3-control.amazonaws.com",
                                    route: "/v20180820/jobs#x-amz-account-id",
                                    validator: validate_ListJobs_21626064,
                                    base: "/", makeUrl: url_ListJobs_21626065,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccessPointPolicy_21626113 = ref object of OpenApiRestCall_21625435
proc url_PutAccessPointPolicy_21626115(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutAccessPointPolicy_21626114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point that you want to associate with the specified policy.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626116 = path.getOrDefault("name")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "name", valid_21626116
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
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for owner of the bucket associated with the specified access point.
  section = newJObject()
  var valid_21626117 = header.getOrDefault("X-Amz-Date")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Date", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Security-Token", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Algorithm", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Signature")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Signature", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Credential")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Credential", valid_21626123
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626124 = header.getOrDefault("x-amz-account-id")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "x-amz-account-id", valid_21626124
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

proc call*(call_21626126: Call_PutAccessPointPolicy_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ## 
  let valid = call_21626126.validator(path, query, header, formData, body, _)
  let scheme = call_21626126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626126.makeUrl(scheme.get, call_21626126.host, call_21626126.base,
                               call_21626126.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626126, uri, valid, _)

proc call*(call_21626127: Call_PutAccessPointPolicy_21626113; name: string;
          body: JsonNode): Recallable =
  ## putAccessPointPolicy
  ## Associates an access policy with the specified access point. Each access point can have only one policy, so a request made to this API replaces any existing policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point that you want to associate with the specified policy.
  ##   body: JObject (required)
  var path_21626128 = newJObject()
  var body_21626129 = newJObject()
  add(path_21626128, "name", newJString(name))
  if body != nil:
    body_21626129 = body
  result = call_21626127.call(path_21626128, nil, nil, nil, body_21626129)

var putAccessPointPolicy* = Call_PutAccessPointPolicy_21626113(
    name: "putAccessPointPolicy", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_PutAccessPointPolicy_21626114, base: "/",
    makeUrl: url_PutAccessPointPolicy_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicy_21626098 = ref object of OpenApiRestCall_21625435
proc url_GetAccessPointPolicy_21626100(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicy_21626099(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the access point policy associated with the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626101 = path.getOrDefault("name")
  valid_21626101 = validateParameter(valid_21626101, JString, required = true,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "name", valid_21626101
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  section = newJObject()
  var valid_21626102 = header.getOrDefault("X-Amz-Date")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Date", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Security-Token", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626109 = header.getOrDefault("x-amz-account-id")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "x-amz-account-id", valid_21626109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626110: Call_GetAccessPointPolicy_21626098; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the access point policy associated with the specified access point.
  ## 
  let valid = call_21626110.validator(path, query, header, formData, body, _)
  let scheme = call_21626110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626110.makeUrl(scheme.get, call_21626110.host, call_21626110.base,
                               call_21626110.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626110, uri, valid, _)

proc call*(call_21626111: Call_GetAccessPointPolicy_21626098; name: string): Recallable =
  ## getAccessPointPolicy
  ## Returns the access point policy associated with the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to retrieve.
  var path_21626112 = newJObject()
  add(path_21626112, "name", newJString(name))
  result = call_21626111.call(path_21626112, nil, nil, nil, nil)

var getAccessPointPolicy* = Call_GetAccessPointPolicy_21626098(
    name: "getAccessPointPolicy", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_GetAccessPointPolicy_21626099, base: "/",
    makeUrl: url_GetAccessPointPolicy_21626100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessPointPolicy_21626130 = ref object of OpenApiRestCall_21625435
proc url_DeleteAccessPointPolicy_21626132(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policy#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAccessPointPolicy_21626131(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the access point policy for the specified access point.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626133 = path.getOrDefault("name")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "name", valid_21626133
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  section = newJObject()
  var valid_21626134 = header.getOrDefault("X-Amz-Date")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Date", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Security-Token", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Algorithm", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Signature")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Signature", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Credential")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Credential", valid_21626140
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626141 = header.getOrDefault("x-amz-account-id")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "x-amz-account-id", valid_21626141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_DeleteAccessPointPolicy_21626130;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the access point policy for the specified access point.
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_DeleteAccessPointPolicy_21626130; name: string): Recallable =
  ## deleteAccessPointPolicy
  ## Deletes the access point policy for the specified access point.
  ##   name: string (required)
  ##       : The name of the access point whose policy you want to delete.
  var path_21626144 = newJObject()
  add(path_21626144, "name", newJString(name))
  result = call_21626143.call(path_21626144, nil, nil, nil, nil)

var deleteAccessPointPolicy* = Call_DeleteAccessPointPolicy_21626130(
    name: "deleteAccessPointPolicy", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policy#x-amz-account-id",
    validator: validate_DeleteAccessPointPolicy_21626131, base: "/",
    makeUrl: url_DeleteAccessPointPolicy_21626132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPublicAccessBlock_21626158 = ref object of OpenApiRestCall_21625435
proc url_PutPublicAccessBlock_21626160(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPublicAccessBlock_21626159(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to set.
  section = newJObject()
  var valid_21626161 = header.getOrDefault("X-Amz-Date")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Date", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Security-Token", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Algorithm", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Signature")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Signature", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Credential")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Credential", valid_21626167
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626168 = header.getOrDefault("x-amz-account-id")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "x-amz-account-id", valid_21626168
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

proc call*(call_21626170: Call_PutPublicAccessBlock_21626158; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_21626170.validator(path, query, header, formData, body, _)
  let scheme = call_21626170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626170.makeUrl(scheme.get, call_21626170.host, call_21626170.base,
                               call_21626170.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626170, uri, valid, _)

proc call*(call_21626171: Call_PutPublicAccessBlock_21626158; body: JsonNode): Recallable =
  ## putPublicAccessBlock
  ## Creates or modifies the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ##   body: JObject (required)
  var body_21626172 = newJObject()
  if body != nil:
    body_21626172 = body
  result = call_21626171.call(nil, nil, nil, nil, body_21626172)

var putPublicAccessBlock* = Call_PutPublicAccessBlock_21626158(
    name: "putPublicAccessBlock", meth: HttpMethod.HttpPut,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_PutPublicAccessBlock_21626159, base: "/",
    makeUrl: url_PutPublicAccessBlock_21626160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicAccessBlock_21626145 = ref object of OpenApiRestCall_21625435
proc url_GetPublicAccessBlock_21626147(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublicAccessBlock_21626146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to retrieve.
  section = newJObject()
  var valid_21626148 = header.getOrDefault("X-Amz-Date")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Date", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Security-Token", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Algorithm", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Signature")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Signature", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Credential")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Credential", valid_21626154
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626155 = header.getOrDefault("x-amz-account-id")
  valid_21626155 = validateParameter(valid_21626155, JString, required = true,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "x-amz-account-id", valid_21626155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626156: Call_GetPublicAccessBlock_21626145; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_GetPublicAccessBlock_21626145): Recallable =
  ## getPublicAccessBlock
  ## Retrieves the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_21626157.call(nil, nil, nil, nil, nil)

var getPublicAccessBlock* = Call_GetPublicAccessBlock_21626145(
    name: "getPublicAccessBlock", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_GetPublicAccessBlock_21626146, base: "/",
    makeUrl: url_GetPublicAccessBlock_21626147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicAccessBlock_21626173 = ref object of OpenApiRestCall_21625435
proc url_DeletePublicAccessBlock_21626175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePublicAccessBlock_21626174(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the Amazon Web Services account whose <code>PublicAccessBlock</code> configuration you want to remove.
  section = newJObject()
  var valid_21626176 = header.getOrDefault("X-Amz-Date")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Date", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Security-Token", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Algorithm", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Signature")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Signature", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Credential")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Credential", valid_21626182
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626183 = header.getOrDefault("x-amz-account-id")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "x-amz-account-id", valid_21626183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626184: Call_DeletePublicAccessBlock_21626173;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  ## 
  let valid = call_21626184.validator(path, query, header, formData, body, _)
  let scheme = call_21626184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626184.makeUrl(scheme.get, call_21626184.host, call_21626184.base,
                               call_21626184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626184, uri, valid, _)

proc call*(call_21626185: Call_DeletePublicAccessBlock_21626173): Recallable =
  ## deletePublicAccessBlock
  ## Removes the <code>PublicAccessBlock</code> configuration for an Amazon Web Services account.
  result = call_21626185.call(nil, nil, nil, nil, nil)

var deletePublicAccessBlock* = Call_DeletePublicAccessBlock_21626173(
    name: "deletePublicAccessBlock", meth: HttpMethod.HttpDelete,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/configuration/publicAccessBlock#x-amz-account-id",
    validator: validate_DeletePublicAccessBlock_21626174, base: "/",
    makeUrl: url_DeletePublicAccessBlock_21626175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_21626186 = ref object of OpenApiRestCall_21625435
proc url_DescribeJob_21626188(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJob_21626187(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose information you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626189 = path.getOrDefault("id")
  valid_21626189 = validateParameter(valid_21626189, JString, required = true,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "id", valid_21626189
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
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_21626190 = header.getOrDefault("X-Amz-Date")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Date", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Security-Token", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Algorithm", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Signature")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Signature", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Credential")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Credential", valid_21626196
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626197 = header.getOrDefault("x-amz-account-id")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "x-amz-account-id", valid_21626197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_DescribeJob_21626186; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the configuration parameters and status for a batch operations job.
  ## 
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_DescribeJob_21626186; id: string): Recallable =
  ## describeJob
  ## Retrieves the configuration parameters and status for a batch operations job.
  ##   id: string (required)
  ##     : The ID for the job whose information you want to retrieve.
  var path_21626200 = newJObject()
  add(path_21626200, "id", newJString(id))
  result = call_21626199.call(path_21626200, nil, nil, nil, nil)

var describeJob* = Call_DescribeJob_21626186(name: "describeJob",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}#x-amz-account-id",
    validator: validate_DescribeJob_21626187, base: "/", makeUrl: url_DescribeJob_21626188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessPointPolicyStatus_21626201 = ref object of OpenApiRestCall_21625435
proc url_GetAccessPointPolicyStatus_21626203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/accesspoint/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/policyStatus#x-amz-account-id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccessPointPolicyStatus_21626202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the access point whose policy status you want to retrieve.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626204 = path.getOrDefault("name")
  valid_21626204 = validateParameter(valid_21626204, JString, required = true,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "name", valid_21626204
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
  ##   x-amz-account-id: JString (required)
  ##                   : The account ID for the account that owns the specified access point.
  section = newJObject()
  var valid_21626205 = header.getOrDefault("X-Amz-Date")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Date", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Security-Token", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Algorithm", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Signature")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Signature", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Credential")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Credential", valid_21626211
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626212 = header.getOrDefault("x-amz-account-id")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "x-amz-account-id", valid_21626212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626213: Call_GetAccessPointPolicyStatus_21626201;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ## 
  let valid = call_21626213.validator(path, query, header, formData, body, _)
  let scheme = call_21626213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626213.makeUrl(scheme.get, call_21626213.host, call_21626213.base,
                               call_21626213.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626213, uri, valid, _)

proc call*(call_21626214: Call_GetAccessPointPolicyStatus_21626201; name: string): Recallable =
  ## getAccessPointPolicyStatus
  ## Indicates whether the specified access point currently has a policy that allows public access. For more information about public access through access points, see <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/access-points.html">Managing Data Access with Amazon S3 Access Points</a> in the <i>Amazon Simple Storage Service Developer Guide</i>.
  ##   name: string (required)
  ##       : The name of the access point whose policy status you want to retrieve.
  var path_21626215 = newJObject()
  add(path_21626215, "name", newJString(name))
  result = call_21626214.call(path_21626215, nil, nil, nil, nil)

var getAccessPointPolicyStatus* = Call_GetAccessPointPolicyStatus_21626201(
    name: "getAccessPointPolicyStatus", meth: HttpMethod.HttpGet,
    host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint/{name}/policyStatus#x-amz-account-id",
    validator: validate_GetAccessPointPolicyStatus_21626202, base: "/",
    makeUrl: url_GetAccessPointPolicyStatus_21626203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccessPoints_21626216 = ref object of OpenApiRestCall_21625435
proc url_ListAccessPoints_21626218(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccessPoints_21626217(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   bucket: JString
  ##         : The name of the bucket whose associated access points you want to list.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the <code>NextToken</code> field that you can use to retrieve the next page of access points.
  ##   nextToken: JString
  ##            : A continuation token. If a previous call to <code>ListAccessPoints</code> returned a continuation token in the <code>NextToken</code> field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626219 = query.getOrDefault("bucket")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "bucket", valid_21626219
  var valid_21626220 = query.getOrDefault("NextToken")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "NextToken", valid_21626220
  var valid_21626221 = query.getOrDefault("maxResults")
  valid_21626221 = validateParameter(valid_21626221, JInt, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "maxResults", valid_21626221
  var valid_21626222 = query.getOrDefault("nextToken")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "nextToken", valid_21626222
  var valid_21626223 = query.getOrDefault("MaxResults")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "MaxResults", valid_21626223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : The AWS account ID for owner of the bucket whose access points you want to list.
  section = newJObject()
  var valid_21626224 = header.getOrDefault("X-Amz-Date")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Date", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Security-Token", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Algorithm", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Signature")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Signature", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Credential")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Credential", valid_21626230
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626231 = header.getOrDefault("x-amz-account-id")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "x-amz-account-id", valid_21626231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626232: Call_ListAccessPoints_21626216; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ## 
  let valid = call_21626232.validator(path, query, header, formData, body, _)
  let scheme = call_21626232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626232.makeUrl(scheme.get, call_21626232.host, call_21626232.base,
                               call_21626232.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626232, uri, valid, _)

proc call*(call_21626233: Call_ListAccessPoints_21626216; bucket: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listAccessPoints
  ## Returns a list of the access points currently associated with the specified bucket. You can retrieve up to 1000 access points per call. If the specified bucket has more than 1000 access points (or the number specified in <code>maxResults</code>, whichever is less), then the response will include a continuation token that you can use to list the additional access points.
  ##   bucket: string
  ##         : The name of the bucket whose associated access points you want to list.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of access points that you want to include in the list. If the specified bucket has more than this number of access points, then the response will include a continuation token in the <code>NextToken</code> field that you can use to retrieve the next page of access points.
  ##   nextToken: string
  ##            : A continuation token. If a previous call to <code>ListAccessPoints</code> returned a continuation token in the <code>NextToken</code> field, then providing that value here causes Amazon S3 to retrieve the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626234 = newJObject()
  add(query_21626234, "bucket", newJString(bucket))
  add(query_21626234, "NextToken", newJString(NextToken))
  add(query_21626234, "maxResults", newJInt(maxResults))
  add(query_21626234, "nextToken", newJString(nextToken))
  add(query_21626234, "MaxResults", newJString(MaxResults))
  result = call_21626233.call(nil, query_21626234, nil, nil, nil)

var listAccessPoints* = Call_ListAccessPoints_21626216(name: "listAccessPoints",
    meth: HttpMethod.HttpGet, host: "s3-control.amazonaws.com",
    route: "/v20180820/accesspoint#x-amz-account-id",
    validator: validate_ListAccessPoints_21626217, base: "/",
    makeUrl: url_ListAccessPoints_21626218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobPriority_21626235 = ref object of OpenApiRestCall_21625435
proc url_UpdateJobPriority_21626237(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/priority#x-amz-account-id&priority")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobPriority_21626236(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing job's priority.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID for the job whose priority you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626238 = path.getOrDefault("id")
  valid_21626238 = validateParameter(valid_21626238, JString, required = true,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "id", valid_21626238
  result.add "path", section
  ## parameters in `query` object:
  ##   priority: JInt (required)
  ##           : The priority you want to assign to this job.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `priority` field"
  var valid_21626239 = query.getOrDefault("priority")
  valid_21626239 = validateParameter(valid_21626239, JInt, required = true,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "priority", valid_21626239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
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
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626247 = header.getOrDefault("x-amz-account-id")
  valid_21626247 = validateParameter(valid_21626247, JString, required = true,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "x-amz-account-id", valid_21626247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626248: Call_UpdateJobPriority_21626235; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing job's priority.
  ## 
  let valid = call_21626248.validator(path, query, header, formData, body, _)
  let scheme = call_21626248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626248.makeUrl(scheme.get, call_21626248.host, call_21626248.base,
                               call_21626248.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626248, uri, valid, _)

proc call*(call_21626249: Call_UpdateJobPriority_21626235; id: string; priority: int): Recallable =
  ## updateJobPriority
  ## Updates an existing job's priority.
  ##   id: string (required)
  ##     : The ID for the job whose priority you want to update.
  ##   priority: int (required)
  ##           : The priority you want to assign to this job.
  var path_21626250 = newJObject()
  var query_21626251 = newJObject()
  add(path_21626250, "id", newJString(id))
  add(query_21626251, "priority", newJInt(priority))
  result = call_21626249.call(path_21626250, query_21626251, nil, nil, nil)

var updateJobPriority* = Call_UpdateJobPriority_21626235(name: "updateJobPriority",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/priority#x-amz-account-id&priority",
    validator: validate_UpdateJobPriority_21626236, base: "/",
    makeUrl: url_UpdateJobPriority_21626237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobStatus_21626252 = ref object of OpenApiRestCall_21625435
proc url_UpdateJobStatus_21626254(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v20180820/jobs/"),
               (kind: VariableSegment, value: "id"), (kind: ConstantSegment,
        value: "/status#x-amz-account-id&requestedJobStatus")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateJobStatus_21626253(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the job whose status you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626255 = path.getOrDefault("id")
  valid_21626255 = validateParameter(valid_21626255, JString, required = true,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "id", valid_21626255
  result.add "path", section
  ## parameters in `query` object:
  ##   requestedJobStatus: JString (required)
  ##                     : The status that you want to move the specified job to.
  ##   statusUpdateReason: JString
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  section = newJObject()
  var valid_21626270 = query.getOrDefault("requestedJobStatus")
  valid_21626270 = validateParameter(valid_21626270, JString, required = true,
                                   default = newJString("Cancelled"))
  if valid_21626270 != nil:
    section.add "requestedJobStatus", valid_21626270
  var valid_21626271 = query.getOrDefault("statusUpdateReason")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "statusUpdateReason", valid_21626271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   x-amz-account-id: JString (required)
  ##                   : <p/>
  section = newJObject()
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Algorithm", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Signature")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Signature", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Credential")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Credential", valid_21626278
  assert header != nil,
        "header argument is necessary due to required `x-amz-account-id` field"
  var valid_21626279 = header.getOrDefault("x-amz-account-id")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "x-amz-account-id", valid_21626279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626280: Call_UpdateJobStatus_21626252; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ## 
  let valid = call_21626280.validator(path, query, header, formData, body, _)
  let scheme = call_21626280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626280.makeUrl(scheme.get, call_21626280.host, call_21626280.base,
                               call_21626280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626280, uri, valid, _)

proc call*(call_21626281: Call_UpdateJobStatus_21626252; id: string;
          requestedJobStatus: string = "Cancelled"; statusUpdateReason: string = ""): Recallable =
  ## updateJobStatus
  ## Updates the status for the specified job. Use this operation to confirm that you want to run a job or to cancel an existing job.
  ##   requestedJobStatus: string (required)
  ##                     : The status that you want to move the specified job to.
  ##   id: string (required)
  ##     : The ID of the job whose status you want to update.
  ##   statusUpdateReason: string
  ##                     : A description of the reason why you want to change the specified job's status. This field can be any string up to the maximum length.
  var path_21626282 = newJObject()
  var query_21626283 = newJObject()
  add(query_21626283, "requestedJobStatus", newJString(requestedJobStatus))
  add(path_21626282, "id", newJString(id))
  add(query_21626283, "statusUpdateReason", newJString(statusUpdateReason))
  result = call_21626281.call(path_21626282, query_21626283, nil, nil, nil)

var updateJobStatus* = Call_UpdateJobStatus_21626252(name: "updateJobStatus",
    meth: HttpMethod.HttpPost, host: "s3-control.amazonaws.com",
    route: "/v20180820/jobs/{id}/status#x-amz-account-id&requestedJobStatus",
    validator: validate_UpdateJobStatus_21626253, base: "/",
    makeUrl: url_UpdateJobStatus_21626254, schemes: {Scheme.Https, Scheme.Http})
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