
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon WorkMail
## version: 2017-10-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon WorkMail is a secure, managed business email and calendaring service with support for existing desktop and mobile email clients. You can access your email, contacts, and calendars using Microsoft Outlook, your browser, or other native iOS and Android email applications. You can integrate WorkMail with your existing corporate directory and control both the keys that encrypt your data and the location in which your data is stored.</p> <p>The WorkMail API is designed for the following scenarios:</p> <ul> <li> <p>Listing and describing organizations</p> </li> </ul> <ul> <li> <p>Managing users</p> </li> </ul> <ul> <li> <p>Managing groups</p> </li> </ul> <ul> <li> <p>Managing resources</p> </li> </ul> <p>All WorkMail API operations are Amazon-authenticated and certificate-signed. They not only require the use of the AWS SDK, but also allow for the exclusive use of AWS Identity and Access Management users and roles to help facilitate access, trust, and permission policies. By creating a role and allowing an IAM user to access the WorkMail site, the IAM user gains full administrative visibility into the entire WorkMail organization (or as set in the IAM policy). This includes, but is not limited to, the ability to create, update, and delete users, groups, and resources. This allows developers to perform the scenarios listed above, as well as give users the ability to grant access on a selective basis using the IAM model.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/workmail/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "workmail.ap-northeast-1.amazonaws.com", "ap-southeast-1": "workmail.ap-southeast-1.amazonaws.com",
                               "us-west-2": "workmail.us-west-2.amazonaws.com",
                               "eu-west-2": "workmail.eu-west-2.amazonaws.com", "ap-northeast-3": "workmail.ap-northeast-3.amazonaws.com", "eu-central-1": "workmail.eu-central-1.amazonaws.com",
                               "us-east-2": "workmail.us-east-2.amazonaws.com",
                               "us-east-1": "workmail.us-east-1.amazonaws.com", "cn-northwest-1": "workmail.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "workmail.ap-south-1.amazonaws.com", "eu-north-1": "workmail.eu-north-1.amazonaws.com", "ap-northeast-2": "workmail.ap-northeast-2.amazonaws.com",
                               "us-west-1": "workmail.us-west-1.amazonaws.com", "us-gov-east-1": "workmail.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "workmail.eu-west-3.amazonaws.com", "cn-north-1": "workmail.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "workmail.sa-east-1.amazonaws.com",
                               "eu-west-1": "workmail.eu-west-1.amazonaws.com", "us-gov-west-1": "workmail.us-gov-west-1.amazonaws.com", "ap-southeast-2": "workmail.ap-southeast-2.amazonaws.com", "ca-central-1": "workmail.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "workmail.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "workmail.ap-southeast-1.amazonaws.com",
      "us-west-2": "workmail.us-west-2.amazonaws.com",
      "eu-west-2": "workmail.eu-west-2.amazonaws.com",
      "ap-northeast-3": "workmail.ap-northeast-3.amazonaws.com",
      "eu-central-1": "workmail.eu-central-1.amazonaws.com",
      "us-east-2": "workmail.us-east-2.amazonaws.com",
      "us-east-1": "workmail.us-east-1.amazonaws.com",
      "cn-northwest-1": "workmail.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "workmail.ap-south-1.amazonaws.com",
      "eu-north-1": "workmail.eu-north-1.amazonaws.com",
      "ap-northeast-2": "workmail.ap-northeast-2.amazonaws.com",
      "us-west-1": "workmail.us-west-1.amazonaws.com",
      "us-gov-east-1": "workmail.us-gov-east-1.amazonaws.com",
      "eu-west-3": "workmail.eu-west-3.amazonaws.com",
      "cn-north-1": "workmail.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "workmail.sa-east-1.amazonaws.com",
      "eu-west-1": "workmail.eu-west-1.amazonaws.com",
      "us-gov-west-1": "workmail.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "workmail.ap-southeast-2.amazonaws.com",
      "ca-central-1": "workmail.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "workmail"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateDelegateToResource_402656294 = ref object of OpenApiRestCall_402656044
proc url_AssociateDelegateToResource_402656296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateDelegateToResource_402656295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Adds a member (user or group) to the resource's set of delegates.
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
      "WorkMailService.AssociateDelegateToResource"))
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

proc call*(call_402656412: Call_AssociateDelegateToResource_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a member (user or group) to the resource's set of delegates.
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

proc call*(call_402656461: Call_AssociateDelegateToResource_402656294;
           body: JsonNode): Recallable =
  ## associateDelegateToResource
  ## Adds a member (user or group) to the resource's set of delegates.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var associateDelegateToResource* = Call_AssociateDelegateToResource_402656294(
    name: "associateDelegateToResource", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.AssociateDelegateToResource",
    validator: validate_AssociateDelegateToResource_402656295, base: "/",
    makeUrl: url_AssociateDelegateToResource_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateMemberToGroup_402656489 = ref object of OpenApiRestCall_402656044
proc url_AssociateMemberToGroup_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateMemberToGroup_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a member (user or group) to the group's set.
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
      "WorkMailService.AssociateMemberToGroup"))
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

