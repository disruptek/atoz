
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateUser_605927 = ref object of OpenApiRestCall_605589
proc url_CreateUser_605929(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateUser_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606055 = path.getOrDefault("InstanceId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "InstanceId", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_CreateUser_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_CreateUser_605927; body: JsonNode; InstanceId: string): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606158 = newJObject()
  var body_606160 = newJObject()
  if body != nil:
    body_606160 = body
  add(path_606158, "InstanceId", newJString(InstanceId))
  result = call_606157.call(path_606158, nil, nil, nil, body_606160)

var createUser* = Call_CreateUser_605927(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_605928,
                                      base: "/", url: url_CreateUser_605929,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_606199 = ref object of OpenApiRestCall_605589
proc url_DescribeUser_606201(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_606200(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606202 = path.getOrDefault("UserId")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "UserId", valid_606202
  var valid_606203 = path.getOrDefault("InstanceId")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = nil)
  if valid_606203 != nil:
    section.add "InstanceId", valid_606203
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_DescribeUser_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_DescribeUser_606199; UserId: string; InstanceId: string): Recallable =
  ## describeUser
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606213 = newJObject()
  add(path_606213, "UserId", newJString(UserId))
  add(path_606213, "InstanceId", newJString(InstanceId))
  result = call_606212.call(path_606213, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_606199(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_606200,
    base: "/", url: url_DescribeUser_606201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_606214 = ref object of OpenApiRestCall_605589
proc url_DeleteUser_606216(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_606215(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606217 = path.getOrDefault("UserId")
  valid_606217 = validateParameter(valid_606217, JString, required = true,
                                 default = nil)
  if valid_606217 != nil:
    section.add "UserId", valid_606217
  var valid_606218 = path.getOrDefault("InstanceId")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "InstanceId", valid_606218
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_DeleteUser_606214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_DeleteUser_606214; UserId: string; InstanceId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606228 = newJObject()
  add(path_606228, "UserId", newJString(UserId))
  add(path_606228, "InstanceId", newJString(InstanceId))
  result = call_606227.call(path_606228, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_606214(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_606215,
                                      base: "/", url: url_DeleteUser_606216,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_606229 = ref object of OpenApiRestCall_605589
proc url_DescribeUserHierarchyGroup_606231(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUserHierarchyGroup_606230(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606232 = path.getOrDefault("HierarchyGroupId")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = nil)
  if valid_606232 != nil:
    section.add "HierarchyGroupId", valid_606232
  var valid_606233 = path.getOrDefault("InstanceId")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "InstanceId", valid_606233
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
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606241: Call_DescribeUserHierarchyGroup_606229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified hierarchy group.
  ## 
  let valid = call_606241.validator(path, query, header, formData, body)
  let scheme = call_606241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606241.url(scheme.get, call_606241.host, call_606241.base,
                         call_606241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606241, url, valid)

proc call*(call_606242: Call_DescribeUserHierarchyGroup_606229;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606243 = newJObject()
  add(path_606243, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_606243, "InstanceId", newJString(InstanceId))
  result = call_606242.call(path_606243, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_606229(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_606230, base: "/",
    url: url_DescribeUserHierarchyGroup_606231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_606244 = ref object of OpenApiRestCall_605589
proc url_DescribeUserHierarchyStructure_606246(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUserHierarchyStructure_606245(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606247 = path.getOrDefault("InstanceId")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = nil)
  if valid_606247 != nil:
    section.add "InstanceId", valid_606247
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
  var valid_606248 = header.getOrDefault("X-Amz-Signature")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Signature", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Content-Sha256", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Date")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Date", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Credential")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Credential", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Security-Token")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Security-Token", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Algorithm")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Algorithm", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-SignedHeaders", valid_606254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_DescribeUserHierarchyStructure_606244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_DescribeUserHierarchyStructure_606244;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606257 = newJObject()
  add(path_606257, "InstanceId", newJString(InstanceId))
  result = call_606256.call(path_606257, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_606244(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_606245, base: "/",
    url: url_DescribeUserHierarchyStructure_606246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_606258 = ref object of OpenApiRestCall_605589
proc url_GetContactAttributes_606260(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetContactAttributes_606259(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606261 = path.getOrDefault("InitialContactId")
  valid_606261 = validateParameter(valid_606261, JString, required = true,
                                 default = nil)
  if valid_606261 != nil:
    section.add "InitialContactId", valid_606261
  var valid_606262 = path.getOrDefault("InstanceId")
  valid_606262 = validateParameter(valid_606262, JString, required = true,
                                 default = nil)
  if valid_606262 != nil:
    section.add "InstanceId", valid_606262
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
  var valid_606263 = header.getOrDefault("X-Amz-Signature")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Signature", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Content-Sha256", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Date")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Date", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Credential")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Credential", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Security-Token")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Security-Token", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Algorithm")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Algorithm", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-SignedHeaders", valid_606269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606270: Call_GetContactAttributes_606258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  let valid = call_606270.validator(path, query, header, formData, body)
  let scheme = call_606270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606270.url(scheme.get, call_606270.host, call_606270.base,
                         call_606270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606270, url, valid)

proc call*(call_606271: Call_GetContactAttributes_606258; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InitialContactId: string (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606272 = newJObject()
  add(path_606272, "InitialContactId", newJString(InitialContactId))
  add(path_606272, "InstanceId", newJString(InstanceId))
  result = call_606271.call(path_606272, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_606258(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_606259, base: "/",
    url: url_GetContactAttributes_606260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_606273 = ref object of OpenApiRestCall_605589
proc url_GetCurrentMetricData_606275(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCurrentMetricData_606274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606276 = path.getOrDefault("InstanceId")
  valid_606276 = validateParameter(valid_606276, JString, required = true,
                                 default = nil)
  if valid_606276 != nil:
    section.add "InstanceId", valid_606276
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606277 = query.getOrDefault("MaxResults")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "MaxResults", valid_606277
  var valid_606278 = query.getOrDefault("NextToken")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "NextToken", valid_606278
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
  var valid_606279 = header.getOrDefault("X-Amz-Signature")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Signature", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Content-Sha256", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Date")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Date", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Credential")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Credential", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Security-Token")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Security-Token", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Algorithm")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Algorithm", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-SignedHeaders", valid_606285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606287: Call_GetCurrentMetricData_606273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_606287.validator(path, query, header, formData, body)
  let scheme = call_606287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606287.url(scheme.get, call_606287.host, call_606287.base,
                         call_606287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606287, url, valid)

proc call*(call_606288: Call_GetCurrentMetricData_606273; body: JsonNode;
          InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCurrentMetricData
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606289 = newJObject()
  var query_606290 = newJObject()
  var body_606291 = newJObject()
  add(query_606290, "MaxResults", newJString(MaxResults))
  add(query_606290, "NextToken", newJString(NextToken))
  if body != nil:
    body_606291 = body
  add(path_606289, "InstanceId", newJString(InstanceId))
  result = call_606288.call(path_606289, query_606290, nil, nil, body_606291)

var getCurrentMetricData* = Call_GetCurrentMetricData_606273(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_606274, base: "/",
    url: url_GetCurrentMetricData_606275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_606292 = ref object of OpenApiRestCall_605589
proc url_GetFederationToken_606294(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFederationToken_606293(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_606295 = path.getOrDefault("InstanceId")
  valid_606295 = validateParameter(valid_606295, JString, required = true,
                                 default = nil)
  if valid_606295 != nil:
    section.add "InstanceId", valid_606295
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
  var valid_606296 = header.getOrDefault("X-Amz-Signature")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Signature", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Content-Sha256", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Date")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Date", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Credential")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Credential", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Security-Token")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Security-Token", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Algorithm")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Algorithm", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-SignedHeaders", valid_606302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606303: Call_GetFederationToken_606292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_606303.validator(path, query, header, formData, body)
  let scheme = call_606303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606303.url(scheme.get, call_606303.host, call_606303.base,
                         call_606303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606303, url, valid)

proc call*(call_606304: Call_GetFederationToken_606292; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606305 = newJObject()
  add(path_606305, "InstanceId", newJString(InstanceId))
  result = call_606304.call(path_606305, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_606292(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_606293, base: "/",
    url: url_GetFederationToken_606294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_606306 = ref object of OpenApiRestCall_605589
proc url_GetMetricData_606308(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMetricData_606307(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606309 = path.getOrDefault("InstanceId")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = nil)
  if valid_606309 != nil:
    section.add "InstanceId", valid_606309
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606310 = query.getOrDefault("MaxResults")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "MaxResults", valid_606310
  var valid_606311 = query.getOrDefault("NextToken")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "NextToken", valid_606311
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
  var valid_606312 = header.getOrDefault("X-Amz-Signature")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Signature", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Content-Sha256", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Date")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Date", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Credential")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Credential", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Security-Token")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Security-Token", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Algorithm")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Algorithm", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-SignedHeaders", valid_606318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_GetMetricData_606306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_GetMetricData_606306; body: JsonNode;
          InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMetricData
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606322 = newJObject()
  var query_606323 = newJObject()
  var body_606324 = newJObject()
  add(query_606323, "MaxResults", newJString(MaxResults))
  add(query_606323, "NextToken", newJString(NextToken))
  if body != nil:
    body_606324 = body
  add(path_606322, "InstanceId", newJString(InstanceId))
  result = call_606321.call(path_606322, query_606323, nil, nil, body_606324)

var getMetricData* = Call_GetMetricData_606306(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_606307,
    base: "/", url: url_GetMetricData_606308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_606325 = ref object of OpenApiRestCall_605589
proc url_ListContactFlows_606327(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListContactFlows_606326(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606328 = path.getOrDefault("InstanceId")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "InstanceId", valid_606328
  result.add "path", section
  ## parameters in `query` object:
  ##   contactFlowTypes: JArray
  ##                   : The type of contact flow.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606329 = query.getOrDefault("contactFlowTypes")
  valid_606329 = validateParameter(valid_606329, JArray, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "contactFlowTypes", valid_606329
  var valid_606330 = query.getOrDefault("nextToken")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "nextToken", valid_606330
  var valid_606331 = query.getOrDefault("MaxResults")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "MaxResults", valid_606331
  var valid_606332 = query.getOrDefault("NextToken")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "NextToken", valid_606332
  var valid_606333 = query.getOrDefault("maxResults")
  valid_606333 = validateParameter(valid_606333, JInt, required = false, default = nil)
  if valid_606333 != nil:
    section.add "maxResults", valid_606333
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
  var valid_606334 = header.getOrDefault("X-Amz-Signature")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Signature", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Content-Sha256", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Date")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Date", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Credential")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Credential", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Security-Token")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Security-Token", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Algorithm")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Algorithm", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-SignedHeaders", valid_606340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606341: Call_ListContactFlows_606325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  let valid = call_606341.validator(path, query, header, formData, body)
  let scheme = call_606341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606341.url(scheme.get, call_606341.host, call_606341.base,
                         call_606341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606341, url, valid)

proc call*(call_606342: Call_ListContactFlows_606325; InstanceId: string;
          contactFlowTypes: JsonNode = nil; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listContactFlows
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ##   contactFlowTypes: JArray
  ##                   : The type of contact flow.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606343 = newJObject()
  var query_606344 = newJObject()
  if contactFlowTypes != nil:
    query_606344.add "contactFlowTypes", contactFlowTypes
  add(query_606344, "nextToken", newJString(nextToken))
  add(query_606344, "MaxResults", newJString(MaxResults))
  add(query_606344, "NextToken", newJString(NextToken))
  add(path_606343, "InstanceId", newJString(InstanceId))
  add(query_606344, "maxResults", newJInt(maxResults))
  result = call_606342.call(path_606343, query_606344, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_606325(name: "listContactFlows",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_606326, base: "/",
    url: url_ListContactFlows_606327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_606345 = ref object of OpenApiRestCall_605589
proc url_ListHoursOfOperations_606347(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListHoursOfOperations_606346(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606348 = path.getOrDefault("InstanceId")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = nil)
  if valid_606348 != nil:
    section.add "InstanceId", valid_606348
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606349 = query.getOrDefault("nextToken")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "nextToken", valid_606349
  var valid_606350 = query.getOrDefault("MaxResults")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "MaxResults", valid_606350
  var valid_606351 = query.getOrDefault("NextToken")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "NextToken", valid_606351
  var valid_606352 = query.getOrDefault("maxResults")
  valid_606352 = validateParameter(valid_606352, JInt, required = false, default = nil)
  if valid_606352 != nil:
    section.add "maxResults", valid_606352
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
  var valid_606353 = header.getOrDefault("X-Amz-Signature")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Signature", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Content-Sha256", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Date")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Date", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Credential")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Credential", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Security-Token")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Security-Token", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Algorithm")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Algorithm", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-SignedHeaders", valid_606359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606360: Call_ListHoursOfOperations_606345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  let valid = call_606360.validator(path, query, header, formData, body)
  let scheme = call_606360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606360.url(scheme.get, call_606360.host, call_606360.base,
                         call_606360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606360, url, valid)

proc call*(call_606361: Call_ListHoursOfOperations_606345; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listHoursOfOperations
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606362 = newJObject()
  var query_606363 = newJObject()
  add(query_606363, "nextToken", newJString(nextToken))
  add(query_606363, "MaxResults", newJString(MaxResults))
  add(query_606363, "NextToken", newJString(NextToken))
  add(path_606362, "InstanceId", newJString(InstanceId))
  add(query_606363, "maxResults", newJInt(maxResults))
  result = call_606361.call(path_606362, query_606363, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_606345(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_606346, base: "/",
    url: url_ListHoursOfOperations_606347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_606364 = ref object of OpenApiRestCall_605589
proc url_ListPhoneNumbers_606366(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPhoneNumbers_606365(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606367 = path.getOrDefault("InstanceId")
  valid_606367 = validateParameter(valid_606367, JString, required = true,
                                 default = nil)
  if valid_606367 != nil:
    section.add "InstanceId", valid_606367
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumberCountryCodes: JArray
  ##                          : The ISO country code.
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   phoneNumberTypes: JArray
  ##                   : The type of phone number.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606368 = query.getOrDefault("phoneNumberCountryCodes")
  valid_606368 = validateParameter(valid_606368, JArray, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "phoneNumberCountryCodes", valid_606368
  var valid_606369 = query.getOrDefault("nextToken")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "nextToken", valid_606369
  var valid_606370 = query.getOrDefault("MaxResults")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "MaxResults", valid_606370
  var valid_606371 = query.getOrDefault("phoneNumberTypes")
  valid_606371 = validateParameter(valid_606371, JArray, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "phoneNumberTypes", valid_606371
  var valid_606372 = query.getOrDefault("NextToken")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "NextToken", valid_606372
  var valid_606373 = query.getOrDefault("maxResults")
  valid_606373 = validateParameter(valid_606373, JInt, required = false, default = nil)
  if valid_606373 != nil:
    section.add "maxResults", valid_606373
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
  var valid_606374 = header.getOrDefault("X-Amz-Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Signature", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Content-Sha256", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Date")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Date", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Credential")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Credential", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Security-Token")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Security-Token", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Algorithm")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Algorithm", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-SignedHeaders", valid_606380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606381: Call_ListPhoneNumbers_606364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  let valid = call_606381.validator(path, query, header, formData, body)
  let scheme = call_606381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606381.url(scheme.get, call_606381.host, call_606381.base,
                         call_606381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606381, url, valid)

proc call*(call_606382: Call_ListPhoneNumbers_606364; InstanceId: string;
          phoneNumberCountryCodes: JsonNode = nil; nextToken: string = "";
          MaxResults: string = ""; phoneNumberTypes: JsonNode = nil;
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listPhoneNumbers
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ##   phoneNumberCountryCodes: JArray
  ##                          : The ISO country code.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   phoneNumberTypes: JArray
  ##                   : The type of phone number.
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606383 = newJObject()
  var query_606384 = newJObject()
  if phoneNumberCountryCodes != nil:
    query_606384.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  add(query_606384, "nextToken", newJString(nextToken))
  add(query_606384, "MaxResults", newJString(MaxResults))
  if phoneNumberTypes != nil:
    query_606384.add "phoneNumberTypes", phoneNumberTypes
  add(query_606384, "NextToken", newJString(NextToken))
  add(path_606383, "InstanceId", newJString(InstanceId))
  add(query_606384, "maxResults", newJInt(maxResults))
  result = call_606382.call(path_606383, query_606384, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_606364(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_606365, base: "/",
    url: url_ListPhoneNumbers_606366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_606385 = ref object of OpenApiRestCall_605589
proc url_ListQueues_606387(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListQueues_606386(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606388 = path.getOrDefault("InstanceId")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "InstanceId", valid_606388
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   queueTypes: JArray
  ##             : The type of queue.
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606389 = query.getOrDefault("nextToken")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "nextToken", valid_606389
  var valid_606390 = query.getOrDefault("MaxResults")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "MaxResults", valid_606390
  var valid_606391 = query.getOrDefault("NextToken")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "NextToken", valid_606391
  var valid_606392 = query.getOrDefault("queueTypes")
  valid_606392 = validateParameter(valid_606392, JArray, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "queueTypes", valid_606392
  var valid_606393 = query.getOrDefault("maxResults")
  valid_606393 = validateParameter(valid_606393, JInt, required = false, default = nil)
  if valid_606393 != nil:
    section.add "maxResults", valid_606393
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
  var valid_606394 = header.getOrDefault("X-Amz-Signature")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Signature", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Content-Sha256", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Date")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Date", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Credential")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Credential", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Security-Token")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Security-Token", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Algorithm")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Algorithm", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-SignedHeaders", valid_606400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_ListQueues_606385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_ListQueues_606385; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          queueTypes: JsonNode = nil; maxResults: int = 0): Recallable =
  ## listQueues
  ## Provides information about the queues for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   queueTypes: JArray
  ##             : The type of queue.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606403 = newJObject()
  var query_606404 = newJObject()
  add(query_606404, "nextToken", newJString(nextToken))
  add(query_606404, "MaxResults", newJString(MaxResults))
  add(query_606404, "NextToken", newJString(NextToken))
  add(path_606403, "InstanceId", newJString(InstanceId))
  if queueTypes != nil:
    query_606404.add "queueTypes", queueTypes
  add(query_606404, "maxResults", newJInt(maxResults))
  result = call_606402.call(path_606403, query_606404, nil, nil, nil)

var listQueues* = Call_ListQueues_606385(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "connect.amazonaws.com",
                                      route: "/queues-summary/{InstanceId}",
                                      validator: validate_ListQueues_606386,
                                      base: "/", url: url_ListQueues_606387,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_606405 = ref object of OpenApiRestCall_605589
proc url_ListRoutingProfiles_606407(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRoutingProfiles_606406(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606408 = path.getOrDefault("InstanceId")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "InstanceId", valid_606408
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606409 = query.getOrDefault("nextToken")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "nextToken", valid_606409
  var valid_606410 = query.getOrDefault("MaxResults")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "MaxResults", valid_606410
  var valid_606411 = query.getOrDefault("NextToken")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "NextToken", valid_606411
  var valid_606412 = query.getOrDefault("maxResults")
  valid_606412 = validateParameter(valid_606412, JInt, required = false, default = nil)
  if valid_606412 != nil:
    section.add "maxResults", valid_606412
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
  var valid_606413 = header.getOrDefault("X-Amz-Signature")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Signature", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Content-Sha256", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Date")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Date", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Credential")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Credential", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Security-Token")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Security-Token", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Algorithm")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Algorithm", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-SignedHeaders", valid_606419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606420: Call_ListRoutingProfiles_606405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_606420.validator(path, query, header, formData, body)
  let scheme = call_606420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606420.url(scheme.get, call_606420.host, call_606420.base,
                         call_606420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606420, url, valid)

proc call*(call_606421: Call_ListRoutingProfiles_606405; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listRoutingProfiles
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606422 = newJObject()
  var query_606423 = newJObject()
  add(query_606423, "nextToken", newJString(nextToken))
  add(query_606423, "MaxResults", newJString(MaxResults))
  add(query_606423, "NextToken", newJString(NextToken))
  add(path_606422, "InstanceId", newJString(InstanceId))
  add(query_606423, "maxResults", newJInt(maxResults))
  result = call_606421.call(path_606422, query_606423, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_606405(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_606406, base: "/",
    url: url_ListRoutingProfiles_606407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_606424 = ref object of OpenApiRestCall_605589
proc url_ListSecurityProfiles_606426(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListSecurityProfiles_606425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606427 = path.getOrDefault("InstanceId")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "InstanceId", valid_606427
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606428 = query.getOrDefault("nextToken")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "nextToken", valid_606428
  var valid_606429 = query.getOrDefault("MaxResults")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "MaxResults", valid_606429
  var valid_606430 = query.getOrDefault("NextToken")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "NextToken", valid_606430
  var valid_606431 = query.getOrDefault("maxResults")
  valid_606431 = validateParameter(valid_606431, JInt, required = false, default = nil)
  if valid_606431 != nil:
    section.add "maxResults", valid_606431
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
  var valid_606432 = header.getOrDefault("X-Amz-Signature")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Signature", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Content-Sha256", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Date")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Date", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Credential")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Credential", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Security-Token")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Security-Token", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Algorithm")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Algorithm", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-SignedHeaders", valid_606438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606439: Call_ListSecurityProfiles_606424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_ListSecurityProfiles_606424; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listSecurityProfiles
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606441 = newJObject()
  var query_606442 = newJObject()
  add(query_606442, "nextToken", newJString(nextToken))
  add(query_606442, "MaxResults", newJString(MaxResults))
  add(query_606442, "NextToken", newJString(NextToken))
  add(path_606441, "InstanceId", newJString(InstanceId))
  add(query_606442, "maxResults", newJInt(maxResults))
  result = call_606440.call(path_606441, query_606442, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_606424(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_606425, base: "/",
    url: url_ListSecurityProfiles_606426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606457 = ref object of OpenApiRestCall_605589
proc url_TagResource_606459(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606458(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606460 = path.getOrDefault("resourceArn")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = nil)
  if valid_606460 != nil:
    section.add "resourceArn", valid_606460
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
  var valid_606461 = header.getOrDefault("X-Amz-Signature")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Signature", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Content-Sha256", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Date")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Date", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Credential")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Credential", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Security-Token")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Security-Token", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Algorithm")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Algorithm", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-SignedHeaders", valid_606467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606469: Call_TagResource_606457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ## 
  let valid = call_606469.validator(path, query, header, formData, body)
  let scheme = call_606469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606469.url(scheme.get, call_606469.host, call_606469.base,
                         call_606469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606469, url, valid)

proc call*(call_606470: Call_TagResource_606457; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_606471 = newJObject()
  var body_606472 = newJObject()
  add(path_606471, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606472 = body
  result = call_606470.call(path_606471, nil, nil, nil, body_606472)

var tagResource* = Call_TagResource_606457(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606458,
                                        base: "/", url: url_TagResource_606459,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606443 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606445(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606444(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606446 = path.getOrDefault("resourceArn")
  valid_606446 = validateParameter(valid_606446, JString, required = true,
                                 default = nil)
  if valid_606446 != nil:
    section.add "resourceArn", valid_606446
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
  var valid_606447 = header.getOrDefault("X-Amz-Signature")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Signature", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Content-Sha256", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Date")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Date", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Credential")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Credential", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Security-Token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Security-Token", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Algorithm")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Algorithm", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-SignedHeaders", valid_606453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606454: Call_ListTagsForResource_606443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_606454.validator(path, query, header, formData, body)
  let scheme = call_606454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606454.url(scheme.get, call_606454.host, call_606454.base,
                         call_606454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606454, url, valid)

proc call*(call_606455: Call_ListTagsForResource_606443; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_606456 = newJObject()
  add(path_606456, "resourceArn", newJString(resourceArn))
  result = call_606455.call(path_606456, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606443(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606444, base: "/",
    url: url_ListTagsForResource_606445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_606473 = ref object of OpenApiRestCall_605589
proc url_ListUserHierarchyGroups_606475(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserHierarchyGroups_606474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606476 = path.getOrDefault("InstanceId")
  valid_606476 = validateParameter(valid_606476, JString, required = true,
                                 default = nil)
  if valid_606476 != nil:
    section.add "InstanceId", valid_606476
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606477 = query.getOrDefault("nextToken")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "nextToken", valid_606477
  var valid_606478 = query.getOrDefault("MaxResults")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "MaxResults", valid_606478
  var valid_606479 = query.getOrDefault("NextToken")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "NextToken", valid_606479
  var valid_606480 = query.getOrDefault("maxResults")
  valid_606480 = validateParameter(valid_606480, JInt, required = false, default = nil)
  if valid_606480 != nil:
    section.add "maxResults", valid_606480
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
  var valid_606481 = header.getOrDefault("X-Amz-Signature")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Signature", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Content-Sha256", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Date")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Date", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Credential")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Credential", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Security-Token")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Security-Token", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Algorithm")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Algorithm", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-SignedHeaders", valid_606487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606488: Call_ListUserHierarchyGroups_606473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  let valid = call_606488.validator(path, query, header, formData, body)
  let scheme = call_606488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606488.url(scheme.get, call_606488.host, call_606488.base,
                         call_606488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606488, url, valid)

proc call*(call_606489: Call_ListUserHierarchyGroups_606473; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listUserHierarchyGroups
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606490 = newJObject()
  var query_606491 = newJObject()
  add(query_606491, "nextToken", newJString(nextToken))
  add(query_606491, "MaxResults", newJString(MaxResults))
  add(query_606491, "NextToken", newJString(NextToken))
  add(path_606490, "InstanceId", newJString(InstanceId))
  add(query_606491, "maxResults", newJInt(maxResults))
  result = call_606489.call(path_606490, query_606491, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_606473(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_606474, base: "/",
    url: url_ListUserHierarchyGroups_606475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_606492 = ref object of OpenApiRestCall_605589
proc url_ListUsers_606494(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_606493(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606495 = path.getOrDefault("InstanceId")
  valid_606495 = validateParameter(valid_606495, JString, required = true,
                                 default = nil)
  if valid_606495 != nil:
    section.add "InstanceId", valid_606495
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximimum number of results to return per page.
  section = newJObject()
  var valid_606496 = query.getOrDefault("nextToken")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "nextToken", valid_606496
  var valid_606497 = query.getOrDefault("MaxResults")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "MaxResults", valid_606497
  var valid_606498 = query.getOrDefault("NextToken")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "NextToken", valid_606498
  var valid_606499 = query.getOrDefault("maxResults")
  valid_606499 = validateParameter(valid_606499, JInt, required = false, default = nil)
  if valid_606499 != nil:
    section.add "maxResults", valid_606499
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
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606507: Call_ListUsers_606492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  let valid = call_606507.validator(path, query, header, formData, body)
  let scheme = call_606507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606507.url(scheme.get, call_606507.host, call_606507.base,
                         call_606507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606507, url, valid)

proc call*(call_606508: Call_ListUsers_606492; InstanceId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listUsers
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ##   nextToken: string
  ##            : The token for the next set of results. Use the value returned in the previous response in the next request to retrieve the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   maxResults: int
  ##             : The maximimum number of results to return per page.
  var path_606509 = newJObject()
  var query_606510 = newJObject()
  add(query_606510, "nextToken", newJString(nextToken))
  add(query_606510, "MaxResults", newJString(MaxResults))
  add(query_606510, "NextToken", newJString(NextToken))
  add(path_606509, "InstanceId", newJString(InstanceId))
  add(query_606510, "maxResults", newJInt(maxResults))
  result = call_606508.call(path_606509, query_606510, nil, nil, nil)

var listUsers* = Call_ListUsers_606492(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_606493,
                                    base: "/", url: url_ListUsers_606494,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChatContact_606511 = ref object of OpenApiRestCall_605589
proc url_StartChatContact_606513(protocol: Scheme; host: string; base: string;
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

proc validate_StartChatContact_606512(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
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
  var valid_606514 = header.getOrDefault("X-Amz-Signature")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Signature", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Content-Sha256", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Date")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Date", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Credential")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Credential", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Security-Token")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Security-Token", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Algorithm")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Algorithm", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-SignedHeaders", valid_606520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606522: Call_StartChatContact_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ## 
  let valid = call_606522.validator(path, query, header, formData, body)
  let scheme = call_606522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606522.url(scheme.get, call_606522.host, call_606522.base,
                         call_606522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606522, url, valid)

proc call*(call_606523: Call_StartChatContact_606511; body: JsonNode): Recallable =
  ## startChatContact
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ##   body: JObject (required)
  var body_606524 = newJObject()
  if body != nil:
    body_606524 = body
  result = call_606523.call(nil, nil, nil, nil, body_606524)

var startChatContact* = Call_StartChatContact_606511(name: "startChatContact",
    meth: HttpMethod.HttpPut, host: "connect.amazonaws.com", route: "/contact/chat",
    validator: validate_StartChatContact_606512, base: "/",
    url: url_StartChatContact_606513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_606525 = ref object of OpenApiRestCall_605589
proc url_StartOutboundVoiceContact_606527(protocol: Scheme; host: string;
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

proc validate_StartOutboundVoiceContact_606526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
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
  var valid_606528 = header.getOrDefault("X-Amz-Signature")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Signature", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Content-Sha256", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Date")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Date", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Credential")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Credential", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Security-Token")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Security-Token", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Algorithm")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Algorithm", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-SignedHeaders", valid_606534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606536: Call_StartOutboundVoiceContact_606525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ## 
  let valid = call_606536.validator(path, query, header, formData, body)
  let scheme = call_606536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606536.url(scheme.get, call_606536.host, call_606536.base,
                         call_606536.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606536, url, valid)

proc call*(call_606537: Call_StartOutboundVoiceContact_606525; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   body: JObject (required)
  var body_606538 = newJObject()
  if body != nil:
    body_606538 = body
  result = call_606537.call(nil, nil, nil, nil, body_606538)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_606525(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_606526, base: "/",
    url: url_StartOutboundVoiceContact_606527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_606539 = ref object of OpenApiRestCall_605589
proc url_StopContact_606541(protocol: Scheme; host: string; base: string;
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

proc validate_StopContact_606540(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Ends the specified contact.
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
  var valid_606542 = header.getOrDefault("X-Amz-Signature")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Signature", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Content-Sha256", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Date")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Date", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Credential")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Credential", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Security-Token")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Security-Token", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Algorithm")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Algorithm", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-SignedHeaders", valid_606548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606550: Call_StopContact_606539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends the specified contact.
  ## 
  let valid = call_606550.validator(path, query, header, formData, body)
  let scheme = call_606550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606550.url(scheme.get, call_606550.host, call_606550.base,
                         call_606550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606550, url, valid)

proc call*(call_606551: Call_StopContact_606539; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_606552 = newJObject()
  if body != nil:
    body_606552 = body
  result = call_606551.call(nil, nil, nil, nil, body_606552)

var stopContact* = Call_StopContact_606539(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_606540,
                                        base: "/", url: url_StopContact_606541,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606553 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606555(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606554(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606556 = path.getOrDefault("resourceArn")
  valid_606556 = validateParameter(valid_606556, JString, required = true,
                                 default = nil)
  if valid_606556 != nil:
    section.add "resourceArn", valid_606556
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606557 = query.getOrDefault("tagKeys")
  valid_606557 = validateParameter(valid_606557, JArray, required = true, default = nil)
  if valid_606557 != nil:
    section.add "tagKeys", valid_606557
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
  var valid_606558 = header.getOrDefault("X-Amz-Signature")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Signature", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Content-Sha256", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Date")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Date", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Credential")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Credential", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Security-Token")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Security-Token", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Algorithm")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Algorithm", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-SignedHeaders", valid_606564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606565: Call_UntagResource_606553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_606565.validator(path, query, header, formData, body)
  let scheme = call_606565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606565.url(scheme.get, call_606565.host, call_606565.base,
                         call_606565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606565, url, valid)

proc call*(call_606566: Call_UntagResource_606553; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  var path_606567 = newJObject()
  var query_606568 = newJObject()
  add(path_606567, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606568.add "tagKeys", tagKeys
  result = call_606566.call(path_606567, query_606568, nil, nil, nil)

var untagResource* = Call_UntagResource_606553(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606554,
    base: "/", url: url_UntagResource_606555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_606569 = ref object of OpenApiRestCall_605589
proc url_UpdateContactAttributes_606571(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContactAttributes_606570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
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
  var valid_606572 = header.getOrDefault("X-Amz-Signature")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Signature", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Content-Sha256", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Date")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Date", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Credential")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Credential", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Security-Token")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Security-Token", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Algorithm")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Algorithm", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-SignedHeaders", valid_606578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606580: Call_UpdateContactAttributes_606569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_606580.validator(path, query, header, formData, body)
  let scheme = call_606580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606580.url(scheme.get, call_606580.host, call_606580.base,
                         call_606580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606580, url, valid)

proc call*(call_606581: Call_UpdateContactAttributes_606569; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_606582 = newJObject()
  if body != nil:
    body_606582 = body
  result = call_606581.call(nil, nil, nil, nil, body_606582)

var updateContactAttributes* = Call_UpdateContactAttributes_606569(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_606570, base: "/",
    url: url_UpdateContactAttributes_606571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_606583 = ref object of OpenApiRestCall_605589
proc url_UpdateUserHierarchy_606585(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserHierarchy_606584(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606586 = path.getOrDefault("UserId")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = nil)
  if valid_606586 != nil:
    section.add "UserId", valid_606586
  var valid_606587 = path.getOrDefault("InstanceId")
  valid_606587 = validateParameter(valid_606587, JString, required = true,
                                 default = nil)
  if valid_606587 != nil:
    section.add "InstanceId", valid_606587
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
  var valid_606588 = header.getOrDefault("X-Amz-Signature")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Signature", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Content-Sha256", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Date")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Date", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Credential")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Credential", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Security-Token")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Security-Token", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Algorithm")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Algorithm", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-SignedHeaders", valid_606594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606596: Call_UpdateUserHierarchy_606583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  let valid = call_606596.validator(path, query, header, formData, body)
  let scheme = call_606596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606596.url(scheme.get, call_606596.host, call_606596.base,
                         call_606596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606596, url, valid)

proc call*(call_606597: Call_UpdateUserHierarchy_606583; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606598 = newJObject()
  var body_606599 = newJObject()
  add(path_606598, "UserId", newJString(UserId))
  if body != nil:
    body_606599 = body
  add(path_606598, "InstanceId", newJString(InstanceId))
  result = call_606597.call(path_606598, nil, nil, nil, body_606599)

var updateUserHierarchy* = Call_UpdateUserHierarchy_606583(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_606584, base: "/",
    url: url_UpdateUserHierarchy_606585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_606600 = ref object of OpenApiRestCall_605589
proc url_UpdateUserIdentityInfo_606602(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserIdentityInfo_606601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the identity information for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606603 = path.getOrDefault("UserId")
  valid_606603 = validateParameter(valid_606603, JString, required = true,
                                 default = nil)
  if valid_606603 != nil:
    section.add "UserId", valid_606603
  var valid_606604 = path.getOrDefault("InstanceId")
  valid_606604 = validateParameter(valid_606604, JString, required = true,
                                 default = nil)
  if valid_606604 != nil:
    section.add "InstanceId", valid_606604
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
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_UpdateUserIdentityInfo_606600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user.
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_UpdateUserIdentityInfo_606600; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606615 = newJObject()
  var body_606616 = newJObject()
  add(path_606615, "UserId", newJString(UserId))
  if body != nil:
    body_606616 = body
  add(path_606615, "InstanceId", newJString(InstanceId))
  result = call_606614.call(path_606615, nil, nil, nil, body_606616)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_606600(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_606601, base: "/",
    url: url_UpdateUserIdentityInfo_606602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_606617 = ref object of OpenApiRestCall_605589
proc url_UpdateUserPhoneConfig_606619(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserPhoneConfig_606618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the phone configuration settings for the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606620 = path.getOrDefault("UserId")
  valid_606620 = validateParameter(valid_606620, JString, required = true,
                                 default = nil)
  if valid_606620 != nil:
    section.add "UserId", valid_606620
  var valid_606621 = path.getOrDefault("InstanceId")
  valid_606621 = validateParameter(valid_606621, JString, required = true,
                                 default = nil)
  if valid_606621 != nil:
    section.add "InstanceId", valid_606621
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
  var valid_606622 = header.getOrDefault("X-Amz-Signature")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Signature", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Content-Sha256", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Date")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Date", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Credential")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Credential", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Security-Token")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Security-Token", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Algorithm")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Algorithm", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-SignedHeaders", valid_606628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606630: Call_UpdateUserPhoneConfig_606617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings for the specified user.
  ## 
  let valid = call_606630.validator(path, query, header, formData, body)
  let scheme = call_606630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606630.url(scheme.get, call_606630.host, call_606630.base,
                         call_606630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606630, url, valid)

proc call*(call_606631: Call_UpdateUserPhoneConfig_606617; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606632 = newJObject()
  var body_606633 = newJObject()
  add(path_606632, "UserId", newJString(UserId))
  if body != nil:
    body_606633 = body
  add(path_606632, "InstanceId", newJString(InstanceId))
  result = call_606631.call(path_606632, nil, nil, nil, body_606633)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_606617(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_606618, base: "/",
    url: url_UpdateUserPhoneConfig_606619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_606634 = ref object of OpenApiRestCall_605589
proc url_UpdateUserRoutingProfile_606636(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserRoutingProfile_606635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns the specified routing profile to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606637 = path.getOrDefault("UserId")
  valid_606637 = validateParameter(valid_606637, JString, required = true,
                                 default = nil)
  if valid_606637 != nil:
    section.add "UserId", valid_606637
  var valid_606638 = path.getOrDefault("InstanceId")
  valid_606638 = validateParameter(valid_606638, JString, required = true,
                                 default = nil)
  if valid_606638 != nil:
    section.add "InstanceId", valid_606638
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
  var valid_606639 = header.getOrDefault("X-Amz-Signature")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Signature", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Content-Sha256", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Date")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Date", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Credential")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Credential", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Security-Token")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Security-Token", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Algorithm")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Algorithm", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-SignedHeaders", valid_606645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_UpdateUserRoutingProfile_606634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to the specified user.
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_UpdateUserRoutingProfile_606634; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606649 = newJObject()
  var body_606650 = newJObject()
  add(path_606649, "UserId", newJString(UserId))
  if body != nil:
    body_606650 = body
  add(path_606649, "InstanceId", newJString(InstanceId))
  result = call_606648.call(path_606649, nil, nil, nil, body_606650)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_606634(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_606635, base: "/",
    url: url_UpdateUserRoutingProfile_606636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_606651 = ref object of OpenApiRestCall_605589
proc url_UpdateUserSecurityProfiles_606653(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserSecurityProfiles_606652(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns the specified security profiles to the specified user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UserId: JString (required)
  ##         : The identifier of the user account.
  ##   InstanceId: JString (required)
  ##             : The identifier of the Amazon Connect instance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UserId` field"
  var valid_606654 = path.getOrDefault("UserId")
  valid_606654 = validateParameter(valid_606654, JString, required = true,
                                 default = nil)
  if valid_606654 != nil:
    section.add "UserId", valid_606654
  var valid_606655 = path.getOrDefault("InstanceId")
  valid_606655 = validateParameter(valid_606655, JString, required = true,
                                 default = nil)
  if valid_606655 != nil:
    section.add "InstanceId", valid_606655
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
  var valid_606656 = header.getOrDefault("X-Amz-Signature")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Signature", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Content-Sha256", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Date")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Date", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Credential")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Credential", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Security-Token")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Security-Token", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Algorithm")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Algorithm", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-SignedHeaders", valid_606662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606664: Call_UpdateUserSecurityProfiles_606651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified security profiles to the specified user.
  ## 
  let valid = call_606664.validator(path, query, header, formData, body)
  let scheme = call_606664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606664.url(scheme.get, call_606664.host, call_606664.base,
                         call_606664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606664, url, valid)

proc call*(call_606665: Call_UpdateUserSecurityProfiles_606651; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_606666 = newJObject()
  var body_606667 = newJObject()
  add(path_606666, "UserId", newJString(UserId))
  if body != nil:
    body_606667 = body
  add(path_606666, "InstanceId", newJString(InstanceId))
  result = call_606665.call(path_606666, nil, nil, nil, body_606667)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_606651(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_606652, base: "/",
    url: url_UpdateUserSecurityProfiles_606653,
    schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
