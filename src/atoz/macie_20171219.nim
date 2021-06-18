
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Macie
## version: 2017-12-19
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Macie</fullname> <p>Amazon Macie is a security service that uses machine learning to automatically discover, classify, and protect sensitive data in AWS. Macie recognizes sensitive data such as personally identifiable information (PII) or intellectual property, and provides you with dashboards and alerts that give visibility into how this data is being accessed or moved. For more information, see the <a href="https://docs.aws.amazon.com/macie/latest/userguide/what-is-macie.html">Macie User Guide</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/macie/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "macie.ap-northeast-1.amazonaws.com", "ap-southeast-1": "macie.ap-southeast-1.amazonaws.com",
                               "us-west-2": "macie.us-west-2.amazonaws.com",
                               "eu-west-2": "macie.eu-west-2.amazonaws.com", "ap-northeast-3": "macie.ap-northeast-3.amazonaws.com", "eu-central-1": "macie.eu-central-1.amazonaws.com",
                               "us-east-2": "macie.us-east-2.amazonaws.com",
                               "us-east-1": "macie.us-east-1.amazonaws.com", "cn-northwest-1": "macie.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "macie.ap-south-1.amazonaws.com",
                               "eu-north-1": "macie.eu-north-1.amazonaws.com", "ap-northeast-2": "macie.ap-northeast-2.amazonaws.com",
                               "us-west-1": "macie.us-west-1.amazonaws.com", "us-gov-east-1": "macie.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "macie.eu-west-3.amazonaws.com", "cn-north-1": "macie.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "macie.sa-east-1.amazonaws.com",
                               "eu-west-1": "macie.eu-west-1.amazonaws.com", "us-gov-west-1": "macie.us-gov-west-1.amazonaws.com", "ap-southeast-2": "macie.ap-southeast-2.amazonaws.com", "ca-central-1": "macie.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "macie.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "macie.ap-southeast-1.amazonaws.com",
      "us-west-2": "macie.us-west-2.amazonaws.com",
      "eu-west-2": "macie.eu-west-2.amazonaws.com",
      "ap-northeast-3": "macie.ap-northeast-3.amazonaws.com",
      "eu-central-1": "macie.eu-central-1.amazonaws.com",
      "us-east-2": "macie.us-east-2.amazonaws.com",
      "us-east-1": "macie.us-east-1.amazonaws.com",
      "cn-northwest-1": "macie.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "macie.ap-south-1.amazonaws.com",
      "eu-north-1": "macie.eu-north-1.amazonaws.com",
      "ap-northeast-2": "macie.ap-northeast-2.amazonaws.com",
      "us-west-1": "macie.us-west-1.amazonaws.com",
      "us-gov-east-1": "macie.us-gov-east-1.amazonaws.com",
      "eu-west-3": "macie.eu-west-3.amazonaws.com",
      "cn-north-1": "macie.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "macie.sa-east-1.amazonaws.com",
      "eu-west-1": "macie.eu-west-1.amazonaws.com",
      "us-gov-west-1": "macie.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "macie.ap-southeast-2.amazonaws.com",
      "ca-central-1": "macie.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "macie"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateMemberAccount_402656288 = ref object of OpenApiRestCall_402656038
proc url_AssociateMemberAccount_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateMemberAccount_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates a specified AWS account with Amazon Macie as a member account.
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
  var valid_402656384 = header.getOrDefault("X-Amz-Target")
  valid_402656384 = validateParameter(valid_402656384, JString, required = true, default = newJString(
      "MacieService.AssociateMemberAccount"))
  if valid_402656384 != nil:
    section.add "X-Amz-Target", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Security-Token", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Signature")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Signature", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Algorithm", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Date")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Date", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Credential")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Credential", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656391
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

