
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "connect.ap-southeast-1.amazonaws.com",
                               "us-west-2": "connect.us-west-2.amazonaws.com",
                               "eu-west-2": "connect.eu-west-2.amazonaws.com", "ap-northeast-3": "connect.ap-northeast-3.amazonaws.com", "eu-central-1": "connect.eu-central-1.amazonaws.com",
                               "us-east-2": "connect.us-east-2.amazonaws.com",
                               "us-east-1": "connect.us-east-1.amazonaws.com", "cn-northwest-1": "connect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "connect.ap-south-1.amazonaws.com", "eu-north-1": "connect.eu-north-1.amazonaws.com", "ap-northeast-2": "connect.ap-northeast-2.amazonaws.com",
                               "us-west-1": "connect.us-west-1.amazonaws.com", "us-gov-east-1": "connect.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "connect.eu-west-3.amazonaws.com", "cn-north-1": "connect.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "connect.sa-east-1.amazonaws.com",
                               "eu-west-1": "connect.eu-west-1.amazonaws.com", "us-gov-west-1": "connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "connect.ap-southeast-2.amazonaws.com", "ca-central-1": "connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateUser_402656294 = ref object of OpenApiRestCall_402656044
proc url_CreateUser_402656296(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUser_402656295(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656389 = path.getOrDefault("InstanceId")
  valid_402656389 = validateParameter(valid_402656389, JString, required = true,
                                      default = nil)
  if valid_402656389 != nil:
    section.add "InstanceId", valid_402656389
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Security-Token", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Signature")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Signature", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Algorithm", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Date")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Date", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Credential")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Credential", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656396
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

proc call*(call_402656411: Call_CreateUser_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user account for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656411.validator(path, query, header, formData, body, _)
  let scheme = call_402656411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656411.makeUrl(scheme.get, call_402656411.host, call_402656411.base,
                                   call_402656411.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656411, uri, valid, _)

proc call*(call_402656460: Call_CreateUser_402656294; body: JsonNode;
           InstanceId: string): Recallable =
  ## createUser
  ## Creates a user account for the specified Amazon Connect instance.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  var path_402656461 = newJObject()
  var body_402656463 = newJObject()
  if body != nil:
    body_402656463 = body
  add(path_402656461, "InstanceId", newJString(InstanceId))
  result = call_402656460.call(path_402656461, nil, nil, nil, body_402656463)

var createUser* = Call_CreateUser_402656294(name: "createUser",
    meth: HttpMethod.HttpPut, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}", validator: validate_CreateUser_402656295,
    base: "/", makeUrl: url_CreateUser_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_402656489 = ref object of OpenApiRestCall_402656044
proc url_DescribeUser_402656491(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_402656490(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656492 = path.getOrDefault("InstanceId")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true,
                                      default = nil)
  if valid_402656492 != nil:
    section.add "InstanceId", valid_402656492
  var valid_402656493 = path.getOrDefault("UserId")
  valid_402656493 = validateParameter(valid_402656493, JString, required = true,
                                      default = nil)
  if valid_402656493 != nil:
    section.add "UserId", valid_402656493
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656494 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Security-Token", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Signature")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Signature", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Algorithm", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Date")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Date", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Credential")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Credential", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_DescribeUser_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_DescribeUser_402656489; InstanceId: string;
           UserId: string): Recallable =
  ## describeUser
  ## Describes the specified user account. You can find the instance ID in the console (it’s the final part of the ARN). The console does not display the user IDs. Instead, list the users and note the IDs provided in the output.
  ##   
                                                                                                                                                                                                                                      ## InstanceId: string (required)
                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                      ## identifier 
                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                      ## Connect 
                                                                                                                                                                                                                                      ## instance.
  ##   
                                                                                                                                                                                                                                                  ## UserId: string (required)
                                                                                                                                                                                                                                                  ##         
                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                  ## identifier 
                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                  ## user 
                                                                                                                                                                                                                                                  ## account.
  var path_402656503 = newJObject()
  add(path_402656503, "InstanceId", newJString(InstanceId))
  add(path_402656503, "UserId", newJString(UserId))
  result = call_402656502.call(path_402656503, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_402656489(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DescribeUser_402656490,
    base: "/", makeUrl: url_DescribeUser_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402656504 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402656506(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUser_402656505(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a user account from the specified Amazon Connect instance.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656507 = path.getOrDefault("InstanceId")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true,
                                      default = nil)
  if valid_402656507 != nil:
    section.add "InstanceId", valid_402656507
  var valid_402656508 = path.getOrDefault("UserId")
  valid_402656508 = validateParameter(valid_402656508, JString, required = true,
                                      default = nil)
  if valid_402656508 != nil:
    section.add "UserId", valid_402656508
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_DeleteUser_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a user account from the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_DeleteUser_402656504; InstanceId: string;
           UserId: string): Recallable =
  ## deleteUser
  ## Deletes a user account from the specified Amazon Connect instance.
  ##   
                                                                       ## InstanceId: string (required)
                                                                       ##             
                                                                       ## : 
                                                                       ## The 
                                                                       ## identifier of 
                                                                       ## the 
                                                                       ## Amazon 
                                                                       ## Connect 
                                                                       ## instance.
  ##   
                                                                                   ## UserId: string (required)
                                                                                   ##         
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## identifier 
                                                                                   ## of 
                                                                                   ## the 
                                                                                   ## user.
  var path_402656518 = newJObject()
  add(path_402656518, "InstanceId", newJString(InstanceId))
  add(path_402656518, "UserId", newJString(UserId))
  result = call_402656517.call(path_402656518, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_402656504(name: "deleteUser",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}", validator: validate_DeleteUser_402656505,
    base: "/", makeUrl: url_DeleteUser_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyGroup_402656519 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserHierarchyGroup_402656521(protocol: Scheme; host: string;
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

proc validate_DescribeUserHierarchyGroup_402656520(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the specified hierarchy group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HierarchyGroupId: JString (required)
                                 ##                   : The identifier of the hierarchy group.
  ##   
                                                                                              ## InstanceId: JString (required)
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## Amazon 
                                                                                              ## Connect 
                                                                                              ## instance.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `HierarchyGroupId` field"
  var valid_402656522 = path.getOrDefault("HierarchyGroupId")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true,
                                      default = nil)
  if valid_402656522 != nil:
    section.add "HierarchyGroupId", valid_402656522
  var valid_402656523 = path.getOrDefault("InstanceId")
  valid_402656523 = validateParameter(valid_402656523, JString, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "InstanceId", valid_402656523
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Security-Token", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Signature")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Signature", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Algorithm", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Date")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Date", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Credential")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Credential", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_DescribeUserHierarchyGroup_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified hierarchy group.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_DescribeUserHierarchyGroup_402656519;
           HierarchyGroupId: string; InstanceId: string): Recallable =
  ## describeUserHierarchyGroup
  ## Describes the specified hierarchy group.
  ##   HierarchyGroupId: string (required)
                                             ##                   : The identifier of the hierarchy group.
  ##   
                                                                                                          ## InstanceId: string (required)
                                                                                                          ##             
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## identifier 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## Amazon 
                                                                                                          ## Connect 
                                                                                                          ## instance.
  var path_402656533 = newJObject()
  add(path_402656533, "HierarchyGroupId", newJString(HierarchyGroupId))
  add(path_402656533, "InstanceId", newJString(InstanceId))
  result = call_402656532.call(path_402656533, nil, nil, nil, nil)

var describeUserHierarchyGroup* = Call_DescribeUserHierarchyGroup_402656519(
    name: "describeUserHierarchyGroup", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups/{InstanceId}/{HierarchyGroupId}",
    validator: validate_DescribeUserHierarchyGroup_402656520, base: "/",
    makeUrl: url_DescribeUserHierarchyGroup_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserHierarchyStructure_402656534 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserHierarchyStructure_402656536(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeUserHierarchyStructure_402656535(path: JsonNode;
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
  var valid_402656537 = path.getOrDefault("InstanceId")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true,
                                      default = nil)
  if valid_402656537 != nil:
    section.add "InstanceId", valid_402656537
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656545: Call_DescribeUserHierarchyStructure_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656545.validator(path, query, header, formData, body, _)
  let scheme = call_402656545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656545.makeUrl(scheme.get, call_402656545.host, call_402656545.base,
                                   call_402656545.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656545, uri, valid, _)

proc call*(call_402656546: Call_DescribeUserHierarchyStructure_402656534;
           InstanceId: string): Recallable =
  ## describeUserHierarchyStructure
  ## Describes the hierarchy structure of the specified Amazon Connect instance.
  ##   
                                                                                ## InstanceId: string (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## identifier 
                                                                                ## of 
                                                                                ## the 
                                                                                ## Amazon 
                                                                                ## Connect 
                                                                                ## instance.
  var path_402656547 = newJObject()
  add(path_402656547, "InstanceId", newJString(InstanceId))
  result = call_402656546.call(path_402656547, nil, nil, nil, nil)

var describeUserHierarchyStructure* = Call_DescribeUserHierarchyStructure_402656534(
    name: "describeUserHierarchyStructure", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-structure/{InstanceId}",
    validator: validate_DescribeUserHierarchyStructure_402656535, base: "/",
    makeUrl: url_DescribeUserHierarchyStructure_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactAttributes_402656548 = ref object of OpenApiRestCall_402656044
proc url_GetContactAttributes_402656550(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetContactAttributes_402656549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the contact attributes for the specified contact.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## InitialContactId: JString (required)
                                                                                                ##                   
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## initial 
                                                                                                ## contact.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656551 = path.getOrDefault("InstanceId")
  valid_402656551 = validateParameter(valid_402656551, JString, required = true,
                                      default = nil)
  if valid_402656551 != nil:
    section.add "InstanceId", valid_402656551
  var valid_402656552 = path.getOrDefault("InitialContactId")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true,
                                      default = nil)
  if valid_402656552 != nil:
    section.add "InitialContactId", valid_402656552
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656560: Call_GetContactAttributes_402656548;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the contact attributes for the specified contact.
                                                                                         ## 
  let valid = call_402656560.validator(path, query, header, formData, body, _)
  let scheme = call_402656560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656560.makeUrl(scheme.get, call_402656560.host, call_402656560.base,
                                   call_402656560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656560, uri, valid, _)

proc call*(call_402656561: Call_GetContactAttributes_402656548;
           InstanceId: string; InitialContactId: string): Recallable =
  ## getContactAttributes
  ## Retrieves the contact attributes for the specified contact.
  ##   InstanceId: string (required)
                                                                ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                                               ## InitialContactId: string (required)
                                                                                                                               ##                   
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## identifier 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## initial 
                                                                                                                               ## contact.
  var path_402656562 = newJObject()
  add(path_402656562, "InstanceId", newJString(InstanceId))
  add(path_402656562, "InitialContactId", newJString(InitialContactId))
  result = call_402656561.call(path_402656562, nil, nil, nil, nil)

var getContactAttributes* = Call_GetContactAttributes_402656548(
    name: "getContactAttributes", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/contact/attributes/{InstanceId}/{InitialContactId}",
    validator: validate_GetContactAttributes_402656549, base: "/",
    makeUrl: url_GetContactAttributes_402656550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCurrentMetricData_402656563 = ref object of OpenApiRestCall_402656044
proc url_GetCurrentMetricData_402656565(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetCurrentMetricData_402656564(path: JsonNode; query: JsonNode;
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
  var valid_402656566 = path.getOrDefault("InstanceId")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "InstanceId", valid_402656566
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656567 = query.getOrDefault("MaxResults")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "MaxResults", valid_402656567
  var valid_402656568 = query.getOrDefault("NextToken")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "NextToken", valid_402656568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656569 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Security-Token", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Signature")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Signature", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Algorithm", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Date")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Date", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Credential")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Credential", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656575
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

proc call*(call_402656577: Call_GetCurrentMetricData_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656577.validator(path, query, header, formData, body, _)
  let scheme = call_402656577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656577.makeUrl(scheme.get, call_402656577.host, call_402656577.base,
                                   call_402656577.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656577, uri, valid, _)

proc call*(call_402656578: Call_GetCurrentMetricData_402656563; body: JsonNode;
           InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCurrentMetricData
  ## <p>Gets the real-time metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html">Real-time Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                         ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                 ## InstanceId: string (required)
                                                                                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                                                 ## identifier 
                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                                                                                                                                                                                 ## Connect 
                                                                                                                                                                                                                                                                                                                                                 ## instance.
  var path_402656579 = newJObject()
  var query_402656580 = newJObject()
  var body_402656581 = newJObject()
  add(query_402656580, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656581 = body
  add(query_402656580, "NextToken", newJString(NextToken))
  add(path_402656579, "InstanceId", newJString(InstanceId))
  result = call_402656578.call(path_402656579, query_402656580, nil, nil, body_402656581)

var getCurrentMetricData* = Call_GetCurrentMetricData_402656563(
    name: "getCurrentMetricData", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/metrics/current/{InstanceId}",
    validator: validate_GetCurrentMetricData_402656564, base: "/",
    makeUrl: url_GetCurrentMetricData_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFederationToken_402656582 = ref object of OpenApiRestCall_402656044
proc url_GetFederationToken_402656584(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetFederationToken_402656583(path: JsonNode; query: JsonNode;
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
  var valid_402656585 = path.getOrDefault("InstanceId")
  valid_402656585 = validateParameter(valid_402656585, JString, required = true,
                                      default = nil)
  if valid_402656585 != nil:
    section.add "InstanceId", valid_402656585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656586 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Security-Token", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Signature")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Signature", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Algorithm", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Date")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Date", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Credential")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Credential", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656593: Call_GetFederationToken_402656582;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a token for federation.
                                                                                         ## 
  let valid = call_402656593.validator(path, query, header, formData, body, _)
  let scheme = call_402656593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656593.makeUrl(scheme.get, call_402656593.host, call_402656593.base,
                                   call_402656593.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656593, uri, valid, _)

proc call*(call_402656594: Call_GetFederationToken_402656582; InstanceId: string): Recallable =
  ## getFederationToken
  ## Retrieves a token for federation.
  ##   InstanceId: string (required)
                                      ##             : The identifier of the Amazon Connect instance.
  var path_402656595 = newJObject()
  add(path_402656595, "InstanceId", newJString(InstanceId))
  result = call_402656594.call(path_402656595, nil, nil, nil, nil)

var getFederationToken* = Call_GetFederationToken_402656582(
    name: "getFederationToken", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/user/federate/{InstanceId}",
    validator: validate_GetFederationToken_402656583, base: "/",
    makeUrl: url_GetFederationToken_402656584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMetricData_402656596 = ref object of OpenApiRestCall_402656044
proc url_GetMetricData_402656598(protocol: Scheme; host: string; base: string;
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

proc validate_GetMetricData_402656597(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656599 = path.getOrDefault("InstanceId")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true,
                                      default = nil)
  if valid_402656599 != nil:
    section.add "InstanceId", valid_402656599
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656600 = query.getOrDefault("MaxResults")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "MaxResults", valid_402656600
  var valid_402656601 = query.getOrDefault("NextToken")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "NextToken", valid_402656601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656602 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Security-Token", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Signature")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Signature", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Algorithm", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Date")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Date", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Credential")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Credential", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656608
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

proc call*(call_402656610: Call_GetMetricData_402656596; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656610.validator(path, query, header, formData, body, _)
  let scheme = call_402656610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656610.makeUrl(scheme.get, call_402656610.host, call_402656610.base,
                                   call_402656610.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656610, uri, valid, _)

proc call*(call_402656611: Call_GetMetricData_402656596; body: JsonNode;
           InstanceId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMetricData
  ## <p>Gets historical metric data from the specified Amazon Connect instance.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/connect/latest/adminguide/historical-metrics.html">Historical Metrics Reports</a> in the <i>Amazon Connect Administrator Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                ## token
  ##   
                                                                                                                                                                                                                                                                                                                                        ## InstanceId: string (required)
                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                        ## identifier 
                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                                                                                                                                                                        ## Connect 
                                                                                                                                                                                                                                                                                                                                        ## instance.
  var path_402656612 = newJObject()
  var query_402656613 = newJObject()
  var body_402656614 = newJObject()
  add(query_402656613, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656614 = body
  add(query_402656613, "NextToken", newJString(NextToken))
  add(path_402656612, "InstanceId", newJString(InstanceId))
  result = call_402656611.call(path_402656612, query_402656613, nil, nil, body_402656614)

var getMetricData* = Call_GetMetricData_402656596(name: "getMetricData",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/metrics/historical/{InstanceId}",
    validator: validate_GetMetricData_402656597, base: "/",
    makeUrl: url_GetMetricData_402656598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContactFlows_402656615 = ref object of OpenApiRestCall_402656044
proc url_ListContactFlows_402656617(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_ListContactFlows_402656616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656618 = path.getOrDefault("InstanceId")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "InstanceId", valid_402656618
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  ##   
                                                                                                                                 ## contactFlowTypes: JArray
                                                                                                                                 ##                   
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## type 
                                                                                                                                 ## of 
                                                                                                                                 ## contact 
                                                                                                                                 ## flow.
  section = newJObject()
  var valid_402656619 = query.getOrDefault("maxResults")
  valid_402656619 = validateParameter(valid_402656619, JInt, required = false,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "maxResults", valid_402656619
  var valid_402656620 = query.getOrDefault("nextToken")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "nextToken", valid_402656620
  var valid_402656621 = query.getOrDefault("MaxResults")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "MaxResults", valid_402656621
  var valid_402656622 = query.getOrDefault("NextToken")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "NextToken", valid_402656622
  var valid_402656623 = query.getOrDefault("contactFlowTypes")
  valid_402656623 = validateParameter(valid_402656623, JArray, required = false,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "contactFlowTypes", valid_402656623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656624 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Security-Token", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Signature")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Signature", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Algorithm", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Date")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Date", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Credential")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Credential", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656631: Call_ListContactFlows_402656615;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the contact flows for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656631.validator(path, query, header, formData, body, _)
  let scheme = call_402656631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656631.makeUrl(scheme.get, call_402656631.host, call_402656631.base,
                                   call_402656631.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656631, uri, valid, _)

proc call*(call_402656632: Call_ListContactFlows_402656615; InstanceId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; contactFlowTypes: JsonNode = nil): Recallable =
  ## listContactFlows
  ## Provides information about the contact flows for the specified Amazon Connect instance.
  ##   
                                                                                            ## maxResults: int
                                                                                            ##             
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## maximimum 
                                                                                            ## number 
                                                                                            ## of 
                                                                                            ## results 
                                                                                            ## to 
                                                                                            ## return 
                                                                                            ## per 
                                                                                            ## page.
  ##   
                                                                                                    ## nextToken: string
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## token 
                                                                                                    ## for 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results. 
                                                                                                    ## Use 
                                                                                                    ## the 
                                                                                                    ## value 
                                                                                                    ## returned 
                                                                                                    ## in 
                                                                                                    ## the 
                                                                                                    ## previous 
                                                                                                    ## response 
                                                                                                    ## in 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## request 
                                                                                                    ## to 
                                                                                                    ## retrieve 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results.
  ##   
                                                                                                               ## MaxResults: string
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## limit
  ##   
                                                                                                                       ## NextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## Pagination 
                                                                                                                       ## token
  ##   
                                                                                                                               ## InstanceId: string (required)
                                                                                                                               ##             
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## identifier 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## Amazon 
                                                                                                                               ## Connect 
                                                                                                                               ## instance.
  ##   
                                                                                                                                           ## contactFlowTypes: JArray
                                                                                                                                           ##                   
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## type 
                                                                                                                                           ## of 
                                                                                                                                           ## contact 
                                                                                                                                           ## flow.
  var path_402656633 = newJObject()
  var query_402656634 = newJObject()
  add(query_402656634, "maxResults", newJInt(maxResults))
  add(query_402656634, "nextToken", newJString(nextToken))
  add(query_402656634, "MaxResults", newJString(MaxResults))
  add(query_402656634, "NextToken", newJString(NextToken))
  add(path_402656633, "InstanceId", newJString(InstanceId))
  if contactFlowTypes != nil:
    query_402656634.add "contactFlowTypes", contactFlowTypes
  result = call_402656632.call(path_402656633, query_402656634, nil, nil, nil)

var listContactFlows* = Call_ListContactFlows_402656615(
    name: "listContactFlows", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/contact-flows-summary/{InstanceId}",
    validator: validate_ListContactFlows_402656616, base: "/",
    makeUrl: url_ListContactFlows_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHoursOfOperations_402656635 = ref object of OpenApiRestCall_402656044
proc url_ListHoursOfOperations_402656637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListHoursOfOperations_402656636(path: JsonNode; query: JsonNode;
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
  var valid_402656638 = path.getOrDefault("InstanceId")
  valid_402656638 = validateParameter(valid_402656638, JString, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "InstanceId", valid_402656638
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  section = newJObject()
  var valid_402656639 = query.getOrDefault("maxResults")
  valid_402656639 = validateParameter(valid_402656639, JInt, required = false,
                                      default = nil)
  if valid_402656639 != nil:
    section.add "maxResults", valid_402656639
  var valid_402656640 = query.getOrDefault("nextToken")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "nextToken", valid_402656640
  var valid_402656641 = query.getOrDefault("MaxResults")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "MaxResults", valid_402656641
  var valid_402656642 = query.getOrDefault("NextToken")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "NextToken", valid_402656642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656650: Call_ListHoursOfOperations_402656635;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_ListHoursOfOperations_402656635;
           InstanceId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHoursOfOperations
  ## Provides information about the hours of operation for the specified Amazon Connect instance.
  ##   
                                                                                                 ## maxResults: int
                                                                                                 ##             
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## maximimum 
                                                                                                 ## number 
                                                                                                 ## of 
                                                                                                 ## results 
                                                                                                 ## to 
                                                                                                 ## return 
                                                                                                 ## per 
                                                                                                 ## page.
  ##   
                                                                                                         ## nextToken: string
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## token 
                                                                                                         ## for 
                                                                                                         ## the 
                                                                                                         ## next 
                                                                                                         ## set 
                                                                                                         ## of 
                                                                                                         ## results. 
                                                                                                         ## Use 
                                                                                                         ## the 
                                                                                                         ## value 
                                                                                                         ## returned 
                                                                                                         ## in 
                                                                                                         ## the 
                                                                                                         ## previous 
                                                                                                         ## response 
                                                                                                         ## in 
                                                                                                         ## the 
                                                                                                         ## next 
                                                                                                         ## request 
                                                                                                         ## to 
                                                                                                         ## retrieve 
                                                                                                         ## the 
                                                                                                         ## next 
                                                                                                         ## set 
                                                                                                         ## of 
                                                                                                         ## results.
  ##   
                                                                                                                    ## MaxResults: string
                                                                                                                    ##             
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## limit
  ##   
                                                                                                                            ## NextToken: string
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## Pagination 
                                                                                                                            ## token
  ##   
                                                                                                                                    ## InstanceId: string (required)
                                                                                                                                    ##             
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## identifier 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## Amazon 
                                                                                                                                    ## Connect 
                                                                                                                                    ## instance.
  var path_402656652 = newJObject()
  var query_402656653 = newJObject()
  add(query_402656653, "maxResults", newJInt(maxResults))
  add(query_402656653, "nextToken", newJString(nextToken))
  add(query_402656653, "MaxResults", newJString(MaxResults))
  add(query_402656653, "NextToken", newJString(NextToken))
  add(path_402656652, "InstanceId", newJString(InstanceId))
  result = call_402656651.call(path_402656652, query_402656653, nil, nil, nil)

var listHoursOfOperations* = Call_ListHoursOfOperations_402656635(
    name: "listHoursOfOperations", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/hours-of-operations-summary/{InstanceId}",
    validator: validate_ListHoursOfOperations_402656636, base: "/",
    makeUrl: url_ListHoursOfOperations_402656637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPhoneNumbers_402656654 = ref object of OpenApiRestCall_402656044
proc url_ListPhoneNumbers_402656656(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
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

proc validate_ListPhoneNumbers_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656657 = path.getOrDefault("InstanceId")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "InstanceId", valid_402656657
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumberTypes: JArray
                                  ##                   : The type of phone number.
  ##   
                                                                                  ## maxResults: JInt
                                                                                  ##             
                                                                                  ## : 
                                                                                  ## The 
                                                                                  ## maximimum 
                                                                                  ## number 
                                                                                  ## of 
                                                                                  ## results 
                                                                                  ## to 
                                                                                  ## return 
                                                                                  ## per 
                                                                                  ## page.
  ##   
                                                                                          ## nextToken: JString
                                                                                          ##            
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## token 
                                                                                          ## for 
                                                                                          ## the 
                                                                                          ## next 
                                                                                          ## set 
                                                                                          ## of 
                                                                                          ## results. 
                                                                                          ## Use 
                                                                                          ## the 
                                                                                          ## value 
                                                                                          ## returned 
                                                                                          ## in 
                                                                                          ## the 
                                                                                          ## previous 
                                                                                          ## response 
                                                                                          ## in 
                                                                                          ## the 
                                                                                          ## next 
                                                                                          ## request 
                                                                                          ## to 
                                                                                          ## retrieve 
                                                                                          ## the 
                                                                                          ## next 
                                                                                          ## set 
                                                                                          ## of 
                                                                                          ## results.
  ##   
                                                                                                     ## MaxResults: JString
                                                                                                     ##             
                                                                                                     ## : 
                                                                                                     ## Pagination 
                                                                                                     ## limit
  ##   
                                                                                                             ## NextToken: JString
                                                                                                             ##            
                                                                                                             ## : 
                                                                                                             ## Pagination 
                                                                                                             ## token
  ##   
                                                                                                                     ## phoneNumberCountryCodes: JArray
                                                                                                                     ##                          
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## ISO 
                                                                                                                     ## country 
                                                                                                                     ## code.
  section = newJObject()
  var valid_402656658 = query.getOrDefault("phoneNumberTypes")
  valid_402656658 = validateParameter(valid_402656658, JArray, required = false,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "phoneNumberTypes", valid_402656658
  var valid_402656659 = query.getOrDefault("maxResults")
  valid_402656659 = validateParameter(valid_402656659, JInt, required = false,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "maxResults", valid_402656659
  var valid_402656660 = query.getOrDefault("nextToken")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "nextToken", valid_402656660
  var valid_402656661 = query.getOrDefault("MaxResults")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "MaxResults", valid_402656661
  var valid_402656662 = query.getOrDefault("NextToken")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "NextToken", valid_402656662
  var valid_402656663 = query.getOrDefault("phoneNumberCountryCodes")
  valid_402656663 = validateParameter(valid_402656663, JArray, required = false,
                                      default = nil)
  if valid_402656663 != nil:
    section.add "phoneNumberCountryCodes", valid_402656663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656664 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Security-Token", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Signature")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Signature", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Algorithm", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Date")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Date", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Credential")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Credential", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656671: Call_ListPhoneNumbers_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656671.validator(path, query, header, formData, body, _)
  let scheme = call_402656671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656671.makeUrl(scheme.get, call_402656671.host, call_402656671.base,
                                   call_402656671.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656671, uri, valid, _)

proc call*(call_402656672: Call_ListPhoneNumbers_402656654; InstanceId: string;
           phoneNumberTypes: JsonNode = nil; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; phoneNumberCountryCodes: JsonNode = nil): Recallable =
  ## listPhoneNumbers
  ## Provides information about the phone numbers for the specified Amazon Connect instance.
  ##   
                                                                                            ## phoneNumberTypes: JArray
                                                                                            ##                   
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## type 
                                                                                            ## of 
                                                                                            ## phone 
                                                                                            ## number.
  ##   
                                                                                                      ## maxResults: int
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## maximimum 
                                                                                                      ## number 
                                                                                                      ## of 
                                                                                                      ## results 
                                                                                                      ## to 
                                                                                                      ## return 
                                                                                                      ## per 
                                                                                                      ## page.
  ##   
                                                                                                              ## nextToken: string
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## token 
                                                                                                              ## for 
                                                                                                              ## the 
                                                                                                              ## next 
                                                                                                              ## set 
                                                                                                              ## of 
                                                                                                              ## results. 
                                                                                                              ## Use 
                                                                                                              ## the 
                                                                                                              ## value 
                                                                                                              ## returned 
                                                                                                              ## in 
                                                                                                              ## the 
                                                                                                              ## previous 
                                                                                                              ## response 
                                                                                                              ## in 
                                                                                                              ## the 
                                                                                                              ## next 
                                                                                                              ## request 
                                                                                                              ## to 
                                                                                                              ## retrieve 
                                                                                                              ## the 
                                                                                                              ## next 
                                                                                                              ## set 
                                                                                                              ## of 
                                                                                                              ## results.
  ##   
                                                                                                                         ## MaxResults: string
                                                                                                                         ##             
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## limit
  ##   
                                                                                                                                 ## NextToken: string
                                                                                                                                 ##            
                                                                                                                                 ## : 
                                                                                                                                 ## Pagination 
                                                                                                                                 ## token
  ##   
                                                                                                                                         ## InstanceId: string (required)
                                                                                                                                         ##             
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## identifier 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## Amazon 
                                                                                                                                         ## Connect 
                                                                                                                                         ## instance.
  ##   
                                                                                                                                                     ## phoneNumberCountryCodes: JArray
                                                                                                                                                     ##                          
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## ISO 
                                                                                                                                                     ## country 
                                                                                                                                                     ## code.
  var path_402656673 = newJObject()
  var query_402656674 = newJObject()
  if phoneNumberTypes != nil:
    query_402656674.add "phoneNumberTypes", phoneNumberTypes
  add(query_402656674, "maxResults", newJInt(maxResults))
  add(query_402656674, "nextToken", newJString(nextToken))
  add(query_402656674, "MaxResults", newJString(MaxResults))
  add(query_402656674, "NextToken", newJString(NextToken))
  add(path_402656673, "InstanceId", newJString(InstanceId))
  if phoneNumberCountryCodes != nil:
    query_402656674.add "phoneNumberCountryCodes", phoneNumberCountryCodes
  result = call_402656672.call(path_402656673, query_402656674, nil, nil, nil)

var listPhoneNumbers* = Call_ListPhoneNumbers_402656654(
    name: "listPhoneNumbers", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/phone-numbers-summary/{InstanceId}",
    validator: validate_ListPhoneNumbers_402656655, base: "/",
    makeUrl: url_ListPhoneNumbers_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueues_402656675 = ref object of OpenApiRestCall_402656044
proc url_ListQueues_402656677(protocol: Scheme; host: string; base: string;
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

proc validate_ListQueues_402656676(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656678 = path.getOrDefault("InstanceId")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true,
                                      default = nil)
  if valid_402656678 != nil:
    section.add "InstanceId", valid_402656678
  result.add "path", section
  ## parameters in `query` object:
  ##   queueTypes: JArray
                                  ##             : The type of queue.
  ##   maxResults: JInt
                                                                     ##             : The maximimum number of results to return per page.
  ##   
                                                                                                                                         ## nextToken: JString
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## token 
                                                                                                                                         ## for 
                                                                                                                                         ## the 
                                                                                                                                         ## next 
                                                                                                                                         ## set 
                                                                                                                                         ## of 
                                                                                                                                         ## results. 
                                                                                                                                         ## Use 
                                                                                                                                         ## the 
                                                                                                                                         ## value 
                                                                                                                                         ## returned 
                                                                                                                                         ## in 
                                                                                                                                         ## the 
                                                                                                                                         ## previous 
                                                                                                                                         ## response 
                                                                                                                                         ## in 
                                                                                                                                         ## the 
                                                                                                                                         ## next 
                                                                                                                                         ## request 
                                                                                                                                         ## to 
                                                                                                                                         ## retrieve 
                                                                                                                                         ## the 
                                                                                                                                         ## next 
                                                                                                                                         ## set 
                                                                                                                                         ## of 
                                                                                                                                         ## results.
  ##   
                                                                                                                                                    ## MaxResults: JString
                                                                                                                                                    ##             
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## limit
  ##   
                                                                                                                                                            ## NextToken: JString
                                                                                                                                                            ##            
                                                                                                                                                            ## : 
                                                                                                                                                            ## Pagination 
                                                                                                                                                            ## token
  section = newJObject()
  var valid_402656679 = query.getOrDefault("queueTypes")
  valid_402656679 = validateParameter(valid_402656679, JArray, required = false,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "queueTypes", valid_402656679
  var valid_402656680 = query.getOrDefault("maxResults")
  valid_402656680 = validateParameter(valid_402656680, JInt, required = false,
                                      default = nil)
  if valid_402656680 != nil:
    section.add "maxResults", valid_402656680
  var valid_402656681 = query.getOrDefault("nextToken")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "nextToken", valid_402656681
  var valid_402656682 = query.getOrDefault("MaxResults")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "MaxResults", valid_402656682
  var valid_402656683 = query.getOrDefault("NextToken")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "NextToken", valid_402656683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Security-Token", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Signature")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Signature", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Algorithm", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Date")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Date", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Credential")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Credential", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656691: Call_ListQueues_402656675; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about the queues for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656691.validator(path, query, header, formData, body, _)
  let scheme = call_402656691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656691.makeUrl(scheme.get, call_402656691.host, call_402656691.base,
                                   call_402656691.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656691, uri, valid, _)

proc call*(call_402656692: Call_ListQueues_402656675; InstanceId: string;
           queueTypes: JsonNode = nil; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listQueues
  ## Provides information about the queues for the specified Amazon Connect instance.
  ##   
                                                                                     ## queueTypes: JArray
                                                                                     ##             
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## type 
                                                                                     ## of 
                                                                                     ## queue.
  ##   
                                                                                              ## maxResults: int
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## maximimum 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## results 
                                                                                              ## to 
                                                                                              ## return 
                                                                                              ## per 
                                                                                              ## page.
  ##   
                                                                                                      ## nextToken: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: string
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  ##   
                                                                                                                                 ## InstanceId: string (required)
                                                                                                                                 ##             
                                                                                                                                 ## : 
                                                                                                                                 ## The 
                                                                                                                                 ## identifier 
                                                                                                                                 ## of 
                                                                                                                                 ## the 
                                                                                                                                 ## Amazon 
                                                                                                                                 ## Connect 
                                                                                                                                 ## instance.
  var path_402656693 = newJObject()
  var query_402656694 = newJObject()
  if queueTypes != nil:
    query_402656694.add "queueTypes", queueTypes
  add(query_402656694, "maxResults", newJInt(maxResults))
  add(query_402656694, "nextToken", newJString(nextToken))
  add(query_402656694, "MaxResults", newJString(MaxResults))
  add(query_402656694, "NextToken", newJString(NextToken))
  add(path_402656693, "InstanceId", newJString(InstanceId))
  result = call_402656692.call(path_402656693, query_402656694, nil, nil, nil)

var listQueues* = Call_ListQueues_402656675(name: "listQueues",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/queues-summary/{InstanceId}", validator: validate_ListQueues_402656676,
    base: "/", makeUrl: url_ListQueues_402656677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRoutingProfiles_402656695 = ref object of OpenApiRestCall_402656044
proc url_ListRoutingProfiles_402656697(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListRoutingProfiles_402656696(path: JsonNode; query: JsonNode;
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
  var valid_402656698 = path.getOrDefault("InstanceId")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true,
                                      default = nil)
  if valid_402656698 != nil:
    section.add "InstanceId", valid_402656698
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  section = newJObject()
  var valid_402656699 = query.getOrDefault("maxResults")
  valid_402656699 = validateParameter(valid_402656699, JInt, required = false,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "maxResults", valid_402656699
  var valid_402656700 = query.getOrDefault("nextToken")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "nextToken", valid_402656700
  var valid_402656701 = query.getOrDefault("MaxResults")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "MaxResults", valid_402656701
  var valid_402656702 = query.getOrDefault("NextToken")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "NextToken", valid_402656702
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656710: Call_ListRoutingProfiles_402656695;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656710.validator(path, query, header, formData, body, _)
  let scheme = call_402656710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656710.makeUrl(scheme.get, call_402656710.host, call_402656710.base,
                                   call_402656710.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656710, uri, valid, _)

proc call*(call_402656711: Call_ListRoutingProfiles_402656695;
           InstanceId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listRoutingProfiles
  ## Provides summary information about the routing profiles for the specified Amazon Connect instance.
  ##   
                                                                                                       ## maxResults: int
                                                                                                       ##             
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## maximimum 
                                                                                                       ## number 
                                                                                                       ## of 
                                                                                                       ## results 
                                                                                                       ## to 
                                                                                                       ## return 
                                                                                                       ## per 
                                                                                                       ## page.
  ##   
                                                                                                               ## nextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## token 
                                                                                                               ## for 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## set 
                                                                                                               ## of 
                                                                                                               ## results. 
                                                                                                               ## Use 
                                                                                                               ## the 
                                                                                                               ## value 
                                                                                                               ## returned 
                                                                                                               ## in 
                                                                                                               ## the 
                                                                                                               ## previous 
                                                                                                               ## response 
                                                                                                               ## in 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## request 
                                                                                                               ## to 
                                                                                                               ## retrieve 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## set 
                                                                                                               ## of 
                                                                                                               ## results.
  ##   
                                                                                                                          ## MaxResults: string
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## limit
  ##   
                                                                                                                                  ## NextToken: string
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## Pagination 
                                                                                                                                  ## token
  ##   
                                                                                                                                          ## InstanceId: string (required)
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## identifier 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## Amazon 
                                                                                                                                          ## Connect 
                                                                                                                                          ## instance.
  var path_402656712 = newJObject()
  var query_402656713 = newJObject()
  add(query_402656713, "maxResults", newJInt(maxResults))
  add(query_402656713, "nextToken", newJString(nextToken))
  add(query_402656713, "MaxResults", newJString(MaxResults))
  add(query_402656713, "NextToken", newJString(NextToken))
  add(path_402656712, "InstanceId", newJString(InstanceId))
  result = call_402656711.call(path_402656712, query_402656713, nil, nil, nil)

var listRoutingProfiles* = Call_ListRoutingProfiles_402656695(
    name: "listRoutingProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/routing-profiles-summary/{InstanceId}",
    validator: validate_ListRoutingProfiles_402656696, base: "/",
    makeUrl: url_ListRoutingProfiles_402656697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityProfiles_402656714 = ref object of OpenApiRestCall_402656044
proc url_ListSecurityProfiles_402656716(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListSecurityProfiles_402656715(path: JsonNode; query: JsonNode;
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
  var valid_402656717 = path.getOrDefault("InstanceId")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "InstanceId", valid_402656717
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  section = newJObject()
  var valid_402656718 = query.getOrDefault("maxResults")
  valid_402656718 = validateParameter(valid_402656718, JInt, required = false,
                                      default = nil)
  if valid_402656718 != nil:
    section.add "maxResults", valid_402656718
  var valid_402656719 = query.getOrDefault("nextToken")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "nextToken", valid_402656719
  var valid_402656720 = query.getOrDefault("MaxResults")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "MaxResults", valid_402656720
  var valid_402656721 = query.getOrDefault("NextToken")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "NextToken", valid_402656721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656729: Call_ListSecurityProfiles_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656729.validator(path, query, header, formData, body, _)
  let scheme = call_402656729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656729.makeUrl(scheme.get, call_402656729.host, call_402656729.base,
                                   call_402656729.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656729, uri, valid, _)

proc call*(call_402656730: Call_ListSecurityProfiles_402656714;
           InstanceId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSecurityProfiles
  ## Provides summary information about the security profiles for the specified Amazon Connect instance.
  ##   
                                                                                                        ## maxResults: int
                                                                                                        ##             
                                                                                                        ## : 
                                                                                                        ## The 
                                                                                                        ## maximimum 
                                                                                                        ## number 
                                                                                                        ## of 
                                                                                                        ## results 
                                                                                                        ## to 
                                                                                                        ## return 
                                                                                                        ## per 
                                                                                                        ## page.
  ##   
                                                                                                                ## nextToken: string
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## token 
                                                                                                                ## for 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## results. 
                                                                                                                ## Use 
                                                                                                                ## the 
                                                                                                                ## value 
                                                                                                                ## returned 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## previous 
                                                                                                                ## response 
                                                                                                                ## in 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## request 
                                                                                                                ## to 
                                                                                                                ## retrieve 
                                                                                                                ## the 
                                                                                                                ## next 
                                                                                                                ## set 
                                                                                                                ## of 
                                                                                                                ## results.
  ##   
                                                                                                                           ## MaxResults: string
                                                                                                                           ##             
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## limit
  ##   
                                                                                                                                   ## NextToken: string
                                                                                                                                   ##            
                                                                                                                                   ## : 
                                                                                                                                   ## Pagination 
                                                                                                                                   ## token
  ##   
                                                                                                                                           ## InstanceId: string (required)
                                                                                                                                           ##             
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## identifier 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## Amazon 
                                                                                                                                           ## Connect 
                                                                                                                                           ## instance.
  var path_402656731 = newJObject()
  var query_402656732 = newJObject()
  add(query_402656732, "maxResults", newJInt(maxResults))
  add(query_402656732, "nextToken", newJString(nextToken))
  add(query_402656732, "MaxResults", newJString(MaxResults))
  add(query_402656732, "NextToken", newJString(NextToken))
  add(path_402656731, "InstanceId", newJString(InstanceId))
  result = call_402656730.call(path_402656731, query_402656732, nil, nil, nil)

var listSecurityProfiles* = Call_ListSecurityProfiles_402656714(
    name: "listSecurityProfiles", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/security-profiles-summary/{InstanceId}",
    validator: validate_ListSecurityProfiles_402656715, base: "/",
    makeUrl: url_ListSecurityProfiles_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656747 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656749(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656748(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656750 = path.getOrDefault("resourceArn")
  valid_402656750 = validateParameter(valid_402656750, JString, required = true,
                                      default = nil)
  if valid_402656750 != nil:
    section.add "resourceArn", valid_402656750
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656751 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Security-Token", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Signature")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Signature", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Algorithm", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Date")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Date", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Credential")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Credential", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656757
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

proc call*(call_402656759: Call_TagResource_402656747; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
                                                                                         ## 
  let valid = call_402656759.validator(path, query, header, formData, body, _)
  let scheme = call_402656759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656759.makeUrl(scheme.get, call_402656759.host, call_402656759.base,
                                   call_402656759.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656759, uri, valid, _)

proc call*(call_402656760: Call_TagResource_402656747; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds the specified tags to the specified resource.</p> <p>The supported resource type is users.</p>
  ##   
                                                                                                           ## body: JObject (required)
  ##   
                                                                                                                                      ## resourceArn: string (required)
                                                                                                                                      ##              
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## Amazon 
                                                                                                                                      ## Resource 
                                                                                                                                      ## Name 
                                                                                                                                      ## (ARN) 
                                                                                                                                      ## of 
                                                                                                                                      ## the 
                                                                                                                                      ## resource.
  var path_402656761 = newJObject()
  var body_402656762 = newJObject()
  if body != nil:
    body_402656762 = body
  add(path_402656761, "resourceArn", newJString(resourceArn))
  result = call_402656760.call(path_402656761, nil, nil, nil, body_402656762)

var tagResource* = Call_TagResource_402656747(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656748,
    base: "/", makeUrl: url_TagResource_402656749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656733 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656735(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402656734(path: JsonNode; query: JsonNode;
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
  var valid_402656736 = path.getOrDefault("resourceArn")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true,
                                      default = nil)
  if valid_402656736 != nil:
    section.add "resourceArn", valid_402656736
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656737 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Security-Token", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Signature")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Signature", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Algorithm", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Date")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Date", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Credential")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Credential", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656744: Call_ListTagsForResource_402656733;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags for the specified resource.
                                                                                         ## 
  let valid = call_402656744.validator(path, query, header, formData, body, _)
  let scheme = call_402656744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656744.makeUrl(scheme.get, call_402656744.host, call_402656744.base,
                                   call_402656744.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656744, uri, valid, _)

proc call*(call_402656745: Call_ListTagsForResource_402656733;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags for the specified resource.
  ##   resourceArn: string (required)
                                               ##              : The Amazon Resource Name (ARN) of the resource.
  var path_402656746 = newJObject()
  add(path_402656746, "resourceArn", newJString(resourceArn))
  result = call_402656745.call(path_402656746, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656733(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656734, base: "/",
    makeUrl: url_ListTagsForResource_402656735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserHierarchyGroups_402656763 = ref object of OpenApiRestCall_402656044
proc url_ListUserHierarchyGroups_402656765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InstanceId" in path, "`InstanceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/user-hierarchy-groups-summary/"),
                 (kind: VariableSegment, value: "InstanceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserHierarchyGroups_402656764(path: JsonNode; query: JsonNode;
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
  var valid_402656766 = path.getOrDefault("InstanceId")
  valid_402656766 = validateParameter(valid_402656766, JString, required = true,
                                      default = nil)
  if valid_402656766 != nil:
    section.add "InstanceId", valid_402656766
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  section = newJObject()
  var valid_402656767 = query.getOrDefault("maxResults")
  valid_402656767 = validateParameter(valid_402656767, JInt, required = false,
                                      default = nil)
  if valid_402656767 != nil:
    section.add "maxResults", valid_402656767
  var valid_402656768 = query.getOrDefault("nextToken")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "nextToken", valid_402656768
  var valid_402656769 = query.getOrDefault("MaxResults")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "MaxResults", valid_402656769
  var valid_402656770 = query.getOrDefault("NextToken")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "NextToken", valid_402656770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656771 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Security-Token", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Signature")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Signature", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Algorithm", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Date")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Date", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Credential")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Credential", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656778: Call_ListUserHierarchyGroups_402656763;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656778.validator(path, query, header, formData, body, _)
  let scheme = call_402656778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656778.makeUrl(scheme.get, call_402656778.host, call_402656778.base,
                                   call_402656778.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656778, uri, valid, _)

proc call*(call_402656779: Call_ListUserHierarchyGroups_402656763;
           InstanceId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserHierarchyGroups
  ## Provides summary information about the hierarchy groups for the specified Amazon Connect instance.
  ##   
                                                                                                       ## maxResults: int
                                                                                                       ##             
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## maximimum 
                                                                                                       ## number 
                                                                                                       ## of 
                                                                                                       ## results 
                                                                                                       ## to 
                                                                                                       ## return 
                                                                                                       ## per 
                                                                                                       ## page.
  ##   
                                                                                                               ## nextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## token 
                                                                                                               ## for 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## set 
                                                                                                               ## of 
                                                                                                               ## results. 
                                                                                                               ## Use 
                                                                                                               ## the 
                                                                                                               ## value 
                                                                                                               ## returned 
                                                                                                               ## in 
                                                                                                               ## the 
                                                                                                               ## previous 
                                                                                                               ## response 
                                                                                                               ## in 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## request 
                                                                                                               ## to 
                                                                                                               ## retrieve 
                                                                                                               ## the 
                                                                                                               ## next 
                                                                                                               ## set 
                                                                                                               ## of 
                                                                                                               ## results.
  ##   
                                                                                                                          ## MaxResults: string
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## limit
  ##   
                                                                                                                                  ## NextToken: string
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## Pagination 
                                                                                                                                  ## token
  ##   
                                                                                                                                          ## InstanceId: string (required)
                                                                                                                                          ##             
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## identifier 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## Amazon 
                                                                                                                                          ## Connect 
                                                                                                                                          ## instance.
  var path_402656780 = newJObject()
  var query_402656781 = newJObject()
  add(query_402656781, "maxResults", newJInt(maxResults))
  add(query_402656781, "nextToken", newJString(nextToken))
  add(query_402656781, "MaxResults", newJString(MaxResults))
  add(query_402656781, "NextToken", newJString(NextToken))
  add(path_402656780, "InstanceId", newJString(InstanceId))
  result = call_402656779.call(path_402656780, query_402656781, nil, nil, nil)

var listUserHierarchyGroups* = Call_ListUserHierarchyGroups_402656763(
    name: "listUserHierarchyGroups", meth: HttpMethod.HttpGet,
    host: "connect.amazonaws.com",
    route: "/user-hierarchy-groups-summary/{InstanceId}",
    validator: validate_ListUserHierarchyGroups_402656764, base: "/",
    makeUrl: url_ListUserHierarchyGroups_402656765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_402656782 = ref object of OpenApiRestCall_402656044
proc url_ListUsers_402656784(protocol: Scheme; host: string; base: string;
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

proc validate_ListUsers_402656783(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_402656785 = path.getOrDefault("InstanceId")
  valid_402656785 = validateParameter(valid_402656785, JString, required = true,
                                      default = nil)
  if valid_402656785 != nil:
    section.add "InstanceId", valid_402656785
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximimum number of results to return per page.
  ##   
                                                                                                      ## nextToken: JString
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## token 
                                                                                                      ## for 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results. 
                                                                                                      ## Use 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## returned 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## previous 
                                                                                                      ## response 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## request 
                                                                                                      ## to 
                                                                                                      ## retrieve 
                                                                                                      ## the 
                                                                                                      ## next 
                                                                                                      ## set 
                                                                                                      ## of 
                                                                                                      ## results.
  ##   
                                                                                                                 ## MaxResults: JString
                                                                                                                 ##             
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## limit
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Pagination 
                                                                                                                         ## token
  section = newJObject()
  var valid_402656786 = query.getOrDefault("maxResults")
  valid_402656786 = validateParameter(valid_402656786, JInt, required = false,
                                      default = nil)
  if valid_402656786 != nil:
    section.add "maxResults", valid_402656786
  var valid_402656787 = query.getOrDefault("nextToken")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "nextToken", valid_402656787
  var valid_402656788 = query.getOrDefault("MaxResults")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "MaxResults", valid_402656788
  var valid_402656789 = query.getOrDefault("NextToken")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "NextToken", valid_402656789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656790 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Security-Token", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Signature")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Signature", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Algorithm", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Date")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Date", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Credential")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Credential", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656797: Call_ListUsers_402656782; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides summary information about the users for the specified Amazon Connect instance.
                                                                                         ## 
  let valid = call_402656797.validator(path, query, header, formData, body, _)
  let scheme = call_402656797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656797.makeUrl(scheme.get, call_402656797.host, call_402656797.base,
                                   call_402656797.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656797, uri, valid, _)

proc call*(call_402656798: Call_ListUsers_402656782; InstanceId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listUsers
  ## Provides summary information about the users for the specified Amazon Connect instance.
  ##   
                                                                                            ## maxResults: int
                                                                                            ##             
                                                                                            ## : 
                                                                                            ## The 
                                                                                            ## maximimum 
                                                                                            ## number 
                                                                                            ## of 
                                                                                            ## results 
                                                                                            ## to 
                                                                                            ## return 
                                                                                            ## per 
                                                                                            ## page.
  ##   
                                                                                                    ## nextToken: string
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## token 
                                                                                                    ## for 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results. 
                                                                                                    ## Use 
                                                                                                    ## the 
                                                                                                    ## value 
                                                                                                    ## returned 
                                                                                                    ## in 
                                                                                                    ## the 
                                                                                                    ## previous 
                                                                                                    ## response 
                                                                                                    ## in 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## request 
                                                                                                    ## to 
                                                                                                    ## retrieve 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## set 
                                                                                                    ## of 
                                                                                                    ## results.
  ##   
                                                                                                               ## MaxResults: string
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## limit
  ##   
                                                                                                                       ## NextToken: string
                                                                                                                       ##            
                                                                                                                       ## : 
                                                                                                                       ## Pagination 
                                                                                                                       ## token
  ##   
                                                                                                                               ## InstanceId: string (required)
                                                                                                                               ##             
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## identifier 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## Amazon 
                                                                                                                               ## Connect 
                                                                                                                               ## instance.
  var path_402656799 = newJObject()
  var query_402656800 = newJObject()
  add(query_402656800, "maxResults", newJInt(maxResults))
  add(query_402656800, "nextToken", newJString(nextToken))
  add(query_402656800, "MaxResults", newJString(MaxResults))
  add(query_402656800, "NextToken", newJString(NextToken))
  add(path_402656799, "InstanceId", newJString(InstanceId))
  result = call_402656798.call(path_402656799, query_402656800, nil, nil, nil)

var listUsers* = Call_ListUsers_402656782(name: "listUsers",
    meth: HttpMethod.HttpGet, host: "connect.amazonaws.com",
    route: "/users-summary/{InstanceId}", validator: validate_ListUsers_402656783,
    base: "/", makeUrl: url_ListUsers_402656784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChatContact_402656801 = ref object of OpenApiRestCall_402656044
proc url_StartChatContact_402656803(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartChatContact_402656802(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656804 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Security-Token", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Signature")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Signature", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Algorithm", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Date")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Date", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Credential")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Credential", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656810
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

proc call*(call_402656812: Call_StartChatContact_402656801;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_StartChatContact_402656801; body: JsonNode): Recallable =
  ## startChatContact
  ## <p>Initiates a contact flow to start a new chat for the customer. Response of this API provides a token required to obtain credentials from the <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> API in the Amazon Connect Participant Service.</p> <p>When a new chat contact is successfully created, clients need to subscribe to the participant’s connection for the created chat within 5 minutes. This is achieved by invoking <a href="https://docs.aws.amazon.com/connect-participant/latest/APIReference/API_CreateParticipantConnection.html">CreateParticipantConnection</a> with WEBSOCKET and CONNECTION_CREDENTIALS. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656814 = newJObject()
  if body != nil:
    body_402656814 = body
  result = call_402656813.call(nil, nil, nil, nil, body_402656814)

var startChatContact* = Call_StartChatContact_402656801(
    name: "startChatContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/chat",
    validator: validate_StartChatContact_402656802, base: "/",
    makeUrl: url_StartChatContact_402656803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOutboundVoiceContact_402656815 = ref object of OpenApiRestCall_402656044
proc url_StartOutboundVoiceContact_402656817(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOutboundVoiceContact_402656816(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656818 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Security-Token", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Signature")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Signature", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Algorithm", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Date")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Date", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Credential")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Credential", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656824
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

proc call*(call_402656826: Call_StartOutboundVoiceContact_402656815;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
                                                                                         ## 
  let valid = call_402656826.validator(path, query, header, formData, body, _)
  let scheme = call_402656826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656826.makeUrl(scheme.get, call_402656826.host, call_402656826.base,
                                   call_402656826.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656826, uri, valid, _)

proc call*(call_402656827: Call_StartOutboundVoiceContact_402656815;
           body: JsonNode): Recallable =
  ## startOutboundVoiceContact
  ## <p>Initiates a contact flow to place an outbound call to a customer.</p> <p>There is a 60 second dialing timeout for this operation. If the call is not connected after 60 seconds, it fails.</p>
  ##   
                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656828 = newJObject()
  if body != nil:
    body_402656828 = body
  result = call_402656827.call(nil, nil, nil, nil, body_402656828)

var startOutboundVoiceContact* = Call_StartOutboundVoiceContact_402656815(
    name: "startOutboundVoiceContact", meth: HttpMethod.HttpPut,
    host: "connect.amazonaws.com", route: "/contact/outbound-voice",
    validator: validate_StartOutboundVoiceContact_402656816, base: "/",
    makeUrl: url_StartOutboundVoiceContact_402656817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContact_402656829 = ref object of OpenApiRestCall_402656044
proc url_StopContact_402656831(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContact_402656830(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656832 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Security-Token", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Signature")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Signature", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Algorithm", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Date")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Date", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Credential")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Credential", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656838
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

proc call*(call_402656840: Call_StopContact_402656829; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Ends the specified contact.
                                                                                         ## 
  let valid = call_402656840.validator(path, query, header, formData, body, _)
  let scheme = call_402656840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656840.makeUrl(scheme.get, call_402656840.host, call_402656840.base,
                                   call_402656840.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656840, uri, valid, _)

proc call*(call_402656841: Call_StopContact_402656829; body: JsonNode): Recallable =
  ## stopContact
  ## Ends the specified contact.
  ##   body: JObject (required)
  var body_402656842 = newJObject()
  if body != nil:
    body_402656842 = body
  result = call_402656841.call(nil, nil, nil, nil, body_402656842)

var stopContact* = Call_StopContact_402656829(name: "stopContact",
    meth: HttpMethod.HttpPost, host: "connect.amazonaws.com",
    route: "/contact/stop", validator: validate_StopContact_402656830,
    base: "/", makeUrl: url_StopContact_402656831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656843 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656845(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402656844(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656846 = path.getOrDefault("resourceArn")
  valid_402656846 = validateParameter(valid_402656846, JString, required = true,
                                      default = nil)
  if valid_402656846 != nil:
    section.add "resourceArn", valid_402656846
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656847 = query.getOrDefault("tagKeys")
  valid_402656847 = validateParameter(valid_402656847, JArray, required = true,
                                      default = nil)
  if valid_402656847 != nil:
    section.add "tagKeys", valid_402656847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656848 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Security-Token", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Signature")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Signature", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Algorithm", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Date")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Date", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Credential")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Credential", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656855: Call_UntagResource_402656843; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified tags from the specified resource.
                                                                                         ## 
  let valid = call_402656855.validator(path, query, header, formData, body, _)
  let scheme = call_402656855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656855.makeUrl(scheme.get, call_402656855.host, call_402656855.base,
                                   call_402656855.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656855, uri, valid, _)

proc call*(call_402656856: Call_UntagResource_402656843; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes the specified tags from the specified resource.
  ##   tagKeys: JArray (required)
                                                            ##          : The tag keys.
  ##   
                                                                                       ## resourceArn: string (required)
                                                                                       ##              
                                                                                       ## : 
                                                                                       ## The 
                                                                                       ## Amazon 
                                                                                       ## Resource 
                                                                                       ## Name 
                                                                                       ## (ARN) 
                                                                                       ## of 
                                                                                       ## the 
                                                                                       ## resource.
  var path_402656857 = newJObject()
  var query_402656858 = newJObject()
  if tagKeys != nil:
    query_402656858.add "tagKeys", tagKeys
  add(path_402656857, "resourceArn", newJString(resourceArn))
  result = call_402656856.call(path_402656857, query_402656858, nil, nil, nil)

var untagResource* = Call_UntagResource_402656843(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "connect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656844,
    base: "/", makeUrl: url_UntagResource_402656845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContactAttributes_402656859 = ref object of OpenApiRestCall_402656044
proc url_UpdateContactAttributes_402656861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateContactAttributes_402656860(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656862 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Security-Token", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Signature")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Signature", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Algorithm", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Date")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Date", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-Credential")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-Credential", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656868
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

proc call*(call_402656870: Call_UpdateContactAttributes_402656859;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
                                                                                         ## 
  let valid = call_402656870.validator(path, query, header, formData, body, _)
  let scheme = call_402656870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656870.makeUrl(scheme.get, call_402656870.host, call_402656870.base,
                                   call_402656870.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656870, uri, valid, _)

proc call*(call_402656871: Call_UpdateContactAttributes_402656859;
           body: JsonNode): Recallable =
  ## updateContactAttributes
  ## <p>Creates or updates the contact attributes associated with the specified contact.</p> <p>You can add or update attributes for both ongoing and completed contacts. For example, you can update the customer's name or the reason the customer called while the call is active, or add notes about steps that the agent took during the call that are displayed to the next agent that takes the call. You can also update attributes for a contact using data from your CRM application and save the data with the contact in Amazon Connect. You could also flag calls for additional analysis, such as legal review or identifying abusive callers.</p> <p>Contact attributes are available in Amazon Connect for 24 months, and are then deleted.</p> <p> <b>Important:</b> You cannot use the operation to update attributes for contacts that occurred prior to the release of the API, September 12, 2018. You can update attributes only for contacts that started after the release of the API. If you attempt to update attributes for a contact that occurred prior to the release of the API, a 400 error is returned. This applies also to queued callbacks that were initiated prior to the release of the API but are still active in your instance.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656872 = newJObject()
  if body != nil:
    body_402656872 = body
  result = call_402656871.call(nil, nil, nil, nil, body_402656872)

var updateContactAttributes* = Call_UpdateContactAttributes_402656859(
    name: "updateContactAttributes", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com", route: "/contact/attributes",
    validator: validate_UpdateContactAttributes_402656860, base: "/",
    makeUrl: url_UpdateContactAttributes_402656861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserHierarchy_402656873 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserHierarchy_402656875(protocol: Scheme; host: string;
                                       base: string; route: string;
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
                 (kind: VariableSegment, value: "UserId"),
                 (kind: ConstantSegment, value: "/hierarchy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserHierarchy_402656874(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns the specified hierarchy group to the specified user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656876 = path.getOrDefault("InstanceId")
  valid_402656876 = validateParameter(valid_402656876, JString, required = true,
                                      default = nil)
  if valid_402656876 != nil:
    section.add "InstanceId", valid_402656876
  var valid_402656877 = path.getOrDefault("UserId")
  valid_402656877 = validateParameter(valid_402656877, JString, required = true,
                                      default = nil)
  if valid_402656877 != nil:
    section.add "UserId", valid_402656877
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656878 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Security-Token", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Signature")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Signature", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Algorithm", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Date")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Date", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Credential")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Credential", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656884
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

proc call*(call_402656886: Call_UpdateUserHierarchy_402656873;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified hierarchy group to the specified user.
                                                                                         ## 
  let valid = call_402656886.validator(path, query, header, formData, body, _)
  let scheme = call_402656886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656886.makeUrl(scheme.get, call_402656886.host, call_402656886.base,
                                   call_402656886.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656886, uri, valid, _)

proc call*(call_402656887: Call_UpdateUserHierarchy_402656873; body: JsonNode;
           InstanceId: string; UserId: string): Recallable =
  ## updateUserHierarchy
  ## Assigns the specified hierarchy group to the specified user.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                              ## UserId: string (required)
                                                                                              ##         
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## user 
                                                                                              ## account.
  var path_402656888 = newJObject()
  var body_402656889 = newJObject()
  if body != nil:
    body_402656889 = body
  add(path_402656888, "InstanceId", newJString(InstanceId))
  add(path_402656888, "UserId", newJString(UserId))
  result = call_402656887.call(path_402656888, nil, nil, nil, body_402656889)

var updateUserHierarchy* = Call_UpdateUserHierarchy_402656873(
    name: "updateUserHierarchy", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/hierarchy",
    validator: validate_UpdateUserHierarchy_402656874, base: "/",
    makeUrl: url_UpdateUserHierarchy_402656875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserIdentityInfo_402656890 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserIdentityInfo_402656892(protocol: Scheme; host: string;
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
                 (kind: ConstantSegment, value: "/identity-info")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserIdentityInfo_402656891(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the identity information for the specified user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656893 = path.getOrDefault("InstanceId")
  valid_402656893 = validateParameter(valid_402656893, JString, required = true,
                                      default = nil)
  if valid_402656893 != nil:
    section.add "InstanceId", valid_402656893
  var valid_402656894 = path.getOrDefault("UserId")
  valid_402656894 = validateParameter(valid_402656894, JString, required = true,
                                      default = nil)
  if valid_402656894 != nil:
    section.add "UserId", valid_402656894
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656895 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Security-Token", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Signature")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Signature", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Algorithm", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Date")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Date", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Credential")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Credential", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656901
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

proc call*(call_402656903: Call_UpdateUserIdentityInfo_402656890;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the identity information for the specified user.
                                                                                         ## 
  let valid = call_402656903.validator(path, query, header, formData, body, _)
  let scheme = call_402656903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656903.makeUrl(scheme.get, call_402656903.host, call_402656903.base,
                                   call_402656903.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656903, uri, valid, _)

proc call*(call_402656904: Call_UpdateUserIdentityInfo_402656890;
           body: JsonNode; InstanceId: string; UserId: string): Recallable =
  ## updateUserIdentityInfo
  ## Updates the identity information for the specified user.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                              ## UserId: string (required)
                                                                                              ##         
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## user 
                                                                                              ## account.
  var path_402656905 = newJObject()
  var body_402656906 = newJObject()
  if body != nil:
    body_402656906 = body
  add(path_402656905, "InstanceId", newJString(InstanceId))
  add(path_402656905, "UserId", newJString(UserId))
  result = call_402656904.call(path_402656905, nil, nil, nil, body_402656906)

var updateUserIdentityInfo* = Call_UpdateUserIdentityInfo_402656890(
    name: "updateUserIdentityInfo", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/identity-info",
    validator: validate_UpdateUserIdentityInfo_402656891, base: "/",
    makeUrl: url_UpdateUserIdentityInfo_402656892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserPhoneConfig_402656907 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserPhoneConfig_402656909(protocol: Scheme; host: string;
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
                 (kind: ConstantSegment, value: "/phone-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUserPhoneConfig_402656908(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the phone configuration settings for the specified user.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656910 = path.getOrDefault("InstanceId")
  valid_402656910 = validateParameter(valid_402656910, JString, required = true,
                                      default = nil)
  if valid_402656910 != nil:
    section.add "InstanceId", valid_402656910
  var valid_402656911 = path.getOrDefault("UserId")
  valid_402656911 = validateParameter(valid_402656911, JString, required = true,
                                      default = nil)
  if valid_402656911 != nil:
    section.add "UserId", valid_402656911
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656912 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Security-Token", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Signature")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Signature", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Algorithm", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Date")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Date", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Credential")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Credential", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656918
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

proc call*(call_402656920: Call_UpdateUserPhoneConfig_402656907;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the phone configuration settings for the specified user.
                                                                                         ## 
  let valid = call_402656920.validator(path, query, header, formData, body, _)
  let scheme = call_402656920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656920.makeUrl(scheme.get, call_402656920.host, call_402656920.base,
                                   call_402656920.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656920, uri, valid, _)

proc call*(call_402656921: Call_UpdateUserPhoneConfig_402656907; body: JsonNode;
           InstanceId: string; UserId: string): Recallable =
  ## updateUserPhoneConfig
  ## Updates the phone configuration settings for the specified user.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                              ## UserId: string (required)
                                                                                              ##         
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## user 
                                                                                              ## account.
  var path_402656922 = newJObject()
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  add(path_402656922, "InstanceId", newJString(InstanceId))
  add(path_402656922, "UserId", newJString(UserId))
  result = call_402656921.call(path_402656922, nil, nil, nil, body_402656923)

var updateUserPhoneConfig* = Call_UpdateUserPhoneConfig_402656907(
    name: "updateUserPhoneConfig", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/phone-config",
    validator: validate_UpdateUserPhoneConfig_402656908, base: "/",
    makeUrl: url_UpdateUserPhoneConfig_402656909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserRoutingProfile_402656924 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserRoutingProfile_402656926(protocol: Scheme; host: string;
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

proc validate_UpdateUserRoutingProfile_402656925(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Assigns the specified routing profile to the specified user.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656927 = path.getOrDefault("InstanceId")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true,
                                      default = nil)
  if valid_402656927 != nil:
    section.add "InstanceId", valid_402656927
  var valid_402656928 = path.getOrDefault("UserId")
  valid_402656928 = validateParameter(valid_402656928, JString, required = true,
                                      default = nil)
  if valid_402656928 != nil:
    section.add "UserId", valid_402656928
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656929 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Security-Token", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Signature")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Signature", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Algorithm", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Date")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Date", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Credential")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Credential", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656935
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

proc call*(call_402656937: Call_UpdateUserRoutingProfile_402656924;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified routing profile to the specified user.
                                                                                         ## 
  let valid = call_402656937.validator(path, query, header, formData, body, _)
  let scheme = call_402656937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656937.makeUrl(scheme.get, call_402656937.host, call_402656937.base,
                                   call_402656937.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656937, uri, valid, _)

proc call*(call_402656938: Call_UpdateUserRoutingProfile_402656924;
           body: JsonNode; InstanceId: string; UserId: string): Recallable =
  ## updateUserRoutingProfile
  ## Assigns the specified routing profile to the specified user.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                              ## UserId: string (required)
                                                                                              ##         
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## user 
                                                                                              ## account.
  var path_402656939 = newJObject()
  var body_402656940 = newJObject()
  if body != nil:
    body_402656940 = body
  add(path_402656939, "InstanceId", newJString(InstanceId))
  add(path_402656939, "UserId", newJString(UserId))
  result = call_402656938.call(path_402656939, nil, nil, nil, body_402656940)

var updateUserRoutingProfile* = Call_UpdateUserRoutingProfile_402656924(
    name: "updateUserRoutingProfile", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/routing-profile",
    validator: validate_UpdateUserRoutingProfile_402656925, base: "/",
    makeUrl: url_UpdateUserRoutingProfile_402656926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserSecurityProfiles_402656941 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserSecurityProfiles_402656943(protocol: Scheme; host: string;
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

proc validate_UpdateUserSecurityProfiles_402656942(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Assigns the specified security profiles to the specified user.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceId: JString (required)
                                 ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                                ## UserId: JString (required)
                                                                                                ##         
                                                                                                ## : 
                                                                                                ## The 
                                                                                                ## identifier 
                                                                                                ## of 
                                                                                                ## the 
                                                                                                ## user 
                                                                                                ## account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `InstanceId` field"
  var valid_402656944 = path.getOrDefault("InstanceId")
  valid_402656944 = validateParameter(valid_402656944, JString, required = true,
                                      default = nil)
  if valid_402656944 != nil:
    section.add "InstanceId", valid_402656944
  var valid_402656945 = path.getOrDefault("UserId")
  valid_402656945 = validateParameter(valid_402656945, JString, required = true,
                                      default = nil)
  if valid_402656945 != nil:
    section.add "UserId", valid_402656945
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656946 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Security-Token", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Signature")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Signature", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Algorithm", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Date")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Date", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Credential")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Credential", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656952
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

proc call*(call_402656954: Call_UpdateUserSecurityProfiles_402656941;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns the specified security profiles to the specified user.
                                                                                         ## 
  let valid = call_402656954.validator(path, query, header, formData, body, _)
  let scheme = call_402656954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656954.makeUrl(scheme.get, call_402656954.host, call_402656954.base,
                                   call_402656954.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656954, uri, valid, _)

proc call*(call_402656955: Call_UpdateUserSecurityProfiles_402656941;
           body: JsonNode; InstanceId: string; UserId: string): Recallable =
  ## updateUserSecurityProfiles
  ## Assigns the specified security profiles to the specified user.
  ##   body: JObject (required)
  ##   InstanceId: string (required)
                               ##             : The identifier of the Amazon Connect instance.
  ##   
                                                                                              ## UserId: string (required)
                                                                                              ##         
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## identifier 
                                                                                              ## of 
                                                                                              ## the 
                                                                                              ## user 
                                                                                              ## account.
  var path_402656956 = newJObject()
  var body_402656957 = newJObject()
  if body != nil:
    body_402656957 = body
  add(path_402656956, "InstanceId", newJString(InstanceId))
  add(path_402656956, "UserId", newJString(UserId))
  result = call_402656955.call(path_402656956, nil, nil, nil, body_402656957)

var updateUserSecurityProfiles* = Call_UpdateUserSecurityProfiles_402656941(
    name: "updateUserSecurityProfiles", meth: HttpMethod.HttpPost,
    host: "connect.amazonaws.com",
    route: "/users/{InstanceId}/{UserId}/security-profiles",
    validator: validate_UpdateUserSecurityProfiles_402656942, base: "/",
    makeUrl: url_UpdateUserSecurityProfiles_402656943,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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