
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateUser_772933 = ref object of OpenApiRestCall_772597
proc url_CreateUser_772935(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateUser_772934(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773061 = path.getOrDefault("InstanceId")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "InstanceId", valid_773061
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
  var valid_773062 = header.getOrDefault("X-Amz-Date")
  valid_773062 = validateParameter(valid_773062, JString, required = false,
                                 default = nil)
  if valid_773062 != nil:
    section.add "X-Amz-Date", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Security-Token")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Security-Token", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Content-Sha256", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Algorithm")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Algorithm", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Signature")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Signature", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-SignedHeaders", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Credential")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Credential", valid_773068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_CreateUser_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user account in your Amazon Connect instance.
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_CreateUser_772933; InstanceId: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates a new user account in your Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  var path_773164 = newJObject()
  var body_773166 = newJObject()
  add(path_773164, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773166 = body
  result = call_773163.call(path_773164, nil, nil, nil, body_773166)

var createUser* = Call_CreateUser_772933(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_772934,
                                      base: "/", url: url_CreateUser_772935,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_773205 = ref object of OpenApiRestCall_772597
proc url_DescribeUser_773207(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeUser_773206(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773208 = path.getOrDefault("InstanceId")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = nil)
  if valid_773208 != nil:
    section.add "InstanceId", valid_773208
  var valid_773209 = path.getOrDefault("UserId")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = nil)
  if valid_773209 != nil:
    section.add "UserId", valid_773209
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
  var valid_773210 = header.getOrDefault("X-Amz-Date")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Date", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Security-Token")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Security-Token", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Content-Sha256", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Algorithm")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Algorithm", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Signature")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Signature", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-SignedHeaders", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Credential")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Credential", valid_773216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773217: Call_DescribeUser_773205; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  let valid = call_773217.validator(path, query, header, formData, body)
  let scheme = call_773217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773217.url(scheme.get, call_773217.host, call_773217.base,
                         call_773217.route, valid.getOrDefault("path"))
  result = hook(call_773217, url, valid)