proc call*(call_402656406: Call_AssociateMemberAccount_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a specified AWS account with Amazon Macie as a member account.
                                                                                         ## 
  let valid = call_402656406.validator(path, query, header, formData, body, _)
  let scheme = call_402656406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656406.makeUrl(scheme.get, call_402656406.host, call_402656406.base,
                                   call_402656406.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656406, uri, valid, _)

proc call*(call_402656455: Call_AssociateMemberAccount_402656288; body: JsonNode): Recallable =
  ## associateMemberAccount
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ##   
                                                                              ## body: JObject (required)
  var body_402656456 = newJObject()
  if body != nil:
    body_402656456 = body
  result = call_402656455.call(nil, nil, nil, nil, body_402656456)

var associateMemberAccount* = Call_AssociateMemberAccount_402656288(
    name: "associateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateMemberAccount",
    validator: validate_AssociateMemberAccount_402656289, base: "/",
    makeUrl: url_AssociateMemberAccount_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateS3Resources_402656483 = ref object of OpenApiRestCall_402656038
proc url_AssociateS3Resources_402656485(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateS3Resources_402656484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
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
  var valid_402656486 = header.getOrDefault("X-Amz-Target")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "MacieService.AssociateS3Resources"))
  if valid_402656486 != nil:
    section.add "X-Amz-Target", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
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

proc call*(call_402656495: Call_AssociateS3Resources_402656483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_AssociateS3Resources_402656483; body: JsonNode): Recallable =
  ## associateS3Resources
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ##   
                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656497 = newJObject()
  if body != nil:
    body_402656497 = body
  result = call_402656496.call(nil, nil, nil, nil, body_402656497)

var associateS3Resources* = Call_AssociateS3Resources_402656483(
    name: "associateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateS3Resources",
    validator: validate_AssociateS3Resources_402656484, base: "/",
    makeUrl: url_AssociateS3Resources_402656485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberAccount_402656498 = ref object of OpenApiRestCall_402656038
proc url_DisassociateMemberAccount_402656500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMemberAccount_402656499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes the specified member account from Amazon Macie.
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
  var valid_402656501 = header.getOrDefault("X-Amz-Target")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true, default = newJString(
      "MacieService.DisassociateMemberAccount"))
  if valid_402656501 != nil:
    section.add "X-Amz-Target", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
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

proc call*(call_402656510: Call_DisassociateMemberAccount_402656498;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified member account from Amazon Macie.
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_DisassociateMemberAccount_402656498;
           body: JsonNode): Recallable =
  ## disassociateMemberAccount
  ## Removes the specified member account from Amazon Macie.
  ##   body: JObject (required)
  var body_402656512 = newJObject()
  if body != nil:
    body_402656512 = body
  result = call_402656511.call(nil, nil, nil, nil, body_402656512)

var disassociateMemberAccount* = Call_DisassociateMemberAccount_402656498(
    name: "disassociateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateMemberAccount",
    validator: validate_DisassociateMemberAccount_402656499, base: "/",
    makeUrl: url_DisassociateMemberAccount_402656500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateS3Resources_402656513 = ref object of OpenApiRestCall_402656038
proc url_DisassociateS3Resources_402656515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateS3Resources_402656514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
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
  var valid_402656516 = header.getOrDefault("X-Amz-Target")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true, default = newJString(
      "MacieService.DisassociateS3Resources"))
  if valid_402656516 != nil:
    section.add "X-Amz-Target", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Security-Token", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Signature")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Signature", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Algorithm", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Date")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Date", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Credential")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Credential", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656523
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

proc call*(call_402656525: Call_DisassociateS3Resources_402656513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_DisassociateS3Resources_402656513;
           body: JsonNode): Recallable =
  ## disassociateS3Resources
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ##   
                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656527 = newJObject()
  if body != nil:
    body_402656527 = body
  result = call_402656526.call(nil, nil, nil, nil, body_402656527)

