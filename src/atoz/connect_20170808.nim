
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Connect Service
## version: 2017-08-08
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>The Amazon Connect API Reference provides descriptions, syntax, and usage examples for each of the Amazon Connect actions, data types, parameters, and errors. Amazon Connect is a cloud-based contact center solution that makes it easy to set up and manage a customer contact center and provide reliable customer engagement at any scale.</p> <p>Throttling limits for the Amazon Connect API operations:</p> <p>For the <code>GetMetricData</code> and <code>GetCurrentMetricData</code> operations, a RateLimit of 5 per second, and a BurstLimit of 8 per second.</p> <p>For all other operations, a RateLimit of 2 per second, and a BurstLimit of 5 per second.</p> <p>You can request an increase to the throttling limits by submitting a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase">Amazon Connect service limits increase form</a>. You must be signed in to your AWS account to access the form.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/connect/
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateUser_600774 = ref object of OpenApiRestCall_600437
proc url_CreateUser_600776(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_CreateUser_600775(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new user account in your Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_600902 = path.getOrDefault("InstanceId")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = nil)
  if valid_600902 != nil:
    section.add "InstanceId", valid_600902
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
  var valid_600903 = header.getOrDefault("X-Amz-Date")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Date", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Security-Token")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Security-Token", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Content-Sha256", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Algorithm")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Algorithm", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Signature")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Signature", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-SignedHeaders", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Credential")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Credential", valid_600909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600933: Call_CreateUser_600774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user account in your Amazon Connect instance.
  ## 
  let valid = call_600933.validator(path, query, header, formData, body)
  let scheme = call_600933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600933.url(scheme.get, call_600933.host, call_600933.base,
                         call_600933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600933, url, valid)

