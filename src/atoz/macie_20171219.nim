
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593424): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateMemberAccount_593761 = ref object of OpenApiRestCall_593424
proc url_AssociateMemberAccount_593763(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateMemberAccount_593762(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593875 = header.getOrDefault("X-Amz-Date")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Date", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Security-Token")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Security-Token", valid_593876
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593890 = header.getOrDefault("X-Amz-Target")
  valid_593890 = validateParameter(valid_593890, JString, required = true, default = newJString(
      "MacieService.AssociateMemberAccount"))
  if valid_593890 != nil:
    section.add "X-Amz-Target", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Content-Sha256", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Algorithm")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Algorithm", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Signature")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Signature", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-SignedHeaders", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Credential")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Credential", valid_593895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593919: Call_AssociateMemberAccount_593761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ## 
  let valid = call_593919.validator(path, query, header, formData, body)
  let scheme = call_593919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593919.url(scheme.get, call_593919.host, call_593919.base,
                         call_593919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593919, url, valid)

proc call*(call_593990: Call_AssociateMemberAccount_593761; body: JsonNode): Recallable =
  ## associateMemberAccount
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ##   body: JObject (required)
  var body_593991 = newJObject()
  if body != nil:
    body_593991 = body
  result = call_593990.call(nil, nil, nil, nil, body_593991)

var associateMemberAccount* = Call_AssociateMemberAccount_593761(
    name: "associateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateMemberAccount",
    validator: validate_AssociateMemberAccount_593762, base: "/",
    url: url_AssociateMemberAccount_593763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateS3Resources_594030 = ref object of OpenApiRestCall_593424
proc url_AssociateS3Resources_594032(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateS3Resources_594031(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594033 = header.getOrDefault("X-Amz-Date")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Date", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594035 = header.getOrDefault("X-Amz-Target")
  valid_594035 = validateParameter(valid_594035, JString, required = true, default = newJString(
      "MacieService.AssociateS3Resources"))
  if valid_594035 != nil:
    section.add "X-Amz-Target", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Content-Sha256", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Algorithm")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Algorithm", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Signature")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Signature", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-SignedHeaders", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Credential")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Credential", valid_594040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594042: Call_AssociateS3Resources_594030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ## 
  let valid = call_594042.validator(path, query, header, formData, body)
  let scheme = call_594042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594042.url(scheme.get, call_594042.host, call_594042.base,
                         call_594042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594042, url, valid)

proc call*(call_594043: Call_AssociateS3Resources_594030; body: JsonNode): Recallable =
  ## associateS3Resources
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ##   body: JObject (required)
  var body_594044 = newJObject()
  if body != nil:
    body_594044 = body
  result = call_594043.call(nil, nil, nil, nil, body_594044)

var associateS3Resources* = Call_AssociateS3Resources_594030(
    name: "associateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateS3Resources",
    validator: validate_AssociateS3Resources_594031, base: "/",
    url: url_AssociateS3Resources_594032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberAccount_594045 = ref object of OpenApiRestCall_593424
proc url_DisassociateMemberAccount_594047(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateMemberAccount_594046(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594048 = header.getOrDefault("X-Amz-Date")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Date", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594050 = header.getOrDefault("X-Amz-Target")
  valid_594050 = validateParameter(valid_594050, JString, required = true, default = newJString(
      "MacieService.DisassociateMemberAccount"))
  if valid_594050 != nil:
    section.add "X-Amz-Target", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Content-Sha256", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Algorithm")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Algorithm", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Signature")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Signature", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-SignedHeaders", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Credential")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Credential", valid_594055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594057: Call_DisassociateMemberAccount_594045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified member account from Amazon Macie.
  ## 
  let valid = call_594057.validator(path, query, header, formData, body)
  let scheme = call_594057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594057.url(scheme.get, call_594057.host, call_594057.base,
                         call_594057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594057, url, valid)

proc call*(call_594058: Call_DisassociateMemberAccount_594045; body: JsonNode): Recallable =
  ## disassociateMemberAccount
  ## Removes the specified member account from Amazon Macie.
  ##   body: JObject (required)
  var body_594059 = newJObject()
  if body != nil:
    body_594059 = body
  result = call_594058.call(nil, nil, nil, nil, body_594059)

var disassociateMemberAccount* = Call_DisassociateMemberAccount_594045(
    name: "disassociateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateMemberAccount",
    validator: validate_DisassociateMemberAccount_594046, base: "/",
    url: url_DisassociateMemberAccount_594047,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateS3Resources_594060 = ref object of OpenApiRestCall_593424
proc url_DisassociateS3Resources_594062(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateS3Resources_594061(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594063 = header.getOrDefault("X-Amz-Date")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Date", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594065 = header.getOrDefault("X-Amz-Target")
  valid_594065 = validateParameter(valid_594065, JString, required = true, default = newJString(
      "MacieService.DisassociateS3Resources"))
  if valid_594065 != nil:
    section.add "X-Amz-Target", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Content-Sha256", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Algorithm")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Algorithm", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Signature")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Signature", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-SignedHeaders", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Credential")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Credential", valid_594070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594072: Call_DisassociateS3Resources_594060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ## 
  let valid = call_594072.validator(path, query, header, formData, body)
  let scheme = call_594072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594072.url(scheme.get, call_594072.host, call_594072.base,
                         call_594072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594072, url, valid)

proc call*(call_594073: Call_DisassociateS3Resources_594060; body: JsonNode): Recallable =
  ## disassociateS3Resources
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ##   body: JObject (required)
  var body_594074 = newJObject()
  if body != nil:
    body_594074 = body
  result = call_594073.call(nil, nil, nil, nil, body_594074)

var disassociateS3Resources* = Call_DisassociateS3Resources_594060(
    name: "disassociateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateS3Resources",
    validator: validate_DisassociateS3Resources_594061, base: "/",
    url: url_DisassociateS3Resources_594062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_594075 = ref object of OpenApiRestCall_593424
proc url_ListMemberAccounts_594077(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListMemberAccounts_594076(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_594078 = query.getOrDefault("maxResults")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "maxResults", valid_594078
  var valid_594079 = query.getOrDefault("nextToken")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "nextToken", valid_594079
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
  var valid_594080 = header.getOrDefault("X-Amz-Date")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Date", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Security-Token")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Security-Token", valid_594081
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594082 = header.getOrDefault("X-Amz-Target")
  valid_594082 = validateParameter(valid_594082, JString, required = true, default = newJString(
      "MacieService.ListMemberAccounts"))
  if valid_594082 != nil:
    section.add "X-Amz-Target", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Content-Sha256", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Algorithm")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Algorithm", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Signature")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Signature", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-SignedHeaders", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Credential")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Credential", valid_594087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594089: Call_ListMemberAccounts_594075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ## 
  let valid = call_594089.validator(path, query, header, formData, body)
  let scheme = call_594089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594089.url(scheme.get, call_594089.host, call_594089.base,
                         call_594089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594089, url, valid)

proc call*(call_594090: Call_ListMemberAccounts_594075; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listMemberAccounts
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594091 = newJObject()
  var body_594092 = newJObject()
  add(query_594091, "maxResults", newJString(maxResults))
  add(query_594091, "nextToken", newJString(nextToken))
  if body != nil:
    body_594092 = body
  result = call_594090.call(nil, query_594091, nil, nil, body_594092)

var listMemberAccounts* = Call_ListMemberAccounts_594075(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListMemberAccounts",
    validator: validate_ListMemberAccounts_594076, base: "/",
    url: url_ListMemberAccounts_594077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListS3Resources_594094 = ref object of OpenApiRestCall_593424
proc url_ListS3Resources_594096(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListS3Resources_594095(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_594097 = query.getOrDefault("maxResults")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "maxResults", valid_594097
  var valid_594098 = query.getOrDefault("nextToken")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "nextToken", valid_594098
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
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Security-Token")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Security-Token", valid_594100
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594101 = header.getOrDefault("X-Amz-Target")
  valid_594101 = validateParameter(valid_594101, JString, required = true, default = newJString(
      "MacieService.ListS3Resources"))
  if valid_594101 != nil:
    section.add "X-Amz-Target", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Content-Sha256", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Algorithm")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Algorithm", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Signature")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Signature", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-SignedHeaders", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Credential")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Credential", valid_594106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594108: Call_ListS3Resources_594094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_594108.validator(path, query, header, formData, body)
  let scheme = call_594108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594108.url(scheme.get, call_594108.host, call_594108.base,
                         call_594108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594108, url, valid)

proc call*(call_594109: Call_ListS3Resources_594094; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listS3Resources
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594110 = newJObject()
  var body_594111 = newJObject()
  add(query_594110, "maxResults", newJString(maxResults))
  add(query_594110, "nextToken", newJString(nextToken))
  if body != nil:
    body_594111 = body
  result = call_594109.call(nil, query_594110, nil, nil, body_594111)

var listS3Resources* = Call_ListS3Resources_594094(name: "listS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListS3Resources",
    validator: validate_ListS3Resources_594095, base: "/", url: url_ListS3Resources_594096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateS3Resources_594112 = ref object of OpenApiRestCall_593424
proc url_UpdateS3Resources_594114(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateS3Resources_594113(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594115 = header.getOrDefault("X-Amz-Date")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Date", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594117 = header.getOrDefault("X-Amz-Target")
  valid_594117 = validateParameter(valid_594117, JString, required = true, default = newJString(
      "MacieService.UpdateS3Resources"))
  if valid_594117 != nil:
    section.add "X-Amz-Target", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Content-Sha256", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Algorithm")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Algorithm", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Signature")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Signature", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-SignedHeaders", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Credential")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Credential", valid_594122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594124: Call_UpdateS3Resources_594112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_594124.validator(path, query, header, formData, body)
  let scheme = call_594124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594124.url(scheme.get, call_594124.host, call_594124.base,
                         call_594124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594124, url, valid)

proc call*(call_594125: Call_UpdateS3Resources_594112; body: JsonNode): Recallable =
  ## updateS3Resources
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ##   body: JObject (required)
  var body_594126 = newJObject()
  if body != nil:
    body_594126 = body
  result = call_594125.call(nil, nil, nil, nil, body_594126)

var updateS3Resources* = Call_UpdateS3Resources_594112(name: "updateS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.UpdateS3Resources",
    validator: validate_UpdateS3Resources_594113, base: "/",
    url: url_UpdateS3Resources_594114, schemes: {Scheme.Https, Scheme.Http})
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
