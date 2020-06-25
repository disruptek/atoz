
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Connect Service
## version: 2017-08-08
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Connect is a cloud-based contact center solution that makes it easy to set up and manage a customer contact center and provide reliable customer engagement at any scale.</p> <p>Amazon Connect provides rich metrics and real-time reporting that allow you to optimize contact routing. You can also resolve customer issues more efficiently by putting customers in touch with the right agents.</p> <p>There are limits to the number of Amazon Connect resources that you can create and limits to the number of requests that you can make per second. For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/amazon-connect-service-limits.html">Amazon Connect Service Limits</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/connect/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "connect.ap-southeast-1.amazonaws.com",
                           "us-west-2": "connect.us-west-2.amazonaws.com",
                           "eu-west-2": "connect.eu-west-2.amazonaws.com", "ap-northeast-3": "connect.ap-northeast-3.amazonaws.com", "eu-central-1": "connect.eu-central-1.amazonaws.com",
                           "us-east-2": "connect.us-east-2.amazonaws.com",
                           "us-east-1": "connect.us-east-1.amazonaws.com", "cn-northwest-1": "connect.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "connect.ap-south-1.amazonaws.com",
                           "eu-north-1": "connect.eu-north-1.amazonaws.com", "ap-northeast-2": "connect.ap-northeast-2.amazonaws.com",
                           "us-west-1": "connect.us-west-1.amazonaws.com", "us-gov-east-1": "connect.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "connect.eu-west-3.amazonaws.com",
                           "cn-north-1": "connect.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "connect.sa-east-1.amazonaws.com",
                           "eu-west-1": "connect.eu-west-1.amazonaws.com", "us-gov-west-1": "connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "connect.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "connect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "connect.ap-southeast-1.amazonaws.com",
      "us-west-2": "connect.us-west-2.amazonaws.com",
      "eu-west-2": "connect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "connect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "connect.eu-central-1.amazonaws.com",
      "us-east-2": "connect.us-east-2.amazonaws.com",
      "us-east-1": "connect.us-east-1.amazonaws.com",
      "cn-northwest-1": "connect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "connect.ap-south-1.amazonaws.com",
      "eu-north-1": "connect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "connect.ap-northeast-2.amazonaws.com",
      "us-west-1": "connect.us-west-1.amazonaws.com",
      "us-gov-east-1": "connect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "connect.eu-west-3.amazonaws.com",
      "cn-north-1": "connect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "connect.sa-east-1.amazonaws.com",
      "eu-west-1": "connect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "connect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "connect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "connect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "connect"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateUser_21625779 = ref object of OpenApiRestCall_21625435
