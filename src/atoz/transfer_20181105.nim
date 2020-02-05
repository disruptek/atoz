
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "transfer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "transfer.ap-southeast-1.amazonaws.com",
                           "us-west-2": "transfer.us-west-2.amazonaws.com",
                           "eu-west-2": "transfer.eu-west-2.amazonaws.com", "ap-northeast-3": "transfer.ap-northeast-3.amazonaws.com", "eu-central-1": "transfer.eu-central-1.amazonaws.com",
                           "us-east-2": "transfer.us-east-2.amazonaws.com",
                           "us-east-1": "transfer.us-east-1.amazonaws.com", "cn-northwest-1": "transfer.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "transfer.ap-south-1.amazonaws.com",
                           "eu-north-1": "transfer.eu-north-1.amazonaws.com", "ap-northeast-2": "transfer.ap-northeast-2.amazonaws.com",
                           "us-west-1": "transfer.us-west-1.amazonaws.com", "us-gov-east-1": "transfer.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "transfer.eu-west-3.amazonaws.com", "cn-north-1": "transfer.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "transfer.sa-east-1.amazonaws.com",
                           "eu-west-1": "transfer.eu-west-1.amazonaws.com", "us-gov-west-1": "transfer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "transfer.ap-southeast-2.amazonaws.com", "ca-central-1": "transfer.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateServer_612996 = ref object of OpenApiRestCall_612658