proc call*(call_402656501: Call_AssociateMemberToGroup_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a member (user or group) to the group's set.
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

proc call*(call_402656502: Call_AssociateMemberToGroup_402656489; body: JsonNode): Recallable =
  ## associateMemberToGroup
  ## Adds a member (user or group) to the group's set.
  ##   body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var associateMemberToGroup* = Call_AssociateMemberToGroup_402656489(
    name: "associateMemberToGroup", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.AssociateMemberToGroup",
    validator: validate_AssociateMemberToGroup_402656490, base: "/",
    makeUrl: url_AssociateMemberToGroup_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateAlias_402656506(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlias_402656505(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds an alias to the set of a given member (user or group) of Amazon WorkMail.
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
      "WorkMailService.CreateAlias"))
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

proc call*(call_402656516: Call_CreateAlias_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds an alias to the set of a given member (user or group) of Amazon WorkMail.
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

proc call*(call_402656517: Call_CreateAlias_402656504; body: JsonNode): Recallable =
  ## createAlias
  ## Adds an alias to the set of a given member (user or group) of Amazon WorkMail.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createAlias* = Call_CreateAlias_402656504(name: "createAlias",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.CreateAlias",
    validator: validate_CreateAlias_402656505, base: "/",
    makeUrl: url_CreateAlias_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateGroup_402656521(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_402656520(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a group that can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
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
      "WorkMailService.CreateGroup"))
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

proc call*(call_402656531: Call_CreateGroup_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a group that can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
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

proc call*(call_402656532: Call_CreateGroup_402656519; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group that can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
  ##   
                                                                                                            ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createGroup* = Call_CreateGroup_402656519(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.CreateGroup",
    validator: validate_CreateGroup_402656520, base: "/",
    makeUrl: url_CreateGroup_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResource_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateResource_402656536(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResource_402656535(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new Amazon WorkMail resource. 
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
      "WorkMailService.CreateResource"))
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

proc call*(call_402656546: Call_CreateResource_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Amazon WorkMail resource. 
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

proc call*(call_402656547: Call_CreateResource_402656534; body: JsonNode): Recallable =
  ## createResource
  ## Creates a new Amazon WorkMail resource. 
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createResource* = Call_CreateResource_402656534(name: "createResource",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.CreateResource",
    validator: validate_CreateResource_402656535, base: "/",
    makeUrl: url_CreateResource_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUser_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateUser_402656551(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUser_402656550(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a user who can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
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
      "WorkMailService.CreateUser"))
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

proc call*(call_402656561: Call_CreateUser_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a user who can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
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

proc call*(call_402656562: Call_CreateUser_402656549; body: JsonNode): Recallable =
  ## createUser
  ## Creates a user who can be used in Amazon WorkMail by calling the <a>RegisterToWorkMail</a> operation.
  ##   
                                                                                                          ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createUser* = Call_CreateUser_402656549(name: "createUser",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.CreateUser",
    validator: validate_CreateUser_402656550, base: "/",
    makeUrl: url_CreateUser_402656551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccessControlRule_402656564 = ref object of OpenApiRestCall_402656044
proc url_DeleteAccessControlRule_402656566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAccessControlRule_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an access control rule for the specified WorkMail organization.
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
      "WorkMailService.DeleteAccessControlRule"))
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

proc call*(call_402656576: Call_DeleteAccessControlRule_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an access control rule for the specified WorkMail organization.
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

proc call*(call_402656577: Call_DeleteAccessControlRule_402656564;
           body: JsonNode): Recallable =
  ## deleteAccessControlRule
  ## Deletes an access control rule for the specified WorkMail organization.
  ##   
                                                                            ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var deleteAccessControlRule* = Call_DeleteAccessControlRule_402656564(
    name: "deleteAccessControlRule", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteAccessControlRule",
    validator: validate_DeleteAccessControlRule_402656565, base: "/",
    makeUrl: url_DeleteAccessControlRule_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_402656579 = ref object of OpenApiRestCall_402656044
proc url_DeleteAlias_402656581(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlias_402656580(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove one or more specified aliases from a set of aliases for a given user.
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
      "WorkMailService.DeleteAlias"))
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

proc call*(call_402656591: Call_DeleteAlias_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more specified aliases from a set of aliases for a given user.
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

proc call*(call_402656592: Call_DeleteAlias_402656579; body: JsonNode): Recallable =
  ## deleteAlias
  ## Remove one or more specified aliases from a set of aliases for a given user.
  ##   
                                                                                 ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var deleteAlias* = Call_DeleteAlias_402656579(name: "deleteAlias",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteAlias",
    validator: validate_DeleteAlias_402656580, base: "/",
    makeUrl: url_DeleteAlias_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_402656594 = ref object of OpenApiRestCall_402656044
proc url_DeleteGroup_402656596(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_402656595(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a group from Amazon WorkMail.
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
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "WorkMailService.DeleteGroup"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
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

proc call*(call_402656606: Call_DeleteGroup_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a group from Amazon WorkMail.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DeleteGroup_402656594; body: JsonNode): Recallable =
  ## deleteGroup
  ## Deletes a group from Amazon WorkMail.
  ##   body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var deleteGroup* = Call_DeleteGroup_402656594(name: "deleteGroup",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteGroup",
    validator: validate_DeleteGroup_402656595, base: "/",
    makeUrl: url_DeleteGroup_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMailboxPermissions_402656609 = ref object of OpenApiRestCall_402656044
proc url_DeleteMailboxPermissions_402656611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMailboxPermissions_402656610(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes permissions granted to a member (user or group).
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
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "WorkMailService.DeleteMailboxPermissions"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
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

proc call*(call_402656621: Call_DeleteMailboxPermissions_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes permissions granted to a member (user or group).
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DeleteMailboxPermissions_402656609;
           body: JsonNode): Recallable =
  ## deleteMailboxPermissions
  ## Deletes permissions granted to a member (user or group).
  ##   body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var deleteMailboxPermissions* = Call_DeleteMailboxPermissions_402656609(
    name: "deleteMailboxPermissions", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteMailboxPermissions",
    validator: validate_DeleteMailboxPermissions_402656610, base: "/",
    makeUrl: url_DeleteMailboxPermissions_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResource_402656624 = ref object of OpenApiRestCall_402656044
proc url_DeleteResource_402656626(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResource_402656625(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified resource. 
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
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "WorkMailService.DeleteResource"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
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

proc call*(call_402656636: Call_DeleteResource_402656624; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified resource. 
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DeleteResource_402656624; body: JsonNode): Recallable =
  ## deleteResource
  ## Deletes the specified resource. 
  ##   body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var deleteResource* = Call_DeleteResource_402656624(name: "deleteResource",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteResource",
    validator: validate_DeleteResource_402656625, base: "/",
    makeUrl: url_DeleteResource_402656626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_402656639 = ref object of OpenApiRestCall_402656044
proc url_DeleteUser_402656641(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUser_402656640(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a user from Amazon WorkMail and all subsequent systems. Before you can delete a user, the user state must be <code>DISABLED</code>. Use the <a>DescribeUser</a> action to confirm the user state.</p> <p>Deleting a user is permanent and cannot be undone. WorkMail archives user mailboxes for 30 days before they are permanently removed.</p>
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
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "WorkMailService.DeleteUser"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DeleteUser_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a user from Amazon WorkMail and all subsequent systems. Before you can delete a user, the user state must be <code>DISABLED</code>. Use the <a>DescribeUser</a> action to confirm the user state.</p> <p>Deleting a user is permanent and cannot be undone. WorkMail archives user mailboxes for 30 days before they are permanently removed.</p>
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeleteUser_402656639; body: JsonNode): Recallable =
  ## deleteUser
  ## <p>Deletes a user from Amazon WorkMail and all subsequent systems. Before you can delete a user, the user state must be <code>DISABLED</code>. Use the <a>DescribeUser</a> action to confirm the user state.</p> <p>Deleting a user is permanent and cannot be undone. WorkMail archives user mailboxes for 30 days before they are permanently removed.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var deleteUser* = Call_DeleteUser_402656639(name: "deleteUser",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeleteUser",
    validator: validate_DeleteUser_402656640, base: "/",
    makeUrl: url_DeleteUser_402656641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterFromWorkMail_402656654 = ref object of OpenApiRestCall_402656044
proc url_DeregisterFromWorkMail_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterFromWorkMail_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Mark a user, group, or resource as no longer used in Amazon WorkMail. This action disassociates the mailbox and schedules it for clean-up. WorkMail keeps mailboxes for 30 days before they are permanently removed. The functionality in the console is <i>Disable</i>.
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
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "WorkMailService.DeregisterFromWorkMail"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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

proc call*(call_402656666: Call_DeregisterFromWorkMail_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Mark a user, group, or resource as no longer used in Amazon WorkMail. This action disassociates the mailbox and schedules it for clean-up. WorkMail keeps mailboxes for 30 days before they are permanently removed. The functionality in the console is <i>Disable</i>.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DeregisterFromWorkMail_402656654; body: JsonNode): Recallable =
  ## deregisterFromWorkMail
  ## Mark a user, group, or resource as no longer used in Amazon WorkMail. This action disassociates the mailbox and schedules it for clean-up. WorkMail keeps mailboxes for 30 days before they are permanently removed. The functionality in the console is <i>Disable</i>.
  ##   
                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var deregisterFromWorkMail* = Call_DeregisterFromWorkMail_402656654(
    name: "deregisterFromWorkMail", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DeregisterFromWorkMail",
    validator: validate_DeregisterFromWorkMail_402656655, base: "/",
    makeUrl: url_DeregisterFromWorkMail_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_402656669 = ref object of OpenApiRestCall_402656044
proc url_DescribeGroup_402656671(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeGroup_402656670(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the data available for the group.
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
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "WorkMailService.DescribeGroup"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
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

proc call*(call_402656681: Call_DescribeGroup_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data available for the group.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DescribeGroup_402656669; body: JsonNode): Recallable =
  ## describeGroup
  ## Returns the data available for the group.
  ##   body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var describeGroup* = Call_DescribeGroup_402656669(name: "describeGroup",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DescribeGroup",
    validator: validate_DescribeGroup_402656670, base: "/",
    makeUrl: url_DescribeGroup_402656671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganization_402656684 = ref object of OpenApiRestCall_402656044
proc url_DescribeOrganization_402656686(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrganization_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides more information regarding a given organization based on its identifier.
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
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "WorkMailService.DescribeOrganization"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
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

proc call*(call_402656696: Call_DescribeOrganization_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides more information regarding a given organization based on its identifier.
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DescribeOrganization_402656684; body: JsonNode): Recallable =
  ## describeOrganization
  ## Provides more information regarding a given organization based on its identifier.
  ##   
                                                                                      ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var describeOrganization* = Call_DescribeOrganization_402656684(
    name: "describeOrganization", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DescribeOrganization",
    validator: validate_DescribeOrganization_402656685, base: "/",
    makeUrl: url_DescribeOrganization_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResource_402656699 = ref object of OpenApiRestCall_402656044
proc url_DescribeResource_402656701(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeResource_402656700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the data available for the resource.
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
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "WorkMailService.DescribeResource"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_DescribeResource_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the data available for the resource.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_DescribeResource_402656699; body: JsonNode): Recallable =
  ## describeResource
  ## Returns the data available for the resource.
  ##   body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var describeResource* = Call_DescribeResource_402656699(
    name: "describeResource", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DescribeResource",
    validator: validate_DescribeResource_402656700, base: "/",
    makeUrl: url_DescribeResource_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_402656714 = ref object of OpenApiRestCall_402656044
proc url_DescribeUser_402656716(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUser_402656715(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information regarding the user.
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
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "WorkMailService.DescribeUser"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
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

proc call*(call_402656726: Call_DescribeUser_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information regarding the user.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_DescribeUser_402656714; body: JsonNode): Recallable =
  ## describeUser
  ## Provides information regarding the user.
  ##   body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var describeUser* = Call_DescribeUser_402656714(name: "describeUser",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DescribeUser",
    validator: validate_DescribeUser_402656715, base: "/",
    makeUrl: url_DescribeUser_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateDelegateFromResource_402656729 = ref object of OpenApiRestCall_402656044
proc url_DisassociateDelegateFromResource_402656731(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateDelegateFromResource_402656730(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a member from the resource's set of delegates.
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
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "WorkMailService.DisassociateDelegateFromResource"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
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

proc call*(call_402656741: Call_DisassociateDelegateFromResource_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a member from the resource's set of delegates.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_DisassociateDelegateFromResource_402656729;
           body: JsonNode): Recallable =
  ## disassociateDelegateFromResource
  ## Removes a member from the resource's set of delegates.
  ##   body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var disassociateDelegateFromResource* = Call_DisassociateDelegateFromResource_402656729(
    name: "disassociateDelegateFromResource", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DisassociateDelegateFromResource",
    validator: validate_DisassociateDelegateFromResource_402656730, base: "/",
    makeUrl: url_DisassociateDelegateFromResource_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberFromGroup_402656744 = ref object of OpenApiRestCall_402656044
proc url_DisassociateMemberFromGroup_402656746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMemberFromGroup_402656745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a member from a group.
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
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "WorkMailService.DisassociateMemberFromGroup"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
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

proc call*(call_402656756: Call_DisassociateMemberFromGroup_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a member from a group.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_DisassociateMemberFromGroup_402656744;
           body: JsonNode): Recallable =
  ## disassociateMemberFromGroup
  ## Removes a member from a group.
  ##   body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var disassociateMemberFromGroup* = Call_DisassociateMemberFromGroup_402656744(
    name: "disassociateMemberFromGroup", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.DisassociateMemberFromGroup",
    validator: validate_DisassociateMemberFromGroup_402656745, base: "/",
    makeUrl: url_DisassociateMemberFromGroup_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccessControlEffect_402656759 = ref object of OpenApiRestCall_402656044
proc url_GetAccessControlEffect_402656761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccessControlEffect_402656760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the effects of an organization's access control rules as they apply to a specified IPv4 address, access protocol action, or user ID. 
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
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "WorkMailService.GetAccessControlEffect"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
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

proc call*(call_402656771: Call_GetAccessControlEffect_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the effects of an organization's access control rules as they apply to a specified IPv4 address, access protocol action, or user ID. 
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_GetAccessControlEffect_402656759; body: JsonNode): Recallable =
  ## getAccessControlEffect
  ## Gets the effects of an organization's access control rules as they apply to a specified IPv4 address, access protocol action, or user ID. 
  ##   
                                                                                                                                               ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var getAccessControlEffect* = Call_GetAccessControlEffect_402656759(
    name: "getAccessControlEffect", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.GetAccessControlEffect",
    validator: validate_GetAccessControlEffect_402656760, base: "/",
    makeUrl: url_GetAccessControlEffect_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMailboxDetails_402656774 = ref object of OpenApiRestCall_402656044
proc url_GetMailboxDetails_402656776(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMailboxDetails_402656775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Requests a user's mailbox details for a specified organization and user.
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
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "WorkMailService.GetMailboxDetails"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
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

proc call*(call_402656786: Call_GetMailboxDetails_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a user's mailbox details for a specified organization and user.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_GetMailboxDetails_402656774; body: JsonNode): Recallable =
  ## getMailboxDetails
  ## Requests a user's mailbox details for a specified organization and user.
  ##   
                                                                             ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var getMailboxDetails* = Call_GetMailboxDetails_402656774(
    name: "getMailboxDetails", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.GetMailboxDetails",
    validator: validate_GetMailboxDetails_402656775, base: "/",
    makeUrl: url_GetMailboxDetails_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccessControlRules_402656789 = ref object of OpenApiRestCall_402656044
proc url_ListAccessControlRules_402656791(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAccessControlRules_402656790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the access control rules for the specified organization.
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
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "WorkMailService.ListAccessControlRules"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
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

proc call*(call_402656801: Call_ListAccessControlRules_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the access control rules for the specified organization.
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_ListAccessControlRules_402656789; body: JsonNode): Recallable =
  ## listAccessControlRules
  ## Lists the access control rules for the specified organization.
  ##   body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var listAccessControlRules* = Call_ListAccessControlRules_402656789(
    name: "listAccessControlRules", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListAccessControlRules",
    validator: validate_ListAccessControlRules_402656790, base: "/",
    makeUrl: url_ListAccessControlRules_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_402656804 = ref object of OpenApiRestCall_402656044
proc url_ListAliases_402656806(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAliases_402656805(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a paginated call to list the aliases associated with a given entity.
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
  var valid_402656807 = query.getOrDefault("MaxResults")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "MaxResults", valid_402656807
  var valid_402656808 = query.getOrDefault("NextToken")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "NextToken", valid_402656808
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
  var valid_402656809 = header.getOrDefault("X-Amz-Target")
  valid_402656809 = validateParameter(valid_402656809, JString, required = true, default = newJString(
      "WorkMailService.ListAliases"))
  if valid_402656809 != nil:
    section.add "X-Amz-Target", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Security-Token", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Signature")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Signature", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Algorithm", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Date")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Date", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Credential")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Credential", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656816
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

proc call*(call_402656818: Call_ListAliases_402656804; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a paginated call to list the aliases associated with a given entity.
                                                                                         ## 
  let valid = call_402656818.validator(path, query, header, formData, body, _)
  let scheme = call_402656818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656818.makeUrl(scheme.get, call_402656818.host, call_402656818.base,
                                   call_402656818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656818, uri, valid, _)

proc call*(call_402656819: Call_ListAliases_402656804; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAliases
  ## Creates a paginated call to list the aliases associated with a given entity.
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
  var query_402656820 = newJObject()
  var body_402656821 = newJObject()
  add(query_402656820, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656821 = body
  add(query_402656820, "NextToken", newJString(NextToken))
  result = call_402656819.call(nil, query_402656820, nil, nil, body_402656821)

var listAliases* = Call_ListAliases_402656804(name: "listAliases",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListAliases",
    validator: validate_ListAliases_402656805, base: "/",
    makeUrl: url_ListAliases_402656806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMembers_402656822 = ref object of OpenApiRestCall_402656044
proc url_ListGroupMembers_402656824(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroupMembers_402656823(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an overview of the members of a group. Users and groups can be members of a group.
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
  var valid_402656825 = query.getOrDefault("MaxResults")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "MaxResults", valid_402656825
  var valid_402656826 = query.getOrDefault("NextToken")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "NextToken", valid_402656826
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
  var valid_402656827 = header.getOrDefault("X-Amz-Target")
  valid_402656827 = validateParameter(valid_402656827, JString, required = true, default = newJString(
      "WorkMailService.ListGroupMembers"))
  if valid_402656827 != nil:
    section.add "X-Amz-Target", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Security-Token", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Signature")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Signature", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Algorithm", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Date")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Date", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Credential")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Credential", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656834
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

proc call*(call_402656836: Call_ListGroupMembers_402656822;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an overview of the members of a group. Users and groups can be members of a group.
                                                                                         ## 
  let valid = call_402656836.validator(path, query, header, formData, body, _)
  let scheme = call_402656836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656836.makeUrl(scheme.get, call_402656836.host, call_402656836.base,
                                   call_402656836.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656836, uri, valid, _)

proc call*(call_402656837: Call_ListGroupMembers_402656822; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroupMembers
  ## Returns an overview of the members of a group. Users and groups can be members of a group.
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
  var query_402656838 = newJObject()
  var body_402656839 = newJObject()
  add(query_402656838, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656839 = body
  add(query_402656838, "NextToken", newJString(NextToken))
  result = call_402656837.call(nil, query_402656838, nil, nil, body_402656839)

var listGroupMembers* = Call_ListGroupMembers_402656822(
    name: "listGroupMembers", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListGroupMembers",
    validator: validate_ListGroupMembers_402656823, base: "/",
    makeUrl: url_ListGroupMembers_402656824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_402656840 = ref object of OpenApiRestCall_402656044
proc url_ListGroups_402656842(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroups_402656841(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns summaries of the organization's groups.
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
  var valid_402656843 = query.getOrDefault("MaxResults")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "MaxResults", valid_402656843
  var valid_402656844 = query.getOrDefault("NextToken")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "NextToken", valid_402656844
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
  var valid_402656845 = header.getOrDefault("X-Amz-Target")
  valid_402656845 = validateParameter(valid_402656845, JString, required = true, default = newJString(
      "WorkMailService.ListGroups"))
  if valid_402656845 != nil:
    section.add "X-Amz-Target", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Security-Token", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Signature")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Signature", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Algorithm", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Date")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Date", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Credential")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Credential", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656852
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

proc call*(call_402656854: Call_ListGroups_402656840; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns summaries of the organization's groups.
                                                                                         ## 
  let valid = call_402656854.validator(path, query, header, formData, body, _)
  let scheme = call_402656854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656854.makeUrl(scheme.get, call_402656854.host, call_402656854.base,
                                   call_402656854.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656854, uri, valid, _)

proc call*(call_402656855: Call_ListGroups_402656840; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listGroups
  ## Returns summaries of the organization's groups.
  ##   MaxResults: string
                                                    ##             : Pagination limit
  ##   
                                                                                     ## body: JObject (required)
  ##   
                                                                                                                ## NextToken: string
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## token
  var query_402656856 = newJObject()
  var body_402656857 = newJObject()
  add(query_402656856, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656857 = body
  add(query_402656856, "NextToken", newJString(NextToken))
  result = call_402656855.call(nil, query_402656856, nil, nil, body_402656857)

var listGroups* = Call_ListGroups_402656840(name: "listGroups",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListGroups",
    validator: validate_ListGroups_402656841, base: "/",
    makeUrl: url_ListGroups_402656842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMailboxPermissions_402656858 = ref object of OpenApiRestCall_402656044
proc url_ListMailboxPermissions_402656860(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMailboxPermissions_402656859(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the mailbox permissions associated with a user, group, or resource mailbox.
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
  var valid_402656861 = query.getOrDefault("MaxResults")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "MaxResults", valid_402656861
  var valid_402656862 = query.getOrDefault("NextToken")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "NextToken", valid_402656862
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
  var valid_402656863 = header.getOrDefault("X-Amz-Target")
  valid_402656863 = validateParameter(valid_402656863, JString, required = true, default = newJString(
      "WorkMailService.ListMailboxPermissions"))
  if valid_402656863 != nil:
    section.add "X-Amz-Target", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Security-Token", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Signature")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Signature", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-Algorithm", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Date")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Date", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Credential")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Credential", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656870
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

proc call*(call_402656872: Call_ListMailboxPermissions_402656858;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the mailbox permissions associated with a user, group, or resource mailbox.
                                                                                         ## 
  let valid = call_402656872.validator(path, query, header, formData, body, _)
  let scheme = call_402656872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656872.makeUrl(scheme.get, call_402656872.host, call_402656872.base,
                                   call_402656872.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656872, uri, valid, _)

proc call*(call_402656873: Call_ListMailboxPermissions_402656858;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMailboxPermissions
  ## Lists the mailbox permissions associated with a user, group, or resource mailbox.
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
  var query_402656874 = newJObject()
  var body_402656875 = newJObject()
  add(query_402656874, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656875 = body
  add(query_402656874, "NextToken", newJString(NextToken))
  result = call_402656873.call(nil, query_402656874, nil, nil, body_402656875)

var listMailboxPermissions* = Call_ListMailboxPermissions_402656858(
    name: "listMailboxPermissions", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListMailboxPermissions",
    validator: validate_ListMailboxPermissions_402656859, base: "/",
    makeUrl: url_ListMailboxPermissions_402656860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizations_402656876 = ref object of OpenApiRestCall_402656044
proc url_ListOrganizations_402656878(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizations_402656877(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns summaries of the customer's non-deleted organizations.
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
  var valid_402656879 = query.getOrDefault("MaxResults")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "MaxResults", valid_402656879
  var valid_402656880 = query.getOrDefault("NextToken")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "NextToken", valid_402656880
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
  var valid_402656881 = header.getOrDefault("X-Amz-Target")
  valid_402656881 = validateParameter(valid_402656881, JString, required = true, default = newJString(
      "WorkMailService.ListOrganizations"))
  if valid_402656881 != nil:
    section.add "X-Amz-Target", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Security-Token", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Signature")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Signature", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Algorithm", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Date")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Date", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Credential")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Credential", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656888
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

proc call*(call_402656890: Call_ListOrganizations_402656876;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns summaries of the customer's non-deleted organizations.
                                                                                         ## 
  let valid = call_402656890.validator(path, query, header, formData, body, _)
  let scheme = call_402656890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656890.makeUrl(scheme.get, call_402656890.host, call_402656890.base,
                                   call_402656890.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656890, uri, valid, _)

proc call*(call_402656891: Call_ListOrganizations_402656876; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listOrganizations
  ## Returns summaries of the customer's non-deleted organizations.
  ##   MaxResults: string
                                                                   ##             : Pagination limit
  ##   
                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                               ## NextToken: string
                                                                                                                               ##            
                                                                                                                               ## : 
                                                                                                                               ## Pagination 
                                                                                                                               ## token
  var query_402656892 = newJObject()
  var body_402656893 = newJObject()
  add(query_402656892, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656893 = body
  add(query_402656892, "NextToken", newJString(NextToken))
  result = call_402656891.call(nil, query_402656892, nil, nil, body_402656893)

var listOrganizations* = Call_ListOrganizations_402656876(
    name: "listOrganizations", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListOrganizations",
    validator: validate_ListOrganizations_402656877, base: "/",
    makeUrl: url_ListOrganizations_402656878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDelegates_402656894 = ref object of OpenApiRestCall_402656044
proc url_ListResourceDelegates_402656896(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDelegates_402656895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the delegates associated with a resource. Users and groups can be resource delegates and answer requests on behalf of the resource.
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
  var valid_402656897 = query.getOrDefault("MaxResults")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "MaxResults", valid_402656897
  var valid_402656898 = query.getOrDefault("NextToken")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "NextToken", valid_402656898
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
  var valid_402656899 = header.getOrDefault("X-Amz-Target")
  valid_402656899 = validateParameter(valid_402656899, JString, required = true, default = newJString(
      "WorkMailService.ListResourceDelegates"))
  if valid_402656899 != nil:
    section.add "X-Amz-Target", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Security-Token", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Signature")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Signature", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Algorithm", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Date")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Date", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Credential")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Credential", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656906
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

proc call*(call_402656908: Call_ListResourceDelegates_402656894;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the delegates associated with a resource. Users and groups can be resource delegates and answer requests on behalf of the resource.
                                                                                         ## 
  let valid = call_402656908.validator(path, query, header, formData, body, _)
  let scheme = call_402656908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656908.makeUrl(scheme.get, call_402656908.host, call_402656908.base,
                                   call_402656908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656908, uri, valid, _)

proc call*(call_402656909: Call_ListResourceDelegates_402656894; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResourceDelegates
  ## Lists the delegates associated with a resource. Users and groups can be resource delegates and answer requests on behalf of the resource.
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
  var query_402656910 = newJObject()
  var body_402656911 = newJObject()
  add(query_402656910, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656911 = body
  add(query_402656910, "NextToken", newJString(NextToken))
  result = call_402656909.call(nil, query_402656910, nil, nil, body_402656911)

var listResourceDelegates* = Call_ListResourceDelegates_402656894(
    name: "listResourceDelegates", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListResourceDelegates",
    validator: validate_ListResourceDelegates_402656895, base: "/",
    makeUrl: url_ListResourceDelegates_402656896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResources_402656912 = ref object of OpenApiRestCall_402656044
proc url_ListResources_402656914(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResources_402656913(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns summaries of the organization's resources.
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
  var valid_402656915 = query.getOrDefault("MaxResults")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "MaxResults", valid_402656915
  var valid_402656916 = query.getOrDefault("NextToken")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "NextToken", valid_402656916
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
  var valid_402656917 = header.getOrDefault("X-Amz-Target")
  valid_402656917 = validateParameter(valid_402656917, JString, required = true, default = newJString(
      "WorkMailService.ListResources"))
  if valid_402656917 != nil:
    section.add "X-Amz-Target", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Security-Token", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Signature")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Signature", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Algorithm", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Date")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Date", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Credential")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Credential", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656924
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

proc call*(call_402656926: Call_ListResources_402656912; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns summaries of the organization's resources.
                                                                                         ## 
  let valid = call_402656926.validator(path, query, header, formData, body, _)
  let scheme = call_402656926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656926.makeUrl(scheme.get, call_402656926.host, call_402656926.base,
                                   call_402656926.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656926, uri, valid, _)

proc call*(call_402656927: Call_ListResources_402656912; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listResources
  ## Returns summaries of the organization's resources.
  ##   MaxResults: string
                                                       ##             : Pagination limit
  ##   
                                                                                        ## body: JObject (required)
  ##   
                                                                                                                   ## NextToken: string
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## Pagination 
                                                                                                                   ## token
  var query_402656928 = newJObject()
  var body_402656929 = newJObject()
  add(query_402656928, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656929 = body
  add(query_402656928, "NextToken", newJString(NextToken))
  result = call_402656927.call(nil, query_402656928, nil, nil, body_402656929)

var listResources* = Call_ListResources_402656912(name: "listResources",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListResources",
    validator: validate_ListResources_402656913, base: "/",
    makeUrl: url_ListResources_402656914, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656930 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656932(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656931(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the tags applied to an Amazon WorkMail organization resource.
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
  var valid_402656933 = header.getOrDefault("X-Amz-Target")
  valid_402656933 = validateParameter(valid_402656933, JString, required = true, default = newJString(
      "WorkMailService.ListTagsForResource"))
  if valid_402656933 != nil:
    section.add "X-Amz-Target", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Security-Token", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Signature")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Signature", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Algorithm", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Date")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Date", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Credential")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Credential", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656940
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

proc call*(call_402656942: Call_ListTagsForResource_402656930;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tags applied to an Amazon WorkMail organization resource.
                                                                                         ## 
  let valid = call_402656942.validator(path, query, header, formData, body, _)
  let scheme = call_402656942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656942.makeUrl(scheme.get, call_402656942.host, call_402656942.base,
                                   call_402656942.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656942, uri, valid, _)

proc call*(call_402656943: Call_ListTagsForResource_402656930; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists the tags applied to an Amazon WorkMail organization resource.
  ##   body: JObject 
                                                                        ## (required)
  var body_402656944 = newJObject()
  if body != nil:
    body_402656944 = body
  result = call_402656943.call(nil, nil, nil, nil, body_402656944)

var listTagsForResource* = Call_ListTagsForResource_402656930(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListTagsForResource",
    validator: validate_ListTagsForResource_402656931, base: "/",
    makeUrl: url_ListTagsForResource_402656932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_402656945 = ref object of OpenApiRestCall_402656044
proc url_ListUsers_402656947(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUsers_402656946(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns summaries of the organization's users.
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
  var valid_402656948 = query.getOrDefault("MaxResults")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "MaxResults", valid_402656948
  var valid_402656949 = query.getOrDefault("NextToken")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "NextToken", valid_402656949
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
  var valid_402656950 = header.getOrDefault("X-Amz-Target")
  valid_402656950 = validateParameter(valid_402656950, JString, required = true, default = newJString(
      "WorkMailService.ListUsers"))
  if valid_402656950 != nil:
    section.add "X-Amz-Target", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Security-Token", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Signature")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Signature", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Algorithm", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Date")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Date", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Credential")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Credential", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656957
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

proc call*(call_402656959: Call_ListUsers_402656945; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns summaries of the organization's users.
                                                                                         ## 
  let valid = call_402656959.validator(path, query, header, formData, body, _)
  let scheme = call_402656959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656959.makeUrl(scheme.get, call_402656959.host, call_402656959.base,
                                   call_402656959.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656959, uri, valid, _)

proc call*(call_402656960: Call_ListUsers_402656945; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUsers
  ## Returns summaries of the organization's users.
  ##   MaxResults: string
                                                   ##             : Pagination limit
  ##   
                                                                                    ## body: JObject (required)
  ##   
                                                                                                               ## NextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## token
  var query_402656961 = newJObject()
  var body_402656962 = newJObject()
  add(query_402656961, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656962 = body
  add(query_402656961, "NextToken", newJString(NextToken))
  result = call_402656960.call(nil, query_402656961, nil, nil, body_402656962)

var listUsers* = Call_ListUsers_402656945(name: "listUsers",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ListUsers",
    validator: validate_ListUsers_402656946, base: "/", makeUrl: url_ListUsers_402656947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccessControlRule_402656963 = ref object of OpenApiRestCall_402656044
proc url_PutAccessControlRule_402656965(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccessControlRule_402656964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a new access control rule for the specified organization. The rule allows or denies access to the organization for the specified IPv4 addresses, access protocol actions, and user IDs. Adding a new rule with the same name as an existing rule replaces the older rule.
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
  var valid_402656966 = header.getOrDefault("X-Amz-Target")
  valid_402656966 = validateParameter(valid_402656966, JString, required = true, default = newJString(
      "WorkMailService.PutAccessControlRule"))
  if valid_402656966 != nil:
    section.add "X-Amz-Target", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Security-Token", valid_402656967
  var valid_402656968 = header.getOrDefault("X-Amz-Signature")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "X-Amz-Signature", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Algorithm", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Date")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Date", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Credential")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Credential", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656973
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

proc call*(call_402656975: Call_PutAccessControlRule_402656963;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new access control rule for the specified organization. The rule allows or denies access to the organization for the specified IPv4 addresses, access protocol actions, and user IDs. Adding a new rule with the same name as an existing rule replaces the older rule.
                                                                                         ## 
  let valid = call_402656975.validator(path, query, header, formData, body, _)
  let scheme = call_402656975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656975.makeUrl(scheme.get, call_402656975.host, call_402656975.base,
                                   call_402656975.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656975, uri, valid, _)

proc call*(call_402656976: Call_PutAccessControlRule_402656963; body: JsonNode): Recallable =
  ## putAccessControlRule
  ## Adds a new access control rule for the specified organization. The rule allows or denies access to the organization for the specified IPv4 addresses, access protocol actions, and user IDs. Adding a new rule with the same name as an existing rule replaces the older rule.
  ##   
                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656977 = newJObject()
  if body != nil:
    body_402656977 = body
  result = call_402656976.call(nil, nil, nil, nil, body_402656977)

var putAccessControlRule* = Call_PutAccessControlRule_402656963(
    name: "putAccessControlRule", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.PutAccessControlRule",
    validator: validate_PutAccessControlRule_402656964, base: "/",
    makeUrl: url_PutAccessControlRule_402656965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutMailboxPermissions_402656978 = ref object of OpenApiRestCall_402656044
proc url_PutMailboxPermissions_402656980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutMailboxPermissions_402656979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets permissions for a user, group, or resource. This replaces any pre-existing permissions.
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
  var valid_402656981 = header.getOrDefault("X-Amz-Target")
  valid_402656981 = validateParameter(valid_402656981, JString, required = true, default = newJString(
      "WorkMailService.PutMailboxPermissions"))
  if valid_402656981 != nil:
    section.add "X-Amz-Target", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Security-Token", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-Signature")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Signature", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Algorithm", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Date")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Date", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Credential")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Credential", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656988
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

proc call*(call_402656990: Call_PutMailboxPermissions_402656978;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets permissions for a user, group, or resource. This replaces any pre-existing permissions.
                                                                                         ## 
  let valid = call_402656990.validator(path, query, header, formData, body, _)
  let scheme = call_402656990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656990.makeUrl(scheme.get, call_402656990.host, call_402656990.base,
                                   call_402656990.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656990, uri, valid, _)

proc call*(call_402656991: Call_PutMailboxPermissions_402656978; body: JsonNode): Recallable =
  ## putMailboxPermissions
  ## Sets permissions for a user, group, or resource. This replaces any pre-existing permissions.
  ##   
                                                                                                 ## body: JObject (required)
  var body_402656992 = newJObject()
  if body != nil:
    body_402656992 = body
  result = call_402656991.call(nil, nil, nil, nil, body_402656992)

var putMailboxPermissions* = Call_PutMailboxPermissions_402656978(
    name: "putMailboxPermissions", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.PutMailboxPermissions",
    validator: validate_PutMailboxPermissions_402656979, base: "/",
    makeUrl: url_PutMailboxPermissions_402656980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterToWorkMail_402656993 = ref object of OpenApiRestCall_402656044
proc url_RegisterToWorkMail_402656995(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterToWorkMail_402656994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Registers an existing and disabled user, group, or resource for Amazon WorkMail use by associating a mailbox and calendaring capabilities. It performs no change if the user, group, or resource is enabled and fails if the user, group, or resource is deleted. This operation results in the accumulation of costs. For more information, see <a href="https://aws.amazon.com/workmail/pricing">Pricing</a>. The equivalent console functionality for this operation is <i>Enable</i>. </p> <p>Users can either be created by calling the <a>CreateUser</a> API operation or they can be synchronized from your directory. For more information, see <a>DeregisterFromWorkMail</a>.</p>
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
  var valid_402656996 = header.getOrDefault("X-Amz-Target")
  valid_402656996 = validateParameter(valid_402656996, JString, required = true, default = newJString(
      "WorkMailService.RegisterToWorkMail"))
  if valid_402656996 != nil:
    section.add "X-Amz-Target", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Security-Token", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Signature")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Signature", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Algorithm", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Date")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Date", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Credential")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Credential", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657003
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

proc call*(call_402657005: Call_RegisterToWorkMail_402656993;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers an existing and disabled user, group, or resource for Amazon WorkMail use by associating a mailbox and calendaring capabilities. It performs no change if the user, group, or resource is enabled and fails if the user, group, or resource is deleted. This operation results in the accumulation of costs. For more information, see <a href="https://aws.amazon.com/workmail/pricing">Pricing</a>. The equivalent console functionality for this operation is <i>Enable</i>. </p> <p>Users can either be created by calling the <a>CreateUser</a> API operation or they can be synchronized from your directory. For more information, see <a>DeregisterFromWorkMail</a>.</p>
                                                                                         ## 
  let valid = call_402657005.validator(path, query, header, formData, body, _)
  let scheme = call_402657005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657005.makeUrl(scheme.get, call_402657005.host, call_402657005.base,
                                   call_402657005.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657005, uri, valid, _)

proc call*(call_402657006: Call_RegisterToWorkMail_402656993; body: JsonNode): Recallable =
  ## registerToWorkMail
  ## <p>Registers an existing and disabled user, group, or resource for Amazon WorkMail use by associating a mailbox and calendaring capabilities. It performs no change if the user, group, or resource is enabled and fails if the user, group, or resource is deleted. This operation results in the accumulation of costs. For more information, see <a href="https://aws.amazon.com/workmail/pricing">Pricing</a>. The equivalent console functionality for this operation is <i>Enable</i>. </p> <p>Users can either be created by calling the <a>CreateUser</a> API operation or they can be synchronized from your directory. For more information, see <a>DeregisterFromWorkMail</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402657007 = newJObject()
  if body != nil:
    body_402657007 = body
  result = call_402657006.call(nil, nil, nil, nil, body_402657007)

var registerToWorkMail* = Call_RegisterToWorkMail_402656993(
    name: "registerToWorkMail", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.RegisterToWorkMail",
    validator: validate_RegisterToWorkMail_402656994, base: "/",
    makeUrl: url_RegisterToWorkMail_402656995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetPassword_402657008 = ref object of OpenApiRestCall_402656044
proc url_ResetPassword_402657010(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetPassword_402657009(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Allows the administrator to reset the password for a user.
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
  var valid_402657011 = header.getOrDefault("X-Amz-Target")
  valid_402657011 = validateParameter(valid_402657011, JString, required = true, default = newJString(
      "WorkMailService.ResetPassword"))
  if valid_402657011 != nil:
    section.add "X-Amz-Target", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Security-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
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

proc call*(call_402657020: Call_ResetPassword_402657008; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows the administrator to reset the password for a user.
                                                                                         ## 
  let valid = call_402657020.validator(path, query, header, formData, body, _)
  let scheme = call_402657020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657020.makeUrl(scheme.get, call_402657020.host, call_402657020.base,
                                   call_402657020.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657020, uri, valid, _)

proc call*(call_402657021: Call_ResetPassword_402657008; body: JsonNode): Recallable =
  ## resetPassword
  ## Allows the administrator to reset the password for a user.
  ##   body: JObject (required)
  var body_402657022 = newJObject()
  if body != nil:
    body_402657022 = body
  result = call_402657021.call(nil, nil, nil, nil, body_402657022)

var resetPassword* = Call_ResetPassword_402657008(name: "resetPassword",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.ResetPassword",
    validator: validate_ResetPassword_402657009, base: "/",
    makeUrl: url_ResetPassword_402657010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657023 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657025(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657024(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Applies the specified tags to the specified Amazon WorkMail organization resource.
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
  var valid_402657026 = header.getOrDefault("X-Amz-Target")
  valid_402657026 = validateParameter(valid_402657026, JString, required = true, default = newJString(
      "WorkMailService.TagResource"))
  if valid_402657026 != nil:
    section.add "X-Amz-Target", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Security-Token", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Signature")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Signature", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Algorithm", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Date")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Date", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Credential")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Credential", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657033
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

proc call*(call_402657035: Call_TagResource_402657023; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies the specified tags to the specified Amazon WorkMail organization resource.
                                                                                         ## 
  let valid = call_402657035.validator(path, query, header, formData, body, _)
  let scheme = call_402657035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657035.makeUrl(scheme.get, call_402657035.host, call_402657035.base,
                                   call_402657035.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657035, uri, valid, _)

proc call*(call_402657036: Call_TagResource_402657023; body: JsonNode): Recallable =
  ## tagResource
  ## Applies the specified tags to the specified Amazon WorkMail organization resource.
  ##   
                                                                                       ## body: JObject (required)
  var body_402657037 = newJObject()
  if body != nil:
    body_402657037 = body
  result = call_402657036.call(nil, nil, nil, nil, body_402657037)

var tagResource* = Call_TagResource_402657023(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.TagResource",
    validator: validate_TagResource_402657024, base: "/",
    makeUrl: url_TagResource_402657025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657038 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657040(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657039(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Untags the specified tags from the specified Amazon WorkMail organization resource.
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
  var valid_402657041 = header.getOrDefault("X-Amz-Target")
  valid_402657041 = validateParameter(valid_402657041, JString, required = true, default = newJString(
      "WorkMailService.UntagResource"))
  if valid_402657041 != nil:
    section.add "X-Amz-Target", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Security-Token", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Signature")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Signature", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Algorithm", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Date")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Date", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Credential")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Credential", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657048
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

proc call*(call_402657050: Call_UntagResource_402657038; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Untags the specified tags from the specified Amazon WorkMail organization resource.
                                                                                         ## 
  let valid = call_402657050.validator(path, query, header, formData, body, _)
  let scheme = call_402657050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657050.makeUrl(scheme.get, call_402657050.host, call_402657050.base,
                                   call_402657050.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657050, uri, valid, _)

proc call*(call_402657051: Call_UntagResource_402657038; body: JsonNode): Recallable =
  ## untagResource
  ## Untags the specified tags from the specified Amazon WorkMail organization resource.
  ##   
                                                                                        ## body: JObject (required)
  var body_402657052 = newJObject()
  if body != nil:
    body_402657052 = body
  result = call_402657051.call(nil, nil, nil, nil, body_402657052)

var untagResource* = Call_UntagResource_402657038(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.UntagResource",
    validator: validate_UntagResource_402657039, base: "/",
    makeUrl: url_UntagResource_402657040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMailboxQuota_402657053 = ref object of OpenApiRestCall_402656044
proc url_UpdateMailboxQuota_402657055(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMailboxQuota_402657054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a user's current mailbox quota for a specified organization and user.
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
  var valid_402657056 = header.getOrDefault("X-Amz-Target")
  valid_402657056 = validateParameter(valid_402657056, JString, required = true, default = newJString(
      "WorkMailService.UpdateMailboxQuota"))
  if valid_402657056 != nil:
    section.add "X-Amz-Target", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Security-Token", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Signature")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Signature", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Algorithm", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Date")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Date", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Credential")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Credential", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657063
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

proc call*(call_402657065: Call_UpdateMailboxQuota_402657053;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a user's current mailbox quota for a specified organization and user.
                                                                                         ## 
  let valid = call_402657065.validator(path, query, header, formData, body, _)
  let scheme = call_402657065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657065.makeUrl(scheme.get, call_402657065.host, call_402657065.base,
                                   call_402657065.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657065, uri, valid, _)

proc call*(call_402657066: Call_UpdateMailboxQuota_402657053; body: JsonNode): Recallable =
  ## updateMailboxQuota
  ## Updates a user's current mailbox quota for a specified organization and user.
  ##   
                                                                                  ## body: JObject (required)
  var body_402657067 = newJObject()
  if body != nil:
    body_402657067 = body
  result = call_402657066.call(nil, nil, nil, nil, body_402657067)

var updateMailboxQuota* = Call_UpdateMailboxQuota_402657053(
    name: "updateMailboxQuota", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.UpdateMailboxQuota",
    validator: validate_UpdateMailboxQuota_402657054, base: "/",
    makeUrl: url_UpdateMailboxQuota_402657055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePrimaryEmailAddress_402657068 = ref object of OpenApiRestCall_402656044
proc url_UpdatePrimaryEmailAddress_402657070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePrimaryEmailAddress_402657069(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates the primary email for a user, group, or resource. The current email is moved into the list of aliases (or swapped between an existing alias and the current primary email), and the email provided in the input is promoted as the primary.
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
  var valid_402657071 = header.getOrDefault("X-Amz-Target")
  valid_402657071 = validateParameter(valid_402657071, JString, required = true, default = newJString(
      "WorkMailService.UpdatePrimaryEmailAddress"))
  if valid_402657071 != nil:
    section.add "X-Amz-Target", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Security-Token", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Signature")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Signature", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Algorithm", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Date")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Date", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Credential")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Credential", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657078
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

proc call*(call_402657080: Call_UpdatePrimaryEmailAddress_402657068;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the primary email for a user, group, or resource. The current email is moved into the list of aliases (or swapped between an existing alias and the current primary email), and the email provided in the input is promoted as the primary.
                                                                                         ## 
  let valid = call_402657080.validator(path, query, header, formData, body, _)
  let scheme = call_402657080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657080.makeUrl(scheme.get, call_402657080.host, call_402657080.base,
                                   call_402657080.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657080, uri, valid, _)

proc call*(call_402657081: Call_UpdatePrimaryEmailAddress_402657068;
           body: JsonNode): Recallable =
  ## updatePrimaryEmailAddress
  ## Updates the primary email for a user, group, or resource. The current email is moved into the list of aliases (or swapped between an existing alias and the current primary email), and the email provided in the input is promoted as the primary.
  ##   
                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657082 = newJObject()
  if body != nil:
    body_402657082 = body
  result = call_402657081.call(nil, nil, nil, nil, body_402657082)

var updatePrimaryEmailAddress* = Call_UpdatePrimaryEmailAddress_402657068(
    name: "updatePrimaryEmailAddress", meth: HttpMethod.HttpPost,
    host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.UpdatePrimaryEmailAddress",
    validator: validate_UpdatePrimaryEmailAddress_402657069, base: "/",
    makeUrl: url_UpdatePrimaryEmailAddress_402657070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResource_402657083 = ref object of OpenApiRestCall_402656044
proc url_UpdateResource_402657085(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResource_402657084(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates data for the resource. To have the latest information, it must be preceded by a <a>DescribeResource</a> call. The dataset in the request should be the one expected when performing another <code>DescribeResource</code> call.
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
  var valid_402657086 = header.getOrDefault("X-Amz-Target")
  valid_402657086 = validateParameter(valid_402657086, JString, required = true, default = newJString(
      "WorkMailService.UpdateResource"))
  if valid_402657086 != nil:
    section.add "X-Amz-Target", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Security-Token", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Signature")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Signature", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Algorithm", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-Date")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-Date", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Credential")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Credential", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657093
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

proc call*(call_402657095: Call_UpdateResource_402657083; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates data for the resource. To have the latest information, it must be preceded by a <a>DescribeResource</a> call. The dataset in the request should be the one expected when performing another <code>DescribeResource</code> call.
                                                                                         ## 
  let valid = call_402657095.validator(path, query, header, formData, body, _)
  let scheme = call_402657095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657095.makeUrl(scheme.get, call_402657095.host, call_402657095.base,
                                   call_402657095.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657095, uri, valid, _)

proc call*(call_402657096: Call_UpdateResource_402657083; body: JsonNode): Recallable =
  ## updateResource
  ## Updates data for the resource. To have the latest information, it must be preceded by a <a>DescribeResource</a> call. The dataset in the request should be the one expected when performing another <code>DescribeResource</code> call.
  ##   
                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402657097 = newJObject()
  if body != nil:
    body_402657097 = body
  result = call_402657096.call(nil, nil, nil, nil, body_402657097)

var updateResource* = Call_UpdateResource_402657083(name: "updateResource",
    meth: HttpMethod.HttpPost, host: "workmail.amazonaws.com",
    route: "/#X-Amz-Target=WorkMailService.UpdateResource",
    validator: validate_UpdateResource_402657084, base: "/",
    makeUrl: url_UpdateResource_402657085, schemes: {Scheme.Https, Scheme.Http})
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