
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
  Call_CreateUser_592703 = ref object of OpenApiRestCall_592364
proc url_CreateUser_592705(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592831 = path.getOrDefault("InstanceId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "InstanceId", valid_592831
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
  var valid_592832 = header.getOrDefault("X-Amz-Signature")
  valid_592832 = validateParameter(valid_592832, JString, required = false,
                                 default = nil)
  if valid_592832 != nil:
    section.add "X-Amz-Signature", valid_592832
  var valid_592833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Content-Sha256", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Date")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Date", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Credential")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Credential", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Security-Token")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Security-Token", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Algorithm")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Algorithm", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-SignedHeaders", valid_592838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_CreateUser_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user account in your Amazon Connect instance.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_CreateUser_592703; body: JsonNode; InstanceId: string): Recallable =
  ## createUser
  ## Creates a new user account in your Amazon Connect instance.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_592934 = newJObject()
  var body_592936 = newJObject()
  if body != nil:
    body_592936 = body
  add(path_592934, "InstanceId", newJString(InstanceId))
  result = call_592933.call(path_592934, nil, nil, nil, body_592936)

var createUser* = Call_CreateUser_592703(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_592704,
                                      base: "/", url: url_CreateUser_592705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_592975 = ref object of OpenApiRestCall_592364
proc url_DescribeUser_592977(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_592976(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : Unique identifier for the user account to return.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_592978 = path.getOrDefault("UserId")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = nil)
  if valid_592978 != nil:
    section.add "UserId", valid_592978
  var valid_592979 = path.getOrDefault("InstanceId")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = nil)
  if valid_592979 != nil:
    section.add "InstanceId", valid_592979
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
  var valid_592980 = header.getOrDefault("X-Amz-Signature")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Signature", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Content-Sha256", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Date")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Date", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Credential")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Credential", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Security-Token")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Security-Token", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Algorithm")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Algorithm", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-SignedHeaders", valid_592986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_DescribeUser_592975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_DescribeUser_592975; UserId: string; InstanceId: string): Recallable =
  ## describeUser
  ## Returns a <code>User</code> object that contains information about the user account specified by the <code>UserId</code>.
  ##   UserId: string (required)
  ##         : Unique identifier for the user account to return.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_592989 = newJObject()
  add(path_592989, "UserId", newJString(UserId))
  add(path_592989, "InstanceId", newJString(InstanceId))
  result = call_592988.call(path_592989, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_592975(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_592976,
    base: "/", url: url_DescribeUser_592977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_592990 = ref object of OpenApiRestCall_592364
proc url_DeleteUser_592992(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_592991(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user account from Amazon Connect.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The unique identifier of the user to delete.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_592993 = path.getOrDefault("UserId")
  valid_592993 = validateParameter(valid_592993, JString, required = true,
                                 default = nil)
  if valid_592993 != nil:
    section.add "UserId", valid_592993
  var valid_592994 = path.getOrDefault("InstanceId")
  valid_592994 = validateParameter(valid_592994, JString, required = true,
                                 default = nil)
  if valid_592994 != nil:
    section.add "InstanceId", valid_592994
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
  var valid_592995 = header.getOrDefault("X-Amz-Signature")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Signature", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-Content-Sha256", valid_592996
  var valid_592997 = header.getOrDefault("X-Amz-Date")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "X-Amz-Date", valid_592997
  var valid_592998 = header.getOrDefault("X-Amz-Credential")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Credential", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Security-Token")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Security-Token", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Algorithm")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Algorithm", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-SignedHeaders", valid_593001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593002: Call_DeleteUser_592990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from Amazon Connect.
  ## 
  let valid = call_593002.validator(path, query, header, formData, body)
  let scheme = call_593002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593002.url(scheme.get, call_593002.host, call_593002.base,
                         call_593002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593002, url, valid)

proc call*(call_593003: Call_DeleteUser_592990; UserId: string; InstanceId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from Amazon Connect.
  ##   UserId: string (required)
  ##         : The unique identifier of the user to delete.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593004 = newJObject()
  add(path_593004, "UserId", newJString(UserId))
  add(path_593004, "InstanceId", newJString(InstanceId))
  result = call_593003.call(path_593004, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_592990(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_592991,
                                      base: "/", url: url_DeleteUser_592992,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_593005 = ref object of OpenApiRestCall_592364
proc url_DescribeUserHierarchyGroup_593007(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_593006(path: JsonNode; query: JsonNode;
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
  var valid_593008 = path.getOrDefault("HierarchyGroupId")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = nil)
  if valid_593008 != nil:
    section.add "HierarchyGroupId", valid_593008
  var valid_593009 = path.getOrDefault("InstanceId")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "InstanceId", valid_593009
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
  var valid_593010 = header.getOrDefault("X-Amz-Signature")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Signature", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-Content-Sha256", valid_593011
  var valid_593012 = header.getOrDefault("X-Amz-Date")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "X-Amz-Date", valid_593012
  var valid_593013 = header.getOrDefault("X-Amz-Credential")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Credential", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Security-Token")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Security-Token", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Algorithm")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Algorithm", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-SignedHeaders", valid_593016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593017: Call_DescribeUserHierarchyGroup_593005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ## 
  let valid = call_593017.validator(path, query, header, formData, body)
  let scheme = call_593017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593017.url(scheme.get, call_593017.host, call_593017.base,
                         call_593017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593017, url, valid)

proc call*(call_593018: Call_DescribeUserHierarchyGroup_593005;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Returns a <code>HierarchyGroup</code> object that includes information about a hierarchy group in your instance.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier for the hierarchy group to return.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593019 = newJObject()
  add(path_593019, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_593019, "InstanceId", newJString(InstanceId))
  result = call_593018.call(path_593019, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_593005(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_593006, base: "/",
    url: url_DescribeUserHierarchyGroup_593007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_593020 = ref object of OpenApiRestCall_592364
proc url_DescribeUserHierarchyStructure_593022(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyStructure_593021(path: JsonNode;
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
  var valid_593023 = path.getOrDefault("InstanceId")
  valid_593023 = validateParameter(valid_593023, JString, required = true,
                                 default = nil)
  if valid_593023 != nil:
    section.add "InstanceId", valid_593023
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
  var valid_593024 = header.getOrDefault("X-Amz-Signature")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Signature", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Content-Sha256", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-Date")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-Date", valid_593026
  var valid_593027 = header.getOrDefault("X-Amz-Credential")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Credential", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Security-Token")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Security-Token", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Algorithm")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Algorithm", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-SignedHeaders", valid_593030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593031: Call_DescribeUserHierarchyStructure_593020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ## 
  let valid = call_593031.validator(path, query, header, formData, body)
  let scheme = call_593031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593031.url(scheme.get, call_593031.host, call_593031.base,
                         call_593031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593031, url, valid)

proc call*(call_593032: Call_DescribeUserHierarchyStructure_593020;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Returns a <code>HiearchyGroupStructure</code> object, which contains data about the levels in the agent hierarchy.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593033 = newJObject()
  add(path_593033, "InstanceId", newJString(InstanceId))
  result = call_593032.call(path_593033, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_593020(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_593021, base: "/",
    url: url_DescribeUserHierarchyStructure_593022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_593034 = ref object of OpenApiRestCall_592364
proc url_GetContactAttributes_593036(protocol: Scheme; host: string; base: string;
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

proc validate_GetContactAttributes_593035(path: JsonNode; query: JsonNode;
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
  var valid_593037 = path.getOrDefault("InitialContactId")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "InitialContactId", valid_593037
  var valid_593038 = path.getOrDefault("InstanceId")
  valid_593038 = validateParameter(valid_593038, JString, required = true,
                                 default = nil)
  if valid_593038 != nil:
    section.add "InstanceId", valid_593038
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
  var valid_593039 = header.getOrDefault("X-Amz-Signature")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Signature", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Content-Sha256", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Date")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Date", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Credential")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Credential", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Security-Token")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Security-Token", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Algorithm")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Algorithm", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-SignedHeaders", valid_593045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593046: Call_GetContactAttributes_593034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes associated with a contact.
  ## 
  let valid = call_593046.validator(path, query, header, formData, body)
  let scheme = call_593046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593046.url(scheme.get, call_593046.host, call_593046.base,
                         call_593046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593046, url, valid)

proc call*(call_593047: Call_GetContactAttributes_593034; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes associated with a contact.
  ##   InitialContactId: string (required)
  ##                   : The ID for the initial contact in Amazon Connect associated with the attributes to update.
  ##   InstanceId: string (required)
  ##             : The instance ID for the instance from which to retrieve contact attributes.
  var path_593048 = newJObject()
  add(path_593048, "InitialContactId", newJString(InitialContactId))
  add(path_593048, "InstanceId", newJString(InstanceId))
  result = call_593047.call(path_593048, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_593034(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_593035, base: "/",
    url: url_GetContactAttributes_593036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_593049 = ref object of OpenApiRestCall_592364
proc url_GetCurrentMetricData_593051(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentMetricData_593050(path: JsonNode; query: JsonNode;
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
  var valid_593052 = path.getOrDefault("InstanceId")
  valid_593052 = validateParameter(valid_593052, JString, required = true,
                                 default = nil)
  if valid_593052 != nil:
    section.add "InstanceId", valid_593052
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593053 = query.getOrDefault("MaxResults")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "MaxResults", valid_593053
  var valid_593054 = query.getOrDefault("NextToken")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "NextToken", valid_593054
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
  var valid_593055 = header.getOrDefault("X-Amz-Signature")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Signature", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Content-Sha256", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Date")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Date", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Credential")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Credential", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-Security-Token")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Security-Token", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Algorithm")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Algorithm", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-SignedHeaders", valid_593061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593063: Call_GetCurrentMetricData_593049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ## 
  let valid = call_593063.validator(path, query, header, formData, body)
  let scheme = call_593063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593063.url(scheme.get, call_593063.host, call_593063.base,
                         call_593063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593063, url, valid)

proc call*(call_593064: Call_GetCurrentMetricData_593049; body: JsonNode;
          InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCurrentMetricData
  ## <p>The <code>GetCurrentMetricData</code> operation retrieves current metric data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetCurrentMetricData</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593065 = newJObject()
  var query_593066 = newJObject()
  var body_593067 = newJObject()
  add(query_593066, "MaxResults", newJString(MaxResults))
  add(query_593066, "NextToken", newJString(NextToken))
  if body != nil:
    body_593067 = body
  add(path_593065, "InstanceId", newJString(InstanceId))
  result = call_593064.call(path_593065, query_593066, nil, nil, body_593067)

var getCurrentMetricData* = Call_GetCurrentMetricData_593049(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_593050, base: "/",
    url: url_GetCurrentMetricData_593051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_593068 = ref object of OpenApiRestCall_592364
proc url_GetFederationToken_593070(protocol: Scheme; host: string; base: string;
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

proc validate_GetFederationToken_593069(path: JsonNode; query: JsonNode;
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
  var valid_593071 = path.getOrDefault("InstanceId")
  valid_593071 = validateParameter(valid_593071, JString, required = true,
                                 default = nil)
  if valid_593071 != nil:
    section.add "InstanceId", valid_593071
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
  var valid_593072 = header.getOrDefault("X-Amz-Signature")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Signature", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Content-Sha256", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Date")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Date", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Credential")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Credential", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Security-Token")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Security-Token", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Algorithm")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Algorithm", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-SignedHeaders", valid_593078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593079: Call_GetFederationToken_593068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_593079.validator(path, query, header, formData, body)
  let scheme = call_593079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593079.url(scheme.get, call_593079.host, call_593079.base,
                         call_593079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593079, url, valid)

proc call*(call_593080: Call_GetFederationToken_593068; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593081 = newJObject()
  add(path_593081, "InstanceId", newJString(InstanceId))
  result = call_593080.call(path_593081, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_593068(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_593069, base: "/",
    url: url_GetFederationToken_593070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_593082 = ref object of OpenApiRestCall_592364
proc url_GetMetricData_593084(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_593083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593085 = path.getOrDefault("InstanceId")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = nil)
  if valid_593085 != nil:
    section.add "InstanceId", valid_593085
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_593086 = query.getOrDefault("MaxResults")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "MaxResults", valid_593086
  var valid_593087 = query.getOrDefault("NextToken")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "NextToken", valid_593087
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
  var valid_593088 = header.getOrDefault("X-Amz-Signature")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Signature", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Content-Sha256", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Date")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Date", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Credential")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Credential", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Security-Token")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Security-Token", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Algorithm")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Algorithm", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-SignedHeaders", valid_593094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593096: Call_GetMetricData_593082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ## 
  let valid = call_593096.validator(path, query, header, formData, body)
  let scheme = call_593096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593096.url(scheme.get, call_593096.host, call_593096.base,
                         call_593096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593096, url, valid)

proc call*(call_593097: Call_GetMetricData_593082; body: JsonNode;
          InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMetricData
  ## <p>The <code>GetMetricData</code> operation retrieves historical metrics data from your Amazon Connect instance.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:GetMetricData</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593098 = newJObject()
  var query_593099 = newJObject()
  var body_593100 = newJObject()
  add(query_593099, "MaxResults", newJString(MaxResults))
  add(query_593099, "NextToken", newJString(NextToken))
  if body != nil:
    body_593100 = body
  add(path_593098, "InstanceId", newJString(InstanceId))
  result = call_593097.call(path_593098, query_593099, nil, nil, body_593100)

var getMetricData* = Call_GetMetricData_593082(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_593083,
    base: "/", url: url_GetMetricData_593084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_593101 = ref object of OpenApiRestCall_592364
proc url_ListRoutingProfiles_593103(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutingProfiles_593102(path: JsonNode; query: JsonNode;
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
  var valid_593104 = path.getOrDefault("InstanceId")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "InstanceId", valid_593104
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of routing profiles to return in the response.
  section = newJObject()
  var valid_593105 = query.getOrDefault("nextToken")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "nextToken", valid_593105
  var valid_593106 = query.getOrDefault("maxResults")
  valid_593106 = validateParameter(valid_593106, JInt, required = false, default = nil)
  if valid_593106 != nil:
    section.add "maxResults", valid_593106
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
  var valid_593107 = header.getOrDefault("X-Amz-Signature")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Signature", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Content-Sha256", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-Date")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-Date", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Credential")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Credential", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Security-Token")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Security-Token", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Algorithm")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Algorithm", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-SignedHeaders", valid_593113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_ListRoutingProfiles_593101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_ListRoutingProfiles_593101; InstanceId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRoutingProfiles
  ## Returns an array of <code>RoutingProfileSummary</code> objects that includes information about the routing profiles in your instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of routing profiles to return in the response.
  var path_593116 = newJObject()
  var query_593117 = newJObject()
  add(query_593117, "nextToken", newJString(nextToken))
  add(path_593116, "InstanceId", newJString(InstanceId))
  add(query_593117, "maxResults", newJInt(maxResults))
  result = call_593115.call(path_593116, query_593117, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_593101(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_593102, base: "/",
    url: url_ListRoutingProfiles_593103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_593118 = ref object of OpenApiRestCall_592364
proc url_ListSecurityProfiles_593120(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecurityProfiles_593119(path: JsonNode; query: JsonNode;
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
  var valid_593121 = path.getOrDefault("InstanceId")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "InstanceId", valid_593121
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of security profiles to return.
  section = newJObject()
  var valid_593122 = query.getOrDefault("nextToken")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "nextToken", valid_593122
  var valid_593123 = query.getOrDefault("maxResults")
  valid_593123 = validateParameter(valid_593123, JInt, required = false, default = nil)
  if valid_593123 != nil:
    section.add "maxResults", valid_593123
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
  var valid_593124 = header.getOrDefault("X-Amz-Signature")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-Signature", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Content-Sha256", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Date")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Date", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Credential")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Credential", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Security-Token")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Security-Token", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Algorithm")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Algorithm", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-SignedHeaders", valid_593130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593131: Call_ListSecurityProfiles_593118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ## 
  let valid = call_593131.validator(path, query, header, formData, body)
  let scheme = call_593131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593131.url(scheme.get, call_593131.host, call_593131.base,
                         call_593131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593131, url, valid)

proc call*(call_593132: Call_ListSecurityProfiles_593118; InstanceId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listSecurityProfiles
  ## Returns an array of SecurityProfileSummary objects that contain information about the security profiles in your instance, including the ARN, Id, and Name of the security profile.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of security profiles to return.
  var path_593133 = newJObject()
  var query_593134 = newJObject()
  add(query_593134, "nextToken", newJString(nextToken))
  add(path_593133, "InstanceId", newJString(InstanceId))
  add(query_593134, "maxResults", newJInt(maxResults))
  result = call_593132.call(path_593133, query_593134, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_593118(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_593119, base: "/",
    url: url_ListSecurityProfiles_593120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_593135 = ref object of OpenApiRestCall_592364
proc url_ListUserHierarchyGroups_593137(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserHierarchyGroups_593136(path: JsonNode; query: JsonNode;
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
  var valid_593138 = path.getOrDefault("InstanceId")
  valid_593138 = validateParameter(valid_593138, JString, required = true,
                                 default = nil)
  if valid_593138 != nil:
    section.add "InstanceId", valid_593138
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of hierarchy groups to return.
  section = newJObject()
  var valid_593139 = query.getOrDefault("nextToken")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "nextToken", valid_593139
  var valid_593140 = query.getOrDefault("maxResults")
  valid_593140 = validateParameter(valid_593140, JInt, required = false, default = nil)
  if valid_593140 != nil:
    section.add "maxResults", valid_593140
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
  if body != nil:
    result.add "body", body

proc call*(call_593148: Call_ListUserHierarchyGroups_593135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ## 
  let valid = call_593148.validator(path, query, header, formData, body)
  let scheme = call_593148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593148.url(scheme.get, call_593148.host, call_593148.base,
                         call_593148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593148, url, valid)

proc call*(call_593149: Call_ListUserHierarchyGroups_593135; InstanceId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listUserHierarchyGroups
  ## Returns a <code>UserHierarchyGroupSummaryList</code>, which is an array of <code>HierarchyGroupSummary</code> objects that contain information about the hierarchy groups in your instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of hierarchy groups to return.
  var path_593150 = newJObject()
  var query_593151 = newJObject()
  add(query_593151, "nextToken", newJString(nextToken))
  add(path_593150, "InstanceId", newJString(InstanceId))
  add(query_593151, "maxResults", newJInt(maxResults))
  result = call_593149.call(path_593150, query_593151, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_593135(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_593136, base: "/",
    url: url_ListUserHierarchyGroups_593137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_593152 = ref object of OpenApiRestCall_592364
proc url_ListUsers_593154(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_593153(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593155 = path.getOrDefault("InstanceId")
  valid_593155 = validateParameter(valid_593155, JString, required = true,
                                 default = nil)
  if valid_593155 != nil:
    section.add "InstanceId", valid_593155
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  section = newJObject()
  var valid_593156 = query.getOrDefault("nextToken")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "nextToken", valid_593156
  var valid_593157 = query.getOrDefault("maxResults")
  valid_593157 = validateParameter(valid_593157, JInt, required = false, default = nil)
  if valid_593157 != nil:
    section.add "maxResults", valid_593157
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
  var valid_593158 = header.getOrDefault("X-Amz-Signature")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Signature", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Content-Sha256", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Date")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Date", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Credential")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Credential", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Security-Token")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Security-Token", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Algorithm")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Algorithm", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-SignedHeaders", valid_593164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_ListUsers_593152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_ListUsers_593152; InstanceId: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listUsers
  ## Returns a <code>UserSummaryList</code>, which is an array of <code>UserSummary</code> objects.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  var path_593167 = newJObject()
  var query_593168 = newJObject()
  add(query_593168, "nextToken", newJString(nextToken))
  add(path_593167, "InstanceId", newJString(InstanceId))
  add(query_593168, "maxResults", newJInt(maxResults))
  result = call_593166.call(path_593167, query_593168, nil, nil, nil)

var listUsers* = Call_ListUsers_593152(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_593153,
                                    base: "/", url: url_ListUsers_593154,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_593169 = ref object of OpenApiRestCall_592364
proc url_StartOutboundVoiceContact_593171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartOutboundVoiceContact_593170(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593172 = header.getOrDefault("X-Amz-Signature")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Signature", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Content-Sha256", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Date")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Date", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Credential")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Credential", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Security-Token")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Security-Token", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Algorithm")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Algorithm", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-SignedHeaders", valid_593178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593180: Call_StartOutboundVoiceContact_593169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ## 
  let valid = call_593180.validator(path, query, header, formData, body)
  let scheme = call_593180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593180.url(scheme.get, call_593180.host, call_593180.base,
                         call_593180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593180, url, valid)

proc call*(call_593181: Call_StartOutboundVoiceContact_593169; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>The <code>StartOutboundVoiceContact</code> operation initiates a contact flow to place an outbound call to a customer.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StartOutboundVoiceContact</code> action.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, the call fails.</p>
  ##   body: JObject (required)
  var body_593182 = newJObject()
  if body != nil:
    body_593182 = body
  result = call_593181.call(nil, nil, nil, nil, body_593182)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_593169(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_593170, base: "/",
    url: url_StartOutboundVoiceContact_593171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_593183 = ref object of OpenApiRestCall_592364
proc url_StopContact_593185(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopContact_593184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593194: Call_StopContact_593183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ## 
  let valid = call_593194.validator(path, query, header, formData, body)
  let scheme = call_593194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593194.url(scheme.get, call_593194.host, call_593194.base,
                         call_593194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593194, url, valid)

proc call*(call_593195: Call_StopContact_593183; body: JsonNode): Recallable =
  ## stopContact
  ## <p>Ends the contact initiated by the <code>StartOutboundVoiceContact</code> operation.</p> <p>If you are using an IAM account, it must have permission to the <code>connect:StopContact</code> action.</p>
  ##   body: JObject (required)
  var body_593196 = newJObject()
  if body != nil:
    body_593196 = body
  result = call_593195.call(nil, nil, nil, nil, body_593196)

var stopContact* = Call_StopContact_593183(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_593184,
                                        base: "/", url: url_StopContact_593185,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_593197 = ref object of OpenApiRestCall_592364
proc url_UpdateContactAttributes_593199(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContactAttributes_593198(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593200 = header.getOrDefault("X-Amz-Signature")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Signature", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Content-Sha256", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Date")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Date", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Credential")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Credential", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Security-Token")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Security-Token", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-Algorithm")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Algorithm", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-SignedHeaders", valid_593206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593208: Call_UpdateContactAttributes_593197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_593208.validator(path, query, header, formData, body)
  let scheme = call_593208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593208.url(scheme.get, call_593208.host, call_593208.base,
                         call_593208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593208, url, valid)

proc call*(call_593209: Call_UpdateContactAttributes_593197; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>The <code>UpdateContactAttributes</code> operation lets you programmatically create new, or update existing, contact attributes associated with a contact. You can use the operation to add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also use the <code>UpdateContactAttributes</code> operation to update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <i>Important:</i> </p> <p>You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_593210 = newJObject()
  if body != nil:
    body_593210 = body
  result = call_593209.call(nil, nil, nil, nil, body_593210)

var updateContactAttributes* = Call_UpdateContactAttributes_593197(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_593198, base: "/",
    url: url_UpdateContactAttributes_593199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_593211 = ref object of OpenApiRestCall_592364
proc url_UpdateUserHierarchy_593213(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserHierarchy_593212(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Assigns the specified hierarchy group to the user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_593214 = path.getOrDefault("UserId")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = nil)
  if valid_593214 != nil:
    section.add "UserId", valid_593214
  var valid_593215 = path.getOrDefault("InstanceId")
  valid_593215 = validateParameter(valid_593215, JString, required = true,
                                 default = nil)
  if valid_593215 != nil:
    section.add "InstanceId", valid_593215
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
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593224: Call_UpdateUserHierarchy_593211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the user.
  ## 
  let valid = call_593224.validator(path, query, header, formData, body)
  let scheme = call_593224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593224.url(scheme.get, call_593224.host, call_593224.base,
                         call_593224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593224, url, valid)

proc call*(call_593225: Call_UpdateUserHierarchy_593211; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the user.
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the hierarchy group to.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593226 = newJObject()
  var body_593227 = newJObject()
  add(path_593226, "UserId", newJString(UserId))
  if body != nil:
    body_593227 = body
  add(path_593226, "InstanceId", newJString(InstanceId))
  result = call_593225.call(path_593226, nil, nil, nil, body_593227)

var updateUserHierarchy* = Call_UpdateUserHierarchy_593211(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_593212, base: "/",
    url: url_UpdateUserHierarchy_593213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_593228 = ref object of OpenApiRestCall_592364
proc url_UpdateUserIdentityInfo_593230(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserIdentityInfo_593229(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier for the user account to update identity information for.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_593231 = path.getOrDefault("UserId")
  valid_593231 = validateParameter(valid_593231, JString, required = true,
                                 default = nil)
  if valid_593231 != nil:
    section.add "UserId", valid_593231
  var valid_593232 = path.getOrDefault("InstanceId")
  valid_593232 = validateParameter(valid_593232, JString, required = true,
                                 default = nil)
  if valid_593232 != nil:
    section.add "InstanceId", valid_593232
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
  var valid_593233 = header.getOrDefault("X-Amz-Signature")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Signature", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Content-Sha256", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Date")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Date", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Credential")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Credential", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Security-Token")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Security-Token", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Algorithm")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Algorithm", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-SignedHeaders", valid_593239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593241: Call_UpdateUserIdentityInfo_593228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ## 
  let valid = call_593241.validator(path, query, header, formData, body)
  let scheme = call_593241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593241.url(scheme.get, call_593241.host, call_593241.base,
                         call_593241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593241, url, valid)

proc call*(call_593242: Call_UpdateUserIdentityInfo_593228; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user in a <code>UserIdentityInfo</code> object, including email, first name, and last name.
  ##   UserId: string (required)
  ##         : The identifier for the user account to update identity information for.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593243 = newJObject()
  var body_593244 = newJObject()
  add(path_593243, "UserId", newJString(UserId))
  if body != nil:
    body_593244 = body
  add(path_593243, "InstanceId", newJString(InstanceId))
  result = call_593242.call(path_593243, nil, nil, nil, body_593244)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_593228(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_593229, base: "/",
    url: url_UpdateUserIdentityInfo_593230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_593245 = ref object of OpenApiRestCall_592364
proc url_UpdateUserPhoneConfig_593247(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPhoneConfig_593246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier for the user account to change phone settings for.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_593248 = path.getOrDefault("UserId")
  valid_593248 = validateParameter(valid_593248, JString, required = true,
                                 default = nil)
  if valid_593248 != nil:
    section.add "UserId", valid_593248
  var valid_593249 = path.getOrDefault("InstanceId")
  valid_593249 = validateParameter(valid_593249, JString, required = true,
                                 default = nil)
  if valid_593249 != nil:
    section.add "InstanceId", valid_593249
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
  var valid_593250 = header.getOrDefault("X-Amz-Signature")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Signature", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Content-Sha256", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Date")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Date", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Credential")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Credential", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Security-Token")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Security-Token", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-Algorithm")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-Algorithm", valid_593255
  var valid_593256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "X-Amz-SignedHeaders", valid_593256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593258: Call_UpdateUserPhoneConfig_593245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ## 
  let valid = call_593258.validator(path, query, header, formData, body)
  let scheme = call_593258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593258.url(scheme.get, call_593258.host, call_593258.base,
                         call_593258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593258, url, valid)

proc call*(call_593259: Call_UpdateUserPhoneConfig_593245; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings in the <code>UserPhoneConfig</code> object for the specified user.
  ##   UserId: string (required)
  ##         : The identifier for the user account to change phone settings for.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593260 = newJObject()
  var body_593261 = newJObject()
  add(path_593260, "UserId", newJString(UserId))
  if body != nil:
    body_593261 = body
  add(path_593260, "InstanceId", newJString(InstanceId))
  result = call_593259.call(path_593260, nil, nil, nil, body_593261)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_593245(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_593246, base: "/",
    url: url_UpdateUserPhoneConfig_593247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_593262 = ref object of OpenApiRestCall_592364
proc url_UpdateUserRoutingProfile_593264(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_593263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns the specified routing profile to a user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier for the user account to assign the routing profile to.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_593265 = path.getOrDefault("UserId")
  valid_593265 = validateParameter(valid_593265, JString, required = true,
                                 default = nil)
  if valid_593265 != nil:
    section.add "UserId", valid_593265
  var valid_593266 = path.getOrDefault("InstanceId")
  valid_593266 = validateParameter(valid_593266, JString, required = true,
                                 default = nil)
  if valid_593266 != nil:
    section.add "InstanceId", valid_593266
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
  var valid_593267 = header.getOrDefault("X-Amz-Signature")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Signature", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Content-Sha256", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Date")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Date", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-Credential")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-Credential", valid_593270
  var valid_593271 = header.getOrDefault("X-Amz-Security-Token")
  valid_593271 = validateParameter(valid_593271, JString, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "X-Amz-Security-Token", valid_593271
  var valid_593272 = header.getOrDefault("X-Amz-Algorithm")
  valid_593272 = validateParameter(valid_593272, JString, required = false,
                                 default = nil)
  if valid_593272 != nil:
    section.add "X-Amz-Algorithm", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-SignedHeaders", valid_593273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593275: Call_UpdateUserRoutingProfile_593262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to a user.
  ## 
  let valid = call_593275.validator(path, query, header, formData, body)
  let scheme = call_593275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593275.url(scheme.get, call_593275.host, call_593275.base,
                         call_593275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593275, url, valid)

proc call*(call_593276: Call_UpdateUserRoutingProfile_593262; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to a user.
  ##   UserId: string (required)
  ##         : The identifier for the user account to assign the routing profile to.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593277 = newJObject()
  var body_593278 = newJObject()
  add(path_593277, "UserId", newJString(UserId))
  if body != nil:
    body_593278 = body
  add(path_593277, "InstanceId", newJString(InstanceId))
  result = call_593276.call(path_593277, nil, nil, nil, body_593278)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_593262(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_593263, base: "/",
    url: url_UpdateUserRoutingProfile_593264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_593279 = ref object of OpenApiRestCall_592364
proc url_UpdateUserSecurityProfiles_593281(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_593280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the security profiles assigned to the user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account to assign the security profiles.
  ##   InstanceId: JString (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_593282 = path.getOrDefault("UserId")
  valid_593282 = validateParameter(valid_593282, JString, required = true,
                                 default = nil)
  if valid_593282 != nil:
    section.add "UserId", valid_593282
  var valid_593283 = path.getOrDefault("InstanceId")
  valid_593283 = validateParameter(valid_593283, JString, required = true,
                                 default = nil)
  if valid_593283 != nil:
    section.add "InstanceId", valid_593283
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
  var valid_593284 = header.getOrDefault("X-Amz-Signature")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Signature", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Content-Sha256", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Date")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Date", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Credential")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Credential", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Security-Token")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Security-Token", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Algorithm")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Algorithm", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-SignedHeaders", valid_593290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593292: Call_UpdateUserSecurityProfiles_593279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the security profiles assigned to the user.
  ## 
  let valid = call_593292.validator(path, query, header, formData, body)
  let scheme = call_593292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593292.url(scheme.get, call_593292.host, call_593292.base,
                         call_593292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593292, url, valid)

proc call*(call_593293: Call_UpdateUserSecurityProfiles_593279; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Updates the security profiles assigned to the user.
  ##   UserId: string (required)
  ##         : The identifier of the user account to assign the security profiles.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier for your Amazon Connect instance. To find the ID of your instance, open the AWS console and select Amazon Connect. Select the alias of the instance in the Instance alias column. The instance ID is displayed in the Overview section of your instance settings. For example, the instance ID is the set of characters at the end of the instance ARN, after instance/, such as 10a4c4eb-f57e-4d4c-b602-bf39176ced07.
  var path_593294 = newJObject()
  var body_593295 = newJObject()
  add(path_593294, "UserId", newJString(UserId))
  if body != nil:
    body_593295 = body
  add(path_593294, "InstanceId", newJString(InstanceId))
  result = call_593293.call(path_593294, nil, nil, nil, body_593295)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_593279(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_593280, base: "/",
    url: url_UpdateUserSecurityProfiles_593281,
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