proc call*(call_773218: Call_DescribeUser_773205; InstanceId: string; UserId: string): Recallable =
  ## describeUser
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : Unique identifier for the user account to return.
  var path_773219 = newJObject()
  add(path_773219, "InstanceId", newJString(InstanceId))
  add(path_773219, "UserId", newJString(UserId))
  result = call_773218.call(path_773219, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_773205(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_773206,
    base: "/", url: url_DescribeUser_773207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_773220 = ref object of OpenApiRestCall_772597
proc url_DeleteUser_773222(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteUser_773221(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773223 = path.getOrDefault("InstanceId")
  valid_773223 = validateParameter(valid_773223, JString, required = true,
                                 default = nil)
  if valid_773223 != nil:
    section.add "InstanceId", valid_773223
  var valid_773224 = path.getOrDefault("UserId")
  valid_773224 = validateParameter(valid_773224, JString, required = true,
                                 default = nil)
  if valid_773224 != nil:
    section.add "UserId", valid_773224
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
  var valid_773225 = header.getOrDefault("X-Amz-Date")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Date", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Security-Token")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Security-Token", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Content-Sha256", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Algorithm")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Algorithm", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Signature")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Signature", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-SignedHeaders", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Credential")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Credential", valid_773231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773232: Call_DeleteUser_773220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from Amazon Connect.
  ## 
  let valid = call_773232.validator(path, query, header, formData, body)
  let scheme = call_773232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773232.url(scheme.get, call_773232.host, call_773232.base,
                         call_773232.route, valid.getOrDefault("path"))
  result = hook(call_773232, url, valid)

proc call*(call_773233: Call_DeleteUser_773220; InstanceId: string; UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from Amazon Connect.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   UserId: string (required)
  ##         : The unique identifier of the user to delete.
  var path_773234 = newJObject()
  add(path_773234, "InstanceId", newJString(InstanceId))
  add(path_773234, "UserId", newJString(UserId))
  result = call_773233.call(path_773234, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_773220(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_773221,
                                      base: "/", url: url_DeleteUser_773222,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_773235 = ref object of OpenApiRestCall_772597
proc url_DescribeUserHierarchyGroup_773237(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeUserHierarchyGroup_773236(path: JsonNode; query: JsonNode;
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
  var valid_773238 = path.getOrDefault("HierarchyGroupId")
  valid_773238 = validateParameter(valid_773238, JString, required = true,
                                 default = nil)
  if valid_773238 != nil:
    section.add "HierarchyGroupId", valid_773238
  var valid_773239 = path.getOrDefault("InstanceId")
  valid_773239 = validateParameter(valid_773239, JString, required = true,
                                 default = nil)
  if valid_773239 != nil:
    section.add "InstanceId", valid_773239
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
  var valid_773240 = header.getOrDefault("X-Amz-Date")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Date", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Security-Token")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Security-Token", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Content-Sha256", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Algorithm")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Algorithm", valid_773243
  var valid_773244 = header.getOrDefault("X-Amz-Signature")
  valid_773244 = validateParameter(valid_773244, JString, required = false,
                                 default = nil)
  if valid_773244 != nil:
    section.add "X-Amz-Signature", valid_773244
  var valid_773245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-SignedHeaders", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Credential")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Credential", valid_773246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773247: Call_DescribeUserHierarchyGroup_773235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ## 
  let valid = call_773247.validator(path, query, header, formData, body)
  let scheme = call_773247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773247.url(scheme.get, call_773247.host, call_773247.base,
                         call_773247.route, valid.getOrDefault("path"))
  result = hook(call_773247, url, valid)

proc call*(call_773248: Call_DescribeUserHierarchyGroup_773235;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier for the hierarchy group to return.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_773249 = newJObject()
  add(path_773249, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_773249, "InstanceId", newJString(InstanceId))
  result = call_773248.call(path_773249, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_773235(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_773236, base: "/",
    url: url_DescribeUserHierarchyGroup_773237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_773250 = ref object of OpenApiRestCall_772597
proc url_DescribeUserHierarchyStructure_773252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user-hierarchy-structure/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeUserHierarchyStructure_773251(path: JsonNode;
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
  var valid_773253 = path.getOrDefault("InstanceId")
  valid_773253 = validateParameter(valid_773253, JString, required = true,
                                 default = nil)
  if valid_773253 != nil:
    section.add "InstanceId", valid_773253
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
  var valid_773254 = header.getOrDefault("X-Amz-Date")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Date", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Security-Token")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Security-Token", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Content-Sha256", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Algorithm")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Algorithm", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Signature")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Signature", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-SignedHeaders", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Credential")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Credential", valid_773260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773261: Call_DescribeUserHierarchyStructure_773250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ## 
  let valid = call_773261.validator(path, query, header, formData, body)
  let scheme = call_773261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773261.url(scheme.get, call_773261.host, call_773261.base,
                         call_773261.route, valid.getOrDefault("path"))
  result = hook(call_773261, url, valid)

proc call*(call_773262: Call_DescribeUserHierarchyStructure_773250;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_773263 = newJObject()
  add(path_773263, "InstanceId", newJString(InstanceId))
  result = call_773262.call(path_773263, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_773250(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_773251, base: "/",
    url: url_DescribeUserHierarchyStructure_773252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_773264 = ref object of OpenApiRestCall_772597
proc url_GetContactAttributes_773266(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetContactAttributes_773265(path: JsonNode; query: JsonNode;
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
  var valid_773267 = path.getOrDefault("InitialContactId")
  valid_773267 = validateParameter(valid_773267, JString, required = true,
                                 default = nil)
  if valid_773267 != nil:
    section.add "InitialContactId", valid_773267
  var valid_773268 = path.getOrDefault("InstanceId")
  valid_773268 = validateParameter(valid_773268, JString, required = true,
                                 default = nil)
  if valid_773268 != nil:
    section.add "InstanceId", valid_773268
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
  var valid_773269 = header.getOrDefault("X-Amz-Date")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Date", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Security-Token")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Security-Token", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Content-Sha256", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Algorithm")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Algorithm", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Signature")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Signature", valid_773273
  var valid_773274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-SignedHeaders", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Credential")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Credential", valid_773275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773276: Call_GetContactAttributes_773264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes associated with a contact.
  ## 
  let valid = call_773276.validator(path, query, header, formData, body)
  let scheme = call_773276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773276.url(scheme.get, call_773276.host, call_773276.base,
                         call_773276.route, valid.getOrDefault("path"))
  result = hook(call_773276, url, valid)

proc call*(call_773277: Call_GetContactAttributes_773264; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes associated with a contact.
  ##   InitialContactId: string (required)
  ##                   : The ID for the initial contact in Amazon Connect associated with the attributes to update.
  ##   InstanceId: string (required)
  ##             : The instance ID for the instance from which to retrieve contact attributes.
  var path_773278 = newJObject()
  add(path_773278, "InitialContactId", newJString(InitialContactId))
  add(path_773278, "InstanceId", newJString(InstanceId))
  result = call_773277.call(path_773278, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_773264(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_773265, base: "/",
    url: url_GetContactAttributes_773266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_773279 = ref object of OpenApiRestCall_772597
proc url_GetCurrentMetricData_773281(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/metrics/current/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCurrentMetricData_773280(path: JsonNode; query: JsonNode;
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
  var valid_773282 = path.getOrDefault("InstanceId")
  valid_773282 = validateParameter(valid_773282, JString, required = true,
                                 default = nil)
  if valid_773282 != nil:
    section.add "InstanceId", valid_773282
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773283 = query.getOrDefault("NextToken")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "NextToken", valid_773283
  var valid_773284 = query.getOrDefault("MaxResults")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "MaxResults", valid_773284
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
  var valid_773285 = header.getOrDefault("X-Amz-Date")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Date", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Security-Token")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Security-Token", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Content-Sha256", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Algorithm")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Algorithm", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Signature")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Signature", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-SignedHeaders", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Credential")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Credential", valid_773291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773293: Call_GetCurrentMetricData_773279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ## 
  let valid = call_773293.validator(path, query, header, formData, body)
  let scheme = call_773293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773293.url(scheme.get, call_773293.host, call_773293.base,
                         call_773293.route, valid.getOrDefault("path"))
  result = hook(call_773293, url, valid)

proc call*(call_773294: Call_GetCurrentMetricData_773279; InstanceId: string;
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
  var path_773295 = newJObject()
  var query_773296 = newJObject()
  var body_773297 = newJObject()
  add(path_773295, "InstanceId", newJString(InstanceId))
  add(query_773296, "NextToken", newJString(NextToken))
  if body != nil:
    body_773297 = body
  add(query_773296, "MaxResults", newJString(MaxResults))
  result = call_773294.call(path_773295, query_773296, nil, nil, body_773297)

var getCurrentMetricData* = Call_GetCurrentMetricData_773279(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_773280, base: "/",
    url: url_GetCurrentMetricData_773281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_773298 = ref object of OpenApiRestCall_772597
proc url_GetFederationToken_773300(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user/federate/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFederationToken_773299(path: JsonNode; query: JsonNode;
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
  var valid_773301 = path.getOrDefault("InstanceId")
  valid_773301 = validateParameter(valid_773301, JString, required = true,
                                 default = nil)
  if valid_773301 != nil:
    section.add "InstanceId", valid_773301
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
  var valid_773302 = header.getOrDefault("X-Amz-Date")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Date", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Security-Token")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Security-Token", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Content-Sha256", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Algorithm")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Algorithm", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Signature")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Signature", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-SignedHeaders", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Credential")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Credential", valid_773308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773309: Call_GetFederationToken_773298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_773309.validator(path, query, header, formData, body)
  let scheme = call_773309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773309.url(scheme.get, call_773309.host, call_773309.base,
                         call_773309.route, valid.getOrDefault("path"))
  result = hook(call_773309, url, valid)

proc call*(call_773310: Call_GetFederationToken_773298; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_773311 = newJObject()
  add(path_773311, "InstanceId", newJString(InstanceId))
  result = call_773310.call(path_773311, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_773298(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_773299, base: "/",
    url: url_GetFederationToken_773300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_773312 = ref object of OpenApiRestCall_772597
proc url_GetMetricData_773314(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/metrics/historical/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMetricData_773313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773315 = path.getOrDefault("InstanceId")
  valid_773315 = validateParameter(valid_773315, JString, required = true,
                                 default = nil)
  if valid_773315 != nil:
    section.add "InstanceId", valid_773315
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_773316 = query.getOrDefault("NextToken")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "NextToken", valid_773316
  var valid_773317 = query.getOrDefault("MaxResults")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "MaxResults", valid_773317
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
  var valid_773318 = header.getOrDefault("X-Amz-Date")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Date", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Security-Token")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Security-Token", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Content-Sha256", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Algorithm")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Algorithm", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-Signature")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-Signature", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-SignedHeaders", valid_773323
  var valid_773324 = header.getOrDefault("X-Amz-Credential")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Credential", valid_773324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773326: Call_GetMetricData_773312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ## 
  let valid = call_773326.validator(path, query, header, formData, body)
  let scheme = call_773326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773326.url(scheme.get, call_773326.host, call_773326.base,
                         call_773326.route, valid.getOrDefault("path"))
  result = hook(call_773326, url, valid)

proc call*(call_773327: Call_GetMetricData_773312; InstanceId: string;
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
  var path_773328 = newJObject()
  var query_773329 = newJObject()
  var body_773330 = newJObject()
  add(path_773328, "InstanceId", newJString(InstanceId))
  add(query_773329, "NextToken", newJString(NextToken))
  if body != nil:
    body_773330 = body
  add(query_773329, "MaxResults", newJString(MaxResults))
  result = call_773327.call(path_773328, query_773329, nil, nil, body_773330)

var getMetricData* = Call_GetMetricData_773312(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_773313,
    base: "/", url: url_GetMetricData_773314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_773331 = ref object of OpenApiRestCall_772597
proc url_ListRoutingProfiles_773333(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/routing-profiles-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListRoutingProfiles_773332(path: JsonNode; query: JsonNode;
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
  var valid_773334 = path.getOrDefault("InstanceId")
  valid_773334 = validateParameter(valid_773334, JString, required = true,
                                 default = nil)
  if valid_773334 != nil:
    section.add "InstanceId", valid_773334
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_773335 = query.getOrDefault("maxResults")
  valid_773335 = validateParameter(valid_773335, JInt, required = false, default = nil)
  if valid_773335 != nil:
    section.add "maxResults", valid_773335
  var valid_773336 = query.getOrDefault("nextToken")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "nextToken", valid_773336
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
  var valid_773337 = header.getOrDefault("X-Amz-Date")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Date", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-Security-Token")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-Security-Token", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Content-Sha256", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Algorithm")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Algorithm", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Signature")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Signature", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-SignedHeaders", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Credential")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Credential", valid_773343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773344: Call_ListRoutingProfiles_773331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ## 
  let valid = call_773344.validator(path, query, header, formData, body)
  let scheme = call_773344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773344.url(scheme.get, call_773344.host, call_773344.base,
                         call_773344.route, valid.getOrDefault("path"))
  result = hook(call_773344, url, valid)

proc call*(call_773345: Call_ListRoutingProfiles_773331; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listRoutingProfiles
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of routing profiles to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_773346 = newJObject()
  var query_773347 = newJObject()
  add(path_773346, "InstanceId", newJString(InstanceId))
  add(query_773347, "maxResults", newJInt(maxResults))
  add(query_773347, "nextToken", newJString(nextToken))
  result = call_773345.call(path_773346, query_773347, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_773331(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_773332, base: "/",
    url: url_ListRoutingProfiles_773333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_773348 = ref object of OpenApiRestCall_772597
proc url_ListSecurityProfiles_773350(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/security-profiles-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListSecurityProfiles_773349(path: JsonNode; query: JsonNode;
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
  var valid_773351 = path.getOrDefault("InstanceId")
  valid_773351 = validateParameter(valid_773351, JString, required = true,
                                 default = nil)
  if valid_773351 != nil:
    section.add "InstanceId", valid_773351
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of security profiles to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_773352 = query.getOrDefault("maxResults")
  valid_773352 = validateParameter(valid_773352, JInt, required = false, default = nil)
  if valid_773352 != nil:
    section.add "maxResults", valid_773352
  var valid_773353 = query.getOrDefault("nextToken")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "nextToken", valid_773353
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
  var valid_773354 = header.getOrDefault("X-Amz-Date")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Date", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Security-Token")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Security-Token", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Content-Sha256", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Algorithm")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Algorithm", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Signature")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Signature", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-SignedHeaders", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Credential")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Credential", valid_773360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773361: Call_ListSecurityProfiles_773348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ## 
  let valid = call_773361.validator(path, query, header, formData, body)
  let scheme = call_773361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773361.url(scheme.get, call_773361.host, call_773361.base,
                         call_773361.route, valid.getOrDefault("path"))
  result = hook(call_773361, url, valid)

proc call*(call_773362: Call_ListSecurityProfiles_773348; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listSecurityProfiles
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of security profiles to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_773363 = newJObject()
  var query_773364 = newJObject()
  add(path_773363, "InstanceId", newJString(InstanceId))
  add(query_773364, "maxResults", newJInt(maxResults))
  add(query_773364, "nextToken", newJString(nextToken))
  result = call_773362.call(path_773363, query_773364, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_773348(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_773349, base: "/",
    url: url_ListSecurityProfiles_773350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_773365 = ref object of OpenApiRestCall_772597
proc url_ListUserHierarchyGroups_773367(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/user-hierarchy-groups-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListUserHierarchyGroups_773366(path: JsonNode; query: JsonNode;
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
  var valid_773368 = path.getOrDefault("InstanceId")
  valid_773368 = validateParameter(valid_773368, JString, required = true,
                                 default = nil)
  if valid_773368 != nil:
    section.add "InstanceId", valid_773368
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_773369 = query.getOrDefault("maxResults")
  valid_773369 = validateParameter(valid_773369, JInt, required = false, default = nil)
  if valid_773369 != nil:
    section.add "maxResults", valid_773369
  var valid_773370 = query.getOrDefault("nextToken")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "nextToken", valid_773370
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
  var valid_773371 = header.getOrDefault("X-Amz-Date")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Date", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Security-Token")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Security-Token", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773378: Call_ListUserHierarchyGroups_773365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ## 
  let valid = call_773378.validator(path, query, header, formData, body)
  let scheme = call_773378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773378.url(scheme.get, call_773378.host, call_773378.base,
                         call_773378.route, valid.getOrDefault("path"))
  result = hook(call_773378, url, valid)

proc call*(call_773379: Call_ListUserHierarchyGroups_773365; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUserHierarchyGroups
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of hierarchy groups to return.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_773380 = newJObject()
  var query_773381 = newJObject()
  add(path_773380, "InstanceId", newJString(InstanceId))
  add(query_773381, "maxResults", newJInt(maxResults))
  add(query_773381, "nextToken", newJString(nextToken))
  result = call_773379.call(path_773380, query_773381, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_773365(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_773366, base: "/",
    url: url_ListUserHierarchyGroups_773367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_773382 = ref object of OpenApiRestCall_772597
proc url_ListUsers_773384(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/users-summary/"),
               (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListUsers_773383(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773385 = path.getOrDefault("InstanceId")
  valid_773385 = validateParameter(valid_773385, JString, required = true,
                                 default = nil)
  if valid_773385 != nil:
    section.add "InstanceId", valid_773385
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  section = newJObject()
  var valid_773386 = query.getOrDefault("maxResults")
  valid_773386 = validateParameter(valid_773386, JInt, required = false, default = nil)
  if valid_773386 != nil:
    section.add "maxResults", valid_773386
  var valid_773387 = query.getOrDefault("nextToken")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "nextToken", valid_773387
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
  var valid_773388 = header.getOrDefault("X-Amz-Date")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Date", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Security-Token")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Security-Token", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Content-Sha256", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Algorithm")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Algorithm", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Signature")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Signature", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-SignedHeaders", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Credential")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Credential", valid_773394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_ListUsers_773382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_ListUsers_773382; InstanceId: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  var path_773397 = newJObject()
  var query_773398 = newJObject()
  add(path_773397, "InstanceId", newJString(InstanceId))
  add(query_773398, "maxResults", newJInt(maxResults))
  add(query_773398, "nextToken", newJString(nextToken))
  result = call_773396.call(path_773397, query_773398, nil, nil, nil)

var listUsers* = Call_ListUsers_773382(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_773383,
                                    base: "/", url: url_ListUsers_773384,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_773399 = ref object of OpenApiRestCall_772597
proc url_StartOutboundVoiceContact_773401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartOutboundVoiceContact_773400(path: JsonNode; query: JsonNode;
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
  var valid_773402 = header.getOrDefault("X-Amz-Date")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Date", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Security-Token")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Security-Token", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Content-Sha256", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Algorithm")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Algorithm", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Signature")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Signature", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-SignedHeaders", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Credential")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Credential", valid_773408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773410: Call_StartOutboundVoiceContact_773399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ## 
  let valid = call_773410.validator(path, query, header, formData, body)
  let scheme = call_773410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773410.url(scheme.get, call_773410.host, call_773410.base,
                         call_773410.route, valid.getOrDefault("path"))
  result = hook(call_773410, url, valid)

proc call*(call_773411: Call_StartOutboundVoiceContact_773399; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ##   body: JObject (required)
  var body_773412 = newJObject()
  if body != nil:
    body_773412 = body
  result = call_773411.call(nil, nil, nil, nil, body_773412)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_773399(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_773400, base: "/",
    url: url_StartOutboundVoiceContact_773401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_773413 = ref object of OpenApiRestCall_772597
proc url_StopContact_773415(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopContact_773414(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773416 = header.getOrDefault("X-Amz-Date")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Date", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Security-Token")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Security-Token", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_StopContact_773413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_StopContact_773413; body: JsonNode): Recallable =
  ## stopContact
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ##   body: JObject (required)
  var body_773426 = newJObject()
  if body != nil:
    body_773426 = body
  result = call_773425.call(nil, nil, nil, nil, body_773426)

var stopContact* = Call_StopContact_773413(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_773414,
                                        base: "/", url: url_StopContact_773415,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_773427 = ref object of OpenApiRestCall_772597
proc url_UpdateContactAttributes_773429(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateContactAttributes_773428(path: JsonNode; query: JsonNode;
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
  var valid_773430 = header.getOrDefault("X-Amz-Date")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Date", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Security-Token")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Security-Token", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Content-Sha256", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Algorithm")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Algorithm", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Signature")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Signature", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-SignedHeaders", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Credential")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Credential", valid_773436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773438: Call_UpdateContactAttributes_773427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_773438.validator(path, query, header, formData, body)
  let scheme = call_773438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773438.url(scheme.get, call_773438.host, call_773438.base,
                         call_773438.route, valid.getOrDefault("path"))
  result = hook(call_773438, url, valid)

proc call*(call_773439: Call_UpdateContactAttributes_773427; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_773440 = newJObject()
  if body != nil:
    body_773440 = body
  result = call_773439.call(nil, nil, nil, nil, body_773440)

var updateContactAttributes* = Call_UpdateContactAttributes_773427(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_773428, base: "/",
    url: url_UpdateContactAttributes_773429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_773441 = ref object of OpenApiRestCall_772597
proc url_UpdateUserHierarchy_773443(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserHierarchy_773442(path: JsonNode; query: JsonNode;
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
  var valid_773444 = path.getOrDefault("InstanceId")
  valid_773444 = validateParameter(valid_773444, JString, required = true,
                                 default = nil)
  if valid_773444 != nil:
    section.add "InstanceId", valid_773444
  var valid_773445 = path.getOrDefault("UserId")
  valid_773445 = validateParameter(valid_773445, JString, required = true,
                                 default = nil)
  if valid_773445 != nil:
    section.add "UserId", valid_773445
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
  var valid_773446 = header.getOrDefault("X-Amz-Date")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Date", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Security-Token")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Security-Token", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Content-Sha256", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Algorithm")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Algorithm", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Signature")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Signature", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-SignedHeaders", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Credential")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Credential", valid_773452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_UpdateUserHierarchy_773441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the user.
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_UpdateUserHierarchy_773441; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  var path_773456 = newJObject()
  var body_773457 = newJObject()
  add(path_773456, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773457 = body
  add(path_773456, "UserId", newJString(UserId))
  result = call_773455.call(path_773456, nil, nil, nil, body_773457)

var updateUserHierarchy* = Call_UpdateUserHierarchy_773441(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_773442, base: "/",
    url: url_UpdateUserHierarchy_773443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_773458 = ref object of OpenApiRestCall_772597
proc url_UpdateUserIdentityInfo_773460(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserIdentityInfo_773459(path: JsonNode; query: JsonNode;
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
  var valid_773461 = path.getOrDefault("InstanceId")
  valid_773461 = validateParameter(valid_773461, JString, required = true,
                                 default = nil)
  if valid_773461 != nil:
    section.add "InstanceId", valid_773461
  var valid_773462 = path.getOrDefault("UserId")
  valid_773462 = validateParameter(valid_773462, JString, required = true,
                                 default = nil)
  if valid_773462 != nil:
    section.add "UserId", valid_773462
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
  var valid_773463 = header.getOrDefault("X-Amz-Date")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Date", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Security-Token")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Security-Token", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Content-Sha256", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Algorithm")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Algorithm", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Signature")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Signature", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-SignedHeaders", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Credential")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Credential", valid_773469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773471: Call_UpdateUserIdentityInfo_773458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  let valid = call_773471.validator(path, query, header, formData, body)
  let scheme = call_773471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773471.url(scheme.get, call_773471.host, call_773471.base,
                         call_773471.route, valid.getOrDefault("path"))
  result = hook(call_773471, url, valid)

proc call*(call_773472: Call_UpdateUserIdentityInfo_773458; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to update identity information for.
  var path_773473 = newJObject()
  var body_773474 = newJObject()
  add(path_773473, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773474 = body
  add(path_773473, "UserId", newJString(UserId))
  result = call_773472.call(path_773473, nil, nil, nil, body_773474)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_773458(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_773459, base: "/",
    url: url_UpdateUserIdentityInfo_773460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_773475 = ref object of OpenApiRestCall_772597
proc url_UpdateUserPhoneConfig_773477(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserPhoneConfig_773476(path: JsonNode; query: JsonNode;
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
  var valid_773478 = path.getOrDefault("InstanceId")
  valid_773478 = validateParameter(valid_773478, JString, required = true,
                                 default = nil)
  if valid_773478 != nil:
    section.add "InstanceId", valid_773478
  var valid_773479 = path.getOrDefault("UserId")
  valid_773479 = validateParameter(valid_773479, JString, required = true,
                                 default = nil)
  if valid_773479 != nil:
    section.add "UserId", valid_773479
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
  var valid_773480 = header.getOrDefault("X-Amz-Date")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Date", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Security-Token")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Security-Token", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Content-Sha256", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Algorithm")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Algorithm", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Signature")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Signature", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-SignedHeaders", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Credential")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Credential", valid_773486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773488: Call_UpdateUserPhoneConfig_773475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  let valid = call_773488.validator(path, query, header, formData, body)
  let scheme = call_773488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773488.url(scheme.get, call_773488.host, call_773488.base,
                         call_773488.route, valid.getOrDefault("path"))
  result = hook(call_773488, url, valid)

proc call*(call_773489: Call_UpdateUserPhoneConfig_773475; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to change phone settings for.
  var path_773490 = newJObject()
  var body_773491 = newJObject()
  add(path_773490, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773491 = body
  add(path_773490, "UserId", newJString(UserId))
  result = call_773489.call(path_773490, nil, nil, nil, body_773491)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_773475(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_773476, base: "/",
    url: url_UpdateUserPhoneConfig_773477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_773492 = ref object of OpenApiRestCall_772597
proc url_UpdateUserRoutingProfile_773494(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserRoutingProfile_773493(path: JsonNode; query: JsonNode;
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
  var valid_773495 = path.getOrDefault("InstanceId")
  valid_773495 = validateParameter(valid_773495, JString, required = true,
                                 default = nil)
  if valid_773495 != nil:
    section.add "InstanceId", valid_773495
  var valid_773496 = path.getOrDefault("UserId")
  valid_773496 = validateParameter(valid_773496, JString, required = true,
                                 default = nil)
  if valid_773496 != nil:
    section.add "UserId", valid_773496
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
  var valid_773497 = header.getOrDefault("X-Amz-Date")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Date", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Security-Token")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Security-Token", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Content-Sha256", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Algorithm")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Algorithm", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Signature")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Signature", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-SignedHeaders", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Credential")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Credential", valid_773503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773505: Call_UpdateUserRoutingProfile_773492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to a user.
  ## 
  let valid = call_773505.validator(path, query, header, formData, body)
  let scheme = call_773505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773505.url(scheme.get, call_773505.host, call_773505.base,
                         call_773505.route, valid.getOrDefault("path"))
  result = hook(call_773505, url, valid)

proc call*(call_773506: Call_UpdateUserRoutingProfile_773492; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to a user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier for the user account to assign the routing profile to.
  var path_773507 = newJObject()
  var body_773508 = newJObject()
  add(path_773507, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773508 = body
  add(path_773507, "UserId", newJString(UserId))
  result = call_773506.call(path_773507, nil, nil, nil, body_773508)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_773492(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_773493, base: "/",
    url: url_UpdateUserRoutingProfile_773494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_773509 = ref object of OpenApiRestCall_772597
proc url_UpdateUserSecurityProfiles_773511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateUserSecurityProfiles_773510(path: JsonNode; query: JsonNode;
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
  var valid_773512 = path.getOrDefault("InstanceId")
  valid_773512 = validateParameter(valid_773512, JString, required = true,
                                 default = nil)
  if valid_773512 != nil:
    section.add "InstanceId", valid_773512
  var valid_773513 = path.getOrDefault("UserId")
  valid_773513 = validateParameter(valid_773513, JString, required = true,
                                 default = nil)
  if valid_773513 != nil:
    section.add "UserId", valid_773513
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
  var valid_773514 = header.getOrDefault("X-Amz-Date")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Date", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Security-Token")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Security-Token", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Content-Sha256", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Algorithm")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Algorithm", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Signature")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Signature", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-SignedHeaders", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Credential")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Credential", valid_773520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773522: Call_UpdateUserSecurityProfiles_773509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the security profiles assigned to the user.
  ## 
  let valid = call_773522.validator(path, query, header, formData, body)
  let scheme = call_773522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773522.url(scheme.get, call_773522.host, call_773522.base,
                         call_773522.route, valid.getOrDefault("path"))
  result = hook(call_773522, url, valid)

proc call*(call_773523: Call_UpdateUserSecurityProfiles_773509; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Updates the security profiles assigned to the user.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the security profiles.
  var path_773524 = newJObject()
  var body_773525 = newJObject()
  add(path_773524, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_773525 = body
  add(path_773524, "UserId", newJString(UserId))
  result = call_773523.call(path_773524, nil, nil, nil, body_773525)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_773509(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_773510, base: "/",
    url: url_UpdateUserSecurityProfiles_773511,
    schemes: {Scheme.Https, Scheme.Http})
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
