
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_CreateUser_593774 = ref object of OpenApiRestCall_593437
proc url_CreateUser_593776(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593902 = path.getOrDefault("InstanceId")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "InstanceId", valid_593902
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
  var valid_593903 = header.getOrDefault("X-Amz-Date")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "X-Amz-Date", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Security-Token")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Security-Token", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Algorithm")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Algorithm", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Signature")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Signature", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-SignedHeaders", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Credential")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Credential", valid_593909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593933: Call_CreateUser_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user account in your Amazon Connect instance.
  ## 
  let valid = call_593933.validator(path, query, header, formData, body)
  let scheme = call_593933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593933.url(scheme.get, call_593933.host, call_593933.base,
                         call_593933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593933, url, valid)

proc call*(call_594004: Call_CreateUser_593774; InstanceId: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user account in your Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  var path_594005 = newJObject()
  var body_594007 = newJObject()
  add(path_594005, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594007 = body
  result = call_594004.call(path_594005, nil, nil, nil, body_594007)

var createUser* = Call_CreateUser_593774(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_593775,
                                      base: "/", url: url_CreateUser_593776,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_594046 = ref object of OpenApiRestCall_593437
proc url_DescribeUser_594048(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_594047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594049 = path.getOrDefault("InstanceId")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = nil)
  if valid_594049 != nil:
    section.add "InstanceId", valid_594049
  var valid_594050 = path.getOrDefault("UserId")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "UserId", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594058: Call_DescribeUser_594046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  let valid = call_594058.validator(path, query, header, formData, body)
  let scheme = call_594058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594058.url(scheme.get, call_594058.host, call_594058.base,
                         call_594058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594058, url, valid)

proc call*(call_594059: Call_DescribeUser_594046; InstanceId: string; UserId: string): Recallable =
  ## describeUser
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : Unique identifier for the user account to return.
  var path_594060 = newJObject()
  add(path_594060, "InstanceId", newJString(InstanceId))
  add(path_594060, "UserId", newJString(UserId))
  result = call_594059.call(path_594060, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_594046(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_594047,
    base: "/", url: url_DescribeUser_594048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_594061 = ref object of OpenApiRestCall_593437
proc url_DeleteUser_594063(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_594062(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594064 = path.getOrDefault("InstanceId")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "InstanceId", valid_594064
  var valid_594065 = path.getOrDefault("UserId")
  valid_594065 = validateParameter(valid_594065, JString, required = true,
                                 default = nil)
  if valid_594065 != nil:
    section.add "UserId", valid_594065
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
  var valid_594066 = header.getOrDefault("X-Amz-Date")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Date", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Security-Token")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Security-Token", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Content-Sha256", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Algorithm")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Algorithm", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Signature")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Signature", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-SignedHeaders", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594073: Call_DeleteUser_594061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from Amazon Connect.
  ## 
  let valid = call_594073.validator(path, query, header, formData, body)
  let scheme = call_594073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594073.url(scheme.get, call_594073.host, call_594073.base,
                         call_594073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594073, url, valid)

proc call*(call_594074: Call_DeleteUser_594061; InstanceId: string; UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from Amazon Connect.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : The unique identifier of the user to delete.
  var path_594075 = newJObject()
  add(path_594075, "InstanceId", newJString(InstanceId))
  add(path_594075, "UserId", newJString(UserId))
  result = call_594074.call(path_594075, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_594061(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_594062,
                                      base: "/", url: url_DeleteUser_594063,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_594076 = ref object of OpenApiRestCall_593437
proc url_DescribeUserHierarchyGroup_594078(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_594077(path: JsonNode; query: JsonNode;
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
  var valid_594079 = path.getOrDefault("HierarchyGroupId")
  valid_594079 = validateParameter(valid_594079, JString, required = true,
                                 default = nil)
  if valid_594079 != nil:
    section.add "HierarchyGroupId", valid_594079
  var valid_594080 = path.getOrDefault("InstanceId")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = nil)
  if valid_594080 != nil:
    section.add "InstanceId", valid_594080
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
  var valid_594081 = header.getOrDefault("X-Amz-Date")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Date", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Security-Token")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Security-Token", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Content-Sha256", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Algorithm")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Algorithm", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Signature")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Signature", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-SignedHeaders", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Credential")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Credential", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594088: Call_DescribeUserHierarchyGroup_594076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ## 
  let valid = call_594088.validator(path, query, header, formData, body)
  let scheme = call_594088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594088.url(scheme.get, call_594088.host, call_594088.base,
                         call_594088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594088, url, valid)

proc call*(call_594089: Call_DescribeUserHierarchyGroup_594076;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier for the hierarchy group to return.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_594090 = newJObject()
  add(path_594090, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_594090, "InstanceId", newJString(InstanceId))
  result = call_594089.call(path_594090, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_594076(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_594077, base: "/",
    url: url_DescribeUserHierarchyGroup_594078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_594091 = ref object of OpenApiRestCall_593437
proc url_DescribeUserHierarchyStructure_594093(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyStructure_594092(path: JsonNode;
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
  var valid_594094 = path.getOrDefault("InstanceId")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "InstanceId", valid_594094
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
  var valid_594095 = header.getOrDefault("X-Amz-Date")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Date", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Security-Token")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Security-Token", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Content-Sha256", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Algorithm")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Algorithm", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Signature")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Signature", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-SignedHeaders", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Credential")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Credential", valid_594101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594102: Call_DescribeUserHierarchyStructure_594091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ## 
  let valid = call_594102.validator(path, query, header, formData, body)
  let scheme = call_594102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594102.url(scheme.get, call_594102.host, call_594102.base,
                         call_594102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594102, url, valid)

proc call*(call_594103: Call_DescribeUserHierarchyStructure_594091;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_594104 = newJObject()
  add(path_594104, "InstanceId", newJString(InstanceId))
  result = call_594103.call(path_594104, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_594091(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_594092, base: "/",
    url: url_DescribeUserHierarchyStructure_594093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_594105 = ref object of OpenApiRestCall_593437
proc url_GetContactAttributes_594107(protocol: Scheme; host: string; base: string;
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

proc validate_GetContactAttributes_594106(path: JsonNode; query: JsonNode;
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
  var valid_594108 = path.getOrDefault("InitialContactId")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "InitialContactId", valid_594108
  var valid_594109 = path.getOrDefault("InstanceId")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = nil)
  if valid_594109 != nil:
    section.add "InstanceId", valid_594109
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
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Security-Token")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Security-Token", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Content-Sha256", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Signature")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Signature", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Credential")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Credential", valid_594116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_GetContactAttributes_594105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes associated with a contact.
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_GetContactAttributes_594105; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes associated with a contact.
  ##   InitialContactId: string (required)
  ##                   : The ID for the initial contact in Amazon Connect associated with the attributes to update.
  ##   InstanceId: string (required)
  ##             : The instance ID for the instance from which to retrieve contact attributes.
  var path_594119 = newJObject()
  add(path_594119, "InitialContactId", newJString(InitialContactId))
  add(path_594119, "InstanceId", newJString(InstanceId))
  result = call_594118.call(path_594119, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_594105(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_594106, base: "/",
    url: url_GetContactAttributes_594107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_594120 = ref object of OpenApiRestCall_593437
proc url_GetCurrentMetricData_594122(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentMetricData_594121(path: JsonNode; query: JsonNode;
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
  var valid_594123 = path.getOrDefault("InstanceId")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = nil)
  if valid_594123 != nil:
    section.add "InstanceId", valid_594123
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594124 = query.getOrDefault("NextToken")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "NextToken", valid_594124
  var valid_594125 = query.getOrDefault("MaxResults")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "MaxResults", valid_594125
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
  var valid_594126 = header.getOrDefault("X-Amz-Date")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Date", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Security-Token")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Security-Token", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Content-Sha256", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Algorithm")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Algorithm", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Signature")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Signature", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-SignedHeaders", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Credential")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Credential", valid_594132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_GetCurrentMetricData_594120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_GetCurrentMetricData_594120; InstanceId: string;
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
  var path_594136 = newJObject()
  var query_594137 = newJObject()
  var body_594138 = newJObject()
  add(path_594136, "InstanceId", newJString(InstanceId))
  add(query_594137, "NextToken", newJString(NextToken))
  if body != nil:
    body_594138 = body
  add(query_594137, "MaxResults", newJString(MaxResults))
  result = call_594135.call(path_594136, query_594137, nil, nil, body_594138)

var getCurrentMetricData* = Call_GetCurrentMetricData_594120(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_594121, base: "/",
    url: url_GetCurrentMetricData_594122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_594139 = ref object of OpenApiRestCall_593437
proc url_GetFederationToken_594141(protocol: Scheme; host: string; base: string;
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

proc validate_GetFederationToken_594140(path: JsonNode; query: JsonNode;
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
  var valid_594142 = path.getOrDefault("InstanceId")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "InstanceId", valid_594142
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
  var valid_594143 = header.getOrDefault("X-Amz-Date")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Date", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Security-Token")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Security-Token", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Algorithm")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Algorithm", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Signature")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Signature", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-SignedHeaders", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594150: Call_GetFederationToken_594139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_594150.validator(path, query, header, formData, body)
  let scheme = call_594150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594150.url(scheme.get, call_594150.host, call_594150.base,
                         call_594150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594150, url, valid)

proc call*(call_594151: Call_GetFederationToken_594139; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_594152 = newJObject()
  add(path_594152, "InstanceId", newJString(InstanceId))
  result = call_594151.call(path_594152, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_594139(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_594140, base: "/",
    url: url_GetFederationToken_594141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_594153 = ref object of OpenApiRestCall_593437
proc url_GetMetricData_594155(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_594154(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594156 = path.getOrDefault("InstanceId")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = nil)
  if valid_594156 != nil:
    section.add "InstanceId", valid_594156
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594157 = query.getOrDefault("NextToken")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "NextToken", valid_594157
  var valid_594158 = query.getOrDefault("MaxResults")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "MaxResults", valid_594158
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
  var valid_594159 = header.getOrDefault("X-Amz-Date")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Date", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Security-Token")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Security-Token", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Content-Sha256", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Algorithm")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Algorithm", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Signature")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Signature", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-SignedHeaders", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Credential")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Credential", valid_594165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_GetMetricData_594153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_GetMetricData_594153; InstanceId: string;
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
  var path_594169 = newJObject()
  var query_594170 = newJObject()
  var body_594171 = newJObject()
  add(path_594169, "InstanceId", newJString(InstanceId))
  add(query_594170, "NextToken", newJString(NextToken))
  if body != nil:
    body_594171 = body
  add(query_594170, "MaxResults", newJString(MaxResults))
  result = call_594168.call(path_594169, query_594170, nil, nil, body_594171)

var getMetricData* = Call_GetMetricData_594153(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_594154,
    base: "/", url: url_GetMetricData_594155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_594172 = ref object of OpenApiRestCall_593437
proc url_ListRoutingProfiles_594174(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutingProfiles_594173(path: JsonNode; query: JsonNode;
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
  var valid_594175 = path.getOrDefault("InstanceId")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "InstanceId", valid_594175
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_594176 = query.getOrDefault("maxResults")
  valid_594176 = validateParameter(valid_594176, JInt, required = false, default = nil)
  if valid_594176 != nil:
    section.add "maxResults", valid_594176
  var valid_594177 = query.getOrDefault("nextToken")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "nextToken", valid_594177
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
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Security-Token")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Security-Token", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Content-Sha256", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Signature")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Signature", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-SignedHeaders", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Credential")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Credential", valid_594184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_ListRoutingProfiles_594172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ## 
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_ListRoutingProfiles_594172; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRoutingProfiles
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_594187 = newJObject()
  var query_594188 = newJObject()
  add(path_594187, "InstanceId", newJString(InstanceId))
  add(query_594188, "maxResults", newJInt(maxResults))
  add(query_594188, "nextToken", newJString(nextToken))
  result = call_594186.call(path_594187, query_594188, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_594172(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_594173, base: "/",
    url: url_ListRoutingProfiles_594174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_594189 = ref object of OpenApiRestCall_593437
proc url_ListSecurityProfiles_594191(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecurityProfiles_594190(path: JsonNode; query: JsonNode;
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
  var valid_594192 = path.getOrDefault("InstanceId")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = nil)
  if valid_594192 != nil:
    section.add "InstanceId", valid_594192
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of security profiles to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_594193 = query.getOrDefault("maxResults")
  valid_594193 = validateParameter(valid_594193, JInt, required = false, default = nil)
  if valid_594193 != nil:
    section.add "maxResults", valid_594193
  var valid_594194 = query.getOrDefault("nextToken")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "nextToken", valid_594194
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
  var valid_594195 = header.getOrDefault("X-Amz-Date")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Date", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Security-Token")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Security-Token", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Content-Sha256", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Algorithm")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Algorithm", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Signature")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Signature", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-SignedHeaders", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Credential")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Credential", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594202: Call_ListSecurityProfiles_594189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ## 
  let valid = call_594202.validator(path, query, header, formData, body)
  let scheme = call_594202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594202.url(scheme.get, call_594202.host, call_594202.base,
                         call_594202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594202, url, valid)

proc call*(call_594203: Call_ListSecurityProfiles_594189; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listSecurityProfiles
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of security profiles to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_594204 = newJObject()
  var query_594205 = newJObject()
  add(path_594204, "InstanceId", newJString(InstanceId))
  add(query_594205, "maxResults", newJInt(maxResults))
  add(query_594205, "nextToken", newJString(nextToken))
  result = call_594203.call(path_594204, query_594205, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_594189(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_594190, base: "/",
    url: url_ListSecurityProfiles_594191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_594206 = ref object of OpenApiRestCall_593437
proc url_ListUserHierarchyGroups_594208(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserHierarchyGroups_594207(path: JsonNode; query: JsonNode;
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
  var valid_594209 = path.getOrDefault("InstanceId")
  valid_594209 = validateParameter(valid_594209, JString, required = true,
                                 default = nil)
  if valid_594209 != nil:
    section.add "InstanceId", valid_594209
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_594210 = query.getOrDefault("maxResults")
  valid_594210 = validateParameter(valid_594210, JInt, required = false, default = nil)
  if valid_594210 != nil:
    section.add "maxResults", valid_594210
  var valid_594211 = query.getOrDefault("nextToken")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "nextToken", valid_594211
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
  var valid_594212 = header.getOrDefault("X-Amz-Date")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Date", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Security-Token")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Security-Token", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594219: Call_ListUserHierarchyGroups_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ## 
  let valid = call_594219.validator(path, query, header, formData, body)
  let scheme = call_594219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594219.url(scheme.get, call_594219.host, call_594219.base,
                         call_594219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594219, url, valid)

proc call*(call_594220: Call_ListUserHierarchyGroups_594206; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUserHierarchyGroups
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_594221 = newJObject()
  var query_594222 = newJObject()
  add(path_594221, "InstanceId", newJString(InstanceId))
  add(query_594222, "maxResults", newJInt(maxResults))
  add(query_594222, "nextToken", newJString(nextToken))
  result = call_594220.call(path_594221, query_594222, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_594206(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_594207, base: "/",
    url: url_ListUserHierarchyGroups_594208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_594223 = ref object of OpenApiRestCall_593437
proc url_ListUsers_594225(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_594224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594226 = path.getOrDefault("InstanceId")
  valid_594226 = validateParameter(valid_594226, JString, required = true,
                                 default = nil)
  if valid_594226 != nil:
    section.add "InstanceId", valid_594226
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_594227 = query.getOrDefault("maxResults")
  valid_594227 = validateParameter(valid_594227, JInt, required = false, default = nil)
  if valid_594227 != nil:
    section.add "maxResults", valid_594227
  var valid_594228 = query.getOrDefault("nextToken")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "nextToken", valid_594228
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
  var valid_594229 = header.getOrDefault("X-Amz-Date")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Date", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Security-Token")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Security-Token", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Content-Sha256", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Algorithm")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Algorithm", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Signature")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Signature", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-SignedHeaders", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Credential")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Credential", valid_594235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594236: Call_ListUsers_594223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ## 
  let valid = call_594236.validator(path, query, header, formData, body)
  let scheme = call_594236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594236.url(scheme.get, call_594236.host, call_594236.base,
                         call_594236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594236, url, valid)

proc call*(call_594237: Call_ListUsers_594223; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_594238 = newJObject()
  var query_594239 = newJObject()
  add(path_594238, "InstanceId", newJString(InstanceId))
  add(query_594239, "maxResults", newJInt(maxResults))
  add(query_594239, "nextToken", newJString(nextToken))
  result = call_594237.call(path_594238, query_594239, nil, nil, nil)

var listUsers* = Call_ListUsers_594223(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_594224,
                                    base: "/", url: url_ListUsers_594225,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_594240 = ref object of OpenApiRestCall_593437
proc url_StartOutboundVoiceContact_594242(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartOutboundVoiceContact_594241(path: JsonNode; query: JsonNode;
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
  var valid_594243 = header.getOrDefault("X-Amz-Date")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Date", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Content-Sha256", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Algorithm")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Algorithm", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Signature")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Signature", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-SignedHeaders", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Credential")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Credential", valid_594249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594251: Call_StartOutboundVoiceContact_594240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ## 
  let valid = call_594251.validator(path, query, header, formData, body)
  let scheme = call_594251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594251.url(scheme.get, call_594251.host, call_594251.base,
                         call_594251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594251, url, valid)

proc call*(call_594252: Call_StartOutboundVoiceContact_594240; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ##   body: JObject (required)
  var body_594253 = newJObject()
  if body != nil:
    body_594253 = body
  result = call_594252.call(nil, nil, nil, nil, body_594253)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_594240(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_594241, base: "/",
    url: url_StartOutboundVoiceContact_594242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_594254 = ref object of OpenApiRestCall_593437
proc url_StopContact_594256(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopContact_594255(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Security-Token")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Security-Token", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_StopContact_594254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_StopContact_594254; body: JsonNode): Recallable =
  ## stopContact
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var stopContact* = Call_StopContact_594254(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_594255,
                                        base: "/", url: url_StopContact_594256,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_594268 = ref object of OpenApiRestCall_593437
proc url_UpdateContactAttributes_594270(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContactAttributes_594269(path: JsonNode; query: JsonNode;
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Content-Sha256", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Algorithm")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Algorithm", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Signature")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Signature", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-SignedHeaders", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-Credential")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Credential", valid_594277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594279: Call_UpdateContactAttributes_594268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_594279.validator(path, query, header, formData, body)
  let scheme = call_594279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594279.url(scheme.get, call_594279.host, call_594279.base,
                         call_594279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594279, url, valid)

proc call*(call_594280: Call_UpdateContactAttributes_594268; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_594281 = newJObject()
  if body != nil:
    body_594281 = body
  result = call_594280.call(nil, nil, nil, nil, body_594281)

var updateContactAttributes* = Call_UpdateContactAttributes_594268(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_594269, base: "/",
    url: url_UpdateContactAttributes_594270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_594282 = ref object of OpenApiRestCall_593437
proc url_UpdateUserHierarchy_594284(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserHierarchy_594283(path: JsonNode; query: JsonNode;
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
  var valid_594285 = path.getOrDefault("InstanceId")
  valid_594285 = validateParameter(valid_594285, JString, required = true,
                                 default = nil)
  if valid_594285 != nil:
    section.add "InstanceId", valid_594285
  var valid_594286 = path.getOrDefault("UserId")
  valid_594286 = validateParameter(valid_594286, JString, required = true,
                                 default = nil)
  if valid_594286 != nil:
    section.add "UserId", valid_594286
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
  var valid_594287 = header.getOrDefault("X-Amz-Date")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Date", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Security-Token")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Security-Token", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_UpdateUserHierarchy_594282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the user.
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_UpdateUserHierarchy_594282; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  var path_594297 = newJObject()
  var body_594298 = newJObject()
  add(path_594297, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594298 = body
  add(path_594297, "UserId", newJString(UserId))
  result = call_594296.call(path_594297, nil, nil, nil, body_594298)

var updateUserHierarchy* = Call_UpdateUserHierarchy_594282(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_594283, base: "/",
    url: url_UpdateUserHierarchy_594284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_594299 = ref object of OpenApiRestCall_593437
proc url_UpdateUserIdentityInfo_594301(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserIdentityInfo_594300(path: JsonNode; query: JsonNode;
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
  var valid_594302 = path.getOrDefault("InstanceId")
  valid_594302 = validateParameter(valid_594302, JString, required = true,
                                 default = nil)
  if valid_594302 != nil:
    section.add "InstanceId", valid_594302
  var valid_594303 = path.getOrDefault("UserId")
  valid_594303 = validateParameter(valid_594303, JString, required = true,
                                 default = nil)
  if valid_594303 != nil:
    section.add "UserId", valid_594303
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
  var valid_594304 = header.getOrDefault("X-Amz-Date")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Date", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Content-Sha256", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Algorithm")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Algorithm", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Signature")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Signature", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-SignedHeaders", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Credential")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Credential", valid_594310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594312: Call_UpdateUserIdentityInfo_594299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  let valid = call_594312.validator(path, query, header, formData, body)
  let scheme = call_594312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594312.url(scheme.get, call_594312.host, call_594312.base,
                         call_594312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594312, url, valid)

proc call*(call_594313: Call_UpdateUserIdentityInfo_594299; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to update identity information for.
  var path_594314 = newJObject()
  var body_594315 = newJObject()
  add(path_594314, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594315 = body
  add(path_594314, "UserId", newJString(UserId))
  result = call_594313.call(path_594314, nil, nil, nil, body_594315)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_594299(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_594300, base: "/",
    url: url_UpdateUserIdentityInfo_594301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_594316 = ref object of OpenApiRestCall_593437
proc url_UpdateUserPhoneConfig_594318(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPhoneConfig_594317(path: JsonNode; query: JsonNode;
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
  var valid_594319 = path.getOrDefault("InstanceId")
  valid_594319 = validateParameter(valid_594319, JString, required = true,
                                 default = nil)
  if valid_594319 != nil:
    section.add "InstanceId", valid_594319
  var valid_594320 = path.getOrDefault("UserId")
  valid_594320 = validateParameter(valid_594320, JString, required = true,
                                 default = nil)
  if valid_594320 != nil:
    section.add "UserId", valid_594320
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
  var valid_594321 = header.getOrDefault("X-Amz-Date")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Date", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Security-Token")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Security-Token", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Content-Sha256", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Algorithm")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Algorithm", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Signature")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Signature", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-SignedHeaders", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Credential")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Credential", valid_594327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594329: Call_UpdateUserPhoneConfig_594316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  let valid = call_594329.validator(path, query, header, formData, body)
  let scheme = call_594329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594329.url(scheme.get, call_594329.host, call_594329.base,
                         call_594329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594329, url, valid)

proc call*(call_594330: Call_UpdateUserPhoneConfig_594316; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to change phone settings for.
  var path_594331 = newJObject()
  var body_594332 = newJObject()
  add(path_594331, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594332 = body
  add(path_594331, "UserId", newJString(UserId))
  result = call_594330.call(path_594331, nil, nil, nil, body_594332)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_594316(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_594317, base: "/",
    url: url_UpdateUserPhoneConfig_594318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_594333 = ref object of OpenApiRestCall_593437
proc url_UpdateUserRoutingProfile_594335(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_594334(path: JsonNode; query: JsonNode;
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
  var valid_594336 = path.getOrDefault("InstanceId")
  valid_594336 = validateParameter(valid_594336, JString, required = true,
                                 default = nil)
  if valid_594336 != nil:
    section.add "InstanceId", valid_594336
  var valid_594337 = path.getOrDefault("UserId")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = nil)
  if valid_594337 != nil:
    section.add "UserId", valid_594337
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
  var valid_594338 = header.getOrDefault("X-Amz-Date")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Date", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Security-Token")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Security-Token", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Content-Sha256", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Algorithm")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Algorithm", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Signature")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Signature", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-SignedHeaders", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Credential")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Credential", valid_594344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594346: Call_UpdateUserRoutingProfile_594333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to a user.
  ## 
  let valid = call_594346.validator(path, query, header, formData, body)
  let scheme = call_594346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594346.url(scheme.get, call_594346.host, call_594346.base,
                         call_594346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594346, url, valid)

proc call*(call_594347: Call_UpdateUserRoutingProfile_594333; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to a user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to assign the routing profile to.
  var path_594348 = newJObject()
  var body_594349 = newJObject()
  add(path_594348, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594349 = body
  add(path_594348, "UserId", newJString(UserId))
  result = call_594347.call(path_594348, nil, nil, nil, body_594349)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_594333(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_594334, base: "/",
    url: url_UpdateUserRoutingProfile_594335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_594350 = ref object of OpenApiRestCall_593437
proc url_UpdateUserSecurityProfiles_594352(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_594351(path: JsonNode; query: JsonNode;
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
  var valid_594353 = path.getOrDefault("InstanceId")
  valid_594353 = validateParameter(valid_594353, JString, required = true,
                                 default = nil)
  if valid_594353 != nil:
    section.add "InstanceId", valid_594353
  var valid_594354 = path.getOrDefault("UserId")
  valid_594354 = validateParameter(valid_594354, JString, required = true,
                                 default = nil)
  if valid_594354 != nil:
    section.add "UserId", valid_594354
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
  var valid_594355 = header.getOrDefault("X-Amz-Date")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Date", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Security-Token")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Security-Token", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-Content-Sha256", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Algorithm")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Algorithm", valid_594358
  var valid_594359 = header.getOrDefault("X-Amz-Signature")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Signature", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-SignedHeaders", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Credential")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Credential", valid_594361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594363: Call_UpdateUserSecurityProfiles_594350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the security profiles assigned to the user.
  ## 
  let valid = call_594363.validator(path, query, header, formData, body)
  let scheme = call_594363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594363.url(scheme.get, call_594363.host, call_594363.base,
                         call_594363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594363, url, valid)

proc call*(call_594364: Call_UpdateUserSecurityProfiles_594350; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Updates the security profiles assigned to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the security profiles.
  var path_594365 = newJObject()
  var body_594366 = newJObject()
  add(path_594365, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_594366 = body
  add(path_594365, "UserId", newJString(UserId))
  result = call_594364.call(path_594365, nil, nil, nil, body_594366)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_594350(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_594351, base: "/",
    url: url_UpdateUserSecurityProfiles_594352,
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
