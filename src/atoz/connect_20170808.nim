
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  Call_CreateUser_590703 = ref object of OpenApiRestCall_590364
proc url_CreateUser_590705(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590831 = path.getOrDefault("InstanceId")
  valid_590831 = validateParameter(valid_590831, JString, required = true,
                                 default = nil)
  if valid_590831 != nil:
    section.add "InstanceId", valid_590831
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
  var valid_590832 = header.getOrDefault("X-Amz-Signature")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Signature", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Content-Sha256", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Date")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Date", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Credential")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Credential", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Security-Token")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Security-Token", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-Algorithm")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-Algorithm", valid_590837
  var valid_590838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590838 = validateParameter(valid_590838, JString, required = false,
                                 default = nil)
  if valid_590838 != nil:
    section.add "X-Amz-SignedHeaders", valid_590838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590862: Call_CreateUser_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  let valid = call_590862.validator(path, query, header, formData, body)
  let scheme = call_590862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590862.url(scheme.get, call_590862.host, call_590862.base,
                         call_590862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590862, url, valid)

proc call*(call_590933: Call_CreateUser_590703; body: JsonNode; InstanceId: string): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_590934 = newJObject()
  var body_590936 = newJObject()
  if body != nil:
    body_590936 = body
  add(path_590934, "InstanceId", newJString(InstanceId))
  result = call_590933.call(path_590934, nil, nil, nil, body_590936)

var createUser* = Call_CreateUser_590703(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_590704,
                                      base: "/", url: url_CreateUser_590705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_590975 = ref object of OpenApiRestCall_590364
proc url_DescribeUser_590977(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_590976(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the specified user account.
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
  var valid_590978 = path.getOrDefault("UserId")
  valid_590978 = validateParameter(valid_590978, JString, required = true,
                                 default = nil)
  if valid_590978 != nil:
    section.add "UserId", valid_590978
  var valid_590979 = path.getOrDefault("InstanceId")
  valid_590979 = validateParameter(valid_590979, JString, required = true,
                                 default = nil)
  if valid_590979 != nil:
    section.add "InstanceId", valid_590979
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
  var valid_590980 = header.getOrDefault("X-Amz-Signature")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Signature", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Content-Sha256", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-Date")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-Date", valid_590982
  var valid_590983 = header.getOrDefault("X-Amz-Credential")
  valid_590983 = validateParameter(valid_590983, JString, required = false,
                                 default = nil)
  if valid_590983 != nil:
    section.add "X-Amz-Credential", valid_590983
  var valid_590984 = header.getOrDefault("X-Amz-Security-Token")
  valid_590984 = validateParameter(valid_590984, JString, required = false,
                                 default = nil)
  if valid_590984 != nil:
    section.add "X-Amz-Security-Token", valid_590984
  var valid_590985 = header.getOrDefault("X-Amz-Algorithm")
  valid_590985 = validateParameter(valid_590985, JString, required = false,
                                 default = nil)
  if valid_590985 != nil:
    section.add "X-Amz-Algorithm", valid_590985
  var valid_590986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590986 = validateParameter(valid_590986, JString, required = false,
                                 default = nil)
  if valid_590986 != nil:
    section.add "X-Amz-SignedHeaders", valid_590986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_590987: Call_DescribeUser_590975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified user account.
  ## 
  let valid = call_590987.validator(path, query, header, formData, body)
  let scheme = call_590987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590987.url(scheme.get, call_590987.host, call_590987.base,
                         call_590987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590987, url, valid)

proc call*(call_590988: Call_DescribeUser_590975; UserId: string; InstanceId: string): Recallable =
  ## describeUser
  ## Describes the specified user account.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_590989 = newJObject()
  add(path_590989, "UserId", newJString(UserId))
  add(path_590989, "InstanceId", newJString(InstanceId))
  result = call_590988.call(path_590989, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_590975(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_590976,
    base: "/", url: url_DescribeUser_590977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_590990 = ref object of OpenApiRestCall_590364
proc url_DeleteUser_590992(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_590991(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590993 = path.getOrDefault("UserId")
  valid_590993 = validateParameter(valid_590993, JString, required = true,
                                 default = nil)
  if valid_590993 != nil:
    section.add "UserId", valid_590993
  var valid_590994 = path.getOrDefault("InstanceId")
  valid_590994 = validateParameter(valid_590994, JString, required = true,
                                 default = nil)
  if valid_590994 != nil:
    section.add "InstanceId", valid_590994
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
  var valid_590995 = header.getOrDefault("X-Amz-Signature")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Signature", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Content-Sha256", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-Date")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-Date", valid_590997
  var valid_590998 = header.getOrDefault("X-Amz-Credential")
  valid_590998 = validateParameter(valid_590998, JString, required = false,
                                 default = nil)
  if valid_590998 != nil:
    section.add "X-Amz-Credential", valid_590998
  var valid_590999 = header.getOrDefault("X-Amz-Security-Token")
  valid_590999 = validateParameter(valid_590999, JString, required = false,
                                 default = nil)
  if valid_590999 != nil:
    section.add "X-Amz-Security-Token", valid_590999
  var valid_591000 = header.getOrDefault("X-Amz-Algorithm")
  valid_591000 = validateParameter(valid_591000, JString, required = false,
                                 default = nil)
  if valid_591000 != nil:
    section.add "X-Amz-Algorithm", valid_591000
  var valid_591001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591001 = validateParameter(valid_591001, JString, required = false,
                                 default = nil)
  if valid_591001 != nil:
    section.add "X-Amz-SignedHeaders", valid_591001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591002: Call_DeleteUser_590990; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  let valid = call_591002.validator(path, query, header, formData, body)
  let scheme = call_591002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591002.url(scheme.get, call_591002.host, call_591002.base,
                         call_591002.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591002, url, valid)

proc call*(call_591003: Call_DeleteUser_590990; UserId: string; InstanceId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591004 = newJObject()
  add(path_591004, "UserId", newJString(UserId))
  add(path_591004, "InstanceId", newJString(InstanceId))
  result = call_591003.call(path_591004, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_590990(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_590991,
                                      base: "/", url: url_DeleteUser_590992,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_591005 = ref object of OpenApiRestCall_590364
proc url_DescribeUserHierarchyGroup_591007(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_591006(path: JsonNode; query: JsonNode;
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
  var valid_591008 = path.getOrDefault("HierarchyGroupId")
  valid_591008 = validateParameter(valid_591008, JString, required = true,
                                 default = nil)
  if valid_591008 != nil:
    section.add "HierarchyGroupId", valid_591008
  var valid_591009 = path.getOrDefault("InstanceId")
  valid_591009 = validateParameter(valid_591009, JString, required = true,
                                 default = nil)
  if valid_591009 != nil:
    section.add "InstanceId", valid_591009
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
  var valid_591010 = header.getOrDefault("X-Amz-Signature")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Signature", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Content-Sha256", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-Date")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-Date", valid_591012
  var valid_591013 = header.getOrDefault("X-Amz-Credential")
  valid_591013 = validateParameter(valid_591013, JString, required = false,
                                 default = nil)
  if valid_591013 != nil:
    section.add "X-Amz-Credential", valid_591013
  var valid_591014 = header.getOrDefault("X-Amz-Security-Token")
  valid_591014 = validateParameter(valid_591014, JString, required = false,
                                 default = nil)
  if valid_591014 != nil:
    section.add "X-Amz-Security-Token", valid_591014
  var valid_591015 = header.getOrDefault("X-Amz-Algorithm")
  valid_591015 = validateParameter(valid_591015, JString, required = false,
                                 default = nil)
  if valid_591015 != nil:
    section.add "X-Amz-Algorithm", valid_591015
  var valid_591016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591016 = validateParameter(valid_591016, JString, required = false,
                                 default = nil)
  if valid_591016 != nil:
    section.add "X-Amz-SignedHeaders", valid_591016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591017: Call_DescribeUserHierarchyGroup_591005; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified hierarchy group.
  ## 
  let valid = call_591017.validator(path, query, header, formData, body)
  let scheme = call_591017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591017.url(scheme.get, call_591017.host, call_591017.base,
                         call_591017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591017, url, valid)

proc call*(call_591018: Call_DescribeUserHierarchyGroup_591005;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591019 = newJObject()
  add(path_591019, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_591019, "InstanceId", newJString(InstanceId))
  result = call_591018.call(path_591019, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_591005(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_591006, base: "/",
    url: url_DescribeUserHierarchyGroup_591007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_591020 = ref object of OpenApiRestCall_590364
proc url_DescribeUserHierarchyStructure_591022(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyStructure_591021(path: JsonNode;
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
  var valid_591023 = path.getOrDefault("InstanceId")
  valid_591023 = validateParameter(valid_591023, JString, required = true,
                                 default = nil)
  if valid_591023 != nil:
    section.add "InstanceId", valid_591023
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
  var valid_591024 = header.getOrDefault("X-Amz-Signature")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Signature", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Content-Sha256", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Date")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Date", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-Credential")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-Credential", valid_591027
  var valid_591028 = header.getOrDefault("X-Amz-Security-Token")
  valid_591028 = validateParameter(valid_591028, JString, required = false,
                                 default = nil)
  if valid_591028 != nil:
    section.add "X-Amz-Security-Token", valid_591028
  var valid_591029 = header.getOrDefault("X-Amz-Algorithm")
  valid_591029 = validateParameter(valid_591029, JString, required = false,
                                 default = nil)
  if valid_591029 != nil:
    section.add "X-Amz-Algorithm", valid_591029
  var valid_591030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591030 = validateParameter(valid_591030, JString, required = false,
                                 default = nil)
  if valid_591030 != nil:
    section.add "X-Amz-SignedHeaders", valid_591030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591031: Call_DescribeUserHierarchyStructure_591020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  let valid = call_591031.validator(path, query, header, formData, body)
  let scheme = call_591031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591031.url(scheme.get, call_591031.host, call_591031.base,
                         call_591031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591031, url, valid)

proc call*(call_591032: Call_DescribeUserHierarchyStructure_591020;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591033 = newJObject()
  add(path_591033, "InstanceId", newJString(InstanceId))
  result = call_591032.call(path_591033, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_591020(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_591021, base: "/",
    url: url_DescribeUserHierarchyStructure_591022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_591034 = ref object of OpenApiRestCall_590364
proc url_GetContactAttributes_591036(protocol: Scheme; host: string; base: string;
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

proc validate_GetContactAttributes_591035(path: JsonNode; query: JsonNode;
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
  var valid_591037 = path.getOrDefault("InitialContactId")
  valid_591037 = validateParameter(valid_591037, JString, required = true,
                                 default = nil)
  if valid_591037 != nil:
    section.add "InitialContactId", valid_591037
  var valid_591038 = path.getOrDefault("InstanceId")
  valid_591038 = validateParameter(valid_591038, JString, required = true,
                                 default = nil)
  if valid_591038 != nil:
    section.add "InstanceId", valid_591038
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
  var valid_591039 = header.getOrDefault("X-Amz-Signature")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Signature", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Content-Sha256", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Date")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Date", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-Credential")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-Credential", valid_591042
  var valid_591043 = header.getOrDefault("X-Amz-Security-Token")
  valid_591043 = validateParameter(valid_591043, JString, required = false,
                                 default = nil)
  if valid_591043 != nil:
    section.add "X-Amz-Security-Token", valid_591043
  var valid_591044 = header.getOrDefault("X-Amz-Algorithm")
  valid_591044 = validateParameter(valid_591044, JString, required = false,
                                 default = nil)
  if valid_591044 != nil:
    section.add "X-Amz-Algorithm", valid_591044
  var valid_591045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-SignedHeaders", valid_591045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591046: Call_GetContactAttributes_591034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  let valid = call_591046.validator(path, query, header, formData, body)
  let scheme = call_591046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591046.url(scheme.get, call_591046.host, call_591046.base,
                         call_591046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591046, url, valid)

proc call*(call_591047: Call_GetContactAttributes_591034; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InitialContactId: string (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591048 = newJObject()
  add(path_591048, "InitialContactId", newJString(InitialContactId))
  add(path_591048, "InstanceId", newJString(InstanceId))
  result = call_591047.call(path_591048, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_591034(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_591035, base: "/",
    url: url_GetContactAttributes_591036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_591049 = ref object of OpenApiRestCall_590364
proc url_GetCurrentMetricData_591051(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentMetricData_591050(path: JsonNode; query: JsonNode;
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
  var valid_591052 = path.getOrDefault("InstanceId")
  valid_591052 = validateParameter(valid_591052, JString, required = true,
                                 default = nil)
  if valid_591052 != nil:
    section.add "InstanceId", valid_591052
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591053 = query.getOrDefault("MaxResults")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "MaxResults", valid_591053
  var valid_591054 = query.getOrDefault("NextToken")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "NextToken", valid_591054
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
  var valid_591055 = header.getOrDefault("X-Amz-Signature")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Signature", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Content-Sha256", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-Date")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-Date", valid_591057
  var valid_591058 = header.getOrDefault("X-Amz-Credential")
  valid_591058 = validateParameter(valid_591058, JString, required = false,
                                 default = nil)
  if valid_591058 != nil:
    section.add "X-Amz-Credential", valid_591058
  var valid_591059 = header.getOrDefault("X-Amz-Security-Token")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-Security-Token", valid_591059
  var valid_591060 = header.getOrDefault("X-Amz-Algorithm")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "X-Amz-Algorithm", valid_591060
  var valid_591061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-SignedHeaders", valid_591061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591063: Call_GetCurrentMetricData_591049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_591063.validator(path, query, header, formData, body)
  let scheme = call_591063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591063.url(scheme.get, call_591063.host, call_591063.base,
                         call_591063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591063, url, valid)

proc call*(call_591064: Call_GetCurrentMetricData_591049; body: JsonNode;
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
  var path_591065 = newJObject()
  var query_591066 = newJObject()
  var body_591067 = newJObject()
  add(query_591066, "MaxResults", newJString(MaxResults))
  add(query_591066, "NextToken", newJString(NextToken))
  if body != nil:
    body_591067 = body
  add(path_591065, "InstanceId", newJString(InstanceId))
  result = call_591064.call(path_591065, query_591066, nil, nil, body_591067)

var getCurrentMetricData* = Call_GetCurrentMetricData_591049(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_591050, base: "/",
    url: url_GetCurrentMetricData_591051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_591068 = ref object of OpenApiRestCall_590364
proc url_GetFederationToken_591070(protocol: Scheme; host: string; base: string;
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

proc validate_GetFederationToken_591069(path: JsonNode; query: JsonNode;
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
  var valid_591071 = path.getOrDefault("InstanceId")
  valid_591071 = validateParameter(valid_591071, JString, required = true,
                                 default = nil)
  if valid_591071 != nil:
    section.add "InstanceId", valid_591071
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
  var valid_591072 = header.getOrDefault("X-Amz-Signature")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Signature", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Content-Sha256", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Date")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Date", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Credential")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Credential", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-Security-Token")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Security-Token", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-Algorithm")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-Algorithm", valid_591077
  var valid_591078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591078 = validateParameter(valid_591078, JString, required = false,
                                 default = nil)
  if valid_591078 != nil:
    section.add "X-Amz-SignedHeaders", valid_591078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591079: Call_GetFederationToken_591068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_591079.validator(path, query, header, formData, body)
  let scheme = call_591079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591079.url(scheme.get, call_591079.host, call_591079.base,
                         call_591079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591079, url, valid)

proc call*(call_591080: Call_GetFederationToken_591068; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591081 = newJObject()
  add(path_591081, "InstanceId", newJString(InstanceId))
  result = call_591080.call(path_591081, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_591068(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_591069, base: "/",
    url: url_GetFederationToken_591070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_591082 = ref object of OpenApiRestCall_590364
proc url_GetMetricData_591084(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_591083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591085 = path.getOrDefault("InstanceId")
  valid_591085 = validateParameter(valid_591085, JString, required = true,
                                 default = nil)
  if valid_591085 != nil:
    section.add "InstanceId", valid_591085
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_591086 = query.getOrDefault("MaxResults")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "MaxResults", valid_591086
  var valid_591087 = query.getOrDefault("NextToken")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "NextToken", valid_591087
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
  var valid_591088 = header.getOrDefault("X-Amz-Signature")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Signature", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Content-Sha256", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Date")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Date", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-Credential")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-Credential", valid_591091
  var valid_591092 = header.getOrDefault("X-Amz-Security-Token")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "X-Amz-Security-Token", valid_591092
  var valid_591093 = header.getOrDefault("X-Amz-Algorithm")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "X-Amz-Algorithm", valid_591093
  var valid_591094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591094 = validateParameter(valid_591094, JString, required = false,
                                 default = nil)
  if valid_591094 != nil:
    section.add "X-Amz-SignedHeaders", valid_591094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591096: Call_GetMetricData_591082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_591096.validator(path, query, header, formData, body)
  let scheme = call_591096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591096.url(scheme.get, call_591096.host, call_591096.base,
                         call_591096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591096, url, valid)

proc call*(call_591097: Call_GetMetricData_591082; body: JsonNode;
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
  var path_591098 = newJObject()
  var query_591099 = newJObject()
  var body_591100 = newJObject()
  add(query_591099, "MaxResults", newJString(MaxResults))
  add(query_591099, "NextToken", newJString(NextToken))
  if body != nil:
    body_591100 = body
  add(path_591098, "InstanceId", newJString(InstanceId))
  result = call_591097.call(path_591098, query_591099, nil, nil, body_591100)

var getMetricData* = Call_GetMetricData_591082(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_591083,
    base: "/", url: url_GetMetricData_591084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_591101 = ref object of OpenApiRestCall_590364
proc url_ListContactFlows_591103(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListContactFlows_591102(path: JsonNode; query: JsonNode;
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
  var valid_591104 = path.getOrDefault("InstanceId")
  valid_591104 = validateParameter(valid_591104, JString, required = true,
                                 default = nil)
  if valid_591104 != nil:
    section.add "InstanceId", valid_591104
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
  var valid_591105 = query.getOrDefault("contactFlowTypes")
  valid_591105 = validateParameter(valid_591105, JArray, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "contactFlowTypes", valid_591105
  var valid_591106 = query.getOrDefault("nextToken")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "nextToken", valid_591106
  var valid_591107 = query.getOrDefault("MaxResults")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "MaxResults", valid_591107
  var valid_591108 = query.getOrDefault("NextToken")
  valid_591108 = validateParameter(valid_591108, JString, required = false,
                                 default = nil)
  if valid_591108 != nil:
    section.add "NextToken", valid_591108
  var valid_591109 = query.getOrDefault("maxResults")
  valid_591109 = validateParameter(valid_591109, JInt, required = false, default = nil)
  if valid_591109 != nil:
    section.add "maxResults", valid_591109
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
  var valid_591110 = header.getOrDefault("X-Amz-Signature")
  valid_591110 = validateParameter(valid_591110, JString, required = false,
                                 default = nil)
  if valid_591110 != nil:
    section.add "X-Amz-Signature", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Content-Sha256", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Date")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Date", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Credential")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Credential", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Security-Token")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Security-Token", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Algorithm")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Algorithm", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-SignedHeaders", valid_591116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591117: Call_ListContactFlows_591101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  let valid = call_591117.validator(path, query, header, formData, body)
  let scheme = call_591117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591117.url(scheme.get, call_591117.host, call_591117.base,
                         call_591117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591117, url, valid)

proc call*(call_591118: Call_ListContactFlows_591101; InstanceId: string;
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
  var path_591119 = newJObject()
  var query_591120 = newJObject()
  if contactFlowTypes != nil:
    query_591120.add "contactFlowTypes", contactFlowTypes
  add(query_591120, "nextToken", newJString(nextToken))
  add(query_591120, "MaxResults", newJString(MaxResults))
  add(query_591120, "NextToken", newJString(NextToken))
  add(path_591119, "InstanceId", newJString(InstanceId))
  add(query_591120, "maxResults", newJInt(maxResults))
  result = call_591118.call(path_591119, query_591120, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_591101(name: "listContactFlows",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_591102, base: "/",
    url: url_ListContactFlows_591103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_591121 = ref object of OpenApiRestCall_590364
proc url_ListHoursOfOperations_591123(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListHoursOfOperations_591122(path: JsonNode; query: JsonNode;
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
  var valid_591124 = path.getOrDefault("InstanceId")
  valid_591124 = validateParameter(valid_591124, JString, required = true,
                                 default = nil)
  if valid_591124 != nil:
    section.add "InstanceId", valid_591124
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
  var valid_591125 = query.getOrDefault("nextToken")
  valid_591125 = validateParameter(valid_591125, JString, required = false,
                                 default = nil)
  if valid_591125 != nil:
    section.add "nextToken", valid_591125
  var valid_591126 = query.getOrDefault("MaxResults")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "MaxResults", valid_591126
  var valid_591127 = query.getOrDefault("NextToken")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "NextToken", valid_591127
  var valid_591128 = query.getOrDefault("maxResults")
  valid_591128 = validateParameter(valid_591128, JInt, required = false, default = nil)
  if valid_591128 != nil:
    section.add "maxResults", valid_591128
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
  var valid_591129 = header.getOrDefault("X-Amz-Signature")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Signature", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Content-Sha256", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Date")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Date", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-Credential")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-Credential", valid_591132
  var valid_591133 = header.getOrDefault("X-Amz-Security-Token")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "X-Amz-Security-Token", valid_591133
  var valid_591134 = header.getOrDefault("X-Amz-Algorithm")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "X-Amz-Algorithm", valid_591134
  var valid_591135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "X-Amz-SignedHeaders", valid_591135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591136: Call_ListHoursOfOperations_591121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  let valid = call_591136.validator(path, query, header, formData, body)
  let scheme = call_591136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591136.url(scheme.get, call_591136.host, call_591136.base,
                         call_591136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591136, url, valid)

proc call*(call_591137: Call_ListHoursOfOperations_591121; InstanceId: string;
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
  var path_591138 = newJObject()
  var query_591139 = newJObject()
  add(query_591139, "nextToken", newJString(nextToken))
  add(query_591139, "MaxResults", newJString(MaxResults))
  add(query_591139, "NextToken", newJString(NextToken))
  add(path_591138, "InstanceId", newJString(InstanceId))
  add(query_591139, "maxResults", newJInt(maxResults))
  result = call_591137.call(path_591138, query_591139, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_591121(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_591122, base: "/",
    url: url_ListHoursOfOperations_591123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_591140 = ref object of OpenApiRestCall_590364
proc url_ListPhoneNumbers_591142(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListPhoneNumbers_591141(path: JsonNode; query: JsonNode;
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
  var valid_591143 = path.getOrDefault("InstanceId")
  valid_591143 = validateParameter(valid_591143, JString, required = true,
                                 default = nil)
  if valid_591143 != nil:
    section.add "InstanceId", valid_591143
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
  var valid_591144 = query.getOrDefault("phoneNumberCountryCodes")
  valid_591144 = validateParameter(valid_591144, JArray, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "phoneNumberCountryCodes", valid_591144
  var valid_591145 = query.getOrDefault("nextToken")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "nextToken", valid_591145
  var valid_591146 = query.getOrDefault("MaxResults")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "MaxResults", valid_591146
  var valid_591147 = query.getOrDefault("phoneNumberTypes")
  valid_591147 = validateParameter(valid_591147, JArray, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "phoneNumberTypes", valid_591147
  var valid_591148 = query.getOrDefault("NextToken")
  valid_591148 = validateParameter(valid_591148, JString, required = false,
                                 default = nil)
  if valid_591148 != nil:
    section.add "NextToken", valid_591148
  var valid_591149 = query.getOrDefault("maxResults")
  valid_591149 = validateParameter(valid_591149, JInt, required = false, default = nil)
  if valid_591149 != nil:
    section.add "maxResults", valid_591149
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
  var valid_591150 = header.getOrDefault("X-Amz-Signature")
  valid_591150 = validateParameter(valid_591150, JString, required = false,
                                 default = nil)
  if valid_591150 != nil:
    section.add "X-Amz-Signature", valid_591150
  var valid_591151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591151 = validateParameter(valid_591151, JString, required = false,
                                 default = nil)
  if valid_591151 != nil:
    section.add "X-Amz-Content-Sha256", valid_591151
  var valid_591152 = header.getOrDefault("X-Amz-Date")
  valid_591152 = validateParameter(valid_591152, JString, required = false,
                                 default = nil)
  if valid_591152 != nil:
    section.add "X-Amz-Date", valid_591152
  var valid_591153 = header.getOrDefault("X-Amz-Credential")
  valid_591153 = validateParameter(valid_591153, JString, required = false,
                                 default = nil)
  if valid_591153 != nil:
    section.add "X-Amz-Credential", valid_591153
  var valid_591154 = header.getOrDefault("X-Amz-Security-Token")
  valid_591154 = validateParameter(valid_591154, JString, required = false,
                                 default = nil)
  if valid_591154 != nil:
    section.add "X-Amz-Security-Token", valid_591154
  var valid_591155 = header.getOrDefault("X-Amz-Algorithm")
  valid_591155 = validateParameter(valid_591155, JString, required = false,
                                 default = nil)
  if valid_591155 != nil:
    section.add "X-Amz-Algorithm", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-SignedHeaders", valid_591156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591157: Call_ListPhoneNumbers_591140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  let valid = call_591157.validator(path, query, header, formData, body)
  let scheme = call_591157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591157.url(scheme.get, call_591157.host, call_591157.base,
                         call_591157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591157, url, valid)

proc call*(call_591158: Call_ListPhoneNumbers_591140; InstanceId: string;
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
  var path_591159 = newJObject()
  var query_591160 = newJObject()
  if phoneNumberCountryCodes != nil:
    query_591160.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  add(query_591160, "nextToken", newJString(nextToken))
  add(query_591160, "MaxResults", newJString(MaxResults))
  if phoneNumberTypes != nil:
    query_591160.add "phoneNumberTypes", phoneNumberTypes
  add(query_591160, "NextToken", newJString(NextToken))
  add(path_591159, "InstanceId", newJString(InstanceId))
  add(query_591160, "maxResults", newJInt(maxResults))
  result = call_591158.call(path_591159, query_591160, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_591140(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_591141, base: "/",
    url: url_ListPhoneNumbers_591142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_591161 = ref object of OpenApiRestCall_590364
proc url_ListQueues_591163(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_ListQueues_591162(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591164 = path.getOrDefault("InstanceId")
  valid_591164 = validateParameter(valid_591164, JString, required = true,
                                 default = nil)
  if valid_591164 != nil:
    section.add "InstanceId", valid_591164
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
  var valid_591165 = query.getOrDefault("nextToken")
  valid_591165 = validateParameter(valid_591165, JString, required = false,
                                 default = nil)
  if valid_591165 != nil:
    section.add "nextToken", valid_591165
  var valid_591166 = query.getOrDefault("MaxResults")
  valid_591166 = validateParameter(valid_591166, JString, required = false,
                                 default = nil)
  if valid_591166 != nil:
    section.add "MaxResults", valid_591166
  var valid_591167 = query.getOrDefault("NextToken")
  valid_591167 = validateParameter(valid_591167, JString, required = false,
                                 default = nil)
  if valid_591167 != nil:
    section.add "NextToken", valid_591167
  var valid_591168 = query.getOrDefault("queueTypes")
  valid_591168 = validateParameter(valid_591168, JArray, required = false,
                                 default = nil)
  if valid_591168 != nil:
    section.add "queueTypes", valid_591168
  var valid_591169 = query.getOrDefault("maxResults")
  valid_591169 = validateParameter(valid_591169, JInt, required = false, default = nil)
  if valid_591169 != nil:
    section.add "maxResults", valid_591169
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
  var valid_591170 = header.getOrDefault("X-Amz-Signature")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Signature", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Content-Sha256", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Date")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Date", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Credential")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Credential", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Security-Token")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Security-Token", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Algorithm")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Algorithm", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-SignedHeaders", valid_591176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591177: Call_ListQueues_591161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  let valid = call_591177.validator(path, query, header, formData, body)
  let scheme = call_591177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591177.url(scheme.get, call_591177.host, call_591177.base,
                         call_591177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591177, url, valid)

proc call*(call_591178: Call_ListQueues_591161; InstanceId: string;
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
  var path_591179 = newJObject()
  var query_591180 = newJObject()
  add(query_591180, "nextToken", newJString(nextToken))
  add(query_591180, "MaxResults", newJString(MaxResults))
  add(query_591180, "NextToken", newJString(NextToken))
  add(path_591179, "InstanceId", newJString(InstanceId))
  if queueTypes != nil:
    query_591180.add "queueTypes", queueTypes
  add(query_591180, "maxResults", newJInt(maxResults))
  result = call_591178.call(path_591179, query_591180, nil, nil, nil)

var listQueues* = Call_ListQueues_591161(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "connect.amazonaws.com",
                                      route: "/queues-summary/{InstanceId}",
                                      validator: validate_ListQueues_591162,
                                      base: "/", url: url_ListQueues_591163,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_591181 = ref object of OpenApiRestCall_590364
proc url_ListRoutingProfiles_591183(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutingProfiles_591182(path: JsonNode; query: JsonNode;
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
  var valid_591184 = path.getOrDefault("InstanceId")
  valid_591184 = validateParameter(valid_591184, JString, required = true,
                                 default = nil)
  if valid_591184 != nil:
    section.add "InstanceId", valid_591184
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
  var valid_591185 = query.getOrDefault("nextToken")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "nextToken", valid_591185
  var valid_591186 = query.getOrDefault("MaxResults")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "MaxResults", valid_591186
  var valid_591187 = query.getOrDefault("NextToken")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "NextToken", valid_591187
  var valid_591188 = query.getOrDefault("maxResults")
  valid_591188 = validateParameter(valid_591188, JInt, required = false, default = nil)
  if valid_591188 != nil:
    section.add "maxResults", valid_591188
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
  var valid_591189 = header.getOrDefault("X-Amz-Signature")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Signature", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Content-Sha256", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Date")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Date", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-Credential")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-Credential", valid_591192
  var valid_591193 = header.getOrDefault("X-Amz-Security-Token")
  valid_591193 = validateParameter(valid_591193, JString, required = false,
                                 default = nil)
  if valid_591193 != nil:
    section.add "X-Amz-Security-Token", valid_591193
  var valid_591194 = header.getOrDefault("X-Amz-Algorithm")
  valid_591194 = validateParameter(valid_591194, JString, required = false,
                                 default = nil)
  if valid_591194 != nil:
    section.add "X-Amz-Algorithm", valid_591194
  var valid_591195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591195 = validateParameter(valid_591195, JString, required = false,
                                 default = nil)
  if valid_591195 != nil:
    section.add "X-Amz-SignedHeaders", valid_591195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591196: Call_ListRoutingProfiles_591181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_591196.validator(path, query, header, formData, body)
  let scheme = call_591196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591196.url(scheme.get, call_591196.host, call_591196.base,
                         call_591196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591196, url, valid)

proc call*(call_591197: Call_ListRoutingProfiles_591181; InstanceId: string;
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
  var path_591198 = newJObject()
  var query_591199 = newJObject()
  add(query_591199, "nextToken", newJString(nextToken))
  add(query_591199, "MaxResults", newJString(MaxResults))
  add(query_591199, "NextToken", newJString(NextToken))
  add(path_591198, "InstanceId", newJString(InstanceId))
  add(query_591199, "maxResults", newJInt(maxResults))
  result = call_591197.call(path_591198, query_591199, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_591181(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_591182, base: "/",
    url: url_ListRoutingProfiles_591183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_591200 = ref object of OpenApiRestCall_590364
proc url_ListSecurityProfiles_591202(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecurityProfiles_591201(path: JsonNode; query: JsonNode;
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
  var valid_591203 = path.getOrDefault("InstanceId")
  valid_591203 = validateParameter(valid_591203, JString, required = true,
                                 default = nil)
  if valid_591203 != nil:
    section.add "InstanceId", valid_591203
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
  var valid_591204 = query.getOrDefault("nextToken")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "nextToken", valid_591204
  var valid_591205 = query.getOrDefault("MaxResults")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "MaxResults", valid_591205
  var valid_591206 = query.getOrDefault("NextToken")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "NextToken", valid_591206
  var valid_591207 = query.getOrDefault("maxResults")
  valid_591207 = validateParameter(valid_591207, JInt, required = false, default = nil)
  if valid_591207 != nil:
    section.add "maxResults", valid_591207
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
  var valid_591208 = header.getOrDefault("X-Amz-Signature")
  valid_591208 = validateParameter(valid_591208, JString, required = false,
                                 default = nil)
  if valid_591208 != nil:
    section.add "X-Amz-Signature", valid_591208
  var valid_591209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591209 = validateParameter(valid_591209, JString, required = false,
                                 default = nil)
  if valid_591209 != nil:
    section.add "X-Amz-Content-Sha256", valid_591209
  var valid_591210 = header.getOrDefault("X-Amz-Date")
  valid_591210 = validateParameter(valid_591210, JString, required = false,
                                 default = nil)
  if valid_591210 != nil:
    section.add "X-Amz-Date", valid_591210
  var valid_591211 = header.getOrDefault("X-Amz-Credential")
  valid_591211 = validateParameter(valid_591211, JString, required = false,
                                 default = nil)
  if valid_591211 != nil:
    section.add "X-Amz-Credential", valid_591211
  var valid_591212 = header.getOrDefault("X-Amz-Security-Token")
  valid_591212 = validateParameter(valid_591212, JString, required = false,
                                 default = nil)
  if valid_591212 != nil:
    section.add "X-Amz-Security-Token", valid_591212
  var valid_591213 = header.getOrDefault("X-Amz-Algorithm")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Algorithm", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-SignedHeaders", valid_591214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591215: Call_ListSecurityProfiles_591200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_591215.validator(path, query, header, formData, body)
  let scheme = call_591215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591215.url(scheme.get, call_591215.host, call_591215.base,
                         call_591215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591215, url, valid)

proc call*(call_591216: Call_ListSecurityProfiles_591200; InstanceId: string;
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
  var path_591217 = newJObject()
  var query_591218 = newJObject()
  add(query_591218, "nextToken", newJString(nextToken))
  add(query_591218, "MaxResults", newJString(MaxResults))
  add(query_591218, "NextToken", newJString(NextToken))
  add(path_591217, "InstanceId", newJString(InstanceId))
  add(query_591218, "maxResults", newJInt(maxResults))
  result = call_591216.call(path_591217, query_591218, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_591200(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_591201, base: "/",
    url: url_ListSecurityProfiles_591202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_591219 = ref object of OpenApiRestCall_590364
proc url_ListUserHierarchyGroups_591221(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserHierarchyGroups_591220(path: JsonNode; query: JsonNode;
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
  var valid_591222 = path.getOrDefault("InstanceId")
  valid_591222 = validateParameter(valid_591222, JString, required = true,
                                 default = nil)
  if valid_591222 != nil:
    section.add "InstanceId", valid_591222
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
  var valid_591223 = query.getOrDefault("nextToken")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "nextToken", valid_591223
  var valid_591224 = query.getOrDefault("MaxResults")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "MaxResults", valid_591224
  var valid_591225 = query.getOrDefault("NextToken")
  valid_591225 = validateParameter(valid_591225, JString, required = false,
                                 default = nil)
  if valid_591225 != nil:
    section.add "NextToken", valid_591225
  var valid_591226 = query.getOrDefault("maxResults")
  valid_591226 = validateParameter(valid_591226, JInt, required = false, default = nil)
  if valid_591226 != nil:
    section.add "maxResults", valid_591226
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
  var valid_591227 = header.getOrDefault("X-Amz-Signature")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Signature", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Content-Sha256", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-Date")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-Date", valid_591229
  var valid_591230 = header.getOrDefault("X-Amz-Credential")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Credential", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Security-Token")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Security-Token", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Algorithm")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Algorithm", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-SignedHeaders", valid_591233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591234: Call_ListUserHierarchyGroups_591219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  let valid = call_591234.validator(path, query, header, formData, body)
  let scheme = call_591234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591234.url(scheme.get, call_591234.host, call_591234.base,
                         call_591234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591234, url, valid)

proc call*(call_591235: Call_ListUserHierarchyGroups_591219; InstanceId: string;
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
  var path_591236 = newJObject()
  var query_591237 = newJObject()
  add(query_591237, "nextToken", newJString(nextToken))
  add(query_591237, "MaxResults", newJString(MaxResults))
  add(query_591237, "NextToken", newJString(NextToken))
  add(path_591236, "InstanceId", newJString(InstanceId))
  add(query_591237, "maxResults", newJInt(maxResults))
  result = call_591235.call(path_591236, query_591237, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_591219(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_591220, base: "/",
    url: url_ListUserHierarchyGroups_591221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_591238 = ref object of OpenApiRestCall_590364
proc url_ListUsers_591240(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_591239(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591241 = path.getOrDefault("InstanceId")
  valid_591241 = validateParameter(valid_591241, JString, required = true,
                                 default = nil)
  if valid_591241 != nil:
    section.add "InstanceId", valid_591241
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
  var valid_591242 = query.getOrDefault("nextToken")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "nextToken", valid_591242
  var valid_591243 = query.getOrDefault("MaxResults")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "MaxResults", valid_591243
  var valid_591244 = query.getOrDefault("NextToken")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "NextToken", valid_591244
  var valid_591245 = query.getOrDefault("maxResults")
  valid_591245 = validateParameter(valid_591245, JInt, required = false, default = nil)
  if valid_591245 != nil:
    section.add "maxResults", valid_591245
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
  var valid_591246 = header.getOrDefault("X-Amz-Signature")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Signature", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Content-Sha256", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Date")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Date", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Credential")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Credential", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Security-Token")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Security-Token", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Algorithm")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Algorithm", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-SignedHeaders", valid_591252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591253: Call_ListUsers_591238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  let valid = call_591253.validator(path, query, header, formData, body)
  let scheme = call_591253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591253.url(scheme.get, call_591253.host, call_591253.base,
                         call_591253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591253, url, valid)

proc call*(call_591254: Call_ListUsers_591238; InstanceId: string;
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
  var path_591255 = newJObject()
  var query_591256 = newJObject()
  add(query_591256, "nextToken", newJString(nextToken))
  add(query_591256, "MaxResults", newJString(MaxResults))
  add(query_591256, "NextToken", newJString(NextToken))
  add(path_591255, "InstanceId", newJString(InstanceId))
  add(query_591256, "maxResults", newJInt(maxResults))
  result = call_591254.call(path_591255, query_591256, nil, nil, nil)

var listUsers* = Call_ListUsers_591238(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_591239,
                                    base: "/", url: url_ListUsers_591240,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_591257 = ref object of OpenApiRestCall_590364
proc url_StartOutboundVoiceContact_591259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartOutboundVoiceContact_591258(path: JsonNode; query: JsonNode;
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
  var valid_591260 = header.getOrDefault("X-Amz-Signature")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Signature", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Content-Sha256", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Date")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Date", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Credential")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Credential", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Security-Token")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Security-Token", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Algorithm")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Algorithm", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-SignedHeaders", valid_591266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591268: Call_StartOutboundVoiceContact_591257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ## 
  let valid = call_591268.validator(path, query, header, formData, body)
  let scheme = call_591268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591268.url(scheme.get, call_591268.host, call_591268.base,
                         call_591268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591268, url, valid)

proc call*(call_591269: Call_StartOutboundVoiceContact_591257; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   body: JObject (required)
  var body_591270 = newJObject()
  if body != nil:
    body_591270 = body
  result = call_591269.call(nil, nil, nil, nil, body_591270)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_591257(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_591258, base: "/",
    url: url_StartOutboundVoiceContact_591259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_591271 = ref object of OpenApiRestCall_590364
proc url_StopContact_591273(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopContact_591272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591274 = header.getOrDefault("X-Amz-Signature")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Signature", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Content-Sha256", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Date")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Date", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Credential")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Credential", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Security-Token")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Security-Token", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Algorithm")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Algorithm", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-SignedHeaders", valid_591280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591282: Call_StopContact_591271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends the specified contact.
  ## 
  let valid = call_591282.validator(path, query, header, formData, body)
  let scheme = call_591282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591282.url(scheme.get, call_591282.host, call_591282.base,
                         call_591282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591282, url, valid)

proc call*(call_591283: Call_StopContact_591271; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_591284 = newJObject()
  if body != nil:
    body_591284 = body
  result = call_591283.call(nil, nil, nil, nil, body_591284)

var stopContact* = Call_StopContact_591271(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_591272,
                                        base: "/", url: url_StopContact_591273,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_591285 = ref object of OpenApiRestCall_590364
proc url_UpdateContactAttributes_591287(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateContactAttributes_591286(path: JsonNode; query: JsonNode;
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
  var valid_591288 = header.getOrDefault("X-Amz-Signature")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "X-Amz-Signature", valid_591288
  var valid_591289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "X-Amz-Content-Sha256", valid_591289
  var valid_591290 = header.getOrDefault("X-Amz-Date")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "X-Amz-Date", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Credential")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Credential", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Security-Token")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Security-Token", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Algorithm")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Algorithm", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-SignedHeaders", valid_591294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591296: Call_UpdateContactAttributes_591285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_591296.validator(path, query, header, formData, body)
  let scheme = call_591296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591296.url(scheme.get, call_591296.host, call_591296.base,
                         call_591296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591296, url, valid)

proc call*(call_591297: Call_UpdateContactAttributes_591285; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_591298 = newJObject()
  if body != nil:
    body_591298 = body
  result = call_591297.call(nil, nil, nil, nil, body_591298)

var updateContactAttributes* = Call_UpdateContactAttributes_591285(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_591286, base: "/",
    url: url_UpdateContactAttributes_591287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_591299 = ref object of OpenApiRestCall_590364
proc url_UpdateUserHierarchy_591301(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserHierarchy_591300(path: JsonNode; query: JsonNode;
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
  var valid_591302 = path.getOrDefault("UserId")
  valid_591302 = validateParameter(valid_591302, JString, required = true,
                                 default = nil)
  if valid_591302 != nil:
    section.add "UserId", valid_591302
  var valid_591303 = path.getOrDefault("InstanceId")
  valid_591303 = validateParameter(valid_591303, JString, required = true,
                                 default = nil)
  if valid_591303 != nil:
    section.add "InstanceId", valid_591303
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
  var valid_591304 = header.getOrDefault("X-Amz-Signature")
  valid_591304 = validateParameter(valid_591304, JString, required = false,
                                 default = nil)
  if valid_591304 != nil:
    section.add "X-Amz-Signature", valid_591304
  var valid_591305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591305 = validateParameter(valid_591305, JString, required = false,
                                 default = nil)
  if valid_591305 != nil:
    section.add "X-Amz-Content-Sha256", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Date")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Date", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Credential")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Credential", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Security-Token")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Security-Token", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Algorithm")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Algorithm", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-SignedHeaders", valid_591310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591312: Call_UpdateUserHierarchy_591299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  let valid = call_591312.validator(path, query, header, formData, body)
  let scheme = call_591312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591312.url(scheme.get, call_591312.host, call_591312.base,
                         call_591312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591312, url, valid)

proc call*(call_591313: Call_UpdateUserHierarchy_591299; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591314 = newJObject()
  var body_591315 = newJObject()
  add(path_591314, "UserId", newJString(UserId))
  if body != nil:
    body_591315 = body
  add(path_591314, "InstanceId", newJString(InstanceId))
  result = call_591313.call(path_591314, nil, nil, nil, body_591315)

var updateUserHierarchy* = Call_UpdateUserHierarchy_591299(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_591300, base: "/",
    url: url_UpdateUserHierarchy_591301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_591316 = ref object of OpenApiRestCall_590364
proc url_UpdateUserIdentityInfo_591318(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserIdentityInfo_591317(path: JsonNode; query: JsonNode;
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
  var valid_591319 = path.getOrDefault("UserId")
  valid_591319 = validateParameter(valid_591319, JString, required = true,
                                 default = nil)
  if valid_591319 != nil:
    section.add "UserId", valid_591319
  var valid_591320 = path.getOrDefault("InstanceId")
  valid_591320 = validateParameter(valid_591320, JString, required = true,
                                 default = nil)
  if valid_591320 != nil:
    section.add "InstanceId", valid_591320
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
  var valid_591321 = header.getOrDefault("X-Amz-Signature")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Signature", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Content-Sha256", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Date")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Date", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Credential")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Credential", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Security-Token")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Security-Token", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Algorithm")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Algorithm", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-SignedHeaders", valid_591327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591329: Call_UpdateUserIdentityInfo_591316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user.
  ## 
  let valid = call_591329.validator(path, query, header, formData, body)
  let scheme = call_591329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591329.url(scheme.get, call_591329.host, call_591329.base,
                         call_591329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591329, url, valid)

proc call*(call_591330: Call_UpdateUserIdentityInfo_591316; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591331 = newJObject()
  var body_591332 = newJObject()
  add(path_591331, "UserId", newJString(UserId))
  if body != nil:
    body_591332 = body
  add(path_591331, "InstanceId", newJString(InstanceId))
  result = call_591330.call(path_591331, nil, nil, nil, body_591332)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_591316(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_591317, base: "/",
    url: url_UpdateUserIdentityInfo_591318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_591333 = ref object of OpenApiRestCall_590364
proc url_UpdateUserPhoneConfig_591335(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPhoneConfig_591334(path: JsonNode; query: JsonNode;
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
  var valid_591336 = path.getOrDefault("UserId")
  valid_591336 = validateParameter(valid_591336, JString, required = true,
                                 default = nil)
  if valid_591336 != nil:
    section.add "UserId", valid_591336
  var valid_591337 = path.getOrDefault("InstanceId")
  valid_591337 = validateParameter(valid_591337, JString, required = true,
                                 default = nil)
  if valid_591337 != nil:
    section.add "InstanceId", valid_591337
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
  var valid_591338 = header.getOrDefault("X-Amz-Signature")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Signature", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Content-Sha256", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-Date")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-Date", valid_591340
  var valid_591341 = header.getOrDefault("X-Amz-Credential")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Credential", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-Security-Token")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-Security-Token", valid_591342
  var valid_591343 = header.getOrDefault("X-Amz-Algorithm")
  valid_591343 = validateParameter(valid_591343, JString, required = false,
                                 default = nil)
  if valid_591343 != nil:
    section.add "X-Amz-Algorithm", valid_591343
  var valid_591344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = nil)
  if valid_591344 != nil:
    section.add "X-Amz-SignedHeaders", valid_591344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591346: Call_UpdateUserPhoneConfig_591333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings for the specified user.
  ## 
  let valid = call_591346.validator(path, query, header, formData, body)
  let scheme = call_591346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591346.url(scheme.get, call_591346.host, call_591346.base,
                         call_591346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591346, url, valid)

proc call*(call_591347: Call_UpdateUserPhoneConfig_591333; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591348 = newJObject()
  var body_591349 = newJObject()
  add(path_591348, "UserId", newJString(UserId))
  if body != nil:
    body_591349 = body
  add(path_591348, "InstanceId", newJString(InstanceId))
  result = call_591347.call(path_591348, nil, nil, nil, body_591349)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_591333(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_591334, base: "/",
    url: url_UpdateUserPhoneConfig_591335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_591350 = ref object of OpenApiRestCall_590364
proc url_UpdateUserRoutingProfile_591352(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_591351(path: JsonNode; query: JsonNode;
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
  var valid_591353 = path.getOrDefault("UserId")
  valid_591353 = validateParameter(valid_591353, JString, required = true,
                                 default = nil)
  if valid_591353 != nil:
    section.add "UserId", valid_591353
  var valid_591354 = path.getOrDefault("InstanceId")
  valid_591354 = validateParameter(valid_591354, JString, required = true,
                                 default = nil)
  if valid_591354 != nil:
    section.add "InstanceId", valid_591354
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
  var valid_591355 = header.getOrDefault("X-Amz-Signature")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-Signature", valid_591355
  var valid_591356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Content-Sha256", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-Date")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-Date", valid_591357
  var valid_591358 = header.getOrDefault("X-Amz-Credential")
  valid_591358 = validateParameter(valid_591358, JString, required = false,
                                 default = nil)
  if valid_591358 != nil:
    section.add "X-Amz-Credential", valid_591358
  var valid_591359 = header.getOrDefault("X-Amz-Security-Token")
  valid_591359 = validateParameter(valid_591359, JString, required = false,
                                 default = nil)
  if valid_591359 != nil:
    section.add "X-Amz-Security-Token", valid_591359
  var valid_591360 = header.getOrDefault("X-Amz-Algorithm")
  valid_591360 = validateParameter(valid_591360, JString, required = false,
                                 default = nil)
  if valid_591360 != nil:
    section.add "X-Amz-Algorithm", valid_591360
  var valid_591361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591361 = validateParameter(valid_591361, JString, required = false,
                                 default = nil)
  if valid_591361 != nil:
    section.add "X-Amz-SignedHeaders", valid_591361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591363: Call_UpdateUserRoutingProfile_591350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to the specified user.
  ## 
  let valid = call_591363.validator(path, query, header, formData, body)
  let scheme = call_591363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591363.url(scheme.get, call_591363.host, call_591363.base,
                         call_591363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591363, url, valid)

proc call*(call_591364: Call_UpdateUserRoutingProfile_591350; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591365 = newJObject()
  var body_591366 = newJObject()
  add(path_591365, "UserId", newJString(UserId))
  if body != nil:
    body_591366 = body
  add(path_591365, "InstanceId", newJString(InstanceId))
  result = call_591364.call(path_591365, nil, nil, nil, body_591366)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_591350(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_591351, base: "/",
    url: url_UpdateUserRoutingProfile_591352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_591367 = ref object of OpenApiRestCall_590364
proc url_UpdateUserSecurityProfiles_591369(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_591368(path: JsonNode; query: JsonNode;
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
  var valid_591370 = path.getOrDefault("UserId")
  valid_591370 = validateParameter(valid_591370, JString, required = true,
                                 default = nil)
  if valid_591370 != nil:
    section.add "UserId", valid_591370
  var valid_591371 = path.getOrDefault("InstanceId")
  valid_591371 = validateParameter(valid_591371, JString, required = true,
                                 default = nil)
  if valid_591371 != nil:
    section.add "InstanceId", valid_591371
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
  var valid_591372 = header.getOrDefault("X-Amz-Signature")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-Signature", valid_591372
  var valid_591373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-Content-Sha256", valid_591373
  var valid_591374 = header.getOrDefault("X-Amz-Date")
  valid_591374 = validateParameter(valid_591374, JString, required = false,
                                 default = nil)
  if valid_591374 != nil:
    section.add "X-Amz-Date", valid_591374
  var valid_591375 = header.getOrDefault("X-Amz-Credential")
  valid_591375 = validateParameter(valid_591375, JString, required = false,
                                 default = nil)
  if valid_591375 != nil:
    section.add "X-Amz-Credential", valid_591375
  var valid_591376 = header.getOrDefault("X-Amz-Security-Token")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-Security-Token", valid_591376
  var valid_591377 = header.getOrDefault("X-Amz-Algorithm")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Algorithm", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-SignedHeaders", valid_591378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591380: Call_UpdateUserSecurityProfiles_591367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified security profiles to the specified user.
  ## 
  let valid = call_591380.validator(path, query, header, formData, body)
  let scheme = call_591380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591380.url(scheme.get, call_591380.host, call_591380.base,
                         call_591380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591380, url, valid)

proc call*(call_591381: Call_UpdateUserSecurityProfiles_591367; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_591382 = newJObject()
  var body_591383 = newJObject()
  add(path_591382, "UserId", newJString(UserId))
  if body != nil:
    body_591383 = body
  add(path_591382, "InstanceId", newJString(InstanceId))
  result = call_591381.call(path_591382, nil, nil, nil, body_591383)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_591367(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_591368, base: "/",
    url: url_UpdateUserSecurityProfiles_591369,
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