proc url_CreateServer_612998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateServer_612997(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "TransferService.CreateServer"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_CreateServer_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_CreateServer_612996; body: JsonNode): Recallable =
  ## createServer
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var createServer* = Call_CreateServer_612996(name: "createServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateServer",
    validator: validate_CreateServer_612997, base: "/", url: url_CreateServer_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_613265 = ref object of OpenApiRestCall_612658
proc url_CreateUser_613267(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_613266(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "TransferService.CreateUser"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_CreateUser_613265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CreateUser_613265; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var createUser* = Call_CreateUser_613265(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.CreateUser",
                                      validator: validate_CreateUser_613266,
                                      base: "/", url: url_CreateUser_613267,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_613280 = ref object of OpenApiRestCall_612658
proc url_DeleteServer_613282(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServer_613281(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "TransferService.DeleteServer"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_DeleteServer_613280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_DeleteServer_613280; body: JsonNode): Recallable =
  ## deleteServer
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var deleteServer* = Call_DeleteServer_613280(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteServer",
    validator: validate_DeleteServer_613281, base: "/", url: url_DeleteServer_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSshPublicKey_613295 = ref object of OpenApiRestCall_612658
proc url_DeleteSshPublicKey_613297(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSshPublicKey_613296(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "TransferService.DeleteSshPublicKey"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_DeleteSshPublicKey_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_DeleteSshPublicKey_613295; body: JsonNode): Recallable =
  ## deleteSshPublicKey
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var deleteSshPublicKey* = Call_DeleteSshPublicKey_613295(
    name: "deleteSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteSshPublicKey",
    validator: validate_DeleteSshPublicKey_613296, base: "/",
    url: url_DeleteSshPublicKey_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_613310 = ref object of OpenApiRestCall_612658
proc url_DeleteUser_613312(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_613311(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "TransferService.DeleteUser"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_DeleteUser_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_DeleteUser_613310; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var deleteUser* = Call_DeleteUser_613310(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.DeleteUser",
                                      validator: validate_DeleteUser_613311,
                                      base: "/", url: url_DeleteUser_613312,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServer_613325 = ref object of OpenApiRestCall_612658
proc url_DescribeServer_613327(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServer_613326(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "TransferService.DescribeServer"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DescribeServer_613325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties. When you set <code>EndpointType</code> to VPC, the response will contain the <code>EndpointDetails</code>.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DescribeServer_613325; body: JsonNode): Recallable =
  ## describeServer
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties. When you set <code>EndpointType</code> to VPC, the response will contain the <code>EndpointDetails</code>.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var describeServer* = Call_DescribeServer_613325(name: "describeServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeServer",
    validator: validate_DescribeServer_613326, base: "/", url: url_DescribeServer_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_613340 = ref object of OpenApiRestCall_612658
proc url_DescribeUser_613342(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_613341(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "TransferService.DescribeUser"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DescribeUser_613340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DescribeUser_613340; body: JsonNode): Recallable =
  ## describeUser
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var describeUser* = Call_DescribeUser_613340(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeUser",
    validator: validate_DescribeUser_613341, base: "/", url: url_DescribeUser_613342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSshPublicKey_613355 = ref object of OpenApiRestCall_612658
proc url_ImportSshPublicKey_613357(protocol: Scheme; host: string; base: string;
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

proc validate_ImportSshPublicKey_613356(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "TransferService.ImportSshPublicKey"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_ImportSshPublicKey_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_ImportSshPublicKey_613355; body: JsonNode): Recallable =
  ## importSshPublicKey
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var importSshPublicKey* = Call_ImportSshPublicKey_613355(
    name: "importSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ImportSshPublicKey",
    validator: validate_ImportSshPublicKey_613356, base: "/",
    url: url_ImportSshPublicKey_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServers_613370 = ref object of OpenApiRestCall_612658
proc url_ListServers_613372(protocol: Scheme; host: string; base: string;
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

proc validate_ListServers_613371(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613373 = query.getOrDefault("MaxResults")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "MaxResults", valid_613373
  var valid_613374 = query.getOrDefault("NextToken")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "NextToken", valid_613374
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613375 = header.getOrDefault("X-Amz-Target")
  valid_613375 = validateParameter(valid_613375, JString, required = true, default = newJString(
      "TransferService.ListServers"))
  if valid_613375 != nil:
    section.add "X-Amz-Target", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Signature")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Signature", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Content-Sha256", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Date")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Date", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Credential")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Credential", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Security-Token")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Security-Token", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Algorithm")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Algorithm", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-SignedHeaders", valid_613382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613384: Call_ListServers_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ## 
  let valid = call_613384.validator(path, query, header, formData, body)
  let scheme = call_613384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613384.url(scheme.get, call_613384.host, call_613384.base,
                         call_613384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613384, url, valid)

proc call*(call_613385: Call_ListServers_613370; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServers
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613386 = newJObject()
  var body_613387 = newJObject()
  add(query_613386, "MaxResults", newJString(MaxResults))
  add(query_613386, "NextToken", newJString(NextToken))
  if body != nil:
    body_613387 = body
  result = call_613385.call(nil, query_613386, nil, nil, body_613387)

var listServers* = Call_ListServers_613370(name: "listServers",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListServers",
                                        validator: validate_ListServers_613371,
                                        base: "/", url: url_ListServers_613372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613389 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613391(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613390(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_613392 = query.getOrDefault("MaxResults")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "MaxResults", valid_613392
  var valid_613393 = query.getOrDefault("NextToken")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "NextToken", valid_613393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613394 = header.getOrDefault("X-Amz-Target")
  valid_613394 = validateParameter(valid_613394, JString, required = true, default = newJString(
      "TransferService.ListTagsForResource"))
  if valid_613394 != nil:
    section.add "X-Amz-Target", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Signature")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Signature", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Content-Sha256", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Date")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Date", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Credential")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Credential", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Security-Token")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Security-Token", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Algorithm")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Algorithm", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-SignedHeaders", valid_613401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613403: Call_ListTagsForResource_613389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ## 
  let valid = call_613403.validator(path, query, header, formData, body)
  let scheme = call_613403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613403.url(scheme.get, call_613403.host, call_613403.base,
                         call_613403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613403, url, valid)

proc call*(call_613404: Call_ListTagsForResource_613389; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613405 = newJObject()
  var body_613406 = newJObject()
  add(query_613405, "MaxResults", newJString(MaxResults))
  add(query_613405, "NextToken", newJString(NextToken))
  if body != nil:
    body_613406 = body
  result = call_613404.call(nil, query_613405, nil, nil, body_613406)

var listTagsForResource* = Call_ListTagsForResource_613389(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListTagsForResource",
    validator: validate_ListTagsForResource_613390, base: "/",
    url: url_ListTagsForResource_613391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_613407 = ref object of OpenApiRestCall_612658
proc url_ListUsers_613409(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_613408(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613410 = query.getOrDefault("MaxResults")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "MaxResults", valid_613410
  var valid_613411 = query.getOrDefault("NextToken")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "NextToken", valid_613411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613412 = header.getOrDefault("X-Amz-Target")
  valid_613412 = validateParameter(valid_613412, JString, required = true, default = newJString(
      "TransferService.ListUsers"))
  if valid_613412 != nil:
    section.add "X-Amz-Target", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Signature")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Signature", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Content-Sha256", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Date")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Date", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Credential")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Credential", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Security-Token")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Security-Token", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Algorithm")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Algorithm", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-SignedHeaders", valid_613419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613421: Call_ListUsers_613407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ## 
  let valid = call_613421.validator(path, query, header, formData, body)
  let scheme = call_613421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613421.url(scheme.get, call_613421.host, call_613421.base,
                         call_613421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613421, url, valid)

proc call*(call_613422: Call_ListUsers_613407; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613423 = newJObject()
  var body_613424 = newJObject()
  add(query_613423, "MaxResults", newJString(MaxResults))
  add(query_613423, "NextToken", newJString(NextToken))
  if body != nil:
    body_613424 = body
  result = call_613422.call(nil, query_613423, nil, nil, body_613424)

var listUsers* = Call_ListUsers_613407(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListUsers",
                                    validator: validate_ListUsers_613408,
                                    base: "/", url: url_ListUsers_613409,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartServer_613425 = ref object of OpenApiRestCall_612658
proc url_StartServer_613427(protocol: Scheme; host: string; base: string;
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

proc validate_StartServer_613426(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613428 = header.getOrDefault("X-Amz-Target")
  valid_613428 = validateParameter(valid_613428, JString, required = true, default = newJString(
      "TransferService.StartServer"))
  if valid_613428 != nil:
    section.add "X-Amz-Target", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Signature")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Signature", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Content-Sha256", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Date")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Date", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Credential")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Credential", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Security-Token")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Security-Token", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Algorithm")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Algorithm", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-SignedHeaders", valid_613435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613437: Call_StartServer_613425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_613437.validator(path, query, header, formData, body)
  let scheme = call_613437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613437.url(scheme.get, call_613437.host, call_613437.base,
                         call_613437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613437, url, valid)

proc call*(call_613438: Call_StartServer_613425; body: JsonNode): Recallable =
  ## startServer
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_613439 = newJObject()
  if body != nil:
    body_613439 = body
  result = call_613438.call(nil, nil, nil, nil, body_613439)

var startServer* = Call_StartServer_613425(name: "startServer",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StartServer",
                                        validator: validate_StartServer_613426,
                                        base: "/", url: url_StartServer_613427,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopServer_613440 = ref object of OpenApiRestCall_612658
proc url_StopServer_613442(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopServer_613441(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613443 = header.getOrDefault("X-Amz-Target")
  valid_613443 = validateParameter(valid_613443, JString, required = true, default = newJString(
      "TransferService.StopServer"))
  if valid_613443 != nil:
    section.add "X-Amz-Target", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Signature")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Signature", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Content-Sha256", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Date")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Date", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Credential")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Credential", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Security-Token")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Security-Token", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Algorithm")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Algorithm", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-SignedHeaders", valid_613450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_StopServer_613440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_StopServer_613440; body: JsonNode): Recallable =
  ## stopServer
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_613454 = newJObject()
  if body != nil:
    body_613454 = body
  result = call_613453.call(nil, nil, nil, nil, body_613454)

var stopServer* = Call_StopServer_613440(name: "stopServer",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StopServer",
                                      validator: validate_StopServer_613441,
                                      base: "/", url: url_StopServer_613442,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613455 = ref object of OpenApiRestCall_612658
proc url_TagResource_613457(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613456(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613458 = header.getOrDefault("X-Amz-Target")
  valid_613458 = validateParameter(valid_613458, JString, required = true, default = newJString(
      "TransferService.TagResource"))
  if valid_613458 != nil:
    section.add "X-Amz-Target", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Signature")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Signature", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Content-Sha256", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Date")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Date", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Credential")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Credential", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Security-Token")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Security-Token", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Algorithm")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Algorithm", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-SignedHeaders", valid_613465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613467: Call_TagResource_613455; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ## 
  let valid = call_613467.validator(path, query, header, formData, body)
  let scheme = call_613467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613467.url(scheme.get, call_613467.host, call_613467.base,
                         call_613467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613467, url, valid)

proc call*(call_613468: Call_TagResource_613455; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ##   body: JObject (required)
  var body_613469 = newJObject()
  if body != nil:
    body_613469 = body
  result = call_613468.call(nil, nil, nil, nil, body_613469)

var tagResource* = Call_TagResource_613455(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.TagResource",
                                        validator: validate_TagResource_613456,
                                        base: "/", url: url_TagResource_613457,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestIdentityProvider_613470 = ref object of OpenApiRestCall_612658
proc url_TestIdentityProvider_613472(protocol: Scheme; host: string; base: string;
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

proc validate_TestIdentityProvider_613471(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613473 = header.getOrDefault("X-Amz-Target")
  valid_613473 = validateParameter(valid_613473, JString, required = true, default = newJString(
      "TransferService.TestIdentityProvider"))
  if valid_613473 != nil:
    section.add "X-Amz-Target", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Signature")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Signature", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Content-Sha256", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Date")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Date", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Credential")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Credential", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Security-Token")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Security-Token", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Algorithm")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Algorithm", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-SignedHeaders", valid_613480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613482: Call_TestIdentityProvider_613470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ## 
  let valid = call_613482.validator(path, query, header, formData, body)
  let scheme = call_613482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613482.url(scheme.get, call_613482.host, call_613482.base,
                         call_613482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613482, url, valid)

proc call*(call_613483: Call_TestIdentityProvider_613470; body: JsonNode): Recallable =
  ## testIdentityProvider
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ##   body: JObject (required)
  var body_613484 = newJObject()
  if body != nil:
    body_613484 = body
  result = call_613483.call(nil, nil, nil, nil, body_613484)

var testIdentityProvider* = Call_TestIdentityProvider_613470(
    name: "testIdentityProvider", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TestIdentityProvider",
    validator: validate_TestIdentityProvider_613471, base: "/",
    url: url_TestIdentityProvider_613472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613485 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613487(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_613486(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613488 = header.getOrDefault("X-Amz-Target")
  valid_613488 = validateParameter(valid_613488, JString, required = true, default = newJString(
      "TransferService.UntagResource"))
  if valid_613488 != nil:
    section.add "X-Amz-Target", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Signature")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Signature", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Content-Sha256", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Date")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Date", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Credential")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Credential", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Security-Token")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Security-Token", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Algorithm")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Algorithm", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-SignedHeaders", valid_613495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613497: Call_UntagResource_613485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_613497.validator(path, query, header, formData, body)
  let scheme = call_613497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613497.url(scheme.get, call_613497.host, call_613497.base,
                         call_613497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613497, url, valid)

proc call*(call_613498: Call_UntagResource_613485; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_613499 = newJObject()
  if body != nil:
    body_613499 = body
  result = call_613498.call(nil, nil, nil, nil, body_613499)

var untagResource* = Call_UntagResource_613485(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UntagResource",
    validator: validate_UntagResource_613486, base: "/", url: url_UntagResource_613487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_613500 = ref object of OpenApiRestCall_612658
proc url_UpdateServer_613502(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServer_613501(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613503 = header.getOrDefault("X-Amz-Target")
  valid_613503 = validateParameter(valid_613503, JString, required = true, default = newJString(
      "TransferService.UpdateServer"))
  if valid_613503 != nil:
    section.add "X-Amz-Target", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Signature")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Signature", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Content-Sha256", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Date")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Date", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Credential")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Credential", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Security-Token")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Security-Token", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Algorithm")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Algorithm", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-SignedHeaders", valid_613510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613512: Call_UpdateServer_613500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ## 
  let valid = call_613512.validator(path, query, header, formData, body)
  let scheme = call_613512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613512.url(scheme.get, call_613512.host, call_613512.base,
                         call_613512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613512, url, valid)

proc call*(call_613513: Call_UpdateServer_613500; body: JsonNode): Recallable =
  ## updateServer
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ##   body: JObject (required)
  var body_613514 = newJObject()
  if body != nil:
    body_613514 = body
  result = call_613513.call(nil, nil, nil, nil, body_613514)

var updateServer* = Call_UpdateServer_613500(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateServer",
    validator: validate_UpdateServer_613501, base: "/", url: url_UpdateServer_613502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_613515 = ref object of OpenApiRestCall_612658
proc url_UpdateUser_613517(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUser_613516(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613518 = header.getOrDefault("X-Amz-Target")
  valid_613518 = validateParameter(valid_613518, JString, required = true, default = newJString(
      "TransferService.UpdateUser"))
  if valid_613518 != nil:
    section.add "X-Amz-Target", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Signature")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Signature", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Content-Sha256", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Date")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Date", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Credential")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Credential", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Security-Token")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Security-Token", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Algorithm")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Algorithm", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-SignedHeaders", valid_613525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613527: Call_UpdateUser_613515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ## 
  let valid = call_613527.validator(path, query, header, formData, body)
  let scheme = call_613527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613527.url(scheme.get, call_613527.host, call_613527.base,
                         call_613527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613527, url, valid)

proc call*(call_613528: Call_UpdateUser_613515; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ##   body: JObject (required)
  var body_613529 = newJObject()
  if body != nil:
    body_613529 = body
  result = call_613528.call(nil, nil, nil, nil, body_613529)

var updateUser* = Call_UpdateUser_613515(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.UpdateUser",
                                      validator: validate_UpdateUser_613516,
                                      base: "/", url: url_UpdateUser_613517,
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
