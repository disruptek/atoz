
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateServer_602770 = ref object of OpenApiRestCall_602433
proc url_CreateServer_602772(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateServer_602771(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "TransferService.CreateServer"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_CreateServer_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_CreateServer_602770; body: JsonNode): Recallable =
  ## createServer
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var createServer* = Call_CreateServer_602770(name: "createServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateServer",
    validator: validate_CreateServer_602771, base: "/", url: url_CreateServer_602772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_603039 = ref object of OpenApiRestCall_602433
proc url_CreateUser_603041(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUser_603040(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "TransferService.CreateUser"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_CreateUser_603039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CreateUser_603039; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var createUser* = Call_CreateUser_603039(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.CreateUser",
                                      validator: validate_CreateUser_603040,
                                      base: "/", url: url_CreateUser_603041,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_603054 = ref object of OpenApiRestCall_602433
proc url_DeleteServer_603056(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteServer_603055(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "TransferService.DeleteServer"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_DeleteServer_603054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_DeleteServer_603054; body: JsonNode): Recallable =
  ## deleteServer
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var deleteServer* = Call_DeleteServer_603054(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteServer",
    validator: validate_DeleteServer_603055, base: "/", url: url_DeleteServer_603056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSshPublicKey_603069 = ref object of OpenApiRestCall_602433
proc url_DeleteSshPublicKey_603071(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSshPublicKey_603070(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "TransferService.DeleteSshPublicKey"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_DeleteSshPublicKey_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DeleteSshPublicKey_603069; body: JsonNode): Recallable =
  ## deleteSshPublicKey
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var deleteSshPublicKey* = Call_DeleteSshPublicKey_603069(
    name: "deleteSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteSshPublicKey",
    validator: validate_DeleteSshPublicKey_603070, base: "/",
    url: url_DeleteSshPublicKey_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_603084 = ref object of OpenApiRestCall_602433
proc url_DeleteUser_603086(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteUser_603085(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "TransferService.DeleteUser"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_DeleteUser_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_DeleteUser_603084; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var deleteUser* = Call_DeleteUser_603084(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.DeleteUser",
                                      validator: validate_DeleteUser_603085,
                                      base: "/", url: url_DeleteUser_603086,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServer_603099 = ref object of OpenApiRestCall_602433
proc url_DescribeServer_603101(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeServer_603100(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "TransferService.DescribeServer"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_DescribeServer_603099; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_DescribeServer_603099; body: JsonNode): Recallable =
  ## describeServer
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var describeServer* = Call_DescribeServer_603099(name: "describeServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeServer",
    validator: validate_DescribeServer_603100, base: "/", url: url_DescribeServer_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_603114 = ref object of OpenApiRestCall_602433
proc url_DescribeUser_603116(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeUser_603115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "TransferService.DescribeUser"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_DescribeUser_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_DescribeUser_603114; body: JsonNode): Recallable =
  ## describeUser
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var describeUser* = Call_DescribeUser_603114(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeUser",
    validator: validate_DescribeUser_603115, base: "/", url: url_DescribeUser_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSshPublicKey_603129 = ref object of OpenApiRestCall_602433
proc url_ImportSshPublicKey_603131(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportSshPublicKey_603130(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "TransferService.ImportSshPublicKey"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_ImportSshPublicKey_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_ImportSshPublicKey_603129; body: JsonNode): Recallable =
  ## importSshPublicKey
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var importSshPublicKey* = Call_ImportSshPublicKey_603129(
    name: "importSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ImportSshPublicKey",
    validator: validate_ImportSshPublicKey_603130, base: "/",
    url: url_ImportSshPublicKey_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServers_603144 = ref object of OpenApiRestCall_602433
proc url_ListServers_603146(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServers_603145(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603147 = query.getOrDefault("NextToken")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "NextToken", valid_603147
  var valid_603148 = query.getOrDefault("MaxResults")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "MaxResults", valid_603148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603149 = header.getOrDefault("X-Amz-Date")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Date", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Security-Token")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Security-Token", valid_603150
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603151 = header.getOrDefault("X-Amz-Target")
  valid_603151 = validateParameter(valid_603151, JString, required = true, default = newJString(
      "TransferService.ListServers"))
  if valid_603151 != nil:
    section.add "X-Amz-Target", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Content-Sha256", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Signature")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Signature", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-SignedHeaders", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Credential")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Credential", valid_603156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_ListServers_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"))
  result = hook(call_603158, url, valid)

proc call*(call_603159: Call_ListServers_603144; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listServers
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603160 = newJObject()
  var body_603161 = newJObject()
  add(query_603160, "NextToken", newJString(NextToken))
  if body != nil:
    body_603161 = body
  add(query_603160, "MaxResults", newJString(MaxResults))
  result = call_603159.call(nil, query_603160, nil, nil, body_603161)

var listServers* = Call_ListServers_603144(name: "listServers",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListServers",
                                        validator: validate_ListServers_603145,
                                        base: "/", url: url_ListServers_603146,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603163 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603165(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_603164(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603166 = query.getOrDefault("NextToken")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "NextToken", valid_603166
  var valid_603167 = query.getOrDefault("MaxResults")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "MaxResults", valid_603167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603168 = header.getOrDefault("X-Amz-Date")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Date", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Security-Token")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Security-Token", valid_603169
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603170 = header.getOrDefault("X-Amz-Target")
  valid_603170 = validateParameter(valid_603170, JString, required = true, default = newJString(
      "TransferService.ListTagsForResource"))
  if valid_603170 != nil:
    section.add "X-Amz-Target", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Algorithm")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Algorithm", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Signature")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Signature", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Credential")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Credential", valid_603175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603177: Call_ListTagsForResource_603163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ## 
  let valid = call_603177.validator(path, query, header, formData, body)
  let scheme = call_603177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603177.url(scheme.get, call_603177.host, call_603177.base,
                         call_603177.route, valid.getOrDefault("path"))
  result = hook(call_603177, url, valid)

proc call*(call_603178: Call_ListTagsForResource_603163; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603179 = newJObject()
  var body_603180 = newJObject()
  add(query_603179, "NextToken", newJString(NextToken))
  if body != nil:
    body_603180 = body
  add(query_603179, "MaxResults", newJString(MaxResults))
  result = call_603178.call(nil, query_603179, nil, nil, body_603180)

var listTagsForResource* = Call_ListTagsForResource_603163(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListTagsForResource",
    validator: validate_ListTagsForResource_603164, base: "/",
    url: url_ListTagsForResource_603165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_603181 = ref object of OpenApiRestCall_602433
proc url_ListUsers_603183(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListUsers_603182(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603184 = query.getOrDefault("NextToken")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "NextToken", valid_603184
  var valid_603185 = query.getOrDefault("MaxResults")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "MaxResults", valid_603185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603186 = header.getOrDefault("X-Amz-Date")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Date", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603188 = header.getOrDefault("X-Amz-Target")
  valid_603188 = validateParameter(valid_603188, JString, required = true, default = newJString(
      "TransferService.ListUsers"))
  if valid_603188 != nil:
    section.add "X-Amz-Target", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Content-Sha256", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Signature")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Signature", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-SignedHeaders", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Credential")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Credential", valid_603193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603195: Call_ListUsers_603181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ## 
  let valid = call_603195.validator(path, query, header, formData, body)
  let scheme = call_603195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603195.url(scheme.get, call_603195.host, call_603195.base,
                         call_603195.route, valid.getOrDefault("path"))
  result = hook(call_603195, url, valid)

proc call*(call_603196: Call_ListUsers_603181; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUsers
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603197 = newJObject()
  var body_603198 = newJObject()
  add(query_603197, "NextToken", newJString(NextToken))
  if body != nil:
    body_603198 = body
  add(query_603197, "MaxResults", newJString(MaxResults))
  result = call_603196.call(nil, query_603197, nil, nil, body_603198)

var listUsers* = Call_ListUsers_603181(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListUsers",
                                    validator: validate_ListUsers_603182,
                                    base: "/", url: url_ListUsers_603183,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartServer_603199 = ref object of OpenApiRestCall_602433
proc url_StartServer_603201(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartServer_603200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Security-Token")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Security-Token", valid_603203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603204 = header.getOrDefault("X-Amz-Target")
  valid_603204 = validateParameter(valid_603204, JString, required = true, default = newJString(
      "TransferService.StartServer"))
  if valid_603204 != nil:
    section.add "X-Amz-Target", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Algorithm")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Algorithm", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Signature")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Signature", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-SignedHeaders", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Credential")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Credential", valid_603209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603211: Call_StartServer_603199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_603211.validator(path, query, header, formData, body)
  let scheme = call_603211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603211.url(scheme.get, call_603211.host, call_603211.base,
                         call_603211.route, valid.getOrDefault("path"))
  result = hook(call_603211, url, valid)

proc call*(call_603212: Call_StartServer_603199; body: JsonNode): Recallable =
  ## startServer
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_603213 = newJObject()
  if body != nil:
    body_603213 = body
  result = call_603212.call(nil, nil, nil, nil, body_603213)

var startServer* = Call_StartServer_603199(name: "startServer",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StartServer",
                                        validator: validate_StartServer_603200,
                                        base: "/", url: url_StartServer_603201,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopServer_603214 = ref object of OpenApiRestCall_602433
proc url_StopServer_603216(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopServer_603215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Security-Token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Security-Token", valid_603218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603219 = header.getOrDefault("X-Amz-Target")
  valid_603219 = validateParameter(valid_603219, JString, required = true, default = newJString(
      "TransferService.StopServer"))
  if valid_603219 != nil:
    section.add "X-Amz-Target", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Content-Sha256", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Algorithm")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Algorithm", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Signature")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Signature", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-SignedHeaders", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Credential")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Credential", valid_603224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_StopServer_603214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_StopServer_603214; body: JsonNode): Recallable =
  ## stopServer
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_603228 = newJObject()
  if body != nil:
    body_603228 = body
  result = call_603227.call(nil, nil, nil, nil, body_603228)

var stopServer* = Call_StopServer_603214(name: "stopServer",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StopServer",
                                      validator: validate_StopServer_603215,
                                      base: "/", url: url_StopServer_603216,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603229 = ref object of OpenApiRestCall_602433
proc url_TagResource_603231(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_603230(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Security-Token")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Security-Token", valid_603233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603234 = header.getOrDefault("X-Amz-Target")
  valid_603234 = validateParameter(valid_603234, JString, required = true, default = newJString(
      "TransferService.TagResource"))
  if valid_603234 != nil:
    section.add "X-Amz-Target", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Content-Sha256", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Algorithm")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Algorithm", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Signature")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Signature", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-SignedHeaders", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Credential")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Credential", valid_603239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603241: Call_TagResource_603229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ## 
  let valid = call_603241.validator(path, query, header, formData, body)
  let scheme = call_603241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603241.url(scheme.get, call_603241.host, call_603241.base,
                         call_603241.route, valid.getOrDefault("path"))
  result = hook(call_603241, url, valid)

proc call*(call_603242: Call_TagResource_603229; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ##   body: JObject (required)
  var body_603243 = newJObject()
  if body != nil:
    body_603243 = body
  result = call_603242.call(nil, nil, nil, nil, body_603243)

var tagResource* = Call_TagResource_603229(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.TagResource",
                                        validator: validate_TagResource_603230,
                                        base: "/", url: url_TagResource_603231,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestIdentityProvider_603244 = ref object of OpenApiRestCall_602433
proc url_TestIdentityProvider_603246(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestIdentityProvider_603245(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Security-Token")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Security-Token", valid_603248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603249 = header.getOrDefault("X-Amz-Target")
  valid_603249 = validateParameter(valid_603249, JString, required = true, default = newJString(
      "TransferService.TestIdentityProvider"))
  if valid_603249 != nil:
    section.add "X-Amz-Target", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Content-Sha256", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Algorithm")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Algorithm", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Signature")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Signature", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-SignedHeaders", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Credential")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Credential", valid_603254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603256: Call_TestIdentityProvider_603244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ## 
  let valid = call_603256.validator(path, query, header, formData, body)
  let scheme = call_603256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603256.url(scheme.get, call_603256.host, call_603256.base,
                         call_603256.route, valid.getOrDefault("path"))
  result = hook(call_603256, url, valid)

proc call*(call_603257: Call_TestIdentityProvider_603244; body: JsonNode): Recallable =
  ## testIdentityProvider
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ##   body: JObject (required)
  var body_603258 = newJObject()
  if body != nil:
    body_603258 = body
  result = call_603257.call(nil, nil, nil, nil, body_603258)

var testIdentityProvider* = Call_TestIdentityProvider_603244(
    name: "testIdentityProvider", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TestIdentityProvider",
    validator: validate_TestIdentityProvider_603245, base: "/",
    url: url_TestIdentityProvider_603246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603259 = ref object of OpenApiRestCall_602433
proc url_UntagResource_603261(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_603260(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603262 = header.getOrDefault("X-Amz-Date")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Date", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Security-Token")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Security-Token", valid_603263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603264 = header.getOrDefault("X-Amz-Target")
  valid_603264 = validateParameter(valid_603264, JString, required = true, default = newJString(
      "TransferService.UntagResource"))
  if valid_603264 != nil:
    section.add "X-Amz-Target", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Content-Sha256", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Algorithm")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Algorithm", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Signature")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Signature", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-SignedHeaders", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Credential")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Credential", valid_603269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603271: Call_UntagResource_603259; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_603271.validator(path, query, header, formData, body)
  let scheme = call_603271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603271.url(scheme.get, call_603271.host, call_603271.base,
                         call_603271.route, valid.getOrDefault("path"))
  result = hook(call_603271, url, valid)

proc call*(call_603272: Call_UntagResource_603259; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_603273 = newJObject()
  if body != nil:
    body_603273 = body
  result = call_603272.call(nil, nil, nil, nil, body_603273)

var untagResource* = Call_UntagResource_603259(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UntagResource",
    validator: validate_UntagResource_603260, base: "/", url: url_UntagResource_603261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_603274 = ref object of OpenApiRestCall_602433
proc url_UpdateServer_603276(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServer_603275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603277 = header.getOrDefault("X-Amz-Date")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Date", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Security-Token")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Security-Token", valid_603278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603279 = header.getOrDefault("X-Amz-Target")
  valid_603279 = validateParameter(valid_603279, JString, required = true, default = newJString(
      "TransferService.UpdateServer"))
  if valid_603279 != nil:
    section.add "X-Amz-Target", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Algorithm")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Algorithm", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-SignedHeaders", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603286: Call_UpdateServer_603274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ## 
  let valid = call_603286.validator(path, query, header, formData, body)
  let scheme = call_603286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603286.url(scheme.get, call_603286.host, call_603286.base,
                         call_603286.route, valid.getOrDefault("path"))
  result = hook(call_603286, url, valid)

proc call*(call_603287: Call_UpdateServer_603274; body: JsonNode): Recallable =
  ## updateServer
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ##   body: JObject (required)
  var body_603288 = newJObject()
  if body != nil:
    body_603288 = body
  result = call_603287.call(nil, nil, nil, nil, body_603288)

var updateServer* = Call_UpdateServer_603274(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateServer",
    validator: validate_UpdateServer_603275, base: "/", url: url_UpdateServer_603276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_603289 = ref object of OpenApiRestCall_602433
proc url_UpdateUser_603291(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateUser_603290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603294 = header.getOrDefault("X-Amz-Target")
  valid_603294 = validateParameter(valid_603294, JString, required = true, default = newJString(
      "TransferService.UpdateUser"))
  if valid_603294 != nil:
    section.add "X-Amz-Target", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Content-Sha256", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Algorithm")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Algorithm", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Signature")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Signature", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-SignedHeaders", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Credential")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Credential", valid_603299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603301: Call_UpdateUser_603289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ## 
  let valid = call_603301.validator(path, query, header, formData, body)
  let scheme = call_603301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603301.url(scheme.get, call_603301.host, call_603301.base,
                         call_603301.route, valid.getOrDefault("path"))
  result = hook(call_603301, url, valid)

proc call*(call_603302: Call_UpdateUser_603289; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ##   body: JObject (required)
  var body_603303 = newJObject()
  if body != nil:
    body_603303 = body
  result = call_603302.call(nil, nil, nil, nil, body_603303)

var updateUser* = Call_UpdateUser_603289(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.UpdateUser",
                                      validator: validate_UpdateUser_603290,
                                      base: "/", url: url_UpdateUser_603291,
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