var disassociateS3Resources* = Call_DisassociateS3Resources_402656513(
    name: "disassociateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateS3Resources",
    validator: validate_DisassociateS3Resources_402656514, base: "/",
    makeUrl: url_DisassociateS3Resources_402656515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_402656528 = ref object of OpenApiRestCall_402656038
proc url_ListMemberAccounts_402656530(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMemberAccounts_402656529(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656531 = query.getOrDefault("maxResults")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "maxResults", valid_402656531
  var valid_402656532 = query.getOrDefault("nextToken")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "nextToken", valid_402656532
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
  var valid_402656533 = header.getOrDefault("X-Amz-Target")
  valid_402656533 = validateParameter(valid_402656533, JString, required = true, default = newJString(
      "MacieService.ListMemberAccounts"))
  if valid_402656533 != nil:
    section.add "X-Amz-Target", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Security-Token", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Signature")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Signature", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Algorithm", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Date")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Date", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Credential")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Credential", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656540
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

proc call*(call_402656542: Call_ListMemberAccounts_402656528;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
                                                                                         ## 
  let valid = call_402656542.validator(path, query, header, formData, body, _)
  let scheme = call_402656542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656542.makeUrl(scheme.get, call_402656542.host, call_402656542.base,
                                   call_402656542.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656542, uri, valid, _)

proc call*(call_402656543: Call_ListMemberAccounts_402656528; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listMemberAccounts
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ##   
                                                                                        ## maxResults: string
                                                                                        ##             
                                                                                        ## : 
                                                                                        ## Pagination 
                                                                                        ## limit
  ##   
                                                                                                ## nextToken: string
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## Pagination 
                                                                                                ## token
  ##   
                                                                                                        ## body: JObject (required)
  var query_402656544 = newJObject()
  var body_402656545 = newJObject()
  add(query_402656544, "maxResults", newJString(maxResults))
  add(query_402656544, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656545 = body
  result = call_402656543.call(nil, query_402656544, nil, nil, body_402656545)

var listMemberAccounts* = Call_ListMemberAccounts_402656528(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListMemberAccounts",
    validator: validate_ListMemberAccounts_402656529, base: "/",
    makeUrl: url_ListMemberAccounts_402656530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListS3Resources_402656546 = ref object of OpenApiRestCall_402656038
proc url_ListS3Resources_402656548(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListS3Resources_402656547(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
                                  ##             : Pagination limit
  ##   nextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656549 = query.getOrDefault("maxResults")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "maxResults", valid_402656549
  var valid_402656550 = query.getOrDefault("nextToken")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "nextToken", valid_402656550
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
  var valid_402656551 = header.getOrDefault("X-Amz-Target")
  valid_402656551 = validateParameter(valid_402656551, JString, required = true, default = newJString(
      "MacieService.ListS3Resources"))
  if valid_402656551 != nil:
    section.add "X-Amz-Target", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Security-Token", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Signature")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Signature", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Algorithm", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Date")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Date", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Credential")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Credential", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656558
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

proc call*(call_402656560: Call_ListS3Resources_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
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

proc call*(call_402656561: Call_ListS3Resources_402656546; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listS3Resources
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ##   
                                                                                                                                                                                                                                                                                                                                   ## maxResults: string
                                                                                                                                                                                                                                                                                                                                   ##             
                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                   ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                           ## nextToken: string
                                                                                                                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                                                                                                                                           ## token
  ##   
                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var query_402656562 = newJObject()
  var body_402656563 = newJObject()
  add(query_402656562, "maxResults", newJString(maxResults))
  add(query_402656562, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656563 = body
  result = call_402656561.call(nil, query_402656562, nil, nil, body_402656563)

var listS3Resources* = Call_ListS3Resources_402656546(name: "listS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListS3Resources",
    validator: validate_ListS3Resources_402656547, base: "/",
    makeUrl: url_ListS3Resources_402656548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateS3Resources_402656564 = ref object of OpenApiRestCall_402656038
proc url_UpdateS3Resources_402656566(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateS3Resources_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
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
      "MacieService.UpdateS3Resources"))
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

proc call*(call_402656576: Call_UpdateS3Resources_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
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

proc call*(call_402656577: Call_UpdateS3Resources_402656564; body: JsonNode): Recallable =
  ## updateS3Resources
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var updateS3Resources* = Call_UpdateS3Resources_402656564(
    name: "updateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.UpdateS3Resources",
    validator: validate_UpdateS3Resources_402656565, base: "/",
    makeUrl: url_UpdateS3Resources_402656566,
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