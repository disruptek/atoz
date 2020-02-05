
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "macie.ap-northeast-1.amazonaws.com", "ap-southeast-1": "macie.ap-southeast-1.amazonaws.com",
                           "us-west-2": "macie.us-west-2.amazonaws.com",
                           "eu-west-2": "macie.eu-west-2.amazonaws.com", "ap-northeast-3": "macie.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "macie.eu-central-1.amazonaws.com",
                           "us-east-2": "macie.us-east-2.amazonaws.com",
                           "us-east-1": "macie.us-east-1.amazonaws.com", "cn-northwest-1": "macie.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "macie.ap-south-1.amazonaws.com",
                           "eu-north-1": "macie.eu-north-1.amazonaws.com", "ap-northeast-2": "macie.ap-northeast-2.amazonaws.com",
                           "us-west-1": "macie.us-west-1.amazonaws.com", "us-gov-east-1": "macie.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "macie.eu-west-3.amazonaws.com",
                           "cn-north-1": "macie.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "macie.sa-east-1.amazonaws.com",
                           "eu-west-1": "macie.eu-west-1.amazonaws.com", "us-gov-west-1": "macie.us-gov-west-1.amazonaws.com", "ap-southeast-2": "macie.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "macie.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateMemberAccount_612987 = ref object of OpenApiRestCall_612649
proc url_AssociateMemberAccount_612989(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateMemberAccount_612988(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613114 = header.getOrDefault("X-Amz-Target")
  valid_613114 = validateParameter(valid_613114, JString, required = true, default = newJString(
      "MacieService.AssociateMemberAccount"))
  if valid_613114 != nil:
    section.add "X-Amz-Target", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Signature")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Signature", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Content-Sha256", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Date")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Date", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Credential")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Credential", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Security-Token")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Security-Token", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Algorithm")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Algorithm", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-SignedHeaders", valid_613121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_AssociateMemberAccount_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_AssociateMemberAccount_612987; body: JsonNode): Recallable =
  ## associateMemberAccount
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ##   body: JObject (required)
  var body_613217 = newJObject()
  if body != nil:
    body_613217 = body
  result = call_613216.call(nil, nil, nil, nil, body_613217)

var associateMemberAccount* = Call_AssociateMemberAccount_612987(
    name: "associateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateMemberAccount",
    validator: validate_AssociateMemberAccount_612988, base: "/",
    url: url_AssociateMemberAccount_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateS3Resources_613256 = ref object of OpenApiRestCall_612649
proc url_AssociateS3Resources_613258(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateS3Resources_613257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613259 = header.getOrDefault("X-Amz-Target")
  valid_613259 = validateParameter(valid_613259, JString, required = true, default = newJString(
      "MacieService.AssociateS3Resources"))
  if valid_613259 != nil:
    section.add "X-Amz-Target", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Signature")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Signature", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Content-Sha256", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Date")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Date", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Credential")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Credential", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Security-Token")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Security-Token", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Algorithm")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Algorithm", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-SignedHeaders", valid_613266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613268: Call_AssociateS3Resources_613256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ## 
  let valid = call_613268.validator(path, query, header, formData, body)
  let scheme = call_613268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613268.url(scheme.get, call_613268.host, call_613268.base,
                         call_613268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613268, url, valid)

proc call*(call_613269: Call_AssociateS3Resources_613256; body: JsonNode): Recallable =
  ## associateS3Resources
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ##   body: JObject (required)
  var body_613270 = newJObject()
  if body != nil:
    body_613270 = body
  result = call_613269.call(nil, nil, nil, nil, body_613270)

var associateS3Resources* = Call_AssociateS3Resources_613256(
    name: "associateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateS3Resources",
    validator: validate_AssociateS3Resources_613257, base: "/",
    url: url_AssociateS3Resources_613258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberAccount_613271 = ref object of OpenApiRestCall_612649
proc url_DisassociateMemberAccount_613273(protocol: Scheme; host: string;
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

proc validate_DisassociateMemberAccount_613272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613274 = header.getOrDefault("X-Amz-Target")
  valid_613274 = validateParameter(valid_613274, JString, required = true, default = newJString(
      "MacieService.DisassociateMemberAccount"))
  if valid_613274 != nil:
    section.add "X-Amz-Target", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Signature")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Signature", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Content-Sha256", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Date")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Date", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Credential")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Credential", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Security-Token")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Security-Token", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Algorithm")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Algorithm", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-SignedHeaders", valid_613281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613283: Call_DisassociateMemberAccount_613271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified member account from Amazon Macie.
  ## 
  let valid = call_613283.validator(path, query, header, formData, body)
  let scheme = call_613283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613283.url(scheme.get, call_613283.host, call_613283.base,
                         call_613283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613283, url, valid)

proc call*(call_613284: Call_DisassociateMemberAccount_613271; body: JsonNode): Recallable =
  ## disassociateMemberAccount
  ## Removes the specified member account from Amazon Macie.
  ##   body: JObject (required)
  var body_613285 = newJObject()
  if body != nil:
    body_613285 = body
  result = call_613284.call(nil, nil, nil, nil, body_613285)

