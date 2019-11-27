
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
  Call_CreateUser_599705 = ref object of OpenApiRestCall_599368
proc url_CreateUser_599707(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_599706(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599833 = path.getOrDefault("InstanceId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "InstanceId", valid_599833
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
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_CreateUser_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_CreateUser_599705; InstanceId: string; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  var path_599936 = newJObject()
  var body_599938 = newJObject()
  add(path_599936, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_599938 = body
  result = call_599935.call(path_599936, nil, nil, nil, body_599938)

var createUser* = Call_CreateUser_599705(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_599706,
                                      base: "/", url: url_CreateUser_599707,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_599977 = ref object of OpenApiRestCall_599368
proc url_DescribeUser_599979(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_599978(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599980 = path.getOrDefault("InstanceId")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = nil)
  if valid_599980 != nil:
    section.add "InstanceId", valid_599980
  var valid_599981 = path.getOrDefault("UserId")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = nil)
  if valid_599981 != nil:
    section.add "UserId", valid_599981
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
  var valid_599982 = header.getOrDefault("X-Amz-Date")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Date", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Security-Token")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Security-Token", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Content-Sha256", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Algorithm")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Algorithm", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Signature")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Signature", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-SignedHeaders", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Credential")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Credential", valid_599988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599989: Call_DescribeUser_599977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  let valid = call_599989.validator(path, query, header, formData, body)
  let scheme = call_599989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599989.url(scheme.get, call_599989.host, call_599989.base,
                         call_599989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599989, url, valid)

proc call*(call_599990: Call_DescribeUser_599977; InstanceId: string; UserId: string): Recallable =
  ## describeUser
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_599991 = newJObject()
  add(path_599991, "InstanceId", newJString(InstanceId))
  add(path_599991, "UserId", newJString(UserId))
  result = call_599990.call(path_599991, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_599977(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_599978,
    base: "/", url: url_DescribeUser_599979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_599992 = ref object of OpenApiRestCall_599368
proc url_DeleteUser_599994(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_599993(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599995 = path.getOrDefault("InstanceId")
  valid_599995 = validateParameter(valid_599995, JString, required = true,
                                 default = nil)
  if valid_599995 != nil:
    section.add "InstanceId", valid_599995
  var valid_599996 = path.getOrDefault("UserId")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "UserId", valid_599996
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
  var valid_599997 = header.getOrDefault("X-Amz-Date")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Date", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Security-Token")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Security-Token", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Content-Sha256", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Algorithm")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Algorithm", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Signature")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Signature", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-SignedHeaders", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Credential")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Credential", valid_600003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600004: Call_DeleteUser_599992; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  let valid = call_600004.validator(path, query, header, formData, body)
  let scheme = call_600004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600004.url(scheme.get, call_600004.host, call_600004.base,
                         call_600004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600004, url, valid)

proc call*(call_600005: Call_DeleteUser_599992; InstanceId: string; UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user.
  var path_600006 = newJObject()
  add(path_600006, "InstanceId", newJString(InstanceId))
  add(path_600006, "UserId", newJString(UserId))
  result = call_600005.call(path_600006, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_599992(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_599993,
                                      base: "/", url: url_DeleteUser_599994,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_600007 = ref object of OpenApiRestCall_599368
proc url_DescribeUserHierarchyGroup_600009(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_600008(path: JsonNode; query: JsonNode;
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
  var valid_600010 = path.getOrDefault("HierarchyGroupId")
  valid_600010 = validateParameter(valid_600010, JString, required = true,
                                 default = nil)
  if valid_600010 != nil:
    section.add "HierarchyGroupId", valid_600010
  var valid_600011 = path.getOrDefault("InstanceId")
  valid_600011 = validateParameter(valid_600011, JString, required = true,
                                 default = nil)
  if valid_600011 != nil:
    section.add "InstanceId", valid_600011
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
  var valid_600012 = header.getOrDefault("X-Amz-Date")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Date", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Security-Token")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Security-Token", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Content-Sha256", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Algorithm")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Algorithm", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Signature")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Signature", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-SignedHeaders", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Credential")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Credential", valid_600018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600019: Call_DescribeUserHierarchyGroup_600007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified hierarchy group.
  ## 
  let valid = call_600019.validator(path, query, header, formData, body)
  let scheme = call_600019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600019.url(scheme.get, call_600019.host, call_600019.base,
                         call_600019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600019, url, valid)

proc call*(call_600020: Call_DescribeUserHierarchyGroup_600007;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_600021 = newJObject()
  add(path_600021, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_600021, "InstanceId", newJString(InstanceId))
  result = call_600020.call(path_600021, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_600007(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_600008, base: "/",
    url: url_DescribeUserHierarchyGroup_600009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_600022 = ref object of OpenApiRestCall_599368
proc url_DescribeUserHierarchyStructure_600024(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyStructure_600023(path: JsonNode;
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
  var valid_600025 = path.getOrDefault("InstanceId")
  valid_600025 = validateParameter(valid_600025, JString, required = true,
                                 default = nil)
  if valid_600025 != nil:
    section.add "InstanceId", valid_600025
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
  var valid_600026 = header.getOrDefault("X-Amz-Date")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Date", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Security-Token")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Security-Token", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Content-Sha256", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Algorithm")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Algorithm", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Signature")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Signature", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-SignedHeaders", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Credential")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Credential", valid_600032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600033: Call_DescribeUserHierarchyStructure_600022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  let valid = call_600033.validator(path, query, header, formData, body)
  let scheme = call_600033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600033.url(scheme.get, call_600033.host, call_600033.base,
                         call_600033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600033, url, valid)

proc call*(call_600034: Call_DescribeUserHierarchyStructure_600022;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_600035 = newJObject()
  add(path_600035, "InstanceId", newJString(InstanceId))
  result = call_600034.call(path_600035, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_600022(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_600023, base: "/",
    url: url_DescribeUserHierarchyStructure_600024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_600036 = ref object of OpenApiRestCall_599368
proc url_GetContactAttributes_600038(protocol: Scheme; host: string; base: string;
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

proc validate_GetContactAttributes_600037(path: JsonNode; query: JsonNode;
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
  var valid_600039 = path.getOrDefault("InitialContactId")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = nil)
  if valid_600039 != nil:
    section.add "InitialContactId", valid_600039
  var valid_600040 = path.getOrDefault("InstanceId")
  valid_600040 = validateParameter(valid_600040, JString, required = true,
                                 default = nil)
  if valid_600040 != nil:
    section.add "InstanceId", valid_600040
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
  var valid_600041 = header.getOrDefault("X-Amz-Date")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Date", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Security-Token")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Security-Token", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Content-Sha256", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Algorithm")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Algorithm", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Signature")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Signature", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-SignedHeaders", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Credential")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Credential", valid_600047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600048: Call_GetContactAttributes_600036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  let valid = call_600048.validator(path, query, header, formData, body)
  let scheme = call_600048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600048.url(scheme.get, call_600048.host, call_600048.base,
                         call_600048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600048, url, valid)

proc call*(call_600049: Call_GetContactAttributes_600036; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InitialContactId: string (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_600050 = newJObject()
  add(path_600050, "InitialContactId", newJString(InitialContactId))
  add(path_600050, "InstanceId", newJString(InstanceId))
  result = call_600049.call(path_600050, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_600036(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_600037, base: "/",
    url: url_GetContactAttributes_600038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_600051 = ref object of OpenApiRestCall_599368
proc url_GetCurrentMetricData_600053(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentMetricData_600052(path: JsonNode; query: JsonNode;
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
  var valid_600054 = path.getOrDefault("InstanceId")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = nil)
  if valid_600054 != nil:
    section.add "InstanceId", valid_600054
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600055 = query.getOrDefault("NextToken")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "NextToken", valid_600055
  var valid_600056 = query.getOrDefault("MaxResults")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "MaxResults", valid_600056
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
  var valid_600057 = header.getOrDefault("X-Amz-Date")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Date", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Security-Token")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Security-Token", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Content-Sha256", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Algorithm")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Algorithm", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Signature")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Signature", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-SignedHeaders", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Credential")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Credential", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600065: Call_GetCurrentMetricData_600051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_600065.validator(path, query, header, formData, body)
  let scheme = call_600065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600065.url(scheme.get, call_600065.host, call_600065.base,
                         call_600065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600065, url, valid)

proc call*(call_600066: Call_GetCurrentMetricData_600051; InstanceId: string;
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
  var path_600067 = newJObject()
  var query_600068 = newJObject()
  var body_600069 = newJObject()
  add(path_600067, "InstanceId", newJString(InstanceId))
  add(query_600068, "NextToken", newJString(NextToken))
  if body != nil:
    body_600069 = body
  add(query_600068, "MaxResults", newJString(MaxResults))
  result = call_600066.call(path_600067, query_600068, nil, nil, body_600069)

var getCurrentMetricData* = Call_GetCurrentMetricData_600051(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_600052, base: "/",
    url: url_GetCurrentMetricData_600053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_600070 = ref object of OpenApiRestCall_599368
proc url_GetFederationToken_600072(protocol: Scheme; host: string; base: string;
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

proc validate_GetFederationToken_600071(path: JsonNode; query: JsonNode;
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
  var valid_600073 = path.getOrDefault("InstanceId")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = nil)
  if valid_600073 != nil:
    section.add "InstanceId", valid_600073
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
  var valid_600074 = header.getOrDefault("X-Amz-Date")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Date", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Security-Token")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Security-Token", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Content-Sha256", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Algorithm")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Algorithm", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Signature")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Signature", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-SignedHeaders", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Credential")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Credential", valid_600080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600081: Call_GetFederationToken_600070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_600081.validator(path, query, header, formData, body)
  let scheme = call_600081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600081.url(scheme.get, call_600081.host, call_600081.base,
                         call_600081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600081, url, valid)

proc call*(call_600082: Call_GetFederationToken_600070; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_600083 = newJObject()
  add(path_600083, "InstanceId", newJString(InstanceId))
  result = call_600082.call(path_600083, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_600070(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_600071, base: "/",
    url: url_GetFederationToken_600072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_600084 = ref object of OpenApiRestCall_599368
proc url_GetMetricData_600086(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_600085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600087 = path.getOrDefault("InstanceId")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = nil)
  if valid_600087 != nil:
    section.add "InstanceId", valid_600087
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600088 = query.getOrDefault("NextToken")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "NextToken", valid_600088
  var valid_600089 = query.getOrDefault("MaxResults")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "MaxResults", valid_600089
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
  var valid_600090 = header.getOrDefault("X-Amz-Date")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Date", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Security-Token")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Security-Token", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Content-Sha256", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Algorithm")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Algorithm", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Signature")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Signature", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-SignedHeaders", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Credential")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Credential", valid_600096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600098: Call_GetMetricData_600084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_600098.validator(path, query, header, formData, body)
  let scheme = call_600098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600098.url(scheme.get, call_600098.host, call_600098.base,
                         call_600098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600098, url, valid)

proc call*(call_600099: Call_GetMetricData_600084; InstanceId: string;
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
  var path_600100 = newJObject()
  var query_600101 = newJObject()
  var body_600102 = newJObject()
  add(path_600100, "InstanceId", newJString(InstanceId))
  add(query_600101, "NextToken", newJString(NextToken))
  if body != nil:
    body_600102 = body
  add(query_600101, "MaxResults", newJString(MaxResults))
  result = call_600099.call(path_600100, query_600101, nil, nil, body_600102)

var getMetricData* = Call_GetMetricData_600084(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_600085,
    base: "/", url: url_GetMetricData_600086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_600103 = ref object of OpenApiRestCall_599368
proc url_ListContactFlows_600105(protocol: Scheme; host: string; base: string;
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

proc validate_ListContactFlows_600104(path: JsonNode; query: JsonNode;
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
  var valid_600106 = path.getOrDefault("InstanceId")
  valid_600106 = validateParameter(valid_600106, JString, required = true,
                                 default = nil)
  if valid_600106 != nil:
    section.add "InstanceId", valid_600106
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
  var valid_600107 = query.getOrDefault("contactFlowTypes")
  valid_600107 = validateParameter(valid_600107, JArray, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "contactFlowTypes", valid_600107
  var valid_600108 = query.getOrDefault("NextToken")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "NextToken", valid_600108
  var valid_600109 = query.getOrDefault("maxResults")
  valid_600109 = validateParameter(valid_600109, JInt, required = false, default = nil)
  if valid_600109 != nil:
    section.add "maxResults", valid_600109
  var valid_600110 = query.getOrDefault("nextToken")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "nextToken", valid_600110
  var valid_600111 = query.getOrDefault("MaxResults")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "MaxResults", valid_600111
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600119: Call_ListContactFlows_600103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  let valid = call_600119.validator(path, query, header, formData, body)
  let scheme = call_600119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600119.url(scheme.get, call_600119.host, call_600119.base,
                         call_600119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600119, url, valid)

proc call*(call_600120: Call_ListContactFlows_600103; InstanceId: string;
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
  var path_600121 = newJObject()
  var query_600122 = newJObject()
  if contactFlowTypes != nil:
    query_600122.add "contactFlowTypes", contactFlowTypes
  add(path_600121, "InstanceId", newJString(InstanceId))
  add(query_600122, "NextToken", newJString(NextToken))
  add(query_600122, "maxResults", newJInt(maxResults))
  add(query_600122, "nextToken", newJString(nextToken))
  add(query_600122, "MaxResults", newJString(MaxResults))
  result = call_600120.call(path_600121, query_600122, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_600103(name: "listContactFlows",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_600104, base: "/",
    url: url_ListContactFlows_600105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_600123 = ref object of OpenApiRestCall_599368
proc url_ListHoursOfOperations_600125(protocol: Scheme; host: string; base: string;
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

proc validate_ListHoursOfOperations_600124(path: JsonNode; query: JsonNode;
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
  var valid_600126 = path.getOrDefault("InstanceId")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = nil)
  if valid_600126 != nil:
    section.add "InstanceId", valid_600126
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
  var valid_600127 = query.getOrDefault("NextToken")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "NextToken", valid_600127
  var valid_600128 = query.getOrDefault("maxResults")
  valid_600128 = validateParameter(valid_600128, JInt, required = false, default = nil)
  if valid_600128 != nil:
    section.add "maxResults", valid_600128
  var valid_600129 = query.getOrDefault("nextToken")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "nextToken", valid_600129
  var valid_600130 = query.getOrDefault("MaxResults")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "MaxResults", valid_600130
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
  var valid_600131 = header.getOrDefault("X-Amz-Date")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Date", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Security-Token")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Security-Token", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Content-Sha256", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Algorithm")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Algorithm", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Signature")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Signature", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-SignedHeaders", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Credential")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Credential", valid_600137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600138: Call_ListHoursOfOperations_600123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  let valid = call_600138.validator(path, query, header, formData, body)
  let scheme = call_600138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600138.url(scheme.get, call_600138.host, call_600138.base,
                         call_600138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600138, url, valid)

proc call*(call_600139: Call_ListHoursOfOperations_600123; InstanceId: string;
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
  var path_600140 = newJObject()
  var query_600141 = newJObject()
  add(path_600140, "InstanceId", newJString(InstanceId))
  add(query_600141, "NextToken", newJString(NextToken))
  add(query_600141, "maxResults", newJInt(maxResults))
  add(query_600141, "nextToken", newJString(nextToken))
  add(query_600141, "MaxResults", newJString(MaxResults))
  result = call_600139.call(path_600140, query_600141, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_600123(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_600124, base: "/",
    url: url_ListHoursOfOperations_600125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_600142 = ref object of OpenApiRestCall_599368
proc url_ListPhoneNumbers_600144(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumbers_600143(path: JsonNode; query: JsonNode;
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
  var valid_600145 = path.getOrDefault("InstanceId")
  valid_600145 = validateParameter(valid_600145, JString, required = true,
                                 default = nil)
  if valid_600145 != nil:
    section.add "InstanceId", valid_600145
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
  var valid_600146 = query.getOrDefault("phoneNumberTypes")
  valid_600146 = validateParameter(valid_600146, JArray, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "phoneNumberTypes", valid_600146
  var valid_600147 = query.getOrDefault("NextToken")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "NextToken", valid_600147
  var valid_600148 = query.getOrDefault("maxResults")
  valid_600148 = validateParameter(valid_600148, JInt, required = false, default = nil)
  if valid_600148 != nil:
    section.add "maxResults", valid_600148
  var valid_600149 = query.getOrDefault("nextToken")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "nextToken", valid_600149
  var valid_600150 = query.getOrDefault("phoneNumberCountryCodes")
  valid_600150 = validateParameter(valid_600150, JArray, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "phoneNumberCountryCodes", valid_600150
  var valid_600151 = query.getOrDefault("MaxResults")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "MaxResults", valid_600151
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
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Content-Sha256", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Algorithm")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Algorithm", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Signature")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Signature", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-SignedHeaders", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Credential")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Credential", valid_600158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600159: Call_ListPhoneNumbers_600142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  let valid = call_600159.validator(path, query, header, formData, body)
  let scheme = call_600159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600159.url(scheme.get, call_600159.host, call_600159.base,
                         call_600159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600159, url, valid)

proc call*(call_600160: Call_ListPhoneNumbers_600142; InstanceId: string;
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
  var path_600161 = newJObject()
  var query_600162 = newJObject()
  if phoneNumberTypes != nil:
    query_600162.add "phoneNumberTypes", phoneNumberTypes
  add(path_600161, "InstanceId", newJString(InstanceId))
  add(query_600162, "NextToken", newJString(NextToken))
  add(query_600162, "maxResults", newJInt(maxResults))
  add(query_600162, "nextToken", newJString(nextToken))
  if phoneNumberCountryCodes != nil:
    query_600162.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  add(query_600162, "MaxResults", newJString(MaxResults))
  result = call_600160.call(path_600161, query_600162, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_600142(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_600143, base: "/",
    url: url_ListPhoneNumbers_600144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_600163 = ref object of OpenApiRestCall_599368
proc url_ListQueues_600165(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListQueues_600164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600166 = path.getOrDefault("InstanceId")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = nil)
  if valid_600166 != nil:
    section.add "InstanceId", valid_600166
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
  var valid_600167 = query.getOrDefault("NextToken")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "NextToken", valid_600167
  var valid_600168 = query.getOrDefault("maxResults")
  valid_600168 = validateParameter(valid_600168, JInt, required = false, default = nil)
  if valid_600168 != nil:
    section.add "maxResults", valid_600168
  var valid_600169 = query.getOrDefault("nextToken")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "nextToken", valid_600169
  var valid_600170 = query.getOrDefault("queueTypes")
  valid_600170 = validateParameter(valid_600170, JArray, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "queueTypes", valid_600170
  var valid_600171 = query.getOrDefault("MaxResults")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "MaxResults", valid_600171
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
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600179: Call_ListQueues_600163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  let valid = call_600179.validator(path, query, header, formData, body)
  let scheme = call_600179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600179.url(scheme.get, call_600179.host, call_600179.base,
                         call_600179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600179, url, valid)

proc call*(call_600180: Call_ListQueues_600163; InstanceId: string;
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
  var path_600181 = newJObject()
  var query_600182 = newJObject()
  add(path_600181, "InstanceId", newJString(InstanceId))
  add(query_600182, "NextToken", newJString(NextToken))
  add(query_600182, "maxResults", newJInt(maxResults))
  add(query_600182, "nextToken", newJString(nextToken))
  if queueTypes != nil:
    query_600182.add "queueTypes", queueTypes
  add(query_600182, "MaxResults", newJString(MaxResults))
  result = call_600180.call(path_600181, query_600182, nil, nil, nil)

var listQueues* = Call_ListQueues_600163(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "connect.amazonaws.com",
                                      route: "/queues-summary/{InstanceId}",
                                      validator: validate_ListQueues_600164,
                                      base: "/", url: url_ListQueues_600165,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_600183 = ref object of OpenApiRestCall_599368
proc url_ListRoutingProfiles_600185(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutingProfiles_600184(path: JsonNode; query: JsonNode;
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
  var valid_600186 = path.getOrDefault("InstanceId")
  valid_600186 = validateParameter(valid_600186, JString, required = true,
                                 default = nil)
  if valid_600186 != nil:
    section.add "InstanceId", valid_600186
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
  var valid_600187 = query.getOrDefault("NextToken")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "NextToken", valid_600187
  var valid_600188 = query.getOrDefault("maxResults")
  valid_600188 = validateParameter(valid_600188, JInt, required = false, default = nil)
  if valid_600188 != nil:
    section.add "maxResults", valid_600188
  var valid_600189 = query.getOrDefault("nextToken")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "nextToken", valid_600189
  var valid_600190 = query.getOrDefault("MaxResults")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "MaxResults", valid_600190
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
  var valid_600191 = header.getOrDefault("X-Amz-Date")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Date", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Security-Token")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Security-Token", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Content-Sha256", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Algorithm")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Algorithm", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Signature")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Signature", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-SignedHeaders", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Credential")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Credential", valid_600197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_ListRoutingProfiles_600183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_ListRoutingProfiles_600183; InstanceId: string;
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
  var path_600200 = newJObject()
  var query_600201 = newJObject()
  add(path_600200, "InstanceId", newJString(InstanceId))
  add(query_600201, "NextToken", newJString(NextToken))
  add(query_600201, "maxResults", newJInt(maxResults))
  add(query_600201, "nextToken", newJString(nextToken))
  add(query_600201, "MaxResults", newJString(MaxResults))
  result = call_600199.call(path_600200, query_600201, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_600183(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_600184, base: "/",
    url: url_ListRoutingProfiles_600185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_600202 = ref object of OpenApiRestCall_599368
proc url_ListSecurityProfiles_600204(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecurityProfiles_600203(path: JsonNode; query: JsonNode;
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
  var valid_600205 = path.getOrDefault("InstanceId")
  valid_600205 = validateParameter(valid_600205, JString, required = true,
                                 default = nil)
  if valid_600205 != nil:
    section.add "InstanceId", valid_600205
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
  var valid_600206 = query.getOrDefault("NextToken")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "NextToken", valid_600206
  var valid_600207 = query.getOrDefault("maxResults")
  valid_600207 = validateParameter(valid_600207, JInt, required = false, default = nil)
  if valid_600207 != nil:
    section.add "maxResults", valid_600207
  var valid_600208 = query.getOrDefault("nextToken")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "nextToken", valid_600208
  var valid_600209 = query.getOrDefault("MaxResults")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "MaxResults", valid_600209
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
  var valid_600210 = header.getOrDefault("X-Amz-Date")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Date", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Security-Token")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Security-Token", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Content-Sha256", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Algorithm")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Algorithm", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Signature")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Signature", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-SignedHeaders", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Credential")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Credential", valid_600216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600217: Call_ListSecurityProfiles_600202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_600217.validator(path, query, header, formData, body)
  let scheme = call_600217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600217.url(scheme.get, call_600217.host, call_600217.base,
                         call_600217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600217, url, valid)

proc call*(call_600218: Call_ListSecurityProfiles_600202; InstanceId: string;
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
  var path_600219 = newJObject()
  var query_600220 = newJObject()
  add(path_600219, "InstanceId", newJString(InstanceId))
  add(query_600220, "NextToken", newJString(NextToken))
  add(query_600220, "maxResults", newJInt(maxResults))
  add(query_600220, "nextToken", newJString(nextToken))
  add(query_600220, "MaxResults", newJString(MaxResults))
  result = call_600218.call(path_600219, query_600220, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_600202(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_600203, base: "/",
    url: url_ListSecurityProfiles_600204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600235 = ref object of OpenApiRestCall_599368
proc url_TagResource_600237(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600236(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600238 = path.getOrDefault("resourceArn")
  valid_600238 = validateParameter(valid_600238, JString, required = true,
                                 default = nil)
  if valid_600238 != nil:
    section.add "resourceArn", valid_600238
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
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Content-Sha256", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Algorithm")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Algorithm", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Signature")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Signature", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-SignedHeaders", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Credential")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Credential", valid_600245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600247: Call_TagResource_600235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ## 
  let valid = call_600247.validator(path, query, header, formData, body)
  let scheme = call_600247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600247.url(scheme.get, call_600247.host, call_600247.base,
                         call_600247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600247, url, valid)

proc call*(call_600248: Call_TagResource_600235; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_600249 = newJObject()
  var body_600250 = newJObject()
  if body != nil:
    body_600250 = body
  add(path_600249, "resourceArn", newJString(resourceArn))
  result = call_600248.call(path_600249, nil, nil, nil, body_600250)

var tagResource* = Call_TagResource_600235(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600236,
                                        base: "/", url: url_TagResource_600237,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600221 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600223(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600222(path: JsonNode; query: JsonNode;
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
  var valid_600224 = path.getOrDefault("resourceArn")
  valid_600224 = validateParameter(valid_600224, JString, required = true,
                                 default = nil)
  if valid_600224 != nil:
    section.add "resourceArn", valid_600224
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
  var valid_600225 = header.getOrDefault("X-Amz-Date")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Date", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Security-Token")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Security-Token", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Content-Sha256", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Algorithm")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Algorithm", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Signature")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Signature", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-SignedHeaders", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Credential")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Credential", valid_600231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600232: Call_ListTagsForResource_600221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_600232.validator(path, query, header, formData, body)
  let scheme = call_600232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600232.url(scheme.get, call_600232.host, call_600232.base,
                         call_600232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600232, url, valid)

proc call*(call_600233: Call_ListTagsForResource_600221; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_600234 = newJObject()
  add(path_600234, "resourceArn", newJString(resourceArn))
  result = call_600233.call(path_600234, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600221(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600222, base: "/",
    url: url_ListTagsForResource_600223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_600251 = ref object of OpenApiRestCall_599368
proc url_ListUserHierarchyGroups_600253(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserHierarchyGroups_600252(path: JsonNode; query: JsonNode;
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
  var valid_600254 = path.getOrDefault("InstanceId")
  valid_600254 = validateParameter(valid_600254, JString, required = true,
                                 default = nil)
  if valid_600254 != nil:
    section.add "InstanceId", valid_600254
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
  var valid_600255 = query.getOrDefault("NextToken")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "NextToken", valid_600255
  var valid_600256 = query.getOrDefault("maxResults")
  valid_600256 = validateParameter(valid_600256, JInt, required = false, default = nil)
  if valid_600256 != nil:
    section.add "maxResults", valid_600256
  var valid_600257 = query.getOrDefault("nextToken")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "nextToken", valid_600257
  var valid_600258 = query.getOrDefault("MaxResults")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "MaxResults", valid_600258
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
  var valid_600259 = header.getOrDefault("X-Amz-Date")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Date", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Security-Token")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Security-Token", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Content-Sha256", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Algorithm")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Algorithm", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Signature")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Signature", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-SignedHeaders", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Credential")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Credential", valid_600265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600266: Call_ListUserHierarchyGroups_600251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  let valid = call_600266.validator(path, query, header, formData, body)
  let scheme = call_600266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600266.url(scheme.get, call_600266.host, call_600266.base,
                         call_600266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600266, url, valid)

proc call*(call_600267: Call_ListUserHierarchyGroups_600251; InstanceId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
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
  var path_600268 = newJObject()
  var query_600269 = newJObject()
  add(path_600268, "InstanceId", newJString(InstanceId))
  add(query_600269, "NextToken", newJString(NextToken))
  add(query_600269, "maxResults", newJInt(maxResults))
  add(query_600269, "nextToken", newJString(nextToken))
  add(query_600269, "MaxResults", newJString(MaxResults))
  result = call_600267.call(path_600268, query_600269, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_600251(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_600252, base: "/",
    url: url_ListUserHierarchyGroups_600253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_600270 = ref object of OpenApiRestCall_599368
proc url_ListUsers_600272(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_600271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600273 = path.getOrDefault("InstanceId")
  valid_600273 = validateParameter(valid_600273, JString, required = true,
                                 default = nil)
  if valid_600273 != nil:
    section.add "InstanceId", valid_600273
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
  var valid_600274 = query.getOrDefault("NextToken")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "NextToken", valid_600274
  var valid_600275 = query.getOrDefault("maxResults")
  valid_600275 = validateParameter(valid_600275, JInt, required = false, default = nil)
  if valid_600275 != nil:
    section.add "maxResults", valid_600275
  var valid_600276 = query.getOrDefault("nextToken")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "nextToken", valid_600276
  var valid_600277 = query.getOrDefault("MaxResults")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "MaxResults", valid_600277
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
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600285: Call_ListUsers_600270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_ListUsers_600270; InstanceId: string;
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
  var path_600287 = newJObject()
  var query_600288 = newJObject()
  add(path_600287, "InstanceId", newJString(InstanceId))
  add(query_600288, "NextToken", newJString(NextToken))
  add(query_600288, "maxResults", newJInt(maxResults))
  add(query_600288, "nextToken", newJString(nextToken))
  add(query_600288, "MaxResults", newJString(MaxResults))
  result = call_600286.call(path_600287, query_600288, nil, nil, nil)

var listUsers* = Call_ListUsers_600270(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_600271,
                                    base: "/", url: url_ListUsers_600272,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChatContact_600289 = ref object of OpenApiRestCall_599368
proc url_StartChatContact_600291(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChatContact_600290(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Content-Sha256", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Algorithm")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Algorithm", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Signature")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Signature", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-SignedHeaders", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Credential")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Credential", valid_600298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600300: Call_StartChatContact_600289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ## 
  let valid = call_600300.validator(path, query, header, formData, body)
  let scheme = call_600300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600300.url(scheme.get, call_600300.host, call_600300.base,
                         call_600300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600300, url, valid)

proc call*(call_600301: Call_StartChatContact_600289; body: JsonNode): Recallable =
  ## startChatContact
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ##   body: JObject (required)
  var body_600302 = newJObject()
  if body != nil:
    body_600302 = body
  result = call_600301.call(nil, nil, nil, nil, body_600302)

var startChatContact* = Call_StartChatContact_600289(name: "startChatContact",
    meth: HttpMethod.HttpPut, host: "connect.amazonaws.com", route: "/contact/chat",
    validator: validate_StartChatContact_600290, base: "/",
    url: url_StartChatContact_600291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_600303 = ref object of OpenApiRestCall_599368
proc url_StartOutboundVoiceContact_600305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOutboundVoiceContact_600304(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600306 = header.getOrDefault("X-Amz-Date")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Date", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Security-Token")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Security-Token", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Content-Sha256", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Algorithm")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Algorithm", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Signature")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Signature", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-SignedHeaders", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Credential")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Credential", valid_600312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600314: Call_StartOutboundVoiceContact_600303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ## 
  let valid = call_600314.validator(path, query, header, formData, body)
  let scheme = call_600314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600314.url(scheme.get, call_600314.host, call_600314.base,
                         call_600314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600314, url, valid)

proc call*(call_600315: Call_StartOutboundVoiceContact_600303; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   body: JObject (required)
  var body_600316 = newJObject()
  if body != nil:
    body_600316 = body
  result = call_600315.call(nil, nil, nil, nil, body_600316)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_600303(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_600304, base: "/",
    url: url_StartOutboundVoiceContact_600305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_600317 = ref object of OpenApiRestCall_599368
proc url_StopContact_600319(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContact_600318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600320 = header.getOrDefault("X-Amz-Date")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Date", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Security-Token")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Security-Token", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Content-Sha256", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Algorithm")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Algorithm", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Signature")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Signature", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-SignedHeaders", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Credential")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Credential", valid_600326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600328: Call_StopContact_600317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends the specified contact.
  ## 
  let valid = call_600328.validator(path, query, header, formData, body)
  let scheme = call_600328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600328.url(scheme.get, call_600328.host, call_600328.base,
                         call_600328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600328, url, valid)

proc call*(call_600329: Call_StopContact_600317; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_600330 = newJObject()
  if body != nil:
    body_600330 = body
  result = call_600329.call(nil, nil, nil, nil, body_600330)

var stopContact* = Call_StopContact_600317(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_600318,
                                        base: "/", url: url_StopContact_600319,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600331 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600333(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600334 = path.getOrDefault("resourceArn")
  valid_600334 = validateParameter(valid_600334, JString, required = true,
                                 default = nil)
  if valid_600334 != nil:
    section.add "resourceArn", valid_600334
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600335 = query.getOrDefault("tagKeys")
  valid_600335 = validateParameter(valid_600335, JArray, required = true, default = nil)
  if valid_600335 != nil:
    section.add "tagKeys", valid_600335
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
  var valid_600336 = header.getOrDefault("X-Amz-Date")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Date", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Security-Token")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Security-Token", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Content-Sha256", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Algorithm")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Algorithm", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Signature")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Signature", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-SignedHeaders", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Credential")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Credential", valid_600342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600343: Call_UntagResource_600331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_600343.validator(path, query, header, formData, body)
  let scheme = call_600343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600343.url(scheme.get, call_600343.host, call_600343.base,
                         call_600343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600343, url, valid)

proc call*(call_600344: Call_UntagResource_600331; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_600345 = newJObject()
  var query_600346 = newJObject()
  if tagKeys != nil:
    query_600346.add "tagKeys", tagKeys
  add(path_600345, "resourceArn", newJString(resourceArn))
  result = call_600344.call(path_600345, query_600346, nil, nil, nil)

var untagResource* = Call_UntagResource_600331(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600332,
    base: "/", url: url_UntagResource_600333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_600347 = ref object of OpenApiRestCall_599368
proc url_UpdateContactAttributes_600349(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContactAttributes_600348(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600350 = header.getOrDefault("X-Amz-Date")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Date", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Security-Token")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Security-Token", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Content-Sha256", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Algorithm")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Algorithm", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Signature")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Signature", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-SignedHeaders", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Credential")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Credential", valid_600356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600358: Call_UpdateContactAttributes_600347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_600358.validator(path, query, header, formData, body)
  let scheme = call_600358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600358.url(scheme.get, call_600358.host, call_600358.base,
                         call_600358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600358, url, valid)

proc call*(call_600359: Call_UpdateContactAttributes_600347; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_600360 = newJObject()
  if body != nil:
    body_600360 = body
  result = call_600359.call(nil, nil, nil, nil, body_600360)

var updateContactAttributes* = Call_UpdateContactAttributes_600347(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_600348, base: "/",
    url: url_UpdateContactAttributes_600349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_600361 = ref object of OpenApiRestCall_599368
proc url_UpdateUserHierarchy_600363(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserHierarchy_600362(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600364 = path.getOrDefault("InstanceId")
  valid_600364 = validateParameter(valid_600364, JString, required = true,
                                 default = nil)
  if valid_600364 != nil:
    section.add "InstanceId", valid_600364
  var valid_600365 = path.getOrDefault("UserId")
  valid_600365 = validateParameter(valid_600365, JString, required = true,
                                 default = nil)
  if valid_600365 != nil:
    section.add "UserId", valid_600365
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
  var valid_600366 = header.getOrDefault("X-Amz-Date")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Date", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Security-Token")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Security-Token", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Content-Sha256", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Algorithm")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Algorithm", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Signature")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Signature", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-SignedHeaders", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Credential")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Credential", valid_600372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600374: Call_UpdateUserHierarchy_600361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  let valid = call_600374.validator(path, query, header, formData, body)
  let scheme = call_600374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600374.url(scheme.get, call_600374.host, call_600374.base,
                         call_600374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600374, url, valid)

proc call*(call_600375: Call_UpdateUserHierarchy_600361; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_600376 = newJObject()
  var body_600377 = newJObject()
  add(path_600376, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_600377 = body
  add(path_600376, "UserId", newJString(UserId))
  result = call_600375.call(path_600376, nil, nil, nil, body_600377)

var updateUserHierarchy* = Call_UpdateUserHierarchy_600361(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_600362, base: "/",
    url: url_UpdateUserHierarchy_600363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_600378 = ref object of OpenApiRestCall_599368
proc url_UpdateUserIdentityInfo_600380(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserIdentityInfo_600379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600381 = path.getOrDefault("InstanceId")
  valid_600381 = validateParameter(valid_600381, JString, required = true,
                                 default = nil)
  if valid_600381 != nil:
    section.add "InstanceId", valid_600381
  var valid_600382 = path.getOrDefault("UserId")
  valid_600382 = validateParameter(valid_600382, JString, required = true,
                                 default = nil)
  if valid_600382 != nil:
    section.add "UserId", valid_600382
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
  var valid_600383 = header.getOrDefault("X-Amz-Date")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Date", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Security-Token")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Security-Token", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_UpdateUserIdentityInfo_600378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user.
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_UpdateUserIdentityInfo_600378; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_600393 = newJObject()
  var body_600394 = newJObject()
  add(path_600393, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_600394 = body
  add(path_600393, "UserId", newJString(UserId))
  result = call_600392.call(path_600393, nil, nil, nil, body_600394)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_600378(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_600379, base: "/",
    url: url_UpdateUserIdentityInfo_600380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_600395 = ref object of OpenApiRestCall_599368
proc url_UpdateUserPhoneConfig_600397(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPhoneConfig_600396(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600398 = path.getOrDefault("InstanceId")
  valid_600398 = validateParameter(valid_600398, JString, required = true,
                                 default = nil)
  if valid_600398 != nil:
    section.add "InstanceId", valid_600398
  var valid_600399 = path.getOrDefault("UserId")
  valid_600399 = validateParameter(valid_600399, JString, required = true,
                                 default = nil)
  if valid_600399 != nil:
    section.add "UserId", valid_600399
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
  var valid_600400 = header.getOrDefault("X-Amz-Date")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Date", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Security-Token")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Security-Token", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Content-Sha256", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Algorithm")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Algorithm", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Signature")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Signature", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-SignedHeaders", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Credential")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Credential", valid_600406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600408: Call_UpdateUserPhoneConfig_600395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings for the specified user.
  ## 
  let valid = call_600408.validator(path, query, header, formData, body)
  let scheme = call_600408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600408.url(scheme.get, call_600408.host, call_600408.base,
                         call_600408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600408, url, valid)

proc call*(call_600409: Call_UpdateUserPhoneConfig_600395; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_600410 = newJObject()
  var body_600411 = newJObject()
  add(path_600410, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_600411 = body
  add(path_600410, "UserId", newJString(UserId))
  result = call_600409.call(path_600410, nil, nil, nil, body_600411)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_600395(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_600396, base: "/",
    url: url_UpdateUserPhoneConfig_600397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_600412 = ref object of OpenApiRestCall_599368
proc url_UpdateUserRoutingProfile_600414(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_600413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600415 = path.getOrDefault("InstanceId")
  valid_600415 = validateParameter(valid_600415, JString, required = true,
                                 default = nil)
  if valid_600415 != nil:
    section.add "InstanceId", valid_600415
  var valid_600416 = path.getOrDefault("UserId")
  valid_600416 = validateParameter(valid_600416, JString, required = true,
                                 default = nil)
  if valid_600416 != nil:
    section.add "UserId", valid_600416
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
  var valid_600423 = header.getOrDefault("X-Amz-Credential")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Credential", valid_600423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600425: Call_UpdateUserRoutingProfile_600412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to the specified user.
  ## 
  let valid = call_600425.validator(path, query, header, formData, body)
  let scheme = call_600425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600425.url(scheme.get, call_600425.host, call_600425.base,
                         call_600425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600425, url, valid)

proc call*(call_600426: Call_UpdateUserRoutingProfile_600412; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_600427 = newJObject()
  var body_600428 = newJObject()
  add(path_600427, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_600428 = body
  add(path_600427, "UserId", newJString(UserId))
  result = call_600426.call(path_600427, nil, nil, nil, body_600428)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_600412(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_600413, base: "/",
    url: url_UpdateUserRoutingProfile_600414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_600429 = ref object of OpenApiRestCall_599368
proc url_UpdateUserSecurityProfiles_600431(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_600430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600432 = path.getOrDefault("InstanceId")
  valid_600432 = validateParameter(valid_600432, JString, required = true,
                                 default = nil)
  if valid_600432 != nil:
    section.add "InstanceId", valid_600432
  var valid_600433 = path.getOrDefault("UserId")
  valid_600433 = validateParameter(valid_600433, JString, required = true,
                                 default = nil)
  if valid_600433 != nil:
    section.add "UserId", valid_600433
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
  var valid_600434 = header.getOrDefault("X-Amz-Date")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Date", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Security-Token")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Security-Token", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Content-Sha256", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Algorithm")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Algorithm", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Signature")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Signature", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-SignedHeaders", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Credential")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Credential", valid_600440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600442: Call_UpdateUserSecurityProfiles_600429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified security profiles to the specified user.
  ## 
  let valid = call_600442.validator(path, query, header, formData, body)
  let scheme = call_600442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600442.url(scheme.get, call_600442.host, call_600442.base,
                         call_600442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600442, url, valid)

proc call*(call_600443: Call_UpdateUserSecurityProfiles_600429; InstanceId: string;
          body: JsonNode; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  ##   body: JObject (required)
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  var path_600444 = newJObject()
  var body_600445 = newJObject()
  add(path_600444, "InstanceId", newJString(InstanceId))
  if body != nil:
    body_600445 = body
  add(path_600444, "UserId", newJString(UserId))
  result = call_600443.call(path_600444, nil, nil, nil, body_600445)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_600429(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_600430, base: "/",
    url: url_UpdateUserSecurityProfiles_600431,
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
