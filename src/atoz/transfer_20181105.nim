
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Transfer for SFTP
## version: 2018-11-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Transfer for SFTP is a fully managed service that enables the transfer of files directly into and out of Amazon S3 using the Secure File Transfer Protocol (SFTP)—also known as Secure Shell (SSH) File Transfer Protocol. AWS helps you seamlessly migrate your file transfer workflows to AWS Transfer for SFTP—by integrating with existing authentication systems, and providing DNS routing with Amazon Route 53—so nothing changes for your customers and partners, or their applications. With your data in S3, you can use it with AWS services for processing, analytics, machine learning, and archiving. Getting started with AWS Transfer for SFTP (AWS SFTP) is easy; there is no infrastructure to buy and set up. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/transfer/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "transfer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "transfer.ap-southeast-1.amazonaws.com",
                               "us-west-2": "transfer.us-west-2.amazonaws.com",
                               "eu-west-2": "transfer.eu-west-2.amazonaws.com", "ap-northeast-3": "transfer.ap-northeast-3.amazonaws.com", "eu-central-1": "transfer.eu-central-1.amazonaws.com",
                               "us-east-2": "transfer.us-east-2.amazonaws.com",
                               "us-east-1": "transfer.us-east-1.amazonaws.com", "cn-northwest-1": "transfer.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "transfer.ap-south-1.amazonaws.com", "eu-north-1": "transfer.eu-north-1.amazonaws.com", "ap-northeast-2": "transfer.ap-northeast-2.amazonaws.com",
                               "us-west-1": "transfer.us-west-1.amazonaws.com", "us-gov-east-1": "transfer.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "transfer.eu-west-3.amazonaws.com", "cn-north-1": "transfer.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "transfer.sa-east-1.amazonaws.com",
                               "eu-west-1": "transfer.eu-west-1.amazonaws.com", "us-gov-west-1": "transfer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "transfer.ap-southeast-2.amazonaws.com", "ca-central-1": "transfer.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "transfer.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "transfer.ap-southeast-1.amazonaws.com",
      "us-west-2": "transfer.us-west-2.amazonaws.com",
      "eu-west-2": "transfer.eu-west-2.amazonaws.com",
      "ap-northeast-3": "transfer.ap-northeast-3.amazonaws.com",
      "eu-central-1": "transfer.eu-central-1.amazonaws.com",
      "us-east-2": "transfer.us-east-2.amazonaws.com",
      "us-east-1": "transfer.us-east-1.amazonaws.com",
      "cn-northwest-1": "transfer.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "transfer.ap-south-1.amazonaws.com",
      "eu-north-1": "transfer.eu-north-1.amazonaws.com",
      "ap-northeast-2": "transfer.ap-northeast-2.amazonaws.com",
      "us-west-1": "transfer.us-west-1.amazonaws.com",
      "us-gov-east-1": "transfer.us-gov-east-1.amazonaws.com",
      "eu-west-3": "transfer.eu-west-3.amazonaws.com",
      "cn-north-1": "transfer.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "transfer.sa-east-1.amazonaws.com",
      "eu-west-1": "transfer.eu-west-1.amazonaws.com",
      "us-gov-west-1": "transfer.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "transfer.ap-southeast-2.amazonaws.com",
      "ca-central-1": "transfer.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "transfer"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateServer_402656294 = ref object of OpenApiRestCall_402656044
proc url_CreateServer_402656296(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServer_402656295(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "TransferService.CreateServer"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
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

proc call*(call_402656412: Call_CreateServer_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_CreateServer_402656294; body: JsonNode): Recallable =
  ## createServer
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ##   
                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var createServer* = Call_CreateServer_402656294(name: "createServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateServer",
    validator: validate_CreateServer_402656295, base: "/",
    makeUrl: url_CreateServer_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_402656489 = ref object of OpenApiRestCall_402656044
proc url_CreateUser_402656491(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_402656490(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "TransferService.CreateUser"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_CreateUser_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
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

proc call*(call_402656502: Call_CreateUser_402656489; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createUser* = Call_CreateUser_402656489(name: "createUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateUser",
    validator: validate_CreateUser_402656490, base: "/",
    makeUrl: url_CreateUser_402656491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_402656504 = ref object of OpenApiRestCall_402656044
proc url_DeleteServer_402656506(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServer_402656505(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "TransferService.DeleteServer"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_DeleteServer_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
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

proc call*(call_402656517: Call_DeleteServer_402656504; body: JsonNode): Recallable =
  ## deleteServer
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ##   
                                                                                                                                     ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var deleteServer* = Call_DeleteServer_402656504(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteServer",
    validator: validate_DeleteServer_402656505, base: "/",
    makeUrl: url_DeleteServer_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSshPublicKey_402656519 = ref object of OpenApiRestCall_402656044
proc url_DeleteSshPublicKey_402656521(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSshPublicKey_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "TransferService.DeleteSshPublicKey"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_DeleteSshPublicKey_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
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

proc call*(call_402656532: Call_DeleteSshPublicKey_402656519; body: JsonNode): Recallable =
  ## deleteSshPublicKey
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ##   
                                                                                                               ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var deleteSshPublicKey* = Call_DeleteSshPublicKey_402656519(
    name: "deleteSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteSshPublicKey",
    validator: validate_DeleteSshPublicKey_402656520, base: "/",
    makeUrl: url_DeleteSshPublicKey_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402656534 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402656536(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_402656535(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "TransferService.DeleteUser"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_DeleteUser_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_DeleteUser_402656534; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ##   
                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var deleteUser* = Call_DeleteUser_402656534(name: "deleteUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteUser",
    validator: validate_DeleteUser_402656535, base: "/",
    makeUrl: url_DeleteUser_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServer_402656549 = ref object of OpenApiRestCall_402656044
proc url_DescribeServer_402656551(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServer_402656550(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties. When you set <code>EndpointType</code> to VPC, the response will contain the <code>EndpointDetails</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "TransferService.DescribeServer"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_DescribeServer_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties. When you set <code>EndpointType</code> to VPC, the response will contain the <code>EndpointDetails</code>.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_DescribeServer_402656549; body: JsonNode): Recallable =
  ## describeServer
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties. When you set <code>EndpointType</code> to VPC, the response will contain the <code>EndpointDetails</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var describeServer* = Call_DescribeServer_402656549(name: "describeServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeServer",
    validator: validate_DescribeServer_402656550, base: "/",
    makeUrl: url_DescribeServer_402656551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_402656564 = ref object of OpenApiRestCall_402656044
proc url_DescribeUser_402656566(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUser_402656565(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "TransferService.DescribeUser"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
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

proc call*(call_402656576: Call_DescribeUser_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DescribeUser_402656564; body: JsonNode): Recallable =
  ## describeUser
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ##   
                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var describeUser* = Call_DescribeUser_402656564(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeUser",
    validator: validate_DescribeUser_402656565, base: "/",
    makeUrl: url_DescribeUser_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSshPublicKey_402656579 = ref object of OpenApiRestCall_402656044
proc url_ImportSshPublicKey_402656581(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportSshPublicKey_402656580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "TransferService.ImportSshPublicKey"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
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

proc call*(call_402656591: Call_ImportSshPublicKey_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_ImportSshPublicKey_402656579; body: JsonNode): Recallable =
  ## importSshPublicKey
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var importSshPublicKey* = Call_ImportSshPublicKey_402656579(
    name: "importSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ImportSshPublicKey",
    validator: validate_ImportSshPublicKey_402656580, base: "/",
    makeUrl: url_ImportSshPublicKey_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServers_402656594 = ref object of OpenApiRestCall_402656044
proc url_ListServers_402656596(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServers_402656595(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656597 = query.getOrDefault("MaxResults")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "MaxResults", valid_402656597
  var valid_402656598 = query.getOrDefault("NextToken")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "NextToken", valid_402656598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656599 = header.getOrDefault("X-Amz-Target")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true, default = newJString(
      "TransferService.ListServers"))
  if valid_402656599 != nil:
    section.add "X-Amz-Target", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Security-Token", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Signature")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Signature", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Algorithm", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Date")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Date", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Credential")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Credential", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656606
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

proc call*(call_402656608: Call_ListServers_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
                                                                                         ## 
  let valid = call_402656608.validator(path, query, header, formData, body, _)
  let scheme = call_402656608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656608.makeUrl(scheme.get, call_402656608.host, call_402656608.base,
                                   call_402656608.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656608, uri, valid, _)

proc call*(call_402656609: Call_ListServers_402656594; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServers
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
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
  var query_402656610 = newJObject()
  var body_402656611 = newJObject()
  add(query_402656610, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656611 = body
  add(query_402656610, "NextToken", newJString(NextToken))
  result = call_402656609.call(nil, query_402656610, nil, nil, body_402656611)

var listServers* = Call_ListServers_402656594(name: "listServers",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListServers",
    validator: validate_ListServers_402656595, base: "/",
    makeUrl: url_ListServers_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656612 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656614(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656615 = query.getOrDefault("MaxResults")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "MaxResults", valid_402656615
  var valid_402656616 = query.getOrDefault("NextToken")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "NextToken", valid_402656616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656617 = header.getOrDefault("X-Amz-Target")
  valid_402656617 = validateParameter(valid_402656617, JString, required = true, default = newJString(
      "TransferService.ListTagsForResource"))
  if valid_402656617 != nil:
    section.add "X-Amz-Target", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Security-Token", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Signature")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Signature", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Algorithm", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Date")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Date", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Credential")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Credential", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656624
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

proc call*(call_402656626: Call_ListTagsForResource_402656612;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
                                                                                         ## 
  let valid = call_402656626.validator(path, query, header, formData, body, _)
  let scheme = call_402656626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656626.makeUrl(scheme.get, call_402656626.host, call_402656626.base,
                                   call_402656626.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656626, uri, valid, _)

proc call*(call_402656627: Call_ListTagsForResource_402656612; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
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
  var query_402656628 = newJObject()
  var body_402656629 = newJObject()
  add(query_402656628, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656629 = body
  add(query_402656628, "NextToken", newJString(NextToken))
  result = call_402656627.call(nil, query_402656628, nil, nil, body_402656629)

var listTagsForResource* = Call_ListTagsForResource_402656612(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListTagsForResource",
    validator: validate_ListTagsForResource_402656613, base: "/",
    makeUrl: url_ListTagsForResource_402656614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_402656630 = ref object of OpenApiRestCall_402656044
proc url_ListUsers_402656632(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_402656631(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656633 = query.getOrDefault("MaxResults")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "MaxResults", valid_402656633
  var valid_402656634 = query.getOrDefault("NextToken")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "NextToken", valid_402656634
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656635 = header.getOrDefault("X-Amz-Target")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true, default = newJString(
      "TransferService.ListUsers"))
  if valid_402656635 != nil:
    section.add "X-Amz-Target", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Security-Token", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Signature")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Signature", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Algorithm", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Date")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Date", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Credential")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Credential", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656642
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

proc call*(call_402656644: Call_ListUsers_402656630; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
                                                                                         ## 
  let valid = call_402656644.validator(path, query, header, formData, body, _)
  let scheme = call_402656644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656644.makeUrl(scheme.get, call_402656644.host, call_402656644.base,
                                   call_402656644.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656644, uri, valid, _)

proc call*(call_402656645: Call_ListUsers_402656630; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
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
  var query_402656646 = newJObject()
  var body_402656647 = newJObject()
  add(query_402656646, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656647 = body
  add(query_402656646, "NextToken", newJString(NextToken))
  result = call_402656645.call(nil, query_402656646, nil, nil, body_402656647)

var listUsers* = Call_ListUsers_402656630(name: "listUsers",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListUsers",
    validator: validate_ListUsers_402656631, base: "/", makeUrl: url_ListUsers_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartServer_402656648 = ref object of OpenApiRestCall_402656044
proc url_StartServer_402656650(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartServer_402656649(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656651 = header.getOrDefault("X-Amz-Target")
  valid_402656651 = validateParameter(valid_402656651, JString, required = true, default = newJString(
      "TransferService.StartServer"))
  if valid_402656651 != nil:
    section.add "X-Amz-Target", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Security-Token", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Signature")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Signature", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Algorithm", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Date")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Date", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Credential")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Credential", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656658
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

proc call*(call_402656660: Call_StartServer_402656648; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
                                                                                         ## 
  let valid = call_402656660.validator(path, query, header, formData, body, _)
  let scheme = call_402656660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656660.makeUrl(scheme.get, call_402656660.host, call_402656660.base,
                                   call_402656660.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656660, uri, valid, _)

proc call*(call_402656661: Call_StartServer_402656648; body: JsonNode): Recallable =
  ## startServer
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656662 = newJObject()
  if body != nil:
    body_402656662 = body
  result = call_402656661.call(nil, nil, nil, nil, body_402656662)

var startServer* = Call_StartServer_402656648(name: "startServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.StartServer",
    validator: validate_StartServer_402656649, base: "/",
    makeUrl: url_StartServer_402656650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopServer_402656663 = ref object of OpenApiRestCall_402656044
proc url_StopServer_402656665(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopServer_402656664(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656666 = header.getOrDefault("X-Amz-Target")
  valid_402656666 = validateParameter(valid_402656666, JString, required = true, default = newJString(
      "TransferService.StopServer"))
  if valid_402656666 != nil:
    section.add "X-Amz-Target", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Security-Token", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Signature")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Signature", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Algorithm", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Date")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Date", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Credential")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Credential", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656673
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

proc call*(call_402656675: Call_StopServer_402656663; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_StopServer_402656663; body: JsonNode): Recallable =
  ## stopServer
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656677 = newJObject()
  if body != nil:
    body_402656677 = body
  result = call_402656676.call(nil, nil, nil, nil, body_402656677)

var stopServer* = Call_StopServer_402656663(name: "stopServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.StopServer",
    validator: validate_StopServer_402656664, base: "/",
    makeUrl: url_StopServer_402656665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656678 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656680(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656679(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656681 = header.getOrDefault("X-Amz-Target")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true, default = newJString(
      "TransferService.TagResource"))
  if valid_402656681 != nil:
    section.add "X-Amz-Target", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
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

proc call*(call_402656690: Call_TagResource_402656678; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
                                                                                         ## 
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_TagResource_402656678; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ##   
                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656692 = newJObject()
  if body != nil:
    body_402656692 = body
  result = call_402656691.call(nil, nil, nil, nil, body_402656692)

var tagResource* = Call_TagResource_402656678(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TagResource",
    validator: validate_TagResource_402656679, base: "/",
    makeUrl: url_TagResource_402656680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestIdentityProvider_402656693 = ref object of OpenApiRestCall_402656044
proc url_TestIdentityProvider_402656695(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestIdentityProvider_402656694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656696 = header.getOrDefault("X-Amz-Target")
  valid_402656696 = validateParameter(valid_402656696, JString, required = true, default = newJString(
      "TransferService.TestIdentityProvider"))
  if valid_402656696 != nil:
    section.add "X-Amz-Target", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Security-Token", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Signature")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Signature", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Algorithm", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Date")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Date", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Credential")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Credential", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656703
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

proc call*(call_402656705: Call_TestIdentityProvider_402656693;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
                                                                                         ## 
  let valid = call_402656705.validator(path, query, header, formData, body, _)
  let scheme = call_402656705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656705.makeUrl(scheme.get, call_402656705.host, call_402656705.base,
                                   call_402656705.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656705, uri, valid, _)

proc call*(call_402656706: Call_TestIdentityProvider_402656693; body: JsonNode): Recallable =
  ## testIdentityProvider
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656707 = newJObject()
  if body != nil:
    body_402656707 = body
  result = call_402656706.call(nil, nil, nil, nil, body_402656707)

var testIdentityProvider* = Call_TestIdentityProvider_402656693(
    name: "testIdentityProvider", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TestIdentityProvider",
    validator: validate_TestIdentityProvider_402656694, base: "/",
    makeUrl: url_TestIdentityProvider_402656695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656708 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656710(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656709(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656711 = header.getOrDefault("X-Amz-Target")
  valid_402656711 = validateParameter(valid_402656711, JString, required = true, default = newJString(
      "TransferService.UntagResource"))
  if valid_402656711 != nil:
    section.add "X-Amz-Target", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Security-Token", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Signature")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Signature", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Algorithm", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Date")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Date", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Credential")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Credential", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656718
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

proc call*(call_402656720: Call_UntagResource_402656708; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
                                                                                         ## 
  let valid = call_402656720.validator(path, query, header, formData, body, _)
  let scheme = call_402656720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656720.makeUrl(scheme.get, call_402656720.host, call_402656720.base,
                                   call_402656720.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656720, uri, valid, _)

proc call*(call_402656721: Call_UntagResource_402656708; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ##   
                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656722 = newJObject()
  if body != nil:
    body_402656722 = body
  result = call_402656721.call(nil, nil, nil, nil, body_402656722)

var untagResource* = Call_UntagResource_402656708(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UntagResource",
    validator: validate_UntagResource_402656709, base: "/",
    makeUrl: url_UntagResource_402656710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_402656723 = ref object of OpenApiRestCall_402656044
proc url_UpdateServer_402656725(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServer_402656724(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656726 = header.getOrDefault("X-Amz-Target")
  valid_402656726 = validateParameter(valid_402656726, JString, required = true, default = newJString(
      "TransferService.UpdateServer"))
  if valid_402656726 != nil:
    section.add "X-Amz-Target", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Security-Token", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Signature")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Signature", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Algorithm", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Date")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Date", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Credential")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Credential", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656733
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

proc call*(call_402656735: Call_UpdateServer_402656723; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
                                                                                         ## 
  let valid = call_402656735.validator(path, query, header, formData, body, _)
  let scheme = call_402656735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656735.makeUrl(scheme.get, call_402656735.host, call_402656735.base,
                                   call_402656735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656735, uri, valid, _)

proc call*(call_402656736: Call_UpdateServer_402656723; body: JsonNode): Recallable =
  ## updateServer
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ##   
                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656737 = newJObject()
  if body != nil:
    body_402656737 = body
  result = call_402656736.call(nil, nil, nil, nil, body_402656737)

var updateServer* = Call_UpdateServer_402656723(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateServer",
    validator: validate_UpdateServer_402656724, base: "/",
    makeUrl: url_UpdateServer_402656725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_402656738 = ref object of OpenApiRestCall_402656044
proc url_UpdateUser_402656740(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUser_402656739(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656741 = header.getOrDefault("X-Amz-Target")
  valid_402656741 = validateParameter(valid_402656741, JString, required = true, default = newJString(
      "TransferService.UpdateUser"))
  if valid_402656741 != nil:
    section.add "X-Amz-Target", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Security-Token", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Signature")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Signature", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Algorithm", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Date")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Date", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Credential")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Credential", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656748
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

proc call*(call_402656750: Call_UpdateUser_402656738; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
                                                                                         ## 
  let valid = call_402656750.validator(path, query, header, formData, body, _)
  let scheme = call_402656750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656750.makeUrl(scheme.get, call_402656750.host, call_402656750.base,
                                   call_402656750.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656750, uri, valid, _)

proc call*(call_402656751: Call_UpdateUser_402656738; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ##   
                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656752 = newJObject()
  if body != nil:
    body_402656752 = body
  result = call_402656751.call(nil, nil, nil, nil, body_402656752)

var updateUser* = Call_UpdateUser_402656738(name: "updateUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateUser",
    validator: validate_UpdateUser_402656739, base: "/",
    makeUrl: url_UpdateUser_402656740, schemes: {Scheme.Https, Scheme.Http})
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