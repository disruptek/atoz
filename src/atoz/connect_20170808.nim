
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateUser_612996 = ref object of OpenApiRestCall_612658
proc url_CreateUser_612998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613124 = path.getOrDefault("InstanceId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "InstanceId", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_CreateUser_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_CreateUser_612996; body: JsonNode; InstanceId: string): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613227 = newJObject()
  var body_613229 = newJObject()
  if body != nil:
    body_613229 = body
  add(path_613227, "InstanceId", newJString(InstanceId))
  result = call_613226.call(path_613227, nil, nil, nil, body_613229)

var createUser* = Call_CreateUser_612996(name: "createUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}",
                                      validator: validate_CreateUser_612997,
                                      base: "/", url: url_CreateUser_612998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_613268 = ref object of OpenApiRestCall_612658
proc url_DescribeUser_613270(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_613269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613271 = path.getOrDefault("UserId")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "UserId", valid_613271
  var valid_613272 = path.getOrDefault("InstanceId")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = nil)
  if valid_613272 != nil:
    section.add "InstanceId", valid_613272
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
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613280: Call_DescribeUser_613268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ## 
  let valid = call_613280.validator(path, query, header, formData, body)
  let scheme = call_613280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613280.url(scheme.get, call_613280.host, call_613280.base,
                         call_613280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613280, url, valid)

proc call*(call_613281: Call_DescribeUser_613268; UserId: string; InstanceId: string): Recallable =
  ## describeUser
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613282 = newJObject()
  add(path_613282, "UserId", newJString(UserId))
  add(path_613282, "InstanceId", newJString(InstanceId))
  result = call_613281.call(path_613282, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_613268(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_613269,
    base: "/", url: url_DescribeUser_613270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_613283 = ref object of OpenApiRestCall_612658
proc url_DeleteUser_613285(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_613284(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613286 = path.getOrDefault("UserId")
  valid_613286 = validateParameter(valid_613286, JString, required = true,
                                 default = nil)
  if valid_613286 != nil:
    section.add "UserId", valid_613286
  var valid_613287 = path.getOrDefault("InstanceId")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "InstanceId", valid_613287
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
  var valid_613288 = header.getOrDefault("X-Amz-Signature")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Signature", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Content-Sha256", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Date")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Date", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Credential")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Credential", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Security-Token")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Security-Token", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Algorithm")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Algorithm", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-SignedHeaders", valid_613294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613295: Call_DeleteUser_613283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
  ## 
  let valid = call_613295.validator(path, query, header, formData, body)
  let scheme = call_613295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613295.url(scheme.get, call_613295.host, call_613295.base,
                         call_613295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613295, url, valid)

proc call*(call_613296: Call_DeleteUser_613283; UserId: string; InstanceId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   UserId: string (required)
  ##         : The identifier of the user.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613297 = newJObject()
  add(path_613297, "UserId", newJString(UserId))
  add(path_613297, "InstanceId", newJString(InstanceId))
  result = call_613296.call(path_613297, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_613283(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "connect.amazonaws.com",
                                      route: "/users/{InstanceId}/{UserId}",
                                      validator: validate_DeleteUser_613284,
                                      base: "/", url: url_DeleteUser_613285,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_613298 = ref object of OpenApiRestCall_612658
proc url_DescribeUserHierarchyGroup_613300(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_613299(path: JsonNode; query: JsonNode;
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
  var valid_613301 = path.getOrDefault("HierarchyGroupId")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = nil)
  if valid_613301 != nil:
    section.add "HierarchyGroupId", valid_613301
  var valid_613302 = path.getOrDefault("InstanceId")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "InstanceId", valid_613302
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
  var valid_613303 = header.getOrDefault("X-Amz-Signature")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Signature", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Content-Sha256", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Date")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Date", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Credential")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Credential", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Security-Token")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Security-Token", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Algorithm")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Algorithm", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-SignedHeaders", valid_613309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613310: Call_DescribeUserHierarchyGroup_613298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified hierarchy group.
  ## 
  let valid = call_613310.validator(path, query, header, formData, body)
  let scheme = call_613310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613310.url(scheme.get, call_613310.host, call_613310.base,
                         call_613310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613310, url, valid)

proc call*(call_613311: Call_DescribeUserHierarchyGroup_613298;
          HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
  ##                   : The identifier of the hierarchy group.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613312 = newJObject()
  add(path_613312, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_613312, "InstanceId", newJString(InstanceId))
  result = call_613311.call(path_613312, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_613298(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_613299, base: "/",
    url: url_DescribeUserHierarchyGroup_613300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_613313 = ref object of OpenApiRestCall_612658
proc url_DescribeUserHierarchyStructure_613315(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyStructure_613314(path: JsonNode;
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
  var valid_613316 = path.getOrDefault("InstanceId")
  valid_613316 = validateParameter(valid_613316, JString, required = true,
                                 default = nil)
  if valid_613316 != nil:
    section.add "InstanceId", valid_613316
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
  var valid_613317 = header.getOrDefault("X-Amz-Signature")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Signature", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Content-Sha256", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Date")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Date", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Credential")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Credential", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Security-Token")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Security-Token", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Algorithm")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Algorithm", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-SignedHeaders", valid_613323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613324: Call_DescribeUserHierarchyStructure_613313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ## 
  let valid = call_613324.validator(path, query, header, formData, body)
  let scheme = call_613324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613324.url(scheme.get, call_613324.host, call_613324.base,
                         call_613324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613324, url, valid)

proc call*(call_613325: Call_DescribeUserHierarchyStructure_613313;
          InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613326 = newJObject()
  add(path_613326, "InstanceId", newJString(InstanceId))
  result = call_613325.call(path_613326, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_613313(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_613314, base: "/",
    url: url_DescribeUserHierarchyStructure_613315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_613327 = ref object of OpenApiRestCall_612658
proc url_GetContactAttributes_613329(protocol: Scheme; host: string; base: string;
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

proc validate_GetContactAttributes_613328(path: JsonNode; query: JsonNode;
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
  var valid_613330 = path.getOrDefault("InitialContactId")
  valid_613330 = validateParameter(valid_613330, JString, required = true,
                                 default = nil)
  if valid_613330 != nil:
    section.add "InitialContactId", valid_613330
  var valid_613331 = path.getOrDefault("InstanceId")
  valid_613331 = validateParameter(valid_613331, JString, required = true,
                                 default = nil)
  if valid_613331 != nil:
    section.add "InstanceId", valid_613331
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
  var valid_613332 = header.getOrDefault("X-Amz-Signature")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Signature", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Content-Sha256", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Date")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Date", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Credential")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Credential", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Security-Token")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Security-Token", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Algorithm")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Algorithm", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-SignedHeaders", valid_613338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_GetContactAttributes_613327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the contact attributes for the specified contact.
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_GetContactAttributes_613327; InitialContactId: string;
          InstanceId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InitialContactId: string (required)
  ##                   : The identifier of the initial contact.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613341 = newJObject()
  add(path_613341, "InitialContactId", newJString(InitialContactId))
  add(path_613341, "InstanceId", newJString(InstanceId))
  result = call_613340.call(path_613341, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_613327(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_613328, base: "/",
    url: url_GetContactAttributes_613329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_613342 = ref object of OpenApiRestCall_612658
proc url_GetCurrentMetricData_613344(protocol: Scheme; host: string; base: string;
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

proc validate_GetCurrentMetricData_613343(path: JsonNode; query: JsonNode;
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
  var valid_613345 = path.getOrDefault("InstanceId")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = nil)
  if valid_613345 != nil:
    section.add "InstanceId", valid_613345
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613346 = query.getOrDefault("MaxResults")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "MaxResults", valid_613346
  var valid_613347 = query.getOrDefault("NextToken")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "NextToken", valid_613347
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
  var valid_613348 = header.getOrDefault("X-Amz-Signature")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Signature", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Content-Sha256", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Date")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Date", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Credential")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Credential", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-Security-Token")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Security-Token", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Algorithm")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Algorithm", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-SignedHeaders", valid_613354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613356: Call_GetCurrentMetricData_613342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_613356.validator(path, query, header, formData, body)
  let scheme = call_613356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613356.url(scheme.get, call_613356.host, call_613356.base,
                         call_613356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613356, url, valid)

proc call*(call_613357: Call_GetCurrentMetricData_613342; body: JsonNode;
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
  var path_613358 = newJObject()
  var query_613359 = newJObject()
  var body_613360 = newJObject()
  add(query_613359, "MaxResults", newJString(MaxResults))
  add(query_613359, "NextToken", newJString(NextToken))
  if body != nil:
    body_613360 = body
  add(path_613358, "InstanceId", newJString(InstanceId))
  result = call_613357.call(path_613358, query_613359, nil, nil, body_613360)

var getCurrentMetricData* = Call_GetCurrentMetricData_613342(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_613343, base: "/",
    url: url_GetCurrentMetricData_613344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_613361 = ref object of OpenApiRestCall_612658
proc url_GetFederationToken_613363(protocol: Scheme; host: string; base: string;
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

proc validate_GetFederationToken_613362(path: JsonNode; query: JsonNode;
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
  var valid_613364 = path.getOrDefault("InstanceId")
  valid_613364 = validateParameter(valid_613364, JString, required = true,
                                 default = nil)
  if valid_613364 != nil:
    section.add "InstanceId", valid_613364
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
  var valid_613365 = header.getOrDefault("X-Amz-Signature")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Signature", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Content-Sha256", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Date")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Date", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Credential")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Credential", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Security-Token")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Security-Token", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Algorithm")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Algorithm", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-SignedHeaders", valid_613371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613372: Call_GetFederationToken_613361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a token for federation.
  ## 
  let valid = call_613372.validator(path, query, header, formData, body)
  let scheme = call_613372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613372.url(scheme.get, call_613372.host, call_613372.base,
                         call_613372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613372, url, valid)

proc call*(call_613373: Call_GetFederationToken_613361; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613374 = newJObject()
  add(path_613374, "InstanceId", newJString(InstanceId))
  result = call_613373.call(path_613374, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_613361(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_613362, base: "/",
    url: url_GetFederationToken_613363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_613375 = ref object of OpenApiRestCall_612658
proc url_GetMetricData_613377(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_613376(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613378 = path.getOrDefault("InstanceId")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = nil)
  if valid_613378 != nil:
    section.add "InstanceId", valid_613378
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613379 = query.getOrDefault("MaxResults")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "MaxResults", valid_613379
  var valid_613380 = query.getOrDefault("NextToken")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "NextToken", valid_613380
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
  var valid_613381 = header.getOrDefault("X-Amz-Signature")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Signature", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Content-Sha256", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Date")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Date", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Credential")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Credential", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Security-Token")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Security-Token", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Algorithm")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Algorithm", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-SignedHeaders", valid_613387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613389: Call_GetMetricData_613375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ## 
  let valid = call_613389.validator(path, query, header, formData, body)
  let scheme = call_613389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613389.url(scheme.get, call_613389.host, call_613389.base,
                         call_613389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613389, url, valid)

proc call*(call_613390: Call_GetMetricData_613375; body: JsonNode;
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
  var path_613391 = newJObject()
  var query_613392 = newJObject()
  var body_613393 = newJObject()
  add(query_613392, "MaxResults", newJString(MaxResults))
  add(query_613392, "NextToken", newJString(NextToken))
  if body != nil:
    body_613393 = body
  add(path_613391, "InstanceId", newJString(InstanceId))
  result = call_613390.call(path_613391, query_613392, nil, nil, body_613393)

var getMetricData* = Call_GetMetricData_613375(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}", validator: validate_GetMetricData_613376,
    base: "/", url: url_GetMetricData_613377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_613394 = ref object of OpenApiRestCall_612658
proc url_ListContactFlows_613396(protocol: Scheme; host: string; base: string;
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

proc validate_ListContactFlows_613395(path: JsonNode; query: JsonNode;
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
  var valid_613397 = path.getOrDefault("InstanceId")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "InstanceId", valid_613397
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
  var valid_613398 = query.getOrDefault("contactFlowTypes")
  valid_613398 = validateParameter(valid_613398, JArray, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "contactFlowTypes", valid_613398
  var valid_613399 = query.getOrDefault("nextToken")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "nextToken", valid_613399
  var valid_613400 = query.getOrDefault("MaxResults")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "MaxResults", valid_613400
  var valid_613401 = query.getOrDefault("NextToken")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "NextToken", valid_613401
  var valid_613402 = query.getOrDefault("maxResults")
  valid_613402 = validateParameter(valid_613402, JInt, required = false, default = nil)
  if valid_613402 != nil:
    section.add "maxResults", valid_613402
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
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613410: Call_ListContactFlows_613394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ## 
  let valid = call_613410.validator(path, query, header, formData, body)
  let scheme = call_613410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613410.url(scheme.get, call_613410.host, call_613410.base,
                         call_613410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613410, url, valid)

proc call*(call_613411: Call_ListContactFlows_613394; InstanceId: string;
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
  var path_613412 = newJObject()
  var query_613413 = newJObject()
  if contactFlowTypes != nil:
    query_613413.add "contactFlowTypes", contactFlowTypes
  add(query_613413, "nextToken", newJString(nextToken))
  add(query_613413, "MaxResults", newJString(MaxResults))
  add(query_613413, "NextToken", newJString(NextToken))
  add(path_613412, "InstanceId", newJString(InstanceId))
  add(query_613413, "maxResults", newJInt(maxResults))
  result = call_613411.call(path_613412, query_613413, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_613394(name: "listContactFlows",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_613395, base: "/",
    url: url_ListContactFlows_613396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_613414 = ref object of OpenApiRestCall_612658
proc url_ListHoursOfOperations_613416(protocol: Scheme; host: string; base: string;
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

proc validate_ListHoursOfOperations_613415(path: JsonNode; query: JsonNode;
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
  var valid_613417 = path.getOrDefault("InstanceId")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = nil)
  if valid_613417 != nil:
    section.add "InstanceId", valid_613417
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
  var valid_613418 = query.getOrDefault("nextToken")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "nextToken", valid_613418
  var valid_613419 = query.getOrDefault("MaxResults")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "MaxResults", valid_613419
  var valid_613420 = query.getOrDefault("NextToken")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "NextToken", valid_613420
  var valid_613421 = query.getOrDefault("maxResults")
  valid_613421 = validateParameter(valid_613421, JInt, required = false, default = nil)
  if valid_613421 != nil:
    section.add "maxResults", valid_613421
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
  var valid_613422 = header.getOrDefault("X-Amz-Signature")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Signature", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Content-Sha256", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Date")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Date", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Credential")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Credential", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Security-Token")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Security-Token", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Algorithm")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Algorithm", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-SignedHeaders", valid_613428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613429: Call_ListHoursOfOperations_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ## 
  let valid = call_613429.validator(path, query, header, formData, body)
  let scheme = call_613429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613429.url(scheme.get, call_613429.host, call_613429.base,
                         call_613429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613429, url, valid)

proc call*(call_613430: Call_ListHoursOfOperations_613414; InstanceId: string;
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
  var path_613431 = newJObject()
  var query_613432 = newJObject()
  add(query_613432, "nextToken", newJString(nextToken))
  add(query_613432, "MaxResults", newJString(MaxResults))
  add(query_613432, "NextToken", newJString(NextToken))
  add(path_613431, "InstanceId", newJString(InstanceId))
  add(query_613432, "maxResults", newJInt(maxResults))
  result = call_613430.call(path_613431, query_613432, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_613414(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_613415, base: "/",
    url: url_ListHoursOfOperations_613416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_613433 = ref object of OpenApiRestCall_612658
proc url_ListPhoneNumbers_613435(protocol: Scheme; host: string; base: string;
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

proc validate_ListPhoneNumbers_613434(path: JsonNode; query: JsonNode;
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
  var valid_613436 = path.getOrDefault("InstanceId")
  valid_613436 = validateParameter(valid_613436, JString, required = true,
                                 default = nil)
  if valid_613436 != nil:
    section.add "InstanceId", valid_613436
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
  var valid_613437 = query.getOrDefault("phoneNumberCountryCodes")
  valid_613437 = validateParameter(valid_613437, JArray, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "phoneNumberCountryCodes", valid_613437
  var valid_613438 = query.getOrDefault("nextToken")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "nextToken", valid_613438
  var valid_613439 = query.getOrDefault("MaxResults")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "MaxResults", valid_613439
  var valid_613440 = query.getOrDefault("phoneNumberTypes")
  valid_613440 = validateParameter(valid_613440, JArray, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "phoneNumberTypes", valid_613440
  var valid_613441 = query.getOrDefault("NextToken")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "NextToken", valid_613441
  var valid_613442 = query.getOrDefault("maxResults")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "maxResults", valid_613442
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
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_ListPhoneNumbers_613433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_ListPhoneNumbers_613433; InstanceId: string;
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
  var path_613452 = newJObject()
  var query_613453 = newJObject()
  if phoneNumberCountryCodes != nil:
    query_613453.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  add(query_613453, "nextToken", newJString(nextToken))
  add(query_613453, "MaxResults", newJString(MaxResults))
  if phoneNumberTypes != nil:
    query_613453.add "phoneNumberTypes", phoneNumberTypes
  add(query_613453, "NextToken", newJString(NextToken))
  add(path_613452, "InstanceId", newJString(InstanceId))
  add(query_613453, "maxResults", newJInt(maxResults))
  result = call_613451.call(path_613452, query_613453, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_613433(name: "listPhoneNumbers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_613434, base: "/",
    url: url_ListPhoneNumbers_613435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_613454 = ref object of OpenApiRestCall_612658
proc url_ListQueues_613456(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListQueues_613455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613457 = path.getOrDefault("InstanceId")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = nil)
  if valid_613457 != nil:
    section.add "InstanceId", valid_613457
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
  var valid_613458 = query.getOrDefault("nextToken")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "nextToken", valid_613458
  var valid_613459 = query.getOrDefault("MaxResults")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "MaxResults", valid_613459
  var valid_613460 = query.getOrDefault("NextToken")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "NextToken", valid_613460
  var valid_613461 = query.getOrDefault("queueTypes")
  valid_613461 = validateParameter(valid_613461, JArray, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "queueTypes", valid_613461
  var valid_613462 = query.getOrDefault("maxResults")
  valid_613462 = validateParameter(valid_613462, JInt, required = false, default = nil)
  if valid_613462 != nil:
    section.add "maxResults", valid_613462
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
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_ListQueues_613454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_ListQueues_613454; InstanceId: string;
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
  var path_613472 = newJObject()
  var query_613473 = newJObject()
  add(query_613473, "nextToken", newJString(nextToken))
  add(query_613473, "MaxResults", newJString(MaxResults))
  add(query_613473, "NextToken", newJString(NextToken))
  add(path_613472, "InstanceId", newJString(InstanceId))
  if queueTypes != nil:
    query_613473.add "queueTypes", queueTypes
  add(query_613473, "maxResults", newJInt(maxResults))
  result = call_613471.call(path_613472, query_613473, nil, nil, nil)

var listQueues* = Call_ListQueues_613454(name: "listQueues",
                                      meth: HttpMethod.HttpGet,
                                      host: "connect.amazonaws.com",
                                      route: "/queues-summary/{InstanceId}",
                                      validator: validate_ListQueues_613455,
                                      base: "/", url: url_ListQueues_613456,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_613474 = ref object of OpenApiRestCall_612658
proc url_ListRoutingProfiles_613476(protocol: Scheme; host: string; base: string;
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

proc validate_ListRoutingProfiles_613475(path: JsonNode; query: JsonNode;
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
  var valid_613477 = path.getOrDefault("InstanceId")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "InstanceId", valid_613477
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
  var valid_613478 = query.getOrDefault("nextToken")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "nextToken", valid_613478
  var valid_613479 = query.getOrDefault("MaxResults")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "MaxResults", valid_613479
  var valid_613480 = query.getOrDefault("NextToken")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "NextToken", valid_613480
  var valid_613481 = query.getOrDefault("maxResults")
  valid_613481 = validateParameter(valid_613481, JInt, required = false, default = nil)
  if valid_613481 != nil:
    section.add "maxResults", valid_613481
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
  var valid_613482 = header.getOrDefault("X-Amz-Signature")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Signature", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Content-Sha256", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Date")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Date", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Credential")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Credential", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Security-Token")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Security-Token", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Algorithm")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Algorithm", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-SignedHeaders", valid_613488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613489: Call_ListRoutingProfiles_613474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_613489.validator(path, query, header, formData, body)
  let scheme = call_613489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613489.url(scheme.get, call_613489.host, call_613489.base,
                         call_613489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613489, url, valid)

proc call*(call_613490: Call_ListRoutingProfiles_613474; InstanceId: string;
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
  var path_613491 = newJObject()
  var query_613492 = newJObject()
  add(query_613492, "nextToken", newJString(nextToken))
  add(query_613492, "MaxResults", newJString(MaxResults))
  add(query_613492, "NextToken", newJString(NextToken))
  add(path_613491, "InstanceId", newJString(InstanceId))
  add(query_613492, "maxResults", newJInt(maxResults))
  result = call_613490.call(path_613491, query_613492, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_613474(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_613475, base: "/",
    url: url_ListRoutingProfiles_613476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_613493 = ref object of OpenApiRestCall_612658
proc url_ListSecurityProfiles_613495(protocol: Scheme; host: string; base: string;
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

proc validate_ListSecurityProfiles_613494(path: JsonNode; query: JsonNode;
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
  var valid_613496 = path.getOrDefault("InstanceId")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "InstanceId", valid_613496
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
  var valid_613497 = query.getOrDefault("nextToken")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "nextToken", valid_613497
  var valid_613498 = query.getOrDefault("MaxResults")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "MaxResults", valid_613498
  var valid_613499 = query.getOrDefault("NextToken")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "NextToken", valid_613499
  var valid_613500 = query.getOrDefault("maxResults")
  valid_613500 = validateParameter(valid_613500, JInt, required = false, default = nil)
  if valid_613500 != nil:
    section.add "maxResults", valid_613500
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
  var valid_613501 = header.getOrDefault("X-Amz-Signature")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Signature", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Content-Sha256", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Date")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Date", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Credential")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Credential", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Security-Token")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Security-Token", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Algorithm")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Algorithm", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-SignedHeaders", valid_613507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613508: Call_ListSecurityProfiles_613493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_ListSecurityProfiles_613493; InstanceId: string;
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
  var path_613510 = newJObject()
  var query_613511 = newJObject()
  add(query_613511, "nextToken", newJString(nextToken))
  add(query_613511, "MaxResults", newJString(MaxResults))
  add(query_613511, "NextToken", newJString(NextToken))
  add(path_613510, "InstanceId", newJString(InstanceId))
  add(query_613511, "maxResults", newJInt(maxResults))
  result = call_613509.call(path_613510, query_613511, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_613493(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_613494, base: "/",
    url: url_ListSecurityProfiles_613495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613526 = ref object of OpenApiRestCall_612658
proc url_TagResource_613528(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613527(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613529 = path.getOrDefault("resourceArn")
  valid_613529 = validateParameter(valid_613529, JString, required = true,
                                 default = nil)
  if valid_613529 != nil:
    section.add "resourceArn", valid_613529
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
  var valid_613530 = header.getOrDefault("X-Amz-Signature")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Signature", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Content-Sha256", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Date")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Date", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Credential")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Credential", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Security-Token")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Security-Token", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Algorithm")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Algorithm", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-SignedHeaders", valid_613536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613538: Call_TagResource_613526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ## 
  let valid = call_613538.validator(path, query, header, formData, body)
  let scheme = call_613538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613538.url(scheme.get, call_613538.host, call_613538.base,
                         call_613538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613538, url, valid)

proc call*(call_613539: Call_TagResource_613526; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   body: JObject (required)
  var path_613540 = newJObject()
  var body_613541 = newJObject()
  add(path_613540, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613541 = body
  result = call_613539.call(path_613540, nil, nil, nil, body_613541)

var tagResource* = Call_TagResource_613526(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613527,
                                        base: "/", url: url_TagResource_613528,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613512 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613514(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613513(path: JsonNode; query: JsonNode;
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
  var valid_613515 = path.getOrDefault("resourceArn")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = nil)
  if valid_613515 != nil:
    section.add "resourceArn", valid_613515
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
  var valid_613516 = header.getOrDefault("X-Amz-Signature")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Signature", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Content-Sha256", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Date")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Date", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Credential")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Credential", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Security-Token")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Security-Token", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Algorithm")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Algorithm", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-SignedHeaders", valid_613522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613523: Call_ListTagsForResource_613512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the specified resource.
  ## 
  let valid = call_613523.validator(path, query, header, formData, body)
  let scheme = call_613523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613523.url(scheme.get, call_613523.host, call_613523.base,
                         call_613523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613523, url, valid)

proc call*(call_613524: Call_ListTagsForResource_613512; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  var path_613525 = newJObject()
  add(path_613525, "resourceArn", newJString(resourceArn))
  result = call_613524.call(path_613525, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613512(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613513, base: "/",
    url: url_ListTagsForResource_613514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_613542 = ref object of OpenApiRestCall_612658
proc url_ListUserHierarchyGroups_613544(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserHierarchyGroups_613543(path: JsonNode; query: JsonNode;
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
  var valid_613545 = path.getOrDefault("InstanceId")
  valid_613545 = validateParameter(valid_613545, JString, required = true,
                                 default = nil)
  if valid_613545 != nil:
    section.add "InstanceId", valid_613545
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
  var valid_613546 = query.getOrDefault("nextToken")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "nextToken", valid_613546
  var valid_613547 = query.getOrDefault("MaxResults")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "MaxResults", valid_613547
  var valid_613548 = query.getOrDefault("NextToken")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "NextToken", valid_613548
  var valid_613549 = query.getOrDefault("maxResults")
  valid_613549 = validateParameter(valid_613549, JInt, required = false, default = nil)
  if valid_613549 != nil:
    section.add "maxResults", valid_613549
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
  var valid_613550 = header.getOrDefault("X-Amz-Signature")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Signature", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Content-Sha256", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Date")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Date", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Credential")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Credential", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Security-Token")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Security-Token", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Algorithm")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Algorithm", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-SignedHeaders", valid_613556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613557: Call_ListUserHierarchyGroups_613542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ## 
  let valid = call_613557.validator(path, query, header, formData, body)
  let scheme = call_613557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613557.url(scheme.get, call_613557.host, call_613557.base,
                         call_613557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613557, url, valid)

proc call*(call_613558: Call_ListUserHierarchyGroups_613542; InstanceId: string;
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
  var path_613559 = newJObject()
  var query_613560 = newJObject()
  add(query_613560, "nextToken", newJString(nextToken))
  add(query_613560, "MaxResults", newJString(MaxResults))
  add(query_613560, "NextToken", newJString(NextToken))
  add(path_613559, "InstanceId", newJString(InstanceId))
  add(query_613560, "maxResults", newJInt(maxResults))
  result = call_613558.call(path_613559, query_613560, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_613542(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_613543, base: "/",
    url: url_ListUserHierarchyGroups_613544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_613561 = ref object of OpenApiRestCall_612658
proc url_ListUsers_613563(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_613562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613564 = path.getOrDefault("InstanceId")
  valid_613564 = validateParameter(valid_613564, JString, required = true,
                                 default = nil)
  if valid_613564 != nil:
    section.add "InstanceId", valid_613564
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
  var valid_613565 = query.getOrDefault("nextToken")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "nextToken", valid_613565
  var valid_613566 = query.getOrDefault("MaxResults")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "MaxResults", valid_613566
  var valid_613567 = query.getOrDefault("NextToken")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "NextToken", valid_613567
  var valid_613568 = query.getOrDefault("maxResults")
  valid_613568 = validateParameter(valid_613568, JInt, required = false, default = nil)
  if valid_613568 != nil:
    section.add "maxResults", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613576: Call_ListUsers_613561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ## 
  let valid = call_613576.validator(path, query, header, formData, body)
  let scheme = call_613576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613576.url(scheme.get, call_613576.host, call_613576.base,
                         call_613576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613576, url, valid)

proc call*(call_613577: Call_ListUsers_613561; InstanceId: string;
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
  var path_613578 = newJObject()
  var query_613579 = newJObject()
  add(query_613579, "nextToken", newJString(nextToken))
  add(query_613579, "MaxResults", newJString(MaxResults))
  add(query_613579, "NextToken", newJString(NextToken))
  add(path_613578, "InstanceId", newJString(InstanceId))
  add(query_613579, "maxResults", newJInt(maxResults))
  result = call_613577.call(path_613578, query_613579, nil, nil, nil)

var listUsers* = Call_ListUsers_613561(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "connect.amazonaws.com",
                                    route: "/users-summary/{InstanceId}",
                                    validator: validate_ListUsers_613562,
                                    base: "/", url: url_ListUsers_613563,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChatContact_613580 = ref object of OpenApiRestCall_612658
proc url_StartChatContact_613582(protocol: Scheme; host: string; base: string;
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

proc validate_StartChatContact_613581(path: JsonNode; query: JsonNode;
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
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613591: Call_StartChatContact_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ## 
  let valid = call_613591.validator(path, query, header, formData, body)
  let scheme = call_613591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613591.url(scheme.get, call_613591.host, call_613591.base,
                         call_613591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613591, url, valid)

proc call*(call_613592: Call_StartChatContact_613580; body: JsonNode): Recallable =
  ## startChatContact
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ##   body: JObject (required)
  var body_613593 = newJObject()
  if body != nil:
    body_613593 = body
  result = call_613592.call(nil, nil, nil, nil, body_613593)

var startChatContact* = Call_StartChatContact_613580(name: "startChatContact",
    meth: HttpMethod.HttpPut, host: "connect.amazonaws.com", route: "/contact/chat",
    validator: validate_StartChatContact_613581, base: "/",
    url: url_StartChatContact_613582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_613594 = ref object of OpenApiRestCall_612658
proc url_StartOutboundVoiceContact_613596(protocol: Scheme; host: string;
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

proc validate_StartOutboundVoiceContact_613595(path: JsonNode; query: JsonNode;
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
  var valid_613597 = header.getOrDefault("X-Amz-Signature")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Signature", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Content-Sha256", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Date")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Date", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Credential")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Credential", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Security-Token")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Security-Token", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Algorithm")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Algorithm", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-SignedHeaders", valid_613603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613605: Call_StartOutboundVoiceContact_613594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ## 
  let valid = call_613605.validator(path, query, header, formData, body)
  let scheme = call_613605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613605.url(scheme.get, call_613605.host, call_613605.base,
                         call_613605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613605, url, valid)

proc call*(call_613606: Call_StartOutboundVoiceContact_613594; body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   body: JObject (required)
  var body_613607 = newJObject()
  if body != nil:
    body_613607 = body
  result = call_613606.call(nil, nil, nil, nil, body_613607)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_613594(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_613595, base: "/",
    url: url_StartOutboundVoiceContact_613596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_613608 = ref object of OpenApiRestCall_612658
proc url_StopContact_613610(protocol: Scheme; host: string; base: string;
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

proc validate_StopContact_613609(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613611 = header.getOrDefault("X-Amz-Signature")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Signature", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Content-Sha256", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Date")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Date", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Credential")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Credential", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Security-Token")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Security-Token", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Algorithm")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Algorithm", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-SignedHeaders", valid_613617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613619: Call_StopContact_613608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ends the specified contact.
  ## 
  let valid = call_613619.validator(path, query, header, formData, body)
  let scheme = call_613619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613619.url(scheme.get, call_613619.host, call_613619.base,
                         call_613619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613619, url, valid)

proc call*(call_613620: Call_StopContact_613608; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_613621 = newJObject()
  if body != nil:
    body_613621 = body
  result = call_613620.call(nil, nil, nil, nil, body_613621)

var stopContact* = Call_StopContact_613608(name: "stopContact",
                                        meth: HttpMethod.HttpPost,
                                        host: "connect.amazonaws.com",
                                        route: "/contact/stop",
                                        validator: validate_StopContact_613609,
                                        base: "/", url: url_StopContact_613610,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613622 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613624(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613625 = path.getOrDefault("resourceArn")
  valid_613625 = validateParameter(valid_613625, JString, required = true,
                                 default = nil)
  if valid_613625 != nil:
    section.add "resourceArn", valid_613625
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613626 = query.getOrDefault("tagKeys")
  valid_613626 = validateParameter(valid_613626, JArray, required = true, default = nil)
  if valid_613626 != nil:
    section.add "tagKeys", valid_613626
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
  var valid_613627 = header.getOrDefault("X-Amz-Signature")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Signature", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Content-Sha256", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Date")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Date", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Credential")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Credential", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Security-Token")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Security-Token", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Algorithm")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Algorithm", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-SignedHeaders", valid_613633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613634: Call_UntagResource_613622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from the specified resource.
  ## 
  let valid = call_613634.validator(path, query, header, formData, body)
  let scheme = call_613634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613634.url(scheme.get, call_613634.host, call_613634.base,
                         call_613634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613634, url, valid)

proc call*(call_613635: Call_UntagResource_613622; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys.
  var path_613636 = newJObject()
  var query_613637 = newJObject()
  add(path_613636, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613637.add "tagKeys", tagKeys
  result = call_613635.call(path_613636, query_613637, nil, nil, nil)

var untagResource* = Call_UntagResource_613622(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613623,
    base: "/", url: url_UntagResource_613624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_613638 = ref object of OpenApiRestCall_612658
proc url_UpdateContactAttributes_613640(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContactAttributes_613639(path: JsonNode; query: JsonNode;
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
  var valid_613641 = header.getOrDefault("X-Amz-Signature")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Signature", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Content-Sha256", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Date")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Date", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Credential")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Credential", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Security-Token")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Security-Token", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Algorithm")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Algorithm", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-SignedHeaders", valid_613647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613649: Call_UpdateContactAttributes_613638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ## 
  let valid = call_613649.validator(path, query, header, formData, body)
  let scheme = call_613649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613649.url(scheme.get, call_613649.host, call_613649.base,
                         call_613649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613649, url, valid)

proc call*(call_613650: Call_UpdateContactAttributes_613638; body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   body: JObject (required)
  var body_613651 = newJObject()
  if body != nil:
    body_613651 = body
  result = call_613650.call(nil, nil, nil, nil, body_613651)

var updateContactAttributes* = Call_UpdateContactAttributes_613638(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_613639, base: "/",
    url: url_UpdateContactAttributes_613640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_613652 = ref object of OpenApiRestCall_612658
proc url_UpdateUserHierarchy_613654(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserHierarchy_613653(path: JsonNode; query: JsonNode;
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
  var valid_613655 = path.getOrDefault("UserId")
  valid_613655 = validateParameter(valid_613655, JString, required = true,
                                 default = nil)
  if valid_613655 != nil:
    section.add "UserId", valid_613655
  var valid_613656 = path.getOrDefault("InstanceId")
  valid_613656 = validateParameter(valid_613656, JString, required = true,
                                 default = nil)
  if valid_613656 != nil:
    section.add "InstanceId", valid_613656
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
  var valid_613657 = header.getOrDefault("X-Amz-Signature")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Signature", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Content-Sha256", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Date")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Date", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Credential")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Credential", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Security-Token")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Security-Token", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Algorithm")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Algorithm", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-SignedHeaders", valid_613663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613665: Call_UpdateUserHierarchy_613652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
  ## 
  let valid = call_613665.validator(path, query, header, formData, body)
  let scheme = call_613665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613665.url(scheme.get, call_613665.host, call_613665.base,
                         call_613665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613665, url, valid)

proc call*(call_613666: Call_UpdateUserHierarchy_613652; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613667 = newJObject()
  var body_613668 = newJObject()
  add(path_613667, "UserId", newJString(UserId))
  if body != nil:
    body_613668 = body
  add(path_613667, "InstanceId", newJString(InstanceId))
  result = call_613666.call(path_613667, nil, nil, nil, body_613668)

var updateUserHierarchy* = Call_UpdateUserHierarchy_613652(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_613653, base: "/",
    url: url_UpdateUserHierarchy_613654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_613669 = ref object of OpenApiRestCall_612658
proc url_UpdateUserIdentityInfo_613671(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserIdentityInfo_613670(path: JsonNode; query: JsonNode;
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
  var valid_613672 = path.getOrDefault("UserId")
  valid_613672 = validateParameter(valid_613672, JString, required = true,
                                 default = nil)
  if valid_613672 != nil:
    section.add "UserId", valid_613672
  var valid_613673 = path.getOrDefault("InstanceId")
  valid_613673 = validateParameter(valid_613673, JString, required = true,
                                 default = nil)
  if valid_613673 != nil:
    section.add "InstanceId", valid_613673
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
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_UpdateUserIdentityInfo_613669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the identity information for the specified user.
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_UpdateUserIdentityInfo_613669; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613684 = newJObject()
  var body_613685 = newJObject()
  add(path_613684, "UserId", newJString(UserId))
  if body != nil:
    body_613685 = body
  add(path_613684, "InstanceId", newJString(InstanceId))
  result = call_613683.call(path_613684, nil, nil, nil, body_613685)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_613669(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_613670, base: "/",
    url: url_UpdateUserIdentityInfo_613671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_613686 = ref object of OpenApiRestCall_612658
proc url_UpdateUserPhoneConfig_613688(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserPhoneConfig_613687(path: JsonNode; query: JsonNode;
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
  var valid_613689 = path.getOrDefault("UserId")
  valid_613689 = validateParameter(valid_613689, JString, required = true,
                                 default = nil)
  if valid_613689 != nil:
    section.add "UserId", valid_613689
  var valid_613690 = path.getOrDefault("InstanceId")
  valid_613690 = validateParameter(valid_613690, JString, required = true,
                                 default = nil)
  if valid_613690 != nil:
    section.add "InstanceId", valid_613690
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
  var valid_613691 = header.getOrDefault("X-Amz-Signature")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Signature", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Content-Sha256", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Date")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Date", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Credential")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Credential", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Security-Token")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Security-Token", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Algorithm")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Algorithm", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-SignedHeaders", valid_613697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613699: Call_UpdateUserPhoneConfig_613686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the phone configuration settings for the specified user.
  ## 
  let valid = call_613699.validator(path, query, header, formData, body)
  let scheme = call_613699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613699.url(scheme.get, call_613699.host, call_613699.base,
                         call_613699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613699, url, valid)

proc call*(call_613700: Call_UpdateUserPhoneConfig_613686; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613701 = newJObject()
  var body_613702 = newJObject()
  add(path_613701, "UserId", newJString(UserId))
  if body != nil:
    body_613702 = body
  add(path_613701, "InstanceId", newJString(InstanceId))
  result = call_613700.call(path_613701, nil, nil, nil, body_613702)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_613686(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_613687, base: "/",
    url: url_UpdateUserPhoneConfig_613688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_613703 = ref object of OpenApiRestCall_612658
proc url_UpdateUserRoutingProfile_613705(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_613704(path: JsonNode; query: JsonNode;
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
  var valid_613706 = path.getOrDefault("UserId")
  valid_613706 = validateParameter(valid_613706, JString, required = true,
                                 default = nil)
  if valid_613706 != nil:
    section.add "UserId", valid_613706
  var valid_613707 = path.getOrDefault("InstanceId")
  valid_613707 = validateParameter(valid_613707, JString, required = true,
                                 default = nil)
  if valid_613707 != nil:
    section.add "InstanceId", valid_613707
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
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_UpdateUserRoutingProfile_613703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified routing profile to the specified user.
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_UpdateUserRoutingProfile_613703; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613718 = newJObject()
  var body_613719 = newJObject()
  add(path_613718, "UserId", newJString(UserId))
  if body != nil:
    body_613719 = body
  add(path_613718, "InstanceId", newJString(InstanceId))
  result = call_613717.call(path_613718, nil, nil, nil, body_613719)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_613703(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_613704, base: "/",
    url: url_UpdateUserRoutingProfile_613705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_613720 = ref object of OpenApiRestCall_612658
proc url_UpdateUserSecurityProfiles_613722(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_613721(path: JsonNode; query: JsonNode;
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
  var valid_613723 = path.getOrDefault("UserId")
  valid_613723 = validateParameter(valid_613723, JString, required = true,
                                 default = nil)
  if valid_613723 != nil:
    section.add "UserId", valid_613723
  var valid_613724 = path.getOrDefault("InstanceId")
  valid_613724 = validateParameter(valid_613724, JString, required = true,
                                 default = nil)
  if valid_613724 != nil:
    section.add "InstanceId", valid_613724
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
  var valid_613725 = header.getOrDefault("X-Amz-Signature")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Signature", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Content-Sha256", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Date")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Date", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Credential")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Credential", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Security-Token")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Security-Token", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Algorithm")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Algorithm", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-SignedHeaders", valid_613731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613733: Call_UpdateUserSecurityProfiles_613720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns the specified security profiles to the specified user.
  ## 
  let valid = call_613733.validator(path, query, header, formData, body)
  let scheme = call_613733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613733.url(scheme.get, call_613733.host, call_613733.base,
                         call_613733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613733, url, valid)

proc call*(call_613734: Call_UpdateUserSecurityProfiles_613720; UserId: string;
          body: JsonNode; InstanceId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   UserId: string (required)
  ##         : The identifier of the user account.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
  ##             : The identifier of the Amazon Connect instance.
  var path_613735 = newJObject()
  var body_613736 = newJObject()
  add(path_613735, "UserId", newJString(UserId))
  if body != nil:
    body_613736 = body
  add(path_613735, "InstanceId", newJString(InstanceId))
  result = call_613734.call(path_613735, nil, nil, nil, body_613736)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_613720(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_613721, base: "/",
    url: url_UpdateUserSecurityProfiles_613722,
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