proc call*(call_601004: Call_CreateUser_600774; InstanceId: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user account in your Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  var path_601005 = newJObject()
  var body_601007 = newJObject()
  add(path_601005, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601007 = body
  result = call_601004.call(path_601005, nil, nil, nil, body_601007)

var createUser* = Call_CreateUser_600774(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_600775,
                                      base: "/", url: url_CreateUser_600776,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_601046 = ref object of OpenApiRestCall_600437
proc url_DescribeUser_601048(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeUser_601047(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : Unique identifier for the user account to return.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601049 = path.getOrDefault("InstanceId")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = nil)
  if valid_601049 != nil:
    section.add "InstanceId", valid_601049
  var valid_601050 = path.getOrDefault("UserId")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = nil)
  if valid_601050 != nil:
    section.add "UserId", valid_601050
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
  var valid_601051 = header.getOrDefault("X-Amz-Date")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Date", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Security-Token")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Security-Token", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Content-Sha256", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Algorithm")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Algorithm", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Signature")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Signature", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-SignedHeaders", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Credential")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Credential", valid_601057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_DescribeUser_601046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_DescribeUser_601046; InstanceId: string; UserId: string): Recallable =
  ## describeUser
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : Unique identifier for the user account to return.
  var path_601060 = newJObject()
  add(path_601060, "InstanceId", newJString(InstanceId))
  add(path_601060, "UserId", newJString(UserId))
  result = call_601059.call(path_601060, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_601046(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_601047,
    base: "/", url: url_DescribeUser_601048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_601061 = ref object of OpenApiRestCall_600437
proc url_DeleteUser_601063(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_DeleteUser_601062(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user account from Amazon Connect.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The unique identifier of the user to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601064 = path.getOrDefault("InstanceId")
  valid_601064 = validateParameter(valid_601064, JString, required = true,
                                 default = nil)
  if valid_601064 != nil:
    section.add "InstanceId", valid_601064
  var valid_601065 = path.getOrDefault("UserId")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = nil)
  if valid_601065 != nil:
    section.add "UserId", valid_601065
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
  var valid_601066 = header.getOrDefault("X-Amz-Date")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Date", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Security-Token")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Security-Token", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Content-Sha256", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Algorithm")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Algorithm", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Signature")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Signature", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-SignedHeaders", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Credential")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Credential", valid_601072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601073: Call_DeleteUser_601061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from Amazon Connect.
  ## 
  let valid = call_601073.validator(path, query, header, formData, body)
  let scheme = call_601073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601073.url(scheme.get, call_601073.host, call_601073.base,
                         call_601073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601073, url, valid)

proc call*(call_601074: Call_DeleteUser_601061; InstanceId: string; UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from Amazon Connect.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : The unique identifier of the user to delete.
  var path_601075 = newJObject()
  add(path_601075, "InstanceId", newJString(InstanceId))
  add(path_601075, "UserId", newJString(UserId))
  result = call_601074.call(path_601075, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_601061(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_601062,
                                      base: "/", url: url_DeleteUser_601063,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_601076 = ref object of OpenApiRestCall_600437
proc url_DescribeUserHierarchyGroup_601078(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeUserHierarchyGroup_601077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HierarchyGroupId: JString (required)
  ##                   : The identifier for the hierarchy group to return.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HierarchyGroupId` field"
  var valid_601079 = path.getOrDefault("HierarchyGroupId")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = nil)
  if valid_601079 != nil:
    section.add "HierarchyGroupId", valid_601079
  var valid_601080 = path.getOrDefault("InstanceId")
  valid_601080 = validateParameter(valid_601080, JString, required = true,
                                 default = nil)
  if valid_601080 != nil:
    section.add "InstanceId", valid_601080
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
  var valid_601081 = header.getOrDefault("X-Amz-Date")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Date", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Security-Token")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Security-Token", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Content-Sha256", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Algorithm")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Algorithm", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Signature")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Signature", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-SignedHeaders", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Credential")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Credential", valid_601087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601088: Call_DescribeUserHierarchyGroup_601076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ## 
  let valid = call_601088.validator(path, query, header, formData, body)
  let scheme = call_601088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601088.url(scheme.get, call_601088.host, call_601088.base,
                         call_601088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601088, url, valid)

proc call*(call_601089: Call_DescribeUserHierarchyGroup_601076;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier for the hierarchy group to return.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_601090 = newJObject()
  add(path_601090, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_601090, "InstanceId", newJString(InstanceId))
  result = call_601089.call(path_601090, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_601076(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_601077, base: "/",
    url: url_DescribeUserHierarchyGroup_601078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_601091 = ref object of OpenApiRestCall_600437
proc url_DescribeUserHierarchyStructure_601093(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeUserHierarchyStructure_601092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601094 = path.getOrDefault("InstanceId")
  valid_601094 = validateParameter(valid_601094, JString, required = true,
                                 default = nil)
  if valid_601094 != nil:
    section.add "InstanceId", valid_601094
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
  var valid_601095 = header.getOrDefault("X-Amz-Date")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Date", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Security-Token")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Security-Token", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Content-Sha256", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Algorithm")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Algorithm", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Signature")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Signature", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-SignedHeaders", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Credential")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Credential", valid_601101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601102: Call_DescribeUserHierarchyStructure_601091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ## 
  let valid = call_601102.validator(path, query, header, formData, body)
  let scheme = call_601102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601102.url(scheme.get, call_601102.host, call_601102.base,
                         call_601102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601102, url, valid)

proc call*(call_601103: Call_DescribeUserHierarchyStructure_601091;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_601104 = newJObject()
  add(path_601104, "InstanceId", newJString(InstanceId))
  result = call_601103.call(path_601104, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_601091(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_601092, base: "/",
    url: url_DescribeUserHierarchyStructure_601093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_601105 = ref object of OpenApiRestCall_600437
proc url_GetContactAttributes_601107(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetContactAttributes_601106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the contact attributes associated with a contact.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InitialContactId: JString (required)
  ##                   : The ID for the initial contact in Amazon Connect associated with the attributes to update.
  ##   InstanceId: JString (required)
  ##             : The instance ID for the instance from which to retrieve contact attributes.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InitialContactId` field"
  var valid_601108 = path.getOrDefault("InitialContactId")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = nil)
  if valid_601108 != nil:
    section.add "InitialContactId", valid_601108
  var valid_601109 = path.getOrDefault("InstanceId")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "InstanceId", valid_601109
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
  var valid_601110 = header.getOrDefault("X-Amz-Date")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Date", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Security-Token")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Security-Token", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Content-Sha256", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Algorithm")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Algorithm", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Signature")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Signature", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-SignedHeaders", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Credential")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Credential", valid_601116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601117: Call_GetContactAttributes_601105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes associated with a contact.
  ## 
  let valid = call_601117.validator(path, query, header, formData, body)
  let scheme = call_601117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601117.url(scheme.get, call_601117.host, call_601117.base,
                         call_601117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601117, url, valid)

proc call*(call_601118: Call_GetContactAttributes_601105; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes associated with a contact.
  ##   InitialContactId: string (required)
  ##                   : The ID for the initial contact in Amazon Connect associated with the attributes to update.
  ##   InstanceId: string (required)
  ##             : The instance ID for the instance from which to retrieve contact attributes.
  var path_601119 = newJObject()
  add(path_601119, "InitialContactId", newJString(InitialContactId))
  add(path_601119, "InstanceId", newJString(InstanceId))
  result = call_601118.call(path_601119, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_601105(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_601106, base: "/",
    url: url_GetContactAttributes_601107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_601120 = ref object of OpenApiRestCall_600437
proc url_GetCurrentMetricData_601122(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetCurrentMetricData_601121(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601123 = path.getOrDefault("InstanceId")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "InstanceId", valid_601123
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601124 = query.getOrDefault("NextToken")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "NextToken", valid_601124
  var valid_601125 = query.getOrDefault("MaxResults")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "MaxResults", valid_601125
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
  var valid_601126 = header.getOrDefault("X-Amz-Date")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Date", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Security-Token")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Security-Token", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Content-Sha256", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Algorithm")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Algorithm", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Signature")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Signature", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-SignedHeaders", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Credential")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Credential", valid_601132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_GetCurrentMetricData_601120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ## 
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601134, url, valid)

proc call*(call_601135: Call_GetCurrentMetricData_601120; InstanceId: string;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getCurrentMetricData
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_601136 = newJObject()
  var query_601137 = newJObject()
  var body_601138 = newJObject()
  add(path_601136, "InstanceId", newJString(InstanceId))
  add(query_601137, "NextToken", newJString(NextToken))
  if body != nil:
    body_601138 = body
  add(query_601137, "MaxResults", newJString(MaxResults))
  result = call_601135.call(path_601136, query_601137, nil, nil, body_601138)

var getCurrentMetricData* = Call_GetCurrentMetricData_601120(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_601121, base: "/",
    url: url_GetCurrentMetricData_601122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_601139 = ref object of OpenApiRestCall_600437
proc url_GetFederationToken_601141(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetFederationToken_601140(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves a token for federation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601142 = path.getOrDefault("InstanceId")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "InstanceId", valid_601142
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
  var valid_601143 = header.getOrDefault("X-Amz-Date")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Date", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Security-Token")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Security-Token", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Content-Sha256", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Algorithm")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Algorithm", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Signature")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Signature", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-SignedHeaders", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Credential")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Credential", valid_601149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601150: Call_GetFederationToken_601139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_601150.validator(path, query, header, formData, body)
  let scheme = call_601150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601150.url(scheme.get, call_601150.host, call_601150.base,
                         call_601150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601150, url, valid)

proc call*(call_601151: Call_GetFederationToken_601139; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_601152 = newJObject()
  add(path_601152, "InstanceId", newJString(InstanceId))
  result = call_601151.call(path_601152, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_601139(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_601140, base: "/",
    url: url_GetFederationToken_601141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_601153 = ref object of OpenApiRestCall_600437
proc url_GetMetricData_601155(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetMetricData_601154(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601156 = path.getOrDefault("InstanceId")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "InstanceId", valid_601156
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601157 = query.getOrDefault("NextToken")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "NextToken", valid_601157
  var valid_601158 = query.getOrDefault("MaxResults")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "MaxResults", valid_601158
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
  var valid_601159 = header.getOrDefault("X-Amz-Date")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Date", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Security-Token")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Security-Token", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Content-Sha256", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Algorithm")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Algorithm", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Signature")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Signature", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-SignedHeaders", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Credential")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Credential", valid_601165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_GetMetricData_601153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_GetMetricData_601153; InstanceId: string;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getMetricData
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_601169 = newJObject()
  var query_601170 = newJObject()
  var body_601171 = newJObject()
  add(path_601169, "InstanceId", newJString(InstanceId))
  add(query_601170, "NextToken", newJString(NextToken))
  if body != nil:
    body_601171 = body
  add(query_601170, "MaxResults", newJString(MaxResults))
  result = call_601168.call(path_601169, query_601170, nil, nil, body_601171)

var getMetricData* = Call_GetMetricData_601153(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_601154,
    base: "/", url: url_GetMetricData_601155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_601172 = ref object of OpenApiRestCall_600437
proc url_ListRoutingProfiles_601174(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListRoutingProfiles_601173(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601175 = path.getOrDefault("InstanceId")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = nil)
  if valid_601175 != nil:
    section.add "InstanceId", valid_601175
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_601176 = query.getOrDefault("maxResults")
  valid_601176 = validateParameter(valid_601176, JInt, required = false, default = nil)
  if valid_601176 != nil:
    section.add "maxResults", valid_601176
  var valid_601177 = query.getOrDefault("nextToken")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "nextToken", valid_601177
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
  var valid_601178 = header.getOrDefault("X-Amz-Date")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Date", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Security-Token")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Security-Token", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Content-Sha256", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Algorithm")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Algorithm", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Signature")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Signature", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-SignedHeaders", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Credential")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Credential", valid_601184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601185: Call_ListRoutingProfiles_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ## 
  let valid = call_601185.validator(path, query, header, formData, body)
  let scheme = call_601185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601185.url(scheme.get, call_601185.host, call_601185.base,
                         call_601185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601185, url, valid)

proc call*(call_601186: Call_ListRoutingProfiles_601172; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRoutingProfiles
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_601187 = newJObject()
  var query_601188 = newJObject()
  add(path_601187, "InstanceId", newJString(InstanceId))
  add(query_601188, "maxResults", newJInt(maxResults))
  add(query_601188, "nextToken", newJString(nextToken))
  result = call_601186.call(path_601187, query_601188, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_601172(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_601173, base: "/",
    url: url_ListRoutingProfiles_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_601189 = ref object of OpenApiRestCall_600437
proc url_ListSecurityProfiles_601191(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListSecurityProfiles_601190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601192 = path.getOrDefault("InstanceId")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "InstanceId", valid_601192
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of security profiles to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_601193 = query.getOrDefault("maxResults")
  valid_601193 = validateParameter(valid_601193, JInt, required = false, default = nil)
  if valid_601193 != nil:
    section.add "maxResults", valid_601193
  var valid_601194 = query.getOrDefault("nextToken")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "nextToken", valid_601194
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
  var valid_601195 = header.getOrDefault("X-Amz-Date")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Date", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Security-Token")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Security-Token", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_ListSecurityProfiles_601189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_ListSecurityProfiles_601189; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listSecurityProfiles
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of security profiles to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_601204 = newJObject()
  var query_601205 = newJObject()
  add(path_601204, "InstanceId", newJString(InstanceId))
  add(query_601205, "maxResults", newJInt(maxResults))
  add(query_601205, "nextToken", newJString(nextToken))
  result = call_601203.call(path_601204, query_601205, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_601189(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_601190, base: "/",
    url: url_ListSecurityProfiles_601191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_601206 = ref object of OpenApiRestCall_600437
proc url_ListUserHierarchyGroups_601208(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_ListUserHierarchyGroups_601207(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601209 = path.getOrDefault("InstanceId")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "InstanceId", valid_601209
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_601210 = query.getOrDefault("maxResults")
  valid_601210 = validateParameter(valid_601210, JInt, required = false, default = nil)
  if valid_601210 != nil:
    section.add "maxResults", valid_601210
  var valid_601211 = query.getOrDefault("nextToken")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "nextToken", valid_601211
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
  if body != nil:
    result.add "body", body

proc call*(call_601219: Call_ListUserHierarchyGroups_601206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ## 
  let valid = call_601219.validator(path, query, header, formData, body)
  let scheme = call_601219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601219.url(scheme.get, call_601219.host, call_601219.base,
                         call_601219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601219, url, valid)

proc call*(call_601220: Call_ListUserHierarchyGroups_601206; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUserHierarchyGroups
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_601221 = newJObject()
  var query_601222 = newJObject()
  add(path_601221, "InstanceId", newJString(InstanceId))
  add(query_601222, "maxResults", newJInt(maxResults))
  add(query_601222, "nextToken", newJString(nextToken))
  result = call_601220.call(path_601221, query_601222, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_601206(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_601207, base: "/",
    url: url_ListUserHierarchyGroups_601208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601223 = ref object of OpenApiRestCall_600437
proc url_ListUsers_601225(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  result.path = base & hydrated.get

proc validate_ListUsers_601224(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601226 = path.getOrDefault("InstanceId")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = nil)
  if valid_601226 != nil:
    section.add "InstanceId", valid_601226
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_601227 = query.getOrDefault("maxResults")
  valid_601227 = validateParameter(valid_601227, JInt, required = false, default = nil)
  if valid_601227 != nil:
    section.add "maxResults", valid_601227
  var valid_601228 = query.getOrDefault("nextToken")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "nextToken", valid_601228
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
  var valid_601229 = header.getOrDefault("X-Amz-Date")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Date", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Security-Token")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Security-Token", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Content-Sha256", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Algorithm")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Algorithm", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Signature")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Signature", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-SignedHeaders", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Credential")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Credential", valid_601235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_ListUsers_601223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_ListUsers_601223; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_601238 = newJObject()
  var query_601239 = newJObject()
  add(path_601238, "InstanceId", newJString(InstanceId))
  add(query_601239, "maxResults", newJInt(maxResults))
  add(query_601239, "nextToken", newJString(nextToken))
  result = call_601237.call(path_601238, query_601239, nil, nil, nil)

var listUsers* = Call_ListUsers_601223(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_601224,
                                    base: "/", url: url_ListUsers_601225,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_601240 = ref object of OpenApiRestCall_600437
proc url_StartOutboundVoiceContact_601242(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartOutboundVoiceContact_601241(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
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
  var valid_601243 = header.getOrDefault("X-Amz-Date")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Date", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Security-Token")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Security-Token", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_StartOutboundVoiceContact_601240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_StartOutboundVoiceContact_601240; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ##   body: JObject (required)
  var body_601253 = newJObject()
  if body != nil:
    body_601253 = body
  result = call_601252.call(nil, nil, nil, nil, body_601253)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_601240(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_601241, base: "/",
    url: url_StartOutboundVoiceContact_601242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_601254 = ref object of OpenApiRestCall_600437
proc url_StopContact_601256(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopContact_601255(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
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
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Content-Sha256", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Algorithm")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Algorithm", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Signature")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Signature", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-SignedHeaders", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Credential")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Credential", valid_601263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601265: Call_StopContact_601254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ## 
  let valid = call_601265.validator(path, query, header, formData, body)
  let scheme = call_601265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601265.url(scheme.get, call_601265.host, call_601265.base,
                         call_601265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601265, url, valid)

proc call*(call_601266: Call_StopContact_601254; body: JsonNode): Recallable =
  ## stopContact
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ##   body: JObject (required)
  var body_601267 = newJObject()
  if body != nil:
    body_601267 = body
  result = call_601266.call(nil, nil, nil, nil, body_601267)

var stopContact* = Call_StopContact_601254(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_601255,
                                        base: "/", url: url_StopContact_601256,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_601268 = ref object of OpenApiRestCall_600437
proc url_UpdateContactAttributes_601270(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContactAttributes_601269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
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
  var valid_601271 = header.getOrDefault("X-Amz-Date")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Date", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Security-Token")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Security-Token", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Content-Sha256", valid_601273
  var valid_601274 = header.getOrDefault("X-Amz-Algorithm")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Algorithm", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Signature")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Signature", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-SignedHeaders", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Credential")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Credential", valid_601277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601279: Call_UpdateContactAttributes_601268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_601279.validator(path, query, header, formData, body)
  let scheme = call_601279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601279.url(scheme.get, call_601279.host, call_601279.base,
                         call_601279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601279, url, valid)

proc call*(call_601280: Call_UpdateContactAttributes_601268; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_601281 = newJObject()
  if body != nil:
    body_601281 = body
  result = call_601280.call(nil, nil, nil, nil, body_601281)

var updateContactAttributes* = Call_UpdateContactAttributes_601268(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_601269, base: "/",
    url: url_UpdateContactAttributes_601270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_601282 = ref object of OpenApiRestCall_600437
proc url_UpdateUserHierarchy_601284(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateUserHierarchy_601283(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Assigns the specified hierarchy group to the user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601285 = path.getOrDefault("InstanceId")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "InstanceId", valid_601285
  var valid_601286 = path.getOrDefault("UserId")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "UserId", valid_601286
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
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Content-Sha256", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Algorithm")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Algorithm", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Signature")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Signature", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-SignedHeaders", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Credential")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Credential", valid_601293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_UpdateUserHierarchy_601282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the user.
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601295, url, valid)

proc call*(call_601296: Call_UpdateUserHierarchy_601282; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  var path_601297 = newJObject()
  var body_601298 = newJObject()
  add(path_601297, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601298 = body
  add(path_601297, "UserId", newJString(UserId))
  result = call_601296.call(path_601297, nil, nil, nil, body_601298)

var updateUserHierarchy* = Call_UpdateUserHierarchy_601282(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_601283, base: "/",
    url: url_UpdateUserHierarchy_601284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_601299 = ref object of OpenApiRestCall_600437
proc url_UpdateUserIdentityInfo_601301(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/identity-info")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUserIdentityInfo_601300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The identifier for the user account to update identity information for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601302 = path.getOrDefault("InstanceId")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = nil)
  if valid_601302 != nil:
    section.add "InstanceId", valid_601302
  var valid_601303 = path.getOrDefault("UserId")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = nil)
  if valid_601303 != nil:
    section.add "UserId", valid_601303
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
  var valid_601304 = header.getOrDefault("X-Amz-Date")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Date", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Security-Token")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Security-Token", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Content-Sha256", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Algorithm")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Algorithm", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Signature")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Signature", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-SignedHeaders", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Credential")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Credential", valid_601310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601312: Call_UpdateUserIdentityInfo_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  let valid = call_601312.validator(path, query, header, formData, body)
  let scheme = call_601312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601312.url(scheme.get, call_601312.host, call_601312.base,
                         call_601312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601312, url, valid)

proc call*(call_601313: Call_UpdateUserIdentityInfo_601299; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to update identity information for.
  var path_601314 = newJObject()
  var body_601315 = newJObject()
  add(path_601314, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601315 = body
  add(path_601314, "UserId", newJString(UserId))
  result = call_601313.call(path_601314, nil, nil, nil, body_601315)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_601299(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_601300, base: "/",
    url: url_UpdateUserIdentityInfo_601301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_601316 = ref object of OpenApiRestCall_600437
proc url_UpdateUserPhoneConfig_601318(protocol: Scheme; host: string; base: string;
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
               (kind: ConstantSegment, value: "/phone-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUserPhoneConfig_601317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The identifier for the user account to change phone settings for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601319 = path.getOrDefault("InstanceId")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "InstanceId", valid_601319
  var valid_601320 = path.getOrDefault("UserId")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "UserId", valid_601320
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
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601329: Call_UpdateUserPhoneConfig_601316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  let valid = call_601329.validator(path, query, header, formData, body)
  let scheme = call_601329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601329.url(scheme.get, call_601329.host, call_601329.base,
                         call_601329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601329, url, valid)

proc call*(call_601330: Call_UpdateUserPhoneConfig_601316; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to change phone settings for.
  var path_601331 = newJObject()
  var body_601332 = newJObject()
  add(path_601331, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601332 = body
  add(path_601331, "UserId", newJString(UserId))
  result = call_601330.call(path_601331, nil, nil, nil, body_601332)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_601316(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_601317, base: "/",
    url: url_UpdateUserPhoneConfig_601318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_601333 = ref object of OpenApiRestCall_600437
proc url_UpdateUserRoutingProfile_601335(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/routing-profile")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUserRoutingProfile_601334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns the specified routing profile to a user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The identifier for the user account to assign the routing profile to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601336 = path.getOrDefault("InstanceId")
  valid_601336 = validateParameter(valid_601336, JString, required = true,
                                 default = nil)
  if valid_601336 != nil:
    section.add "InstanceId", valid_601336
  var valid_601337 = path.getOrDefault("UserId")
  valid_601337 = validateParameter(valid_601337, JString, required = true,
                                 default = nil)
  if valid_601337 != nil:
    section.add "UserId", valid_601337
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
  var valid_601338 = header.getOrDefault("X-Amz-Date")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Date", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Security-Token")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Security-Token", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Content-Sha256", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Algorithm")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Algorithm", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Signature")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Signature", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-SignedHeaders", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Credential")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Credential", valid_601344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601346: Call_UpdateUserRoutingProfile_601333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to a user.
  ## 
  let valid = call_601346.validator(path, query, header, formData, body)
  let scheme = call_601346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601346.url(scheme.get, call_601346.host, call_601346.base,
                         call_601346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601346, url, valid)

proc call*(call_601347: Call_UpdateUserRoutingProfile_601333; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to a user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to assign the routing profile to.
  var path_601348 = newJObject()
  var body_601349 = newJObject()
  add(path_601348, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601349 = body
  add(path_601348, "UserId", newJString(UserId))
  result = call_601347.call(path_601348, nil, nil, nil, body_601349)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_601333(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_601334, base: "/",
    url: url_UpdateUserRoutingProfile_601335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_601350 = ref object of OpenApiRestCall_600437
proc url_UpdateUserSecurityProfiles_601352(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateUserSecurityProfiles_601351(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the security profiles assigned to the user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: JString (required)
  ##         : The identifier of the user account to assign the security profiles.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceId` field"
  var valid_601353 = path.getOrDefault("InstanceId")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = nil)
  if valid_601353 != nil:
    section.add "InstanceId", valid_601353
  var valid_601354 = path.getOrDefault("UserId")
  valid_601354 = validateParameter(valid_601354, JString, required = true,
                                 default = nil)
  if valid_601354 != nil:
    section.add "UserId", valid_601354
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
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Content-Sha256", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Algorithm")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Algorithm", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Signature")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Signature", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-SignedHeaders", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Credential")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Credential", valid_601361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601363: Call_UpdateUserSecurityProfiles_601350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the security profiles assigned to the user.
  ## 
  let valid = call_601363.validator(path, query, header, formData, body)
  let scheme = call_601363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601363.url(scheme.get, call_601363.host, call_601363.base,
                         call_601363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601363, url, valid)

proc call*(call_601364: Call_UpdateUserSecurityProfiles_601350; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Updates the security profiles assigned to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the security profiles.
  var path_601365 = newJObject()
  var body_601366 = newJObject()
  add(path_601365, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_601366 = body
  add(path_601365, "UserId", newJString(UserId))
  result = call_601364.call(path_601365, nil, nil, nil, body_601366)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_601350(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_601351, base: "/",
    url: url_UpdateUserSecurityProfiles_601352,
    schemes: {Scheme.Https, Scheme.Http})
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