proc url_CreateUser_21625781(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21625895 = path.getOrDefault("InstanceId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "InstanceId", valid_21625895
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625928: Call_CreateUser_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  let valid = call_21625928.validator(path, query, header, formData, body, _)
  let scheme = call_21625928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625928.makeUrl(scheme.get, call_21625928.host, call_21625928.base,
                               call_21625928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625928, uri, valid, _)

proc call*(call_21625991: Call_CreateUser_21625779; InstanceId: string;
          body: JsonNode): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  var path_21625993 = newJObject()
  var body_21625995 = newJObject()
  add(path_21625993, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21625995 = body
  result = call_21625991.call(path_21625993, nil, nil, nil, body_21625995)

var createUser* = Call_CreateUser_21625779(name: "createUser",
                                        meth: HttpMethod.HttpPut,
                                        host: "connect.amazonaws.com",
                                        route: "/users/{InstanceId}",
                                        validator: validate_CreateUser_21625780,
                                        base: "/", makeUrl: url_CreateUser_21625781,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_21626032 = ref object of OpenApiRestCall_21625435
proc url_DescribeUser_21626034(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_21626033(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626035 = path.getOrDefault("InstanceId")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "InstanceId", valid_21626035
  var valid_21626036 = path.getOrDefault("UserId")
  valid_21626036 = validateParameter(valid_21626036, JString, required = true,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "UserId", valid_21626036
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
  var valid_21626037 = header.getOrDefault("X-Amz-Date")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Date", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Security-Token", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Algorithm", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Signature")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Signature", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Credential")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Credential", valid_21626043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626044: Call_DescribeUser_21626032; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  let valid = call_21626044.validator(path, query, header, formData, body, _)
  let scheme = call_21626044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626044.makeUrl(scheme.get, call_21626044.host, call_21626044.base,
                               call_21626044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626044, uri, valid, _)

proc call*(call_21626045: Call_DescribeUser_21626032; InstanceId: string;
          UserId: string): Recallable =
  ## describeUser
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626046 = newJObject()
  add(path_21626046, "InstanceId", newJString(InstanceId))
  add(path_21626046, "UserId", newJString(UserId))
  result = call_21626045.call(path_21626046, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_21626032(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_21626033,
    base: "/", makeUrl: url_DescribeUser_21626034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_21626047 = ref object of OpenApiRestCall_21625435
proc url_DeleteUser_21626049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_21626048(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626050 = path.getOrDefault("InstanceId")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "InstanceId", valid_21626050
  var valid_21626051 = path.getOrDefault("UserId")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "UserId", valid_21626051
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
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626059: Call_DeleteUser_21626047; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  let valid = call_21626059.validator(path, query, header, formData, body, _)
  let scheme = call_21626059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626059.makeUrl(scheme.get, call_21626059.host, call_21626059.base,
                               call_21626059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626059, uri, valid, _)

proc call*(call_21626060: Call_DeleteUser_21626047; InstanceId: string;
          UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user.
  var path_21626061 = newJObject()
  add(path_21626061, "InstanceId", newJString(InstanceId))
  add(path_21626061, "UserId", newJString(UserId))
  result = call_21626060.call(path_21626061, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_21626047(name: "deleteUser",
                                        meth: HttpMethod.HttpDelete,
                                        host: "connect.amazonaws.com",
                                        route: "/users/{InstanceId}/{UserId}",
                                        validator: validate_DeleteUser_21626048,
                                        base: "/", makeUrl: url_DeleteUser_21626049,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_21626062 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserHierarchyGroup_21626064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "HierarchyGroupId" in path,
        "`HierarchyGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user-hierarchy-groups/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "HierarchyGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUserHierarchyGroup_21626063(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the specified hierarchy group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HierarchyGroupId: JString (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HierarchyGroupId` field"
  var valid_21626065 = path.getOrDefault("HierarchyGroupId")
  valid_21626065 = validateParameter(valid_21626065, JString, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "HierarchyGroupId", valid_21626065
  var valid_21626066 = path.getOrDefault("InstanceId")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "InstanceId", valid_21626066
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
  var valid_21626067 = header.getOrDefault("X-Amz-Date")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Date", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Security-Token", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Algorithm", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Signature")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Signature", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Credential")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Credential", valid_21626073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626074: Call_DescribeUserHierarchyGroup_21626062;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified hierarchy group.
  ## 
  let valid = call_21626074.validator(path, query, header, formData, body, _)
  let scheme = call_21626074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626074.makeUrl(scheme.get, call_21626074.host, call_21626074.base,
                               call_21626074.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626074, uri, valid, _)

proc call*(call_21626075: Call_DescribeUserHierarchyGroup_21626062;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_21626076 = newJObject()
  add(path_21626076, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_21626076, "InstanceId", newJString(InstanceId))
  result = call_21626075.call(path_21626076, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_21626062(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_21626063, base: "/",
    makeUrl: url_DescribeUserHierarchyGroup_21626064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_21626077 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserHierarchyStructure_21626079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user-hierarchy-structure/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUserHierarchyStructure_21626078(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626080 = path.getOrDefault("InstanceId")
  valid_21626080 = validateParameter(valid_21626080, JString, required = true,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "InstanceId", valid_21626080
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
  var valid_21626081 = header.getOrDefault("X-Amz-Date")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Date", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Security-Token", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Algorithm", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Signature")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Signature", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Credential")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Credential", valid_21626087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_DescribeUserHierarchyStructure_21626077;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_DescribeUserHierarchyStructure_21626077;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_21626090 = newJObject()
  add(path_21626090, "InstanceId", newJString(InstanceId))
  result = call_21626089.call(path_21626090, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_21626077(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_21626078, base: "/",
    makeUrl: url_DescribeUserHierarchyStructure_21626079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_21626091 = ref object of OpenApiRestCall_21625435
proc url_GetContactAttributes_21626093(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "InitialContactId" in path,
        "`InitialContactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/attributes/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "InitialContactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetContactAttributes_21626092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InitialContactId: JString (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InitialContactId` field"
  var valid_21626094 = path.getOrDefault("InitialContactId")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "InitialContactId", valid_21626094
  var valid_21626095 = path.getOrDefault("InstanceId")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "InstanceId", valid_21626095
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
  var valid_21626096 = header.getOrDefault("X-Amz-Date")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Date", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Security-Token", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Algorithm", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Signature")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Signature", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Credential")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Credential", valid_21626102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626103: Call_GetContactAttributes_21626091; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  let valid = call_21626103.validator(path, query, header, formData, body, _)
  let scheme = call_21626103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626103.makeUrl(scheme.get, call_21626103.host, call_21626103.base,
                               call_21626103.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626103, uri, valid, _)

proc call*(call_21626104: Call_GetContactAttributes_21626091;
          InitialContactId: string; InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InitialContactId: string (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_21626105 = newJObject()
  add(path_21626105, "InitialContactId", newJString(InitialContactId))
  add(path_21626105, "InstanceId", newJString(InstanceId))
  result = call_21626104.call(path_21626105, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_21626091(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_21626092, base: "/",
    makeUrl: url_GetContactAttributes_21626093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_21626106 = ref object of OpenApiRestCall_21625435
proc url_GetCurrentMetricData_21626108(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/metrics/current/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCurrentMetricData_21626107(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626109 = path.getOrDefault("InstanceId")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "InstanceId", valid_21626109
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626110 = query.getOrDefault("NextToken")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "NextToken", valid_21626110
  var valid_21626111 = query.getOrDefault("MaxResults")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "MaxResults", valid_21626111
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
  var valid_21626112 = header.getOrDefault("X-Amz-Date")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Date", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Security-Token", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Algorithm", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Signature")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Signature", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Credential")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Credential", valid_21626118
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

proc call*(call_21626120: Call_GetCurrentMetricData_21626106; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_21626120.validator(path, query, header, formData, body, _)
  let scheme = call_21626120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626120.makeUrl(scheme.get, call_21626120.host, call_21626120.base,
                               call_21626120.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626120, uri, valid, _)

proc call*(call_21626121: Call_GetCurrentMetricData_21626106; InstanceId: string;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCurrentMetricData
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626122 = newJObject()
  var query_21626123 = newJObject()
  var body_21626124 = newJObject()
  add(path_21626122, "InstanceId", newJString(InstanceId))
  add(query_21626123, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626124 = body
  add(query_21626123, "MaxResults", newJString(MaxResults))
  result = call_21626121.call(path_21626122, query_21626123, nil, nil, body_21626124)

var getCurrentMetricData* = Call_GetCurrentMetricData_21626106(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_21626107, base: "/",
    makeUrl: url_GetCurrentMetricData_21626108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_21626126 = ref object of OpenApiRestCall_21625435
proc url_GetFederationToken_21626128(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user/federate/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFederationToken_21626127(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a token for federation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626129 = path.getOrDefault("InstanceId")
  valid_21626129 = validateParameter(valid_21626129, JString, required = true,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "InstanceId", valid_21626129
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
  var valid_21626130 = header.getOrDefault("X-Amz-Date")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Date", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Security-Token", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Algorithm", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Signature")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Signature", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Credential")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Credential", valid_21626136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626137: Call_GetFederationToken_21626126; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_21626137.validator(path, query, header, formData, body, _)
  let scheme = call_21626137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626137.makeUrl(scheme.get, call_21626137.host, call_21626137.base,
                               call_21626137.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626137, uri, valid, _)

proc call*(call_21626138: Call_GetFederationToken_21626126; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_21626139 = newJObject()
  add(path_21626139, "InstanceId", newJString(InstanceId))
  result = call_21626138.call(path_21626139, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_21626126(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_21626127, base: "/",
    makeUrl: url_GetFederationToken_21626128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_21626140 = ref object of OpenApiRestCall_21625435
proc url_GetMetricData_21626142(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/metrics/historical/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMetricData_21626141(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626143 = path.getOrDefault("InstanceId")
  valid_21626143 = validateParameter(valid_21626143, JString, required = true,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "InstanceId", valid_21626143
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626144 = query.getOrDefault("NextToken")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "NextToken", valid_21626144
  var valid_21626145 = query.getOrDefault("MaxResults")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "MaxResults", valid_21626145
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
  var valid_21626146 = header.getOrDefault("X-Amz-Date")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Date", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Security-Token", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Algorithm", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Signature")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Signature", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Credential")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Credential", valid_21626152
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

proc call*(call_21626154: Call_GetMetricData_21626140; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_21626154.validator(path, query, header, formData, body, _)
  let scheme = call_21626154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626154.makeUrl(scheme.get, call_21626154.host, call_21626154.base,
                               call_21626154.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626154, uri, valid, _)

proc call*(call_21626155: Call_GetMetricData_21626140; InstanceId: string;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMetricData
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626156 = newJObject()
  var query_21626157 = newJObject()
  var body_21626158 = newJObject()
  add(path_21626156, "InstanceId", newJString(InstanceId))
  add(query_21626157, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626158 = body
  add(query_21626157, "MaxResults", newJString(MaxResults))
  result = call_21626155.call(path_21626156, query_21626157, nil, nil, body_21626158)

var getMetricData* = Call_GetMetricData_21626140(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_21626141,
    base: "/", makeUrl: url_GetMetricData_21626142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_21626159 = ref object of OpenApiRestCall_21625435
proc url_ListContactFlows_21626161(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact-flows-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListContactFlows_21626160(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626162 = path.getOrDefault("InstanceId")
  valid_21626162 = validateParameter(valid_21626162, JString, required = true,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "InstanceId", valid_21626162
  result.add "path", section
  ## parameters in `query` object:
  ##   contactFlowTypes: JArray
  ##                   : The type of contact flow.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626163 = query.getOrDefault("contactFlowTypes")
  valid_21626163 = validateParameter(valid_21626163, JArray, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "contactFlowTypes", valid_21626163
  var valid_21626164 = query.getOrDefault("NextToken")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "NextToken", valid_21626164
  var valid_21626165 = query.getOrDefault("maxResults")
  valid_21626165 = validateParameter(valid_21626165, JInt, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "maxResults", valid_21626165
  var valid_21626166 = query.getOrDefault("nextToken")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "nextToken", valid_21626166
  var valid_21626167 = query.getOrDefault("MaxResults")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "MaxResults", valid_21626167
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
  var valid_21626168 = header.getOrDefault("X-Amz-Date")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Date", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Security-Token", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626175: Call_ListContactFlows_21626159; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  let valid = call_21626175.validator(path, query, header, formData, body, _)
  let scheme = call_21626175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626175.makeUrl(scheme.get, call_21626175.host, call_21626175.base,
                               call_21626175.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626175, uri, valid, _)

proc call*(call_21626176: Call_ListContactFlows_21626159; InstanceId: string;
          contactFlowTypes: JsonNode = nil; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listContactFlows
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ##   contactFlowTypes: JArray
  ##                   : The type of contact flow.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626177 = newJObject()
  var query_21626178 = newJObject()
  if contactFlowTypes != nil:
    query_21626178.add "contactFlowTypes", contactFlowTypes
  add(path_21626177, "InstanceId", newJString(InstanceId))
  add(query_21626178, "NextToken", newJString(NextToken))
  add(query_21626178, "maxResults", newJInt(maxResults))
  add(query_21626178, "nextToken", newJString(nextToken))
  add(query_21626178, "MaxResults", newJString(MaxResults))
  result = call_21626176.call(path_21626177, query_21626178, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_21626159(name: "listContactFlows",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_21626160, base: "/",
    makeUrl: url_ListContactFlows_21626161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_21626179 = ref object of OpenApiRestCall_21625435
proc url_ListHoursOfOperations_21626181(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/hours-of-operations-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListHoursOfOperations_21626180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626182 = path.getOrDefault("InstanceId")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "InstanceId", valid_21626182
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626183 = query.getOrDefault("NextToken")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "NextToken", valid_21626183
  var valid_21626184 = query.getOrDefault("maxResults")
  valid_21626184 = validateParameter(valid_21626184, JInt, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "maxResults", valid_21626184
  var valid_21626185 = query.getOrDefault("nextToken")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "nextToken", valid_21626185
  var valid_21626186 = query.getOrDefault("MaxResults")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "MaxResults", valid_21626186
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
  var valid_21626187 = header.getOrDefault("X-Amz-Date")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Date", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Security-Token", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Algorithm", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Signature")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Signature", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Credential")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Credential", valid_21626193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626194: Call_ListHoursOfOperations_21626179;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  let valid = call_21626194.validator(path, query, header, formData, body, _)
  let scheme = call_21626194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626194.makeUrl(scheme.get, call_21626194.host, call_21626194.base,
                               call_21626194.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626194, uri, valid, _)

proc call*(call_21626195: Call_ListHoursOfOperations_21626179; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listHoursOfOperations
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626196 = newJObject()
  var query_21626197 = newJObject()
  add(path_21626196, "InstanceId", newJString(InstanceId))
  add(query_21626197, "NextToken", newJString(NextToken))
  add(query_21626197, "maxResults", newJInt(maxResults))
  add(query_21626197, "nextToken", newJString(nextToken))
  add(query_21626197, "MaxResults", newJString(MaxResults))
  result = call_21626195.call(path_21626196, query_21626197, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_21626179(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_21626180, base: "/",
    makeUrl: url_ListHoursOfOperations_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_21626198 = ref object of OpenApiRestCall_21625435
proc url_ListPhoneNumbers_21626200(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/phone-numbers-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPhoneNumbers_21626199(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626201 = path.getOrDefault("InstanceId")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "InstanceId", valid_21626201
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumberTypes: JArray
  ##                   : The type of phone number.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   phoneNumberCountryCodes: JArray
  ##                          : The ISO country code.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626202 = query.getOrDefault("phoneNumberTypes")
  valid_21626202 = validateParameter(valid_21626202, JArray, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "phoneNumberTypes", valid_21626202
  var valid_21626203 = query.getOrDefault("NextToken")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "NextToken", valid_21626203
  var valid_21626204 = query.getOrDefault("maxResults")
  valid_21626204 = validateParameter(valid_21626204, JInt, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "maxResults", valid_21626204
  var valid_21626205 = query.getOrDefault("nextToken")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "nextToken", valid_21626205
  var valid_21626206 = query.getOrDefault("phoneNumberCountryCodes")
  valid_21626206 = validateParameter(valid_21626206, JArray, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "phoneNumberCountryCodes", valid_21626206
  var valid_21626207 = query.getOrDefault("MaxResults")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "MaxResults", valid_21626207
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
  var valid_21626208 = header.getOrDefault("X-Amz-Date")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Date", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Security-Token", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626215: Call_ListPhoneNumbers_21626198; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  let valid = call_21626215.validator(path, query, header, formData, body, _)
  let scheme = call_21626215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626215.makeUrl(scheme.get, call_21626215.host, call_21626215.base,
                               call_21626215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626215, uri, valid, _)

proc call*(call_21626216: Call_ListPhoneNumbers_21626198; InstanceId: string;
          phoneNumberTypes: JsonNode = nil; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; phoneNumberCountryCodes: JsonNode = nil;
          MaxResults: string = ""): Recallable =
  ## listPhoneNumbers
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ##   phoneNumberTypes: JArray
  ##                   : The type of phone number.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   phoneNumberCountryCodes: JArray
  ##                          : The ISO country code.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626217 = newJObject()
  var query_21626218 = newJObject()
  if phoneNumberTypes != nil:
    query_21626218.add "phoneNumberTypes", phoneNumberTypes
  add(path_21626217, "InstanceId", newJString(InstanceId))
  add(query_21626218, "NextToken", newJString(NextToken))
  add(query_21626218, "maxResults", newJInt(maxResults))
  add(query_21626218, "nextToken", newJString(nextToken))
  if phoneNumberCountryCodes != nil:
    query_21626218.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  add(query_21626218, "MaxResults", newJString(MaxResults))
  result = call_21626216.call(path_21626217, query_21626218, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_21626198(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_21626199, base: "/",
    makeUrl: url_ListPhoneNumbers_21626200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_21626219 = ref object of OpenApiRestCall_21625435
proc url_ListQueues_21626221(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/queues-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListQueues_21626220(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626222 = path.getOrDefault("InstanceId")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "InstanceId", valid_21626222
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   queueTypes: JArray
  ##             : The type of queue.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626223 = query.getOrDefault("NextToken")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "NextToken", valid_21626223
  var valid_21626224 = query.getOrDefault("maxResults")
  valid_21626224 = validateParameter(valid_21626224, JInt, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "maxResults", valid_21626224
  var valid_21626225 = query.getOrDefault("nextToken")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "nextToken", valid_21626225
  var valid_21626226 = query.getOrDefault("queueTypes")
  valid_21626226 = validateParameter(valid_21626226, JArray, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "queueTypes", valid_21626226
  var valid_21626227 = query.getOrDefault("MaxResults")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "MaxResults", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626235: Call_ListQueues_21626219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  let valid = call_21626235.validator(path, query, header, formData, body, _)
  let scheme = call_21626235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626235.makeUrl(scheme.get, call_21626235.host, call_21626235.base,
                               call_21626235.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626235, uri, valid, _)

proc call*(call_21626236: Call_ListQueues_21626219; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          queueTypes: JsonNode = nil; MaxResults: string = ""): Recallable =
  ## listQueues
  ## Provides information about the queues for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   queueTypes: JArray
  ##             : The type of queue.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626237 = newJObject()
  var query_21626238 = newJObject()
  add(path_21626237, "InstanceId", newJString(InstanceId))
  add(query_21626238, "NextToken", newJString(NextToken))
  add(query_21626238, "maxResults", newJInt(maxResults))
  add(query_21626238, "nextToken", newJString(nextToken))
  if queueTypes != nil:
    query_21626238.add "queueTypes", queueTypes
  add(query_21626238, "MaxResults", newJString(MaxResults))
  result = call_21626236.call(path_21626237, query_21626238, nil, nil, nil)

var listQueues* = Call_ListQueues_21626219(name: "listQueues",
                                        meth: HttpMethod.HttpGet,
                                        host: "connect.amazonaws.com",
                                        route: "/queues-summary/{InstanceId}",
                                        validator: validate_ListQueues_21626220,
                                        base: "/", makeUrl: url_ListQueues_21626221,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_21626239 = ref object of OpenApiRestCall_21625435
proc url_ListRoutingProfiles_21626241(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/routing-profiles-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoutingProfiles_21626240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626242 = path.getOrDefault("InstanceId")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "InstanceId", valid_21626242
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626243 = query.getOrDefault("NextToken")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "NextToken", valid_21626243
  var valid_21626244 = query.getOrDefault("maxResults")
  valid_21626244 = validateParameter(valid_21626244, JInt, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "maxResults", valid_21626244
  var valid_21626245 = query.getOrDefault("nextToken")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "nextToken", valid_21626245
  var valid_21626246 = query.getOrDefault("MaxResults")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "MaxResults", valid_21626246
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
  var valid_21626247 = header.getOrDefault("X-Amz-Date")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Date", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Security-Token", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Algorithm", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Signature")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Signature", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Credential")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Credential", valid_21626253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626254: Call_ListRoutingProfiles_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_21626254.validator(path, query, header, formData, body, _)
  let scheme = call_21626254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626254.makeUrl(scheme.get, call_21626254.host, call_21626254.base,
                               call_21626254.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626254, uri, valid, _)

proc call*(call_21626255: Call_ListRoutingProfiles_21626239; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listRoutingProfiles
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626256 = newJObject()
  var query_21626257 = newJObject()
  add(path_21626256, "InstanceId", newJString(InstanceId))
  add(query_21626257, "NextToken", newJString(NextToken))
  add(query_21626257, "maxResults", newJInt(maxResults))
  add(query_21626257, "nextToken", newJString(nextToken))
  add(query_21626257, "MaxResults", newJString(MaxResults))
  result = call_21626255.call(path_21626256, query_21626257, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_21626239(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_21626240, base: "/",
    makeUrl: url_ListRoutingProfiles_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_21626258 = ref object of OpenApiRestCall_21625435
proc url_ListSecurityProfiles_21626260(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/security-profiles-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSecurityProfiles_21626259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626261 = path.getOrDefault("InstanceId")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "InstanceId", valid_21626261
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626262 = query.getOrDefault("NextToken")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "NextToken", valid_21626262
  var valid_21626263 = query.getOrDefault("maxResults")
  valid_21626263 = validateParameter(valid_21626263, JInt, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "maxResults", valid_21626263
  var valid_21626264 = query.getOrDefault("nextToken")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "nextToken", valid_21626264
  var valid_21626265 = query.getOrDefault("MaxResults")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "MaxResults", valid_21626265
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
  var valid_21626266 = header.getOrDefault("X-Amz-Date")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Date", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Security-Token", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Algorithm", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Signature")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Signature", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Credential")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Credential", valid_21626272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626273: Call_ListSecurityProfiles_21626258; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_21626273.validator(path, query, header, formData, body, _)
  let scheme = call_21626273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626273.makeUrl(scheme.get, call_21626273.host, call_21626273.base,
                               call_21626273.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626273, uri, valid, _)

proc call*(call_21626274: Call_ListSecurityProfiles_21626258; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listSecurityProfiles
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626275 = newJObject()
  var query_21626276 = newJObject()
  add(path_21626275, "InstanceId", newJString(InstanceId))
  add(query_21626276, "NextToken", newJString(NextToken))
  add(query_21626276, "maxResults", newJInt(maxResults))
  add(query_21626276, "nextToken", newJString(nextToken))
  add(query_21626276, "MaxResults", newJString(MaxResults))
  result = call_21626274.call(path_21626275, query_21626276, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_21626258(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_21626259, base: "/",
    makeUrl: url_ListSecurityProfiles_21626260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626291 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626293(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626292(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626294 = path.getOrDefault("resourceArn")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "resourceArn", valid_21626294
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
  var valid_21626295 = header.getOrDefault("X-Amz-Date")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Date", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Security-Token", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Algorithm", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Signature")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Signature", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Credential")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Credential", valid_21626301
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

proc call*(call_21626303: Call_TagResource_21626291; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ## 
  let valid = call_21626303.validator(path, query, header, formData, body, _)
  let scheme = call_21626303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626303.makeUrl(scheme.get, call_21626303.host, call_21626303.base,
                               call_21626303.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626303, uri, valid, _)

proc call*(call_21626304: Call_TagResource_21626291; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626305 = newJObject()
  var body_21626306 = newJObject()
  if body != nil:
    body_21626306 = body
  add(path_21626305, "resourceArn", newJString(resourceArn))
  result = call_21626304.call(path_21626305, nil, nil, nil, body_21626306)

var tagResource* = Call_TagResource_21626291(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626292,
    base: "/", makeUrl: url_TagResource_21626293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626277 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626279(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags for the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626280 = path.getOrDefault("resourceArn")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "resourceArn", valid_21626280
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
  var valid_21626281 = header.getOrDefault("X-Amz-Date")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Date", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Security-Token", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Algorithm", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Signature")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Signature", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Credential")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Credential", valid_21626287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626288: Call_ListTagsForResource_21626277; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_21626288.validator(path, query, header, formData, body, _)
  let scheme = call_21626288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626288.makeUrl(scheme.get, call_21626288.host, call_21626288.base,
                               call_21626288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626288, uri, valid, _)

proc call*(call_21626289: Call_ListTagsForResource_21626277; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626290 = newJObject()
  add(path_21626290, "resourceArn", newJString(resourceArn))
  result = call_21626289.call(path_21626290, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626277(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626278, base: "/",
    makeUrl: url_ListTagsForResource_21626279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_21626307 = ref object of OpenApiRestCall_21625435
proc url_ListUserHierarchyGroups_21626309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user-hierarchy-groups-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserHierarchyGroups_21626308(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626310 = path.getOrDefault("InstanceId")
  valid_21626310 = validateParameter(valid_21626310, JString, required = true,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "InstanceId", valid_21626310
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626311 = query.getOrDefault("NextToken")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "NextToken", valid_21626311
  var valid_21626312 = query.getOrDefault("maxResults")
  valid_21626312 = validateParameter(valid_21626312, JInt, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "maxResults", valid_21626312
  var valid_21626313 = query.getOrDefault("nextToken")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "nextToken", valid_21626313
  var valid_21626314 = query.getOrDefault("MaxResults")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "MaxResults", valid_21626314
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
  var valid_21626315 = header.getOrDefault("X-Amz-Date")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Date", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Security-Token", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Algorithm", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Signature")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Signature", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Credential")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Credential", valid_21626321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626322: Call_ListUserHierarchyGroups_21626307;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  let valid = call_21626322.validator(path, query, header, formData, body, _)
  let scheme = call_21626322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626322.makeUrl(scheme.get, call_21626322.host, call_21626322.base,
                               call_21626322.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626322, uri, valid, _)

proc call*(call_21626323: Call_ListUserHierarchyGroups_21626307;
          InstanceId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserHierarchyGroups
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626324 = newJObject()
  var query_21626325 = newJObject()
  add(path_21626324, "InstanceId", newJString(InstanceId))
  add(query_21626325, "NextToken", newJString(NextToken))
  add(query_21626325, "maxResults", newJInt(maxResults))
  add(query_21626325, "nextToken", newJString(nextToken))
  add(query_21626325, "MaxResults", newJString(MaxResults))
  result = call_21626323.call(path_21626324, query_21626325, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_21626307(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_21626308, base: "/",
    makeUrl: url_ListUserHierarchyGroups_21626309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_21626326 = ref object of OpenApiRestCall_21625435
proc url_ListUsers_21626328(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_21626327(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626329 = path.getOrDefault("InstanceId")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "InstanceId", valid_21626329
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626330 = query.getOrDefault("NextToken")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "NextToken", valid_21626330
  var valid_21626331 = query.getOrDefault("maxResults")
  valid_21626331 = validateParameter(valid_21626331, JInt, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "maxResults", valid_21626331
  var valid_21626332 = query.getOrDefault("nextToken")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "nextToken", valid_21626332
  var valid_21626333 = query.getOrDefault("MaxResults")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "MaxResults", valid_21626333
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
  var valid_21626334 = header.getOrDefault("X-Amz-Date")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Date", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Security-Token", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Algorithm", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Signature")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Signature", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Credential")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Credential", valid_21626340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626341: Call_ListUsers_21626326; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_ListUsers_21626326; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listUsers
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626343 = newJObject()
  var query_21626344 = newJObject()
  add(path_21626343, "InstanceId", newJString(InstanceId))
  add(query_21626344, "NextToken", newJString(NextToken))
  add(query_21626344, "maxResults", newJInt(maxResults))
  add(query_21626344, "nextToken", newJString(nextToken))
  add(query_21626344, "MaxResults", newJString(MaxResults))
  result = call_21626342.call(path_21626343, query_21626344, nil, nil, nil)

var listUsers* = Call_ListUsers_21626326(name: "listUsers", meth: HttpMethod.HttpGet,
                                      host: "connect.amazonaws.com",
                                      route: "/users-summary/{InstanceId}",
                                      validator: validate_ListUsers_21626327,
                                      base: "/", makeUrl: url_ListUsers_21626328,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChatContact_21626345 = ref object of OpenApiRestCall_21625435
proc url_StartChatContact_21626347(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChatContact_21626346(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
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
  var valid_21626348 = header.getOrDefault("X-Amz-Date")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Date", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Security-Token", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_StartChatContact_21626345; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_StartChatContact_21626345; body: JsonNode): Recallable =
  ## startChatContact
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var startChatContact* = Call_StartChatContact_21626345(name: "startChatContact",
    meth: HttpMethod.HttpPut, host: "connect.amazonaws.com", route: "/contact/chat",
    validator: validate_StartChatContact_21626346, base: "/",
    makeUrl: url_StartChatContact_21626347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_21626359 = ref object of OpenApiRestCall_21625435
proc url_StartOutboundVoiceContact_21626361(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOutboundVoiceContact_21626360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
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
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Algorithm", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Signature")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Signature", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Credential")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Credential", valid_21626368
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

proc call*(call_21626370: Call_StartOutboundVoiceContact_21626359;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ## 
  let valid = call_21626370.validator(path, query, header, formData, body, _)
  let scheme = call_21626370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626370.makeUrl(scheme.get, call_21626370.host, call_21626370.base,
                               call_21626370.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626370, uri, valid, _)

proc call*(call_21626371: Call_StartOutboundVoiceContact_21626359; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   body: JObject (required)
  var body_21626372 = newJObject()
  if body != nil:
    body_21626372 = body
  result = call_21626371.call(nil, nil, nil, nil, body_21626372)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_21626359(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_21626360, base: "/",
    makeUrl: url_StartOutboundVoiceContact_21626361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_21626373 = ref object of OpenApiRestCall_21625435
proc url_StopContact_21626375(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContact_21626374(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Ends the specified contact.
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
  var valid_21626376 = header.getOrDefault("X-Amz-Date")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Date", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Security-Token", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Algorithm", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Signature")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Signature", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Credential")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Credential", valid_21626382
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

proc call*(call_21626384: Call_StopContact_21626373; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Ends the specified contact.
  ## 
  let valid = call_21626384.validator(path, query, header, formData, body, _)
  let scheme = call_21626384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626384.makeUrl(scheme.get, call_21626384.host, call_21626384.base,
                               call_21626384.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626384, uri, valid, _)

proc call*(call_21626385: Call_StopContact_21626373; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_21626386 = newJObject()
  if body != nil:
    body_21626386 = body
  result = call_21626385.call(nil, nil, nil, nil, body_21626386)

var stopContact* = Call_StopContact_21626373(name: "stopContact",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/contact/stop", validator: validate_StopContact_21626374, base: "/",
    makeUrl: url_StopContact_21626375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626387 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626389(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626388(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes the specified tags from the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_21626390 = path.getOrDefault("resourceArn")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "resourceArn", valid_21626390
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626391 = query.getOrDefault("tagKeys")
  valid_21626391 = validateParameter(valid_21626391, JArray, required = true,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "tagKeys", valid_21626391
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
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Algorithm", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Signature")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Signature", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Credential")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Credential", valid_21626398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626399: Call_UntagResource_21626387; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_21626399.validator(path, query, header, formData, body, _)
  let scheme = call_21626399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626399.makeUrl(scheme.get, call_21626399.host, call_21626399.base,
                               call_21626399.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626399, uri, valid, _)

proc call*(call_21626400: Call_UntagResource_21626387; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_21626401 = newJObject()
  var query_21626402 = newJObject()
  if tagKeys != nil:
    query_21626402.add "tagKeys", tagKeys
  add(path_21626401, "resourceArn", newJString(resourceArn))
  result = call_21626400.call(path_21626401, query_21626402, nil, nil, nil)

var untagResource* = Call_UntagResource_21626387(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626388,
    base: "/", makeUrl: url_UntagResource_21626389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_21626403 = ref object of OpenApiRestCall_21625435
proc url_UpdateContactAttributes_21626405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContactAttributes_21626404(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
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
  var valid_21626406 = header.getOrDefault("X-Amz-Date")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Date", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Security-Token", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Algorithm", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Signature")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Signature", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Credential")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Credential", valid_21626412
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

proc call*(call_21626414: Call_UpdateContactAttributes_21626403;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_21626414.validator(path, query, header, formData, body, _)
  let scheme = call_21626414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626414.makeUrl(scheme.get, call_21626414.host, call_21626414.base,
                               call_21626414.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626414, uri, valid, _)

proc call*(call_21626415: Call_UpdateContactAttributes_21626403; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_21626416 = newJObject()
  if body != nil:
    body_21626416 = body
  result = call_21626415.call(nil, nil, nil, nil, body_21626416)

var updateContactAttributes* = Call_UpdateContactAttributes_21626403(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_21626404, base: "/",
    makeUrl: url_UpdateContactAttributes_21626405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_21626417 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserHierarchy_21626419(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/hierarchy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserHierarchy_21626418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626420 = path.getOrDefault("InstanceId")
  valid_21626420 = validateParameter(valid_21626420, JString, required = true,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "InstanceId", valid_21626420
  var valid_21626421 = path.getOrDefault("UserId")
  valid_21626421 = validateParameter(valid_21626421, JString, required = true,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "UserId", valid_21626421
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
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Algorithm", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Signature")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Signature", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Credential")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Credential", valid_21626428
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

proc call*(call_21626430: Call_UpdateUserHierarchy_21626417; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  let valid = call_21626430.validator(path, query, header, formData, body, _)
  let scheme = call_21626430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626430.makeUrl(scheme.get, call_21626430.host, call_21626430.base,
                               call_21626430.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626430, uri, valid, _)

proc call*(call_21626431: Call_UpdateUserHierarchy_21626417; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626432 = newJObject()
  var body_21626433 = newJObject()
  add(path_21626432, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21626433 = body
  add(path_21626432, "UserId", newJString(UserId))
  result = call_21626431.call(path_21626432, nil, nil, nil, body_21626433)

var updateUserHierarchy* = Call_UpdateUserHierarchy_21626417(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_21626418, base: "/",
    makeUrl: url_UpdateUserHierarchy_21626419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_21626434 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserIdentityInfo_21626436(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/identity-info")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserIdentityInfo_21626435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the identity information for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626437 = path.getOrDefault("InstanceId")
  valid_21626437 = validateParameter(valid_21626437, JString, required = true,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "InstanceId", valid_21626437
  var valid_21626438 = path.getOrDefault("UserId")
  valid_21626438 = validateParameter(valid_21626438, JString, required = true,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "UserId", valid_21626438
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
  var valid_21626439 = header.getOrDefault("X-Amz-Date")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Date", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Security-Token", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Algorithm", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Signature")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Signature", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Credential")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Credential", valid_21626445
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

proc call*(call_21626447: Call_UpdateUserIdentityInfo_21626434;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the identity information for the specified user.
  ## 
  let valid = call_21626447.validator(path, query, header, formData, body, _)
  let scheme = call_21626447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626447.makeUrl(scheme.get, call_21626447.host, call_21626447.base,
                               call_21626447.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626447, uri, valid, _)

proc call*(call_21626448: Call_UpdateUserIdentityInfo_21626434; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626449 = newJObject()
  var body_21626450 = newJObject()
  add(path_21626449, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21626450 = body
  add(path_21626449, "UserId", newJString(UserId))
  result = call_21626448.call(path_21626449, nil, nil, nil, body_21626450)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_21626434(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_21626435, base: "/",
    makeUrl: url_UpdateUserIdentityInfo_21626436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_21626451 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserPhoneConfig_21626453(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/phone-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserPhoneConfig_21626452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the phone configuration settings for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626454 = path.getOrDefault("InstanceId")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "InstanceId", valid_21626454
  var valid_21626455 = path.getOrDefault("UserId")
  valid_21626455 = validateParameter(valid_21626455, JString, required = true,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "UserId", valid_21626455
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
  var valid_21626456 = header.getOrDefault("X-Amz-Date")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Date", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Security-Token", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Algorithm", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Signature")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Signature", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Credential")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Credential", valid_21626462
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

proc call*(call_21626464: Call_UpdateUserPhoneConfig_21626451;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the phone configuration settings for the specified user.
  ## 
  let valid = call_21626464.validator(path, query, header, formData, body, _)
  let scheme = call_21626464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626464.makeUrl(scheme.get, call_21626464.host, call_21626464.base,
                               call_21626464.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626464, uri, valid, _)

proc call*(call_21626465: Call_UpdateUserPhoneConfig_21626451; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626466 = newJObject()
  var body_21626467 = newJObject()
  add(path_21626466, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21626467 = body
  add(path_21626466, "UserId", newJString(UserId))
  result = call_21626465.call(path_21626466, nil, nil, nil, body_21626467)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_21626451(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_21626452, base: "/",
    makeUrl: url_UpdateUserPhoneConfig_21626453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_21626468 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserRoutingProfile_21626470(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/routing-profile")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserRoutingProfile_21626469(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns the specified routing profile to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626471 = path.getOrDefault("InstanceId")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "InstanceId", valid_21626471
  var valid_21626472 = path.getOrDefault("UserId")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "UserId", valid_21626472
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
  var valid_21626473 = header.getOrDefault("X-Amz-Date")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Date", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Security-Token", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Algorithm", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Signature")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Signature", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Credential")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Credential", valid_21626479
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

proc call*(call_21626481: Call_UpdateUserRoutingProfile_21626468;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified routing profile to the specified user.
  ## 
  let valid = call_21626481.validator(path, query, header, formData, body, _)
  let scheme = call_21626481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626481.makeUrl(scheme.get, call_21626481.host, call_21626481.base,
                               call_21626481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626481, uri, valid, _)

proc call*(call_21626482: Call_UpdateUserRoutingProfile_21626468;
          InstanceId: string; body: JsonNode; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626483 = newJObject()
  var body_21626484 = newJObject()
  add(path_21626483, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21626484 = body
  add(path_21626483, "UserId", newJString(UserId))
  result = call_21626482.call(path_21626483, nil, nil, nil, body_21626484)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_21626468(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_21626469, base: "/",
    makeUrl: url_UpdateUserRoutingProfile_21626470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_21626485 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserSecurityProfiles_21626487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  assert "UserId" in path, "`UserId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "UserId"),
               (kind: ConstantSegment, value: "/security-profiles")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserSecurityProfiles_21626486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns the specified security profiles to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_21626488 = path.getOrDefault("InstanceId")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "InstanceId", valid_21626488
  var valid_21626489 = path.getOrDefault("UserId")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "UserId", valid_21626489
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
  var valid_21626490 = header.getOrDefault("X-Amz-Date")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Date", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Security-Token", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Algorithm", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Signature")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Signature", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Credential")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Credential", valid_21626496
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

proc call*(call_21626498: Call_UpdateUserSecurityProfiles_21626485;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified security profiles to the specified user.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_UpdateUserSecurityProfiles_21626485;
          InstanceId: string; body: JsonNode; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_21626500 = newJObject()
  var body_21626501 = newJObject()
  add(path_21626500, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_21626501 = body
  add(path_21626500, "UserId", newJString(UserId))
  result = call_21626499.call(path_21626500, nil, nil, nil, body_21626501)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_21626485(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_21626486, base: "/",
    makeUrl: url_UpdateUserSecurityProfiles_21626487,
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