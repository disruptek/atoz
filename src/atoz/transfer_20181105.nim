
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_591364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_591364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_591364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateServer_591703 = ref object of OpenApiRestCall_591364
proc url_CreateServer_591705(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateServer_591704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591830 = header.getOrDefault("X-Amz-Target")
  valid_591830 = validateParameter(valid_591830, JString, required = true, default = newJString(
      "TransferService.CreateServer"))
  if valid_591830 != nil:
    section.add "X-Amz-Target", valid_591830
  var valid_591831 = header.getOrDefault("X-Amz-Signature")
  valid_591831 = validateParameter(valid_591831, JString, required = false,
                                 default = nil)
  if valid_591831 != nil:
    section.add "X-Amz-Signature", valid_591831
  var valid_591832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591832 = validateParameter(valid_591832, JString, required = false,
                                 default = nil)
  if valid_591832 != nil:
    section.add "X-Amz-Content-Sha256", valid_591832
  var valid_591833 = header.getOrDefault("X-Amz-Date")
  valid_591833 = validateParameter(valid_591833, JString, required = false,
                                 default = nil)
  if valid_591833 != nil:
    section.add "X-Amz-Date", valid_591833
  var valid_591834 = header.getOrDefault("X-Amz-Credential")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "X-Amz-Credential", valid_591834
  var valid_591835 = header.getOrDefault("X-Amz-Security-Token")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "X-Amz-Security-Token", valid_591835
  var valid_591836 = header.getOrDefault("X-Amz-Algorithm")
  valid_591836 = validateParameter(valid_591836, JString, required = false,
                                 default = nil)
  if valid_591836 != nil:
    section.add "X-Amz-Algorithm", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-SignedHeaders", valid_591837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591861: Call_CreateServer_591703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ## 
  let valid = call_591861.validator(path, query, header, formData, body)
  let scheme = call_591861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591861.url(scheme.get, call_591861.host, call_591861.base,
                         call_591861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591861, url, valid)

proc call*(call_591932: Call_CreateServer_591703; body: JsonNode): Recallable =
  ## createServer
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ##   body: JObject (required)
  var body_591933 = newJObject()
  if body != nil:
    body_591933 = body
  result = call_591932.call(nil, nil, nil, nil, body_591933)

var createServer* = Call_CreateServer_591703(name: "createServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateServer",
    validator: validate_CreateServer_591704, base: "/", url: url_CreateServer_591705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_591972 = ref object of OpenApiRestCall_591364
proc url_CreateUser_591974(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUser_591973(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591975 = header.getOrDefault("X-Amz-Target")
  valid_591975 = validateParameter(valid_591975, JString, required = true, default = newJString(
      "TransferService.CreateUser"))
  if valid_591975 != nil:
    section.add "X-Amz-Target", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-Signature")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-Signature", valid_591976
  var valid_591977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591977 = validateParameter(valid_591977, JString, required = false,
                                 default = nil)
  if valid_591977 != nil:
    section.add "X-Amz-Content-Sha256", valid_591977
  var valid_591978 = header.getOrDefault("X-Amz-Date")
  valid_591978 = validateParameter(valid_591978, JString, required = false,
                                 default = nil)
  if valid_591978 != nil:
    section.add "X-Amz-Date", valid_591978
  var valid_591979 = header.getOrDefault("X-Amz-Credential")
  valid_591979 = validateParameter(valid_591979, JString, required = false,
                                 default = nil)
  if valid_591979 != nil:
    section.add "X-Amz-Credential", valid_591979
  var valid_591980 = header.getOrDefault("X-Amz-Security-Token")
  valid_591980 = validateParameter(valid_591980, JString, required = false,
                                 default = nil)
  if valid_591980 != nil:
    section.add "X-Amz-Security-Token", valid_591980
  var valid_591981 = header.getOrDefault("X-Amz-Algorithm")
  valid_591981 = validateParameter(valid_591981, JString, required = false,
                                 default = nil)
  if valid_591981 != nil:
    section.add "X-Amz-Algorithm", valid_591981
  var valid_591982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591982 = validateParameter(valid_591982, JString, required = false,
                                 default = nil)
  if valid_591982 != nil:
    section.add "X-Amz-SignedHeaders", valid_591982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591984: Call_CreateUser_591972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ## 
  let valid = call_591984.validator(path, query, header, formData, body)
  let scheme = call_591984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591984.url(scheme.get, call_591984.host, call_591984.base,
                         call_591984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591984, url, valid)

proc call*(call_591985: Call_CreateUser_591972; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ##   body: JObject (required)
  var body_591986 = newJObject()
  if body != nil:
    body_591986 = body
  result = call_591985.call(nil, nil, nil, nil, body_591986)

var createUser* = Call_CreateUser_591972(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.CreateUser",
                                      validator: validate_CreateUser_591973,
                                      base: "/", url: url_CreateUser_591974,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_591987 = ref object of OpenApiRestCall_591364
proc url_DeleteServer_591989(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteServer_591988(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591990 = header.getOrDefault("X-Amz-Target")
  valid_591990 = validateParameter(valid_591990, JString, required = true, default = newJString(
      "TransferService.DeleteServer"))
  if valid_591990 != nil:
    section.add "X-Amz-Target", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-Signature")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-Signature", valid_591991
  var valid_591992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591992 = validateParameter(valid_591992, JString, required = false,
                                 default = nil)
  if valid_591992 != nil:
    section.add "X-Amz-Content-Sha256", valid_591992
  var valid_591993 = header.getOrDefault("X-Amz-Date")
  valid_591993 = validateParameter(valid_591993, JString, required = false,
                                 default = nil)
  if valid_591993 != nil:
    section.add "X-Amz-Date", valid_591993
  var valid_591994 = header.getOrDefault("X-Amz-Credential")
  valid_591994 = validateParameter(valid_591994, JString, required = false,
                                 default = nil)
  if valid_591994 != nil:
    section.add "X-Amz-Credential", valid_591994
  var valid_591995 = header.getOrDefault("X-Amz-Security-Token")
  valid_591995 = validateParameter(valid_591995, JString, required = false,
                                 default = nil)
  if valid_591995 != nil:
    section.add "X-Amz-Security-Token", valid_591995
  var valid_591996 = header.getOrDefault("X-Amz-Algorithm")
  valid_591996 = validateParameter(valid_591996, JString, required = false,
                                 default = nil)
  if valid_591996 != nil:
    section.add "X-Amz-Algorithm", valid_591996
  var valid_591997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591997 = validateParameter(valid_591997, JString, required = false,
                                 default = nil)
  if valid_591997 != nil:
    section.add "X-Amz-SignedHeaders", valid_591997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591999: Call_DeleteServer_591987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ## 
  let valid = call_591999.validator(path, query, header, formData, body)
  let scheme = call_591999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591999.url(scheme.get, call_591999.host, call_591999.base,
                         call_591999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591999, url, valid)

proc call*(call_592000: Call_DeleteServer_591987; body: JsonNode): Recallable =
  ## deleteServer
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ##   body: JObject (required)
  var body_592001 = newJObject()
  if body != nil:
    body_592001 = body
  result = call_592000.call(nil, nil, nil, nil, body_592001)

var deleteServer* = Call_DeleteServer_591987(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteServer",
    validator: validate_DeleteServer_591988, base: "/", url: url_DeleteServer_591989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSshPublicKey_592002 = ref object of OpenApiRestCall_591364
proc url_DeleteSshPublicKey_592004(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSshPublicKey_592003(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592005 = header.getOrDefault("X-Amz-Target")
  valid_592005 = validateParameter(valid_592005, JString, required = true, default = newJString(
      "TransferService.DeleteSshPublicKey"))
  if valid_592005 != nil:
    section.add "X-Amz-Target", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-Signature")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-Signature", valid_592006
  var valid_592007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592007 = validateParameter(valid_592007, JString, required = false,
                                 default = nil)
  if valid_592007 != nil:
    section.add "X-Amz-Content-Sha256", valid_592007
  var valid_592008 = header.getOrDefault("X-Amz-Date")
  valid_592008 = validateParameter(valid_592008, JString, required = false,
                                 default = nil)
  if valid_592008 != nil:
    section.add "X-Amz-Date", valid_592008
  var valid_592009 = header.getOrDefault("X-Amz-Credential")
  valid_592009 = validateParameter(valid_592009, JString, required = false,
                                 default = nil)
  if valid_592009 != nil:
    section.add "X-Amz-Credential", valid_592009
  var valid_592010 = header.getOrDefault("X-Amz-Security-Token")
  valid_592010 = validateParameter(valid_592010, JString, required = false,
                                 default = nil)
  if valid_592010 != nil:
    section.add "X-Amz-Security-Token", valid_592010
  var valid_592011 = header.getOrDefault("X-Amz-Algorithm")
  valid_592011 = validateParameter(valid_592011, JString, required = false,
                                 default = nil)
  if valid_592011 != nil:
    section.add "X-Amz-Algorithm", valid_592011
  var valid_592012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592012 = validateParameter(valid_592012, JString, required = false,
                                 default = nil)
  if valid_592012 != nil:
    section.add "X-Amz-SignedHeaders", valid_592012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592014: Call_DeleteSshPublicKey_592002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ## 
  let valid = call_592014.validator(path, query, header, formData, body)
  let scheme = call_592014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592014.url(scheme.get, call_592014.host, call_592014.base,
                         call_592014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592014, url, valid)

proc call*(call_592015: Call_DeleteSshPublicKey_592002; body: JsonNode): Recallable =
  ## deleteSshPublicKey
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ##   body: JObject (required)
  var body_592016 = newJObject()
  if body != nil:
    body_592016 = body
  result = call_592015.call(nil, nil, nil, nil, body_592016)

var deleteSshPublicKey* = Call_DeleteSshPublicKey_592002(
    name: "deleteSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteSshPublicKey",
    validator: validate_DeleteSshPublicKey_592003, base: "/",
    url: url_DeleteSshPublicKey_592004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_592017 = ref object of OpenApiRestCall_591364
proc url_DeleteUser_592019(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteUser_592018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592020 = header.getOrDefault("X-Amz-Target")
  valid_592020 = validateParameter(valid_592020, JString, required = true, default = newJString(
      "TransferService.DeleteUser"))
  if valid_592020 != nil:
    section.add "X-Amz-Target", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-Signature")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-Signature", valid_592021
  var valid_592022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592022 = validateParameter(valid_592022, JString, required = false,
                                 default = nil)
  if valid_592022 != nil:
    section.add "X-Amz-Content-Sha256", valid_592022
  var valid_592023 = header.getOrDefault("X-Amz-Date")
  valid_592023 = validateParameter(valid_592023, JString, required = false,
                                 default = nil)
  if valid_592023 != nil:
    section.add "X-Amz-Date", valid_592023
  var valid_592024 = header.getOrDefault("X-Amz-Credential")
  valid_592024 = validateParameter(valid_592024, JString, required = false,
                                 default = nil)
  if valid_592024 != nil:
    section.add "X-Amz-Credential", valid_592024
  var valid_592025 = header.getOrDefault("X-Amz-Security-Token")
  valid_592025 = validateParameter(valid_592025, JString, required = false,
                                 default = nil)
  if valid_592025 != nil:
    section.add "X-Amz-Security-Token", valid_592025
  var valid_592026 = header.getOrDefault("X-Amz-Algorithm")
  valid_592026 = validateParameter(valid_592026, JString, required = false,
                                 default = nil)
  if valid_592026 != nil:
    section.add "X-Amz-Algorithm", valid_592026
  var valid_592027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592027 = validateParameter(valid_592027, JString, required = false,
                                 default = nil)
  if valid_592027 != nil:
    section.add "X-Amz-SignedHeaders", valid_592027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592029: Call_DeleteUser_592017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ## 
  let valid = call_592029.validator(path, query, header, formData, body)
  let scheme = call_592029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592029.url(scheme.get, call_592029.host, call_592029.base,
                         call_592029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592029, url, valid)

proc call*(call_592030: Call_DeleteUser_592017; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ##   body: JObject (required)
  var body_592031 = newJObject()
  if body != nil:
    body_592031 = body
  result = call_592030.call(nil, nil, nil, nil, body_592031)

var deleteUser* = Call_DeleteUser_592017(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.DeleteUser",
                                      validator: validate_DeleteUser_592018,
                                      base: "/", url: url_DeleteUser_592019,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServer_592032 = ref object of OpenApiRestCall_591364
proc url_DescribeServer_592034(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServer_592033(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592035 = header.getOrDefault("X-Amz-Target")
  valid_592035 = validateParameter(valid_592035, JString, required = true, default = newJString(
      "TransferService.DescribeServer"))
  if valid_592035 != nil:
    section.add "X-Amz-Target", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-Signature")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-Signature", valid_592036
  var valid_592037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592037 = validateParameter(valid_592037, JString, required = false,
                                 default = nil)
  if valid_592037 != nil:
    section.add "X-Amz-Content-Sha256", valid_592037
  var valid_592038 = header.getOrDefault("X-Amz-Date")
  valid_592038 = validateParameter(valid_592038, JString, required = false,
                                 default = nil)
  if valid_592038 != nil:
    section.add "X-Amz-Date", valid_592038
  var valid_592039 = header.getOrDefault("X-Amz-Credential")
  valid_592039 = validateParameter(valid_592039, JString, required = false,
                                 default = nil)
  if valid_592039 != nil:
    section.add "X-Amz-Credential", valid_592039
  var valid_592040 = header.getOrDefault("X-Amz-Security-Token")
  valid_592040 = validateParameter(valid_592040, JString, required = false,
                                 default = nil)
  if valid_592040 != nil:
    section.add "X-Amz-Security-Token", valid_592040
  var valid_592041 = header.getOrDefault("X-Amz-Algorithm")
  valid_592041 = validateParameter(valid_592041, JString, required = false,
                                 default = nil)
  if valid_592041 != nil:
    section.add "X-Amz-Algorithm", valid_592041
  var valid_592042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592042 = validateParameter(valid_592042, JString, required = false,
                                 default = nil)
  if valid_592042 != nil:
    section.add "X-Amz-SignedHeaders", valid_592042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592044: Call_DescribeServer_592032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ## 
  let valid = call_592044.validator(path, query, header, formData, body)
  let scheme = call_592044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592044.url(scheme.get, call_592044.host, call_592044.base,
                         call_592044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592044, url, valid)

proc call*(call_592045: Call_DescribeServer_592032; body: JsonNode): Recallable =
  ## describeServer
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ##   body: JObject (required)
  var body_592046 = newJObject()
  if body != nil:
    body_592046 = body
  result = call_592045.call(nil, nil, nil, nil, body_592046)

var describeServer* = Call_DescribeServer_592032(name: "describeServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeServer",
    validator: validate_DescribeServer_592033, base: "/", url: url_DescribeServer_592034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_592047 = ref object of OpenApiRestCall_591364
proc url_DescribeUser_592049(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeUser_592048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592050 = header.getOrDefault("X-Amz-Target")
  valid_592050 = validateParameter(valid_592050, JString, required = true, default = newJString(
      "TransferService.DescribeUser"))
  if valid_592050 != nil:
    section.add "X-Amz-Target", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-Signature")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-Signature", valid_592051
  var valid_592052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592052 = validateParameter(valid_592052, JString, required = false,
                                 default = nil)
  if valid_592052 != nil:
    section.add "X-Amz-Content-Sha256", valid_592052
  var valid_592053 = header.getOrDefault("X-Amz-Date")
  valid_592053 = validateParameter(valid_592053, JString, required = false,
                                 default = nil)
  if valid_592053 != nil:
    section.add "X-Amz-Date", valid_592053
  var valid_592054 = header.getOrDefault("X-Amz-Credential")
  valid_592054 = validateParameter(valid_592054, JString, required = false,
                                 default = nil)
  if valid_592054 != nil:
    section.add "X-Amz-Credential", valid_592054
  var valid_592055 = header.getOrDefault("X-Amz-Security-Token")
  valid_592055 = validateParameter(valid_592055, JString, required = false,
                                 default = nil)
  if valid_592055 != nil:
    section.add "X-Amz-Security-Token", valid_592055
  var valid_592056 = header.getOrDefault("X-Amz-Algorithm")
  valid_592056 = validateParameter(valid_592056, JString, required = false,
                                 default = nil)
  if valid_592056 != nil:
    section.add "X-Amz-Algorithm", valid_592056
  var valid_592057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592057 = validateParameter(valid_592057, JString, required = false,
                                 default = nil)
  if valid_592057 != nil:
    section.add "X-Amz-SignedHeaders", valid_592057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592059: Call_DescribeUser_592047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ## 
  let valid = call_592059.validator(path, query, header, formData, body)
  let scheme = call_592059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592059.url(scheme.get, call_592059.host, call_592059.base,
                         call_592059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592059, url, valid)

proc call*(call_592060: Call_DescribeUser_592047; body: JsonNode): Recallable =
  ## describeUser
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ##   body: JObject (required)
  var body_592061 = newJObject()
  if body != nil:
    body_592061 = body
  result = call_592060.call(nil, nil, nil, nil, body_592061)

var describeUser* = Call_DescribeUser_592047(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeUser",
    validator: validate_DescribeUser_592048, base: "/", url: url_DescribeUser_592049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSshPublicKey_592062 = ref object of OpenApiRestCall_591364
proc url_ImportSshPublicKey_592064(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportSshPublicKey_592063(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592065 = header.getOrDefault("X-Amz-Target")
  valid_592065 = validateParameter(valid_592065, JString, required = true, default = newJString(
      "TransferService.ImportSshPublicKey"))
  if valid_592065 != nil:
    section.add "X-Amz-Target", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-Signature")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-Signature", valid_592066
  var valid_592067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592067 = validateParameter(valid_592067, JString, required = false,
                                 default = nil)
  if valid_592067 != nil:
    section.add "X-Amz-Content-Sha256", valid_592067
  var valid_592068 = header.getOrDefault("X-Amz-Date")
  valid_592068 = validateParameter(valid_592068, JString, required = false,
                                 default = nil)
  if valid_592068 != nil:
    section.add "X-Amz-Date", valid_592068
  var valid_592069 = header.getOrDefault("X-Amz-Credential")
  valid_592069 = validateParameter(valid_592069, JString, required = false,
                                 default = nil)
  if valid_592069 != nil:
    section.add "X-Amz-Credential", valid_592069
  var valid_592070 = header.getOrDefault("X-Amz-Security-Token")
  valid_592070 = validateParameter(valid_592070, JString, required = false,
                                 default = nil)
  if valid_592070 != nil:
    section.add "X-Amz-Security-Token", valid_592070
  var valid_592071 = header.getOrDefault("X-Amz-Algorithm")
  valid_592071 = validateParameter(valid_592071, JString, required = false,
                                 default = nil)
  if valid_592071 != nil:
    section.add "X-Amz-Algorithm", valid_592071
  var valid_592072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592072 = validateParameter(valid_592072, JString, required = false,
                                 default = nil)
  if valid_592072 != nil:
    section.add "X-Amz-SignedHeaders", valid_592072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592074: Call_ImportSshPublicKey_592062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ## 
  let valid = call_592074.validator(path, query, header, formData, body)
  let scheme = call_592074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592074.url(scheme.get, call_592074.host, call_592074.base,
                         call_592074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592074, url, valid)

proc call*(call_592075: Call_ImportSshPublicKey_592062; body: JsonNode): Recallable =
  ## importSshPublicKey
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ##   body: JObject (required)
  var body_592076 = newJObject()
  if body != nil:
    body_592076 = body
  result = call_592075.call(nil, nil, nil, nil, body_592076)

var importSshPublicKey* = Call_ImportSshPublicKey_592062(
    name: "importSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ImportSshPublicKey",
    validator: validate_ImportSshPublicKey_592063, base: "/",
    url: url_ImportSshPublicKey_592064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServers_592077 = ref object of OpenApiRestCall_591364
proc url_ListServers_592079(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServers_592078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592080 = query.getOrDefault("MaxResults")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "MaxResults", valid_592080
  var valid_592081 = query.getOrDefault("NextToken")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "NextToken", valid_592081
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592082 = header.getOrDefault("X-Amz-Target")
  valid_592082 = validateParameter(valid_592082, JString, required = true, default = newJString(
      "TransferService.ListServers"))
  if valid_592082 != nil:
    section.add "X-Amz-Target", valid_592082
  var valid_592083 = header.getOrDefault("X-Amz-Signature")
  valid_592083 = validateParameter(valid_592083, JString, required = false,
                                 default = nil)
  if valid_592083 != nil:
    section.add "X-Amz-Signature", valid_592083
  var valid_592084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592084 = validateParameter(valid_592084, JString, required = false,
                                 default = nil)
  if valid_592084 != nil:
    section.add "X-Amz-Content-Sha256", valid_592084
  var valid_592085 = header.getOrDefault("X-Amz-Date")
  valid_592085 = validateParameter(valid_592085, JString, required = false,
                                 default = nil)
  if valid_592085 != nil:
    section.add "X-Amz-Date", valid_592085
  var valid_592086 = header.getOrDefault("X-Amz-Credential")
  valid_592086 = validateParameter(valid_592086, JString, required = false,
                                 default = nil)
  if valid_592086 != nil:
    section.add "X-Amz-Credential", valid_592086
  var valid_592087 = header.getOrDefault("X-Amz-Security-Token")
  valid_592087 = validateParameter(valid_592087, JString, required = false,
                                 default = nil)
  if valid_592087 != nil:
    section.add "X-Amz-Security-Token", valid_592087
  var valid_592088 = header.getOrDefault("X-Amz-Algorithm")
  valid_592088 = validateParameter(valid_592088, JString, required = false,
                                 default = nil)
  if valid_592088 != nil:
    section.add "X-Amz-Algorithm", valid_592088
  var valid_592089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592089 = validateParameter(valid_592089, JString, required = false,
                                 default = nil)
  if valid_592089 != nil:
    section.add "X-Amz-SignedHeaders", valid_592089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592091: Call_ListServers_592077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ## 
  let valid = call_592091.validator(path, query, header, formData, body)
  let scheme = call_592091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592091.url(scheme.get, call_592091.host, call_592091.base,
                         call_592091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592091, url, valid)

proc call*(call_592092: Call_ListServers_592077; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServers
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592093 = newJObject()
  var body_592094 = newJObject()
  add(query_592093, "MaxResults", newJString(MaxResults))
  add(query_592093, "NextToken", newJString(NextToken))
  if body != nil:
    body_592094 = body
  result = call_592092.call(nil, query_592093, nil, nil, body_592094)

var listServers* = Call_ListServers_592077(name: "listServers",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListServers",
                                        validator: validate_ListServers_592078,
                                        base: "/", url: url_ListServers_592079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_592096 = ref object of OpenApiRestCall_591364
proc url_ListTagsForResource_592098(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_592097(path: JsonNode; query: JsonNode;
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
  var valid_592099 = query.getOrDefault("MaxResults")
  valid_592099 = validateParameter(valid_592099, JString, required = false,
                                 default = nil)
  if valid_592099 != nil:
    section.add "MaxResults", valid_592099
  var valid_592100 = query.getOrDefault("NextToken")
  valid_592100 = validateParameter(valid_592100, JString, required = false,
                                 default = nil)
  if valid_592100 != nil:
    section.add "NextToken", valid_592100
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592101 = header.getOrDefault("X-Amz-Target")
  valid_592101 = validateParameter(valid_592101, JString, required = true, default = newJString(
      "TransferService.ListTagsForResource"))
  if valid_592101 != nil:
    section.add "X-Amz-Target", valid_592101
  var valid_592102 = header.getOrDefault("X-Amz-Signature")
  valid_592102 = validateParameter(valid_592102, JString, required = false,
                                 default = nil)
  if valid_592102 != nil:
    section.add "X-Amz-Signature", valid_592102
  var valid_592103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592103 = validateParameter(valid_592103, JString, required = false,
                                 default = nil)
  if valid_592103 != nil:
    section.add "X-Amz-Content-Sha256", valid_592103
  var valid_592104 = header.getOrDefault("X-Amz-Date")
  valid_592104 = validateParameter(valid_592104, JString, required = false,
                                 default = nil)
  if valid_592104 != nil:
    section.add "X-Amz-Date", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Credential")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Credential", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Security-Token")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Security-Token", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Algorithm")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Algorithm", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-SignedHeaders", valid_592108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592110: Call_ListTagsForResource_592096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ## 
  let valid = call_592110.validator(path, query, header, formData, body)
  let scheme = call_592110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592110.url(scheme.get, call_592110.host, call_592110.base,
                         call_592110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592110, url, valid)

proc call*(call_592111: Call_ListTagsForResource_592096; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592112 = newJObject()
  var body_592113 = newJObject()
  add(query_592112, "MaxResults", newJString(MaxResults))
  add(query_592112, "NextToken", newJString(NextToken))
  if body != nil:
    body_592113 = body
  result = call_592111.call(nil, query_592112, nil, nil, body_592113)

var listTagsForResource* = Call_ListTagsForResource_592096(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListTagsForResource",
    validator: validate_ListTagsForResource_592097, base: "/",
    url: url_ListTagsForResource_592098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_592114 = ref object of OpenApiRestCall_591364
proc url_ListUsers_592116(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListUsers_592115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592117 = query.getOrDefault("MaxResults")
  valid_592117 = validateParameter(valid_592117, JString, required = false,
                                 default = nil)
  if valid_592117 != nil:
    section.add "MaxResults", valid_592117
  var valid_592118 = query.getOrDefault("NextToken")
  valid_592118 = validateParameter(valid_592118, JString, required = false,
                                 default = nil)
  if valid_592118 != nil:
    section.add "NextToken", valid_592118
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592119 = header.getOrDefault("X-Amz-Target")
  valid_592119 = validateParameter(valid_592119, JString, required = true, default = newJString(
      "TransferService.ListUsers"))
  if valid_592119 != nil:
    section.add "X-Amz-Target", valid_592119
  var valid_592120 = header.getOrDefault("X-Amz-Signature")
  valid_592120 = validateParameter(valid_592120, JString, required = false,
                                 default = nil)
  if valid_592120 != nil:
    section.add "X-Amz-Signature", valid_592120
  var valid_592121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592121 = validateParameter(valid_592121, JString, required = false,
                                 default = nil)
  if valid_592121 != nil:
    section.add "X-Amz-Content-Sha256", valid_592121
  var valid_592122 = header.getOrDefault("X-Amz-Date")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "X-Amz-Date", valid_592122
  var valid_592123 = header.getOrDefault("X-Amz-Credential")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "X-Amz-Credential", valid_592123
  var valid_592124 = header.getOrDefault("X-Amz-Security-Token")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-Security-Token", valid_592124
  var valid_592125 = header.getOrDefault("X-Amz-Algorithm")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Algorithm", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-SignedHeaders", valid_592126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592128: Call_ListUsers_592114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ## 
  let valid = call_592128.validator(path, query, header, formData, body)
  let scheme = call_592128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592128.url(scheme.get, call_592128.host, call_592128.base,
                         call_592128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592128, url, valid)

proc call*(call_592129: Call_ListUsers_592114; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_592130 = newJObject()
  var body_592131 = newJObject()
  add(query_592130, "MaxResults", newJString(MaxResults))
  add(query_592130, "NextToken", newJString(NextToken))
  if body != nil:
    body_592131 = body
  result = call_592129.call(nil, query_592130, nil, nil, body_592131)

var listUsers* = Call_ListUsers_592114(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListUsers",
                                    validator: validate_ListUsers_592115,
                                    base: "/", url: url_ListUsers_592116,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartServer_592132 = ref object of OpenApiRestCall_591364
proc url_StartServer_592134(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartServer_592133(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592135 = header.getOrDefault("X-Amz-Target")
  valid_592135 = validateParameter(valid_592135, JString, required = true, default = newJString(
      "TransferService.StartServer"))
  if valid_592135 != nil:
    section.add "X-Amz-Target", valid_592135
  var valid_592136 = header.getOrDefault("X-Amz-Signature")
  valid_592136 = validateParameter(valid_592136, JString, required = false,
                                 default = nil)
  if valid_592136 != nil:
    section.add "X-Amz-Signature", valid_592136
  var valid_592137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592137 = validateParameter(valid_592137, JString, required = false,
                                 default = nil)
  if valid_592137 != nil:
    section.add "X-Amz-Content-Sha256", valid_592137
  var valid_592138 = header.getOrDefault("X-Amz-Date")
  valid_592138 = validateParameter(valid_592138, JString, required = false,
                                 default = nil)
  if valid_592138 != nil:
    section.add "X-Amz-Date", valid_592138
  var valid_592139 = header.getOrDefault("X-Amz-Credential")
  valid_592139 = validateParameter(valid_592139, JString, required = false,
                                 default = nil)
  if valid_592139 != nil:
    section.add "X-Amz-Credential", valid_592139
  var valid_592140 = header.getOrDefault("X-Amz-Security-Token")
  valid_592140 = validateParameter(valid_592140, JString, required = false,
                                 default = nil)
  if valid_592140 != nil:
    section.add "X-Amz-Security-Token", valid_592140
  var valid_592141 = header.getOrDefault("X-Amz-Algorithm")
  valid_592141 = validateParameter(valid_592141, JString, required = false,
                                 default = nil)
  if valid_592141 != nil:
    section.add "X-Amz-Algorithm", valid_592141
  var valid_592142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592142 = validateParameter(valid_592142, JString, required = false,
                                 default = nil)
  if valid_592142 != nil:
    section.add "X-Amz-SignedHeaders", valid_592142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592144: Call_StartServer_592132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_592144.validator(path, query, header, formData, body)
  let scheme = call_592144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592144.url(scheme.get, call_592144.host, call_592144.base,
                         call_592144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592144, url, valid)

proc call*(call_592145: Call_StartServer_592132; body: JsonNode): Recallable =
  ## startServer
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_592146 = newJObject()
  if body != nil:
    body_592146 = body
  result = call_592145.call(nil, nil, nil, nil, body_592146)

var startServer* = Call_StartServer_592132(name: "startServer",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StartServer",
                                        validator: validate_StartServer_592133,
                                        base: "/", url: url_StartServer_592134,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopServer_592147 = ref object of OpenApiRestCall_591364
proc url_StopServer_592149(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopServer_592148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592150 = header.getOrDefault("X-Amz-Target")
  valid_592150 = validateParameter(valid_592150, JString, required = true, default = newJString(
      "TransferService.StopServer"))
  if valid_592150 != nil:
    section.add "X-Amz-Target", valid_592150
  var valid_592151 = header.getOrDefault("X-Amz-Signature")
  valid_592151 = validateParameter(valid_592151, JString, required = false,
                                 default = nil)
  if valid_592151 != nil:
    section.add "X-Amz-Signature", valid_592151
  var valid_592152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592152 = validateParameter(valid_592152, JString, required = false,
                                 default = nil)
  if valid_592152 != nil:
    section.add "X-Amz-Content-Sha256", valid_592152
  var valid_592153 = header.getOrDefault("X-Amz-Date")
  valid_592153 = validateParameter(valid_592153, JString, required = false,
                                 default = nil)
  if valid_592153 != nil:
    section.add "X-Amz-Date", valid_592153
  var valid_592154 = header.getOrDefault("X-Amz-Credential")
  valid_592154 = validateParameter(valid_592154, JString, required = false,
                                 default = nil)
  if valid_592154 != nil:
    section.add "X-Amz-Credential", valid_592154
  var valid_592155 = header.getOrDefault("X-Amz-Security-Token")
  valid_592155 = validateParameter(valid_592155, JString, required = false,
                                 default = nil)
  if valid_592155 != nil:
    section.add "X-Amz-Security-Token", valid_592155
  var valid_592156 = header.getOrDefault("X-Amz-Algorithm")
  valid_592156 = validateParameter(valid_592156, JString, required = false,
                                 default = nil)
  if valid_592156 != nil:
    section.add "X-Amz-Algorithm", valid_592156
  var valid_592157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592157 = validateParameter(valid_592157, JString, required = false,
                                 default = nil)
  if valid_592157 != nil:
    section.add "X-Amz-SignedHeaders", valid_592157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592159: Call_StopServer_592147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_592159.validator(path, query, header, formData, body)
  let scheme = call_592159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592159.url(scheme.get, call_592159.host, call_592159.base,
                         call_592159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592159, url, valid)

proc call*(call_592160: Call_StopServer_592147; body: JsonNode): Recallable =
  ## stopServer
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_592161 = newJObject()
  if body != nil:
    body_592161 = body
  result = call_592160.call(nil, nil, nil, nil, body_592161)

var stopServer* = Call_StopServer_592147(name: "stopServer",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StopServer",
                                      validator: validate_StopServer_592148,
                                      base: "/", url: url_StopServer_592149,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_592162 = ref object of OpenApiRestCall_591364
proc url_TagResource_592164(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_592163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592165 = header.getOrDefault("X-Amz-Target")
  valid_592165 = validateParameter(valid_592165, JString, required = true, default = newJString(
      "TransferService.TagResource"))
  if valid_592165 != nil:
    section.add "X-Amz-Target", valid_592165
  var valid_592166 = header.getOrDefault("X-Amz-Signature")
  valid_592166 = validateParameter(valid_592166, JString, required = false,
                                 default = nil)
  if valid_592166 != nil:
    section.add "X-Amz-Signature", valid_592166
  var valid_592167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592167 = validateParameter(valid_592167, JString, required = false,
                                 default = nil)
  if valid_592167 != nil:
    section.add "X-Amz-Content-Sha256", valid_592167
  var valid_592168 = header.getOrDefault("X-Amz-Date")
  valid_592168 = validateParameter(valid_592168, JString, required = false,
                                 default = nil)
  if valid_592168 != nil:
    section.add "X-Amz-Date", valid_592168
  var valid_592169 = header.getOrDefault("X-Amz-Credential")
  valid_592169 = validateParameter(valid_592169, JString, required = false,
                                 default = nil)
  if valid_592169 != nil:
    section.add "X-Amz-Credential", valid_592169
  var valid_592170 = header.getOrDefault("X-Amz-Security-Token")
  valid_592170 = validateParameter(valid_592170, JString, required = false,
                                 default = nil)
  if valid_592170 != nil:
    section.add "X-Amz-Security-Token", valid_592170
  var valid_592171 = header.getOrDefault("X-Amz-Algorithm")
  valid_592171 = validateParameter(valid_592171, JString, required = false,
                                 default = nil)
  if valid_592171 != nil:
    section.add "X-Amz-Algorithm", valid_592171
  var valid_592172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592172 = validateParameter(valid_592172, JString, required = false,
                                 default = nil)
  if valid_592172 != nil:
    section.add "X-Amz-SignedHeaders", valid_592172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592174: Call_TagResource_592162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ## 
  let valid = call_592174.validator(path, query, header, formData, body)
  let scheme = call_592174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592174.url(scheme.get, call_592174.host, call_592174.base,
                         call_592174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592174, url, valid)

proc call*(call_592175: Call_TagResource_592162; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ##   body: JObject (required)
  var body_592176 = newJObject()
  if body != nil:
    body_592176 = body
  result = call_592175.call(nil, nil, nil, nil, body_592176)

var tagResource* = Call_TagResource_592162(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.TagResource",
                                        validator: validate_TagResource_592163,
                                        base: "/", url: url_TagResource_592164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestIdentityProvider_592177 = ref object of OpenApiRestCall_591364
proc url_TestIdentityProvider_592179(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestIdentityProvider_592178(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592180 = header.getOrDefault("X-Amz-Target")
  valid_592180 = validateParameter(valid_592180, JString, required = true, default = newJString(
      "TransferService.TestIdentityProvider"))
  if valid_592180 != nil:
    section.add "X-Amz-Target", valid_592180
  var valid_592181 = header.getOrDefault("X-Amz-Signature")
  valid_592181 = validateParameter(valid_592181, JString, required = false,
                                 default = nil)
  if valid_592181 != nil:
    section.add "X-Amz-Signature", valid_592181
  var valid_592182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592182 = validateParameter(valid_592182, JString, required = false,
                                 default = nil)
  if valid_592182 != nil:
    section.add "X-Amz-Content-Sha256", valid_592182
  var valid_592183 = header.getOrDefault("X-Amz-Date")
  valid_592183 = validateParameter(valid_592183, JString, required = false,
                                 default = nil)
  if valid_592183 != nil:
    section.add "X-Amz-Date", valid_592183
  var valid_592184 = header.getOrDefault("X-Amz-Credential")
  valid_592184 = validateParameter(valid_592184, JString, required = false,
                                 default = nil)
  if valid_592184 != nil:
    section.add "X-Amz-Credential", valid_592184
  var valid_592185 = header.getOrDefault("X-Amz-Security-Token")
  valid_592185 = validateParameter(valid_592185, JString, required = false,
                                 default = nil)
  if valid_592185 != nil:
    section.add "X-Amz-Security-Token", valid_592185
  var valid_592186 = header.getOrDefault("X-Amz-Algorithm")
  valid_592186 = validateParameter(valid_592186, JString, required = false,
                                 default = nil)
  if valid_592186 != nil:
    section.add "X-Amz-Algorithm", valid_592186
  var valid_592187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592187 = validateParameter(valid_592187, JString, required = false,
                                 default = nil)
  if valid_592187 != nil:
    section.add "X-Amz-SignedHeaders", valid_592187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592189: Call_TestIdentityProvider_592177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ## 
  let valid = call_592189.validator(path, query, header, formData, body)
  let scheme = call_592189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592189.url(scheme.get, call_592189.host, call_592189.base,
                         call_592189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592189, url, valid)

proc call*(call_592190: Call_TestIdentityProvider_592177; body: JsonNode): Recallable =
  ## testIdentityProvider
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ##   body: JObject (required)
  var body_592191 = newJObject()
  if body != nil:
    body_592191 = body
  result = call_592190.call(nil, nil, nil, nil, body_592191)

var testIdentityProvider* = Call_TestIdentityProvider_592177(
    name: "testIdentityProvider", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TestIdentityProvider",
    validator: validate_TestIdentityProvider_592178, base: "/",
    url: url_TestIdentityProvider_592179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_592192 = ref object of OpenApiRestCall_591364
proc url_UntagResource_592194(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_592193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592195 = header.getOrDefault("X-Amz-Target")
  valid_592195 = validateParameter(valid_592195, JString, required = true, default = newJString(
      "TransferService.UntagResource"))
  if valid_592195 != nil:
    section.add "X-Amz-Target", valid_592195
  var valid_592196 = header.getOrDefault("X-Amz-Signature")
  valid_592196 = validateParameter(valid_592196, JString, required = false,
                                 default = nil)
  if valid_592196 != nil:
    section.add "X-Amz-Signature", valid_592196
  var valid_592197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592197 = validateParameter(valid_592197, JString, required = false,
                                 default = nil)
  if valid_592197 != nil:
    section.add "X-Amz-Content-Sha256", valid_592197
  var valid_592198 = header.getOrDefault("X-Amz-Date")
  valid_592198 = validateParameter(valid_592198, JString, required = false,
                                 default = nil)
  if valid_592198 != nil:
    section.add "X-Amz-Date", valid_592198
  var valid_592199 = header.getOrDefault("X-Amz-Credential")
  valid_592199 = validateParameter(valid_592199, JString, required = false,
                                 default = nil)
  if valid_592199 != nil:
    section.add "X-Amz-Credential", valid_592199
  var valid_592200 = header.getOrDefault("X-Amz-Security-Token")
  valid_592200 = validateParameter(valid_592200, JString, required = false,
                                 default = nil)
  if valid_592200 != nil:
    section.add "X-Amz-Security-Token", valid_592200
  var valid_592201 = header.getOrDefault("X-Amz-Algorithm")
  valid_592201 = validateParameter(valid_592201, JString, required = false,
                                 default = nil)
  if valid_592201 != nil:
    section.add "X-Amz-Algorithm", valid_592201
  var valid_592202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592202 = validateParameter(valid_592202, JString, required = false,
                                 default = nil)
  if valid_592202 != nil:
    section.add "X-Amz-SignedHeaders", valid_592202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592204: Call_UntagResource_592192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_592204.validator(path, query, header, formData, body)
  let scheme = call_592204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592204.url(scheme.get, call_592204.host, call_592204.base,
                         call_592204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592204, url, valid)

proc call*(call_592205: Call_UntagResource_592192; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_592206 = newJObject()
  if body != nil:
    body_592206 = body
  result = call_592205.call(nil, nil, nil, nil, body_592206)

var untagResource* = Call_UntagResource_592192(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UntagResource",
    validator: validate_UntagResource_592193, base: "/", url: url_UntagResource_592194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_592207 = ref object of OpenApiRestCall_591364
proc url_UpdateServer_592209(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServer_592208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592210 = header.getOrDefault("X-Amz-Target")
  valid_592210 = validateParameter(valid_592210, JString, required = true, default = newJString(
      "TransferService.UpdateServer"))
  if valid_592210 != nil:
    section.add "X-Amz-Target", valid_592210
  var valid_592211 = header.getOrDefault("X-Amz-Signature")
  valid_592211 = validateParameter(valid_592211, JString, required = false,
                                 default = nil)
  if valid_592211 != nil:
    section.add "X-Amz-Signature", valid_592211
  var valid_592212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592212 = validateParameter(valid_592212, JString, required = false,
                                 default = nil)
  if valid_592212 != nil:
    section.add "X-Amz-Content-Sha256", valid_592212
  var valid_592213 = header.getOrDefault("X-Amz-Date")
  valid_592213 = validateParameter(valid_592213, JString, required = false,
                                 default = nil)
  if valid_592213 != nil:
    section.add "X-Amz-Date", valid_592213
  var valid_592214 = header.getOrDefault("X-Amz-Credential")
  valid_592214 = validateParameter(valid_592214, JString, required = false,
                                 default = nil)
  if valid_592214 != nil:
    section.add "X-Amz-Credential", valid_592214
  var valid_592215 = header.getOrDefault("X-Amz-Security-Token")
  valid_592215 = validateParameter(valid_592215, JString, required = false,
                                 default = nil)
  if valid_592215 != nil:
    section.add "X-Amz-Security-Token", valid_592215
  var valid_592216 = header.getOrDefault("X-Amz-Algorithm")
  valid_592216 = validateParameter(valid_592216, JString, required = false,
                                 default = nil)
  if valid_592216 != nil:
    section.add "X-Amz-Algorithm", valid_592216
  var valid_592217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592217 = validateParameter(valid_592217, JString, required = false,
                                 default = nil)
  if valid_592217 != nil:
    section.add "X-Amz-SignedHeaders", valid_592217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592219: Call_UpdateServer_592207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ## 
  let valid = call_592219.validator(path, query, header, formData, body)
  let scheme = call_592219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592219.url(scheme.get, call_592219.host, call_592219.base,
                         call_592219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592219, url, valid)

proc call*(call_592220: Call_UpdateServer_592207; body: JsonNode): Recallable =
  ## updateServer
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ##   body: JObject (required)
  var body_592221 = newJObject()
  if body != nil:
    body_592221 = body
  result = call_592220.call(nil, nil, nil, nil, body_592221)

var updateServer* = Call_UpdateServer_592207(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateServer",
    validator: validate_UpdateServer_592208, base: "/", url: url_UpdateServer_592209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_592222 = ref object of OpenApiRestCall_591364
proc url_UpdateUser_592224(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateUser_592223(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_592225 = header.getOrDefault("X-Amz-Target")
  valid_592225 = validateParameter(valid_592225, JString, required = true, default = newJString(
      "TransferService.UpdateUser"))
  if valid_592225 != nil:
    section.add "X-Amz-Target", valid_592225
  var valid_592226 = header.getOrDefault("X-Amz-Signature")
  valid_592226 = validateParameter(valid_592226, JString, required = false,
                                 default = nil)
  if valid_592226 != nil:
    section.add "X-Amz-Signature", valid_592226
  var valid_592227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592227 = validateParameter(valid_592227, JString, required = false,
                                 default = nil)
  if valid_592227 != nil:
    section.add "X-Amz-Content-Sha256", valid_592227
  var valid_592228 = header.getOrDefault("X-Amz-Date")
  valid_592228 = validateParameter(valid_592228, JString, required = false,
                                 default = nil)
  if valid_592228 != nil:
    section.add "X-Amz-Date", valid_592228
  var valid_592229 = header.getOrDefault("X-Amz-Credential")
  valid_592229 = validateParameter(valid_592229, JString, required = false,
                                 default = nil)
  if valid_592229 != nil:
    section.add "X-Amz-Credential", valid_592229
  var valid_592230 = header.getOrDefault("X-Amz-Security-Token")
  valid_592230 = validateParameter(valid_592230, JString, required = false,
                                 default = nil)
  if valid_592230 != nil:
    section.add "X-Amz-Security-Token", valid_592230
  var valid_592231 = header.getOrDefault("X-Amz-Algorithm")
  valid_592231 = validateParameter(valid_592231, JString, required = false,
                                 default = nil)
  if valid_592231 != nil:
    section.add "X-Amz-Algorithm", valid_592231
  var valid_592232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592232 = validateParameter(valid_592232, JString, required = false,
                                 default = nil)
  if valid_592232 != nil:
    section.add "X-Amz-SignedHeaders", valid_592232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592234: Call_UpdateUser_592222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ## 
  let valid = call_592234.validator(path, query, header, formData, body)
  let scheme = call_592234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592234.url(scheme.get, call_592234.host, call_592234.base,
                         call_592234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592234, url, valid)

proc call*(call_592235: Call_UpdateUser_592222; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ##   body: JObject (required)
  var body_592236 = newJObject()
  if body != nil:
    body_592236 = body
  result = call_592235.call(nil, nil, nil, nil, body_592236)

var updateUser* = Call_UpdateUser_592222(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.UpdateUser",
                                      validator: validate_UpdateUser_592223,
                                      base: "/", url: url_UpdateUser_592224,
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