var disassociateMemberAccount* = Call_DisassociateMemberAccount_613271(
    name: "disassociateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateMemberAccount",
    validator: validate_DisassociateMemberAccount_613272, base: "/",
    url: url_DisassociateMemberAccount_613273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateS3Resources_613286 = ref object of OpenApiRestCall_612649
proc url_DisassociateS3Resources_613288(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateS3Resources_613287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613289 = header.getOrDefault("X-Amz-Target")
  valid_613289 = validateParameter(valid_613289, JString, required = true, default = newJString(
      "MacieService.DisassociateS3Resources"))
  if valid_613289 != nil:
    section.add "X-Amz-Target", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Signature", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Content-Sha256", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Date")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Date", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Credential")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Credential", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Security-Token")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Security-Token", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Algorithm")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Algorithm", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-SignedHeaders", valid_613296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_DisassociateS3Resources_613286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_DisassociateS3Resources_613286; body: JsonNode): Recallable =
  ## disassociateS3Resources
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ##   body: JObject (required)
  var body_613300 = newJObject()
  if body != nil:
    body_613300 = body
  result = call_613299.call(nil, nil, nil, nil, body_613300)

var disassociateS3Resources* = Call_DisassociateS3Resources_613286(
    name: "disassociateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateS3Resources",
    validator: validate_DisassociateS3Resources_613287, base: "/",
    url: url_DisassociateS3Resources_613288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_613301 = ref object of OpenApiRestCall_612649
proc url_ListMemberAccounts_613303(protocol: Scheme; host: string; base: string;
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

proc validate_ListMemberAccounts_613302(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613304 = query.getOrDefault("nextToken")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "nextToken", valid_613304
  var valid_613305 = query.getOrDefault("maxResults")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "maxResults", valid_613305
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
  var valid_613306 = header.getOrDefault("X-Amz-Target")
  valid_613306 = validateParameter(valid_613306, JString, required = true, default = newJString(
      "MacieService.ListMemberAccounts"))
  if valid_613306 != nil:
    section.add "X-Amz-Target", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_ListMemberAccounts_613301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_ListMemberAccounts_613301; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listMemberAccounts
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613317 = newJObject()
  var body_613318 = newJObject()
  add(query_613317, "nextToken", newJString(nextToken))
  if body != nil:
    body_613318 = body
  add(query_613317, "maxResults", newJString(maxResults))
  result = call_613316.call(nil, query_613317, nil, nil, body_613318)

var listMemberAccounts* = Call_ListMemberAccounts_613301(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListMemberAccounts",
    validator: validate_ListMemberAccounts_613302, base: "/",
    url: url_ListMemberAccounts_613303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListS3Resources_613320 = ref object of OpenApiRestCall_612649
proc url_ListS3Resources_613322(protocol: Scheme; host: string; base: string;
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

proc validate_ListS3Resources_613321(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613323 = query.getOrDefault("nextToken")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "nextToken", valid_613323
  var valid_613324 = query.getOrDefault("maxResults")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "maxResults", valid_613324
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
  var valid_613325 = header.getOrDefault("X-Amz-Target")
  valid_613325 = validateParameter(valid_613325, JString, required = true, default = newJString(
      "MacieService.ListS3Resources"))
  if valid_613325 != nil:
    section.add "X-Amz-Target", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Signature")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Signature", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Content-Sha256", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Date")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Date", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Credential")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Credential", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Security-Token")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Security-Token", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Algorithm")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Algorithm", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-SignedHeaders", valid_613332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613334: Call_ListS3Resources_613320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_613334.validator(path, query, header, formData, body)
  let scheme = call_613334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613334.url(scheme.get, call_613334.host, call_613334.base,
                         call_613334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613334, url, valid)

proc call*(call_613335: Call_ListS3Resources_613320; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listS3Resources
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613336 = newJObject()
  var body_613337 = newJObject()
  add(query_613336, "nextToken", newJString(nextToken))
  if body != nil:
    body_613337 = body
  add(query_613336, "maxResults", newJString(maxResults))
  result = call_613335.call(nil, query_613336, nil, nil, body_613337)

var listS3Resources* = Call_ListS3Resources_613320(name: "listS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListS3Resources",
    validator: validate_ListS3Resources_613321, base: "/", url: url_ListS3Resources_613322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateS3Resources_613338 = ref object of OpenApiRestCall_612649
proc url_UpdateS3Resources_613340(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateS3Resources_613339(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613341 = header.getOrDefault("X-Amz-Target")
  valid_613341 = validateParameter(valid_613341, JString, required = true, default = newJString(
      "MacieService.UpdateS3Resources"))
  if valid_613341 != nil:
    section.add "X-Amz-Target", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Signature")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Signature", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Content-Sha256", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Date")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Date", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Credential")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Credential", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Security-Token")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Security-Token", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Algorithm")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Algorithm", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-SignedHeaders", valid_613348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613350: Call_UpdateS3Resources_613338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_613350.validator(path, query, header, formData, body)
  let scheme = call_613350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613350.url(scheme.get, call_613350.host, call_613350.base,
                         call_613350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613350, url, valid)

proc call*(call_613351: Call_UpdateS3Resources_613338; body: JsonNode): Recallable =
  ## updateS3Resources
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ##   body: JObject (required)
  var body_613352 = newJObject()
  if body != nil:
    body_613352 = body
  result = call_613351.call(nil, nil, nil, nil, body_613352)

var updateS3Resources* = Call_UpdateS3Resources_613338(name: "updateS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.UpdateS3Resources",
    validator: validate_UpdateS3Resources_613339, base: "/",
    url: url_UpdateS3Resources_613340, schemes: {Scheme.Https, Scheme.Http})
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
