
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateServer_601727 = ref object of OpenApiRestCall_601389
proc url_CreateServer_601729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateServer_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "TransferService.CreateServer"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_CreateServer_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_CreateServer_601727; body: JsonNode): Recallable =
  ## createServer
  ## Instantiates an autoscaling virtual server based on Secure File Transfer Protocol (SFTP) in AWS. When you make updates to your server or when you work with users, use the service-generated <code>ServerId</code> property that is assigned to the newly created server.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var createServer* = Call_CreateServer_601727(name: "createServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.CreateServer",
    validator: validate_CreateServer_601728, base: "/", url: url_CreateServer_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_601996 = ref object of OpenApiRestCall_601389
proc url_CreateUser_601998(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateUser_601997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "TransferService.CreateUser"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CreateUser_601996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreateUser_601996; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user and associates them with an existing Secure File Transfer Protocol (SFTP) server. You can only create and associate users with SFTP servers that have the <code>IdentityProviderType</code> set to <code>SERVICE_MANAGED</code>. Using parameters for <code>CreateUser</code>, you can specify the user name, set the home directory, store the user's public key, and assign the user's AWS Identity and Access Management (IAM) role. You can also optionally add a scope-down policy, and assign metadata with tags that can be used to group and search for users.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createUser* = Call_CreateUser_601996(name: "createUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.CreateUser",
                                      validator: validate_CreateUser_601997,
                                      base: "/", url: url_CreateUser_601998,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServer_602011 = ref object of OpenApiRestCall_601389
proc url_DeleteServer_602013(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServer_602012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "TransferService.DeleteServer"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_DeleteServer_602011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_DeleteServer_602011; body: JsonNode): Recallable =
  ## deleteServer
  ## <p>Deletes the Secure File Transfer Protocol (SFTP) server that you specify.</p> <p>No response returns from this operation.</p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var deleteServer* = Call_DeleteServer_602011(name: "deleteServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteServer",
    validator: validate_DeleteServer_602012, base: "/", url: url_DeleteServer_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSshPublicKey_602026 = ref object of OpenApiRestCall_601389
proc url_DeleteSshPublicKey_602028(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSshPublicKey_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "TransferService.DeleteSshPublicKey"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_DeleteSshPublicKey_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_DeleteSshPublicKey_602026; body: JsonNode): Recallable =
  ## deleteSshPublicKey
  ## <p>Deletes a user's Secure Shell (SSH) public key.</p> <p>No response is returned from this operation.</p>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var deleteSshPublicKey* = Call_DeleteSshPublicKey_602026(
    name: "deleteSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DeleteSshPublicKey",
    validator: validate_DeleteSshPublicKey_602027, base: "/",
    url: url_DeleteSshPublicKey_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_602041 = ref object of OpenApiRestCall_601389
proc url_DeleteUser_602043(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_602042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "TransferService.DeleteUser"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_DeleteUser_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_DeleteUser_602041; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes the user belonging to the server you specify.</p> <p>No response returns from this operation.</p> <note> <p>When you delete a user from a server, the user's information is lost.</p> </note>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var deleteUser* = Call_DeleteUser_602041(name: "deleteUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.DeleteUser",
                                      validator: validate_DeleteUser_602042,
                                      base: "/", url: url_DeleteUser_602043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServer_602056 = ref object of OpenApiRestCall_601389
proc url_DescribeServer_602058(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServer_602057(path: JsonNode; query: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "TransferService.DescribeServer"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_DescribeServer_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DescribeServer_602056; body: JsonNode): Recallable =
  ## describeServer
  ## <p>Describes the server that you specify by passing the <code>ServerId</code> parameter.</p> <p>The response contains a description of the server's properties.</p>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var describeServer* = Call_DescribeServer_602056(name: "describeServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeServer",
    validator: validate_DescribeServer_602057, base: "/", url: url_DescribeServer_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_602071 = ref object of OpenApiRestCall_601389
proc url_DescribeUser_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_602072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "TransferService.DescribeUser"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DescribeUser_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DescribeUser_602071; body: JsonNode): Recallable =
  ## describeUser
  ## <p>Describes the user assigned to a specific server, as identified by its <code>ServerId</code> property.</p> <p>The response from this call returns the properties of the user associated with the <code>ServerId</code> value that was specified.</p>
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var describeUser* = Call_DescribeUser_602071(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.DescribeUser",
    validator: validate_DescribeUser_602072, base: "/", url: url_DescribeUser_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportSshPublicKey_602086 = ref object of OpenApiRestCall_601389
proc url_ImportSshPublicKey_602088(protocol: Scheme; host: string; base: string;
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

proc validate_ImportSshPublicKey_602087(path: JsonNode; query: JsonNode;
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "TransferService.ImportSshPublicKey"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_ImportSshPublicKey_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_ImportSshPublicKey_602086; body: JsonNode): Recallable =
  ## importSshPublicKey
  ## <p>Adds a Secure Shell (SSH) public key to a user account identified by a <code>UserName</code> value assigned to a specific server, identified by <code>ServerId</code>.</p> <p>The response returns the <code>UserName</code> value, the <code>ServerId</code> value, and the name of the <code>SshPublicKeyId</code>.</p>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var importSshPublicKey* = Call_ImportSshPublicKey_602086(
    name: "importSshPublicKey", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ImportSshPublicKey",
    validator: validate_ImportSshPublicKey_602087, base: "/",
    url: url_ImportSshPublicKey_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServers_602101 = ref object of OpenApiRestCall_601389
proc url_ListServers_602103(protocol: Scheme; host: string; base: string;
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

proc validate_ListServers_602102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602104 = query.getOrDefault("MaxResults")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "MaxResults", valid_602104
  var valid_602105 = query.getOrDefault("NextToken")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "NextToken", valid_602105
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
  var valid_602106 = header.getOrDefault("X-Amz-Target")
  valid_602106 = validateParameter(valid_602106, JString, required = true, default = newJString(
      "TransferService.ListServers"))
  if valid_602106 != nil:
    section.add "X-Amz-Target", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Content-Sha256", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Credential")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Credential", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Security-Token")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Security-Token", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-SignedHeaders", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_ListServers_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602115, url, valid)

proc call*(call_602116: Call_ListServers_602101; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listServers
  ## Lists the Secure File Transfer Protocol (SFTP) servers that are associated with your AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602117 = newJObject()
  var body_602118 = newJObject()
  add(query_602117, "MaxResults", newJString(MaxResults))
  add(query_602117, "NextToken", newJString(NextToken))
  if body != nil:
    body_602118 = body
  result = call_602116.call(nil, query_602117, nil, nil, body_602118)

var listServers* = Call_ListServers_602101(name: "listServers",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListServers",
                                        validator: validate_ListServers_602102,
                                        base: "/", url: url_ListServers_602103,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602120 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602122(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602121(path: JsonNode; query: JsonNode;
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
  var valid_602123 = query.getOrDefault("MaxResults")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "MaxResults", valid_602123
  var valid_602124 = query.getOrDefault("NextToken")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "NextToken", valid_602124
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
  var valid_602125 = header.getOrDefault("X-Amz-Target")
  valid_602125 = validateParameter(valid_602125, JString, required = true, default = newJString(
      "TransferService.ListTagsForResource"))
  if valid_602125 != nil:
    section.add "X-Amz-Target", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Signature")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Signature", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Content-Sha256", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Date")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Date", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Credential")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Credential", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Security-Token")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Security-Token", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Algorithm")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Algorithm", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-SignedHeaders", valid_602132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_ListTagsForResource_602120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_ListTagsForResource_602120; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Lists all of the tags associated with the Amazon Resource Number (ARN) you specify. The resource can be a user, server, or role.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602136 = newJObject()
  var body_602137 = newJObject()
  add(query_602136, "MaxResults", newJString(MaxResults))
  add(query_602136, "NextToken", newJString(NextToken))
  if body != nil:
    body_602137 = body
  result = call_602135.call(nil, query_602136, nil, nil, body_602137)

var listTagsForResource* = Call_ListTagsForResource_602120(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.ListTagsForResource",
    validator: validate_ListTagsForResource_602121, base: "/",
    url: url_ListTagsForResource_602122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_602138 = ref object of OpenApiRestCall_601389
proc url_ListUsers_602140(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_602139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602141 = query.getOrDefault("MaxResults")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "MaxResults", valid_602141
  var valid_602142 = query.getOrDefault("NextToken")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "NextToken", valid_602142
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
  var valid_602143 = header.getOrDefault("X-Amz-Target")
  valid_602143 = validateParameter(valid_602143, JString, required = true, default = newJString(
      "TransferService.ListUsers"))
  if valid_602143 != nil:
    section.add "X-Amz-Target", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Content-Sha256", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-SignedHeaders", valid_602150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602152: Call_ListUsers_602138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ## 
  let valid = call_602152.validator(path, query, header, formData, body)
  let scheme = call_602152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602152.url(scheme.get, call_602152.host, call_602152.base,
                         call_602152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602152, url, valid)

proc call*(call_602153: Call_ListUsers_602138; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUsers
  ## Lists the users for the server that you specify by passing the <code>ServerId</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602154 = newJObject()
  var body_602155 = newJObject()
  add(query_602154, "MaxResults", newJString(MaxResults))
  add(query_602154, "NextToken", newJString(NextToken))
  if body != nil:
    body_602155 = body
  result = call_602153.call(nil, query_602154, nil, nil, body_602155)

var listUsers* = Call_ListUsers_602138(name: "listUsers", meth: HttpMethod.HttpPost,
                                    host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.ListUsers",
                                    validator: validate_ListUsers_602139,
                                    base: "/", url: url_ListUsers_602140,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartServer_602156 = ref object of OpenApiRestCall_601389
proc url_StartServer_602158(protocol: Scheme; host: string; base: string;
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

proc validate_StartServer_602157(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602159 = header.getOrDefault("X-Amz-Target")
  valid_602159 = validateParameter(valid_602159, JString, required = true, default = newJString(
      "TransferService.StartServer"))
  if valid_602159 != nil:
    section.add "X-Amz-Target", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Signature")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Signature", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Content-Sha256", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Date")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Date", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Credential")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Credential", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Security-Token")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Security-Token", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Algorithm")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Algorithm", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-SignedHeaders", valid_602166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602168: Call_StartServer_602156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_602168.validator(path, query, header, formData, body)
  let scheme = call_602168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602168.url(scheme.get, call_602168.host, call_602168.base,
                         call_602168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602168, url, valid)

proc call*(call_602169: Call_StartServer_602156; body: JsonNode): Recallable =
  ## startServer
  ## <p>Changes the state of a Secure File Transfer Protocol (SFTP) server from <code>OFFLINE</code> to <code>ONLINE</code>. It has no impact on an SFTP server that is already <code>ONLINE</code>. An <code>ONLINE</code> server can accept and process file transfer jobs.</p> <p>The state of <code>STARTING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully online. The values of <code>START_FAILED</code> can indicate an error condition. </p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_602170 = newJObject()
  if body != nil:
    body_602170 = body
  result = call_602169.call(nil, nil, nil, nil, body_602170)

var startServer* = Call_StartServer_602156(name: "startServer",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StartServer",
                                        validator: validate_StartServer_602157,
                                        base: "/", url: url_StartServer_602158,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopServer_602171 = ref object of OpenApiRestCall_601389
proc url_StopServer_602173(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopServer_602172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602174 = header.getOrDefault("X-Amz-Target")
  valid_602174 = validateParameter(valid_602174, JString, required = true, default = newJString(
      "TransferService.StopServer"))
  if valid_602174 != nil:
    section.add "X-Amz-Target", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Signature")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Signature", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Content-Sha256", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Credential")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Credential", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Security-Token")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Security-Token", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-SignedHeaders", valid_602181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_StopServer_602171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602183, url, valid)

proc call*(call_602184: Call_StopServer_602171; body: JsonNode): Recallable =
  ## stopServer
  ## <p>Changes the state of an SFTP server from <code>ONLINE</code> to <code>OFFLINE</code>. An <code>OFFLINE</code> server cannot accept and process file transfer jobs. Information tied to your server such as server and user properties are not affected by stopping your server. Stopping a server will not reduce or impact your Secure File Transfer Protocol (SFTP) endpoint billing.</p> <p>The state of <code>STOPPING</code> indicates that the server is in an intermediate state, either not fully able to respond, or not fully offline. The values of <code>STOP_FAILED</code> can indicate an error condition.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_602185 = newJObject()
  if body != nil:
    body_602185 = body
  result = call_602184.call(nil, nil, nil, nil, body_602185)

var stopServer* = Call_StopServer_602171(name: "stopServer",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.StopServer",
                                      validator: validate_StopServer_602172,
                                      base: "/", url: url_StopServer_602173,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602186 = ref object of OpenApiRestCall_601389
proc url_TagResource_602188(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602187(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602189 = header.getOrDefault("X-Amz-Target")
  valid_602189 = validateParameter(valid_602189, JString, required = true, default = newJString(
      "TransferService.TagResource"))
  if valid_602189 != nil:
    section.add "X-Amz-Target", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Signature")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Signature", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Credential")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Credential", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Security-Token")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Security-Token", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-SignedHeaders", valid_602196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602198: Call_TagResource_602186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ## 
  let valid = call_602198.validator(path, query, header, formData, body)
  let scheme = call_602198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602198.url(scheme.get, call_602198.host, call_602198.base,
                         call_602198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602198, url, valid)

proc call*(call_602199: Call_TagResource_602186; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Attaches a key-value pair to a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>There is no response returned from this call.</p>
  ##   body: JObject (required)
  var body_602200 = newJObject()
  if body != nil:
    body_602200 = body
  result = call_602199.call(nil, nil, nil, nil, body_602200)

var tagResource* = Call_TagResource_602186(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.TagResource",
                                        validator: validate_TagResource_602187,
                                        base: "/", url: url_TagResource_602188,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestIdentityProvider_602201 = ref object of OpenApiRestCall_601389
proc url_TestIdentityProvider_602203(protocol: Scheme; host: string; base: string;
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

proc validate_TestIdentityProvider_602202(path: JsonNode; query: JsonNode;
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
  var valid_602204 = header.getOrDefault("X-Amz-Target")
  valid_602204 = validateParameter(valid_602204, JString, required = true, default = newJString(
      "TransferService.TestIdentityProvider"))
  if valid_602204 != nil:
    section.add "X-Amz-Target", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_TestIdentityProvider_602201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_TestIdentityProvider_602201; body: JsonNode): Recallable =
  ## testIdentityProvider
  ## If the <code>IdentityProviderType</code> of the server is <code>API_Gateway</code>, tests whether your API Gateway is set up successfully. We highly recommend that you call this operation to test your authentication method as soon as you create your server. By doing so, you can troubleshoot issues with the API Gateway integration to ensure that your users can successfully use the service.
  ##   body: JObject (required)
  var body_602215 = newJObject()
  if body != nil:
    body_602215 = body
  result = call_602214.call(nil, nil, nil, nil, body_602215)

var testIdentityProvider* = Call_TestIdentityProvider_602201(
    name: "testIdentityProvider", meth: HttpMethod.HttpPost,
    host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.TestIdentityProvider",
    validator: validate_TestIdentityProvider_602202, base: "/",
    url: url_TestIdentityProvider_602203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602216 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602218(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602219 = header.getOrDefault("X-Amz-Target")
  valid_602219 = validateParameter(valid_602219, JString, required = true, default = newJString(
      "TransferService.UntagResource"))
  if valid_602219 != nil:
    section.add "X-Amz-Target", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Signature")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Signature", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Content-Sha256", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Date")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Date", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Credential")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Credential", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Security-Token")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Security-Token", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Algorithm")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Algorithm", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-SignedHeaders", valid_602226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602228: Call_UntagResource_602216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ## 
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602228, url, valid)

proc call*(call_602229: Call_UntagResource_602216; body: JsonNode): Recallable =
  ## untagResource
  ## <p>Detaches a key-value pair from a resource, as identified by its Amazon Resource Name (ARN). Resources are users, servers, roles, and other entities.</p> <p>No response is returned from this call.</p>
  ##   body: JObject (required)
  var body_602230 = newJObject()
  if body != nil:
    body_602230 = body
  result = call_602229.call(nil, nil, nil, nil, body_602230)

var untagResource* = Call_UntagResource_602216(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UntagResource",
    validator: validate_UntagResource_602217, base: "/", url: url_UntagResource_602218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServer_602231 = ref object of OpenApiRestCall_601389
proc url_UpdateServer_602233(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateServer_602232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602234 = header.getOrDefault("X-Amz-Target")
  valid_602234 = validateParameter(valid_602234, JString, required = true, default = newJString(
      "TransferService.UpdateServer"))
  if valid_602234 != nil:
    section.add "X-Amz-Target", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Signature")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Signature", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Content-Sha256", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Date")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Date", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Credential")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Credential", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Security-Token")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Security-Token", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Algorithm")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Algorithm", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602243: Call_UpdateServer_602231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ## 
  let valid = call_602243.validator(path, query, header, formData, body)
  let scheme = call_602243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602243.url(scheme.get, call_602243.host, call_602243.base,
                         call_602243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602243, url, valid)

proc call*(call_602244: Call_UpdateServer_602231; body: JsonNode): Recallable =
  ## updateServer
  ## <p>Updates the server properties after that server has been created.</p> <p>The <code>UpdateServer</code> call returns the <code>ServerId</code> of the Secure File Transfer Protocol (SFTP) server you updated.</p>
  ##   body: JObject (required)
  var body_602245 = newJObject()
  if body != nil:
    body_602245 = body
  result = call_602244.call(nil, nil, nil, nil, body_602245)

var updateServer* = Call_UpdateServer_602231(name: "updateServer",
    meth: HttpMethod.HttpPost, host: "transfer.amazonaws.com",
    route: "/#X-Amz-Target=TransferService.UpdateServer",
    validator: validate_UpdateServer_602232, base: "/", url: url_UpdateServer_602233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_602246 = ref object of OpenApiRestCall_601389
proc url_UpdateUser_602248(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_602247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602249 = header.getOrDefault("X-Amz-Target")
  valid_602249 = validateParameter(valid_602249, JString, required = true, default = newJString(
      "TransferService.UpdateUser"))
  if valid_602249 != nil:
    section.add "X-Amz-Target", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602258: Call_UpdateUser_602246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ## 
  let valid = call_602258.validator(path, query, header, formData, body)
  let scheme = call_602258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602258.url(scheme.get, call_602258.host, call_602258.base,
                         call_602258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602258, url, valid)

proc call*(call_602259: Call_UpdateUser_602246; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Assigns new properties to a user. Parameters you pass modify any or all of the following: the home directory, role, and policy for the <code>UserName</code> and <code>ServerId</code> you specify.</p> <p>The response returns the <code>ServerId</code> and the <code>UserName</code> for the updated user.</p>
  ##   body: JObject (required)
  var body_602260 = newJObject()
  if body != nil:
    body_602260 = body
  result = call_602259.call(nil, nil, nil, nil, body_602260)

var updateUser* = Call_UpdateUser_602246(name: "updateUser",
                                      meth: HttpMethod.HttpPost,
                                      host: "transfer.amazonaws.com", route: "/#X-Amz-Target=TransferService.UpdateUser",
                                      validator: validate_UpdateUser_602247,
                                      base: "/", url: url_UpdateUser_602248,
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
