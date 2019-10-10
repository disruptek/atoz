
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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
  Call_AssociateMemberAccount_602794 = ref object of OpenApiRestCall_602457
proc url_AssociateMemberAccount_602796(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateMemberAccount_602795(path: JsonNode; query: JsonNode;
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
  var valid_602908 = header.getOrDefault("X-Amz-Date")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Date", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Security-Token")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Security-Token", valid_602909
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602923 = header.getOrDefault("X-Amz-Target")
  valid_602923 = validateParameter(valid_602923, JString, required = true, default = newJString(
      "MacieService.AssociateMemberAccount"))
  if valid_602923 != nil:
    section.add "X-Amz-Target", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Content-Sha256", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Algorithm")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Algorithm", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Signature")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Signature", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-SignedHeaders", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Credential")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Credential", valid_602928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602952: Call_AssociateMemberAccount_602794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ## 
  let valid = call_602952.validator(path, query, header, formData, body)
  let scheme = call_602952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602952.url(scheme.get, call_602952.host, call_602952.base,
                         call_602952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602952, url, valid)

proc call*(call_603023: Call_AssociateMemberAccount_602794; body: JsonNode): Recallable =
  ## associateMemberAccount
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ##   body: JObject (required)
  var body_603024 = newJObject()
  if body != nil:
    body_603024 = body
  result = call_603023.call(nil, nil, nil, nil, body_603024)

var associateMemberAccount* = Call_AssociateMemberAccount_602794(
    name: "associateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateMemberAccount",
    validator: validate_AssociateMemberAccount_602795, base: "/",
    url: url_AssociateMemberAccount_602796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateS3Resources_603063 = ref object of OpenApiRestCall_602457
proc url_AssociateS3Resources_603065(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateS3Resources_603064(path: JsonNode; query: JsonNode;
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
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Security-Token")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Security-Token", valid_603067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603068 = header.getOrDefault("X-Amz-Target")
  valid_603068 = validateParameter(valid_603068, JString, required = true, default = newJString(
      "MacieService.AssociateS3Resources"))
  if valid_603068 != nil:
    section.add "X-Amz-Target", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Algorithm")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Algorithm", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Signature")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Signature", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-SignedHeaders", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_AssociateS3Resources_603063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ## 
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603075, url, valid)

proc call*(call_603076: Call_AssociateS3Resources_603063; body: JsonNode): Recallable =
  ## associateS3Resources
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ##   body: JObject (required)
  var body_603077 = newJObject()
  if body != nil:
    body_603077 = body
  result = call_603076.call(nil, nil, nil, nil, body_603077)

var associateS3Resources* = Call_AssociateS3Resources_603063(
    name: "associateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateS3Resources",
    validator: validate_AssociateS3Resources_603064, base: "/",
    url: url_AssociateS3Resources_603065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberAccount_603078 = ref object of OpenApiRestCall_602457
proc url_DisassociateMemberAccount_603080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateMemberAccount_603079(path: JsonNode; query: JsonNode;
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
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603083 = header.getOrDefault("X-Amz-Target")
  valid_603083 = validateParameter(valid_603083, JString, required = true, default = newJString(
      "MacieService.DisassociateMemberAccount"))
  if valid_603083 != nil:
    section.add "X-Amz-Target", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_DisassociateMemberAccount_603078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified member account from Amazon Macie.
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603090, url, valid)

proc call*(call_603091: Call_DisassociateMemberAccount_603078; body: JsonNode): Recallable =
  ## disassociateMemberAccount
  ## Removes the specified member account from Amazon Macie.
  ##   body: JObject (required)
  var body_603092 = newJObject()
  if body != nil:
    body_603092 = body
  result = call_603091.call(nil, nil, nil, nil, body_603092)

var disassociateMemberAccount* = Call_DisassociateMemberAccount_603078(
    name: "disassociateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateMemberAccount",
    validator: validate_DisassociateMemberAccount_603079, base: "/",
    url: url_DisassociateMemberAccount_603080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateS3Resources_603093 = ref object of OpenApiRestCall_602457
proc url_DisassociateS3Resources_603095(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateS3Resources_603094(path: JsonNode; query: JsonNode;
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
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603098 = header.getOrDefault("X-Amz-Target")
  valid_603098 = validateParameter(valid_603098, JString, required = true, default = newJString(
      "MacieService.DisassociateS3Resources"))
  if valid_603098 != nil:
    section.add "X-Amz-Target", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Content-Sha256", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Algorithm")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Algorithm", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Signature")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Signature", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-SignedHeaders", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Credential")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Credential", valid_603103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603105: Call_DisassociateS3Resources_603093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ## 
  let valid = call_603105.validator(path, query, header, formData, body)
  let scheme = call_603105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603105.url(scheme.get, call_603105.host, call_603105.base,
                         call_603105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603105, url, valid)

proc call*(call_603106: Call_DisassociateS3Resources_603093; body: JsonNode): Recallable =
  ## disassociateS3Resources
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ##   body: JObject (required)
  var body_603107 = newJObject()
  if body != nil:
    body_603107 = body
  result = call_603106.call(nil, nil, nil, nil, body_603107)

var disassociateS3Resources* = Call_DisassociateS3Resources_603093(
    name: "disassociateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateS3Resources",
    validator: validate_DisassociateS3Resources_603094, base: "/",
    url: url_DisassociateS3Resources_603095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_603108 = ref object of OpenApiRestCall_602457
proc url_ListMemberAccounts_603110(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListMemberAccounts_603109(path: JsonNode; query: JsonNode;
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
  var valid_603111 = query.getOrDefault("maxResults")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "maxResults", valid_603111
  var valid_603112 = query.getOrDefault("nextToken")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "nextToken", valid_603112
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
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603115 = header.getOrDefault("X-Amz-Target")
  valid_603115 = validateParameter(valid_603115, JString, required = true, default = newJString(
      "MacieService.ListMemberAccounts"))
  if valid_603115 != nil:
    section.add "X-Amz-Target", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Algorithm")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Algorithm", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Signature")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Signature", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-SignedHeaders", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Credential")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Credential", valid_603120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603122: Call_ListMemberAccounts_603108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ## 
  let valid = call_603122.validator(path, query, header, formData, body)
  let scheme = call_603122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603122.url(scheme.get, call_603122.host, call_603122.base,
                         call_603122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603122, url, valid)

proc call*(call_603123: Call_ListMemberAccounts_603108; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listMemberAccounts
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603124 = newJObject()
  var body_603125 = newJObject()
  add(query_603124, "maxResults", newJString(maxResults))
  add(query_603124, "nextToken", newJString(nextToken))
  if body != nil:
    body_603125 = body
  result = call_603123.call(nil, query_603124, nil, nil, body_603125)

var listMemberAccounts* = Call_ListMemberAccounts_603108(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListMemberAccounts",
    validator: validate_ListMemberAccounts_603109, base: "/",
    url: url_ListMemberAccounts_603110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListS3Resources_603127 = ref object of OpenApiRestCall_602457
proc url_ListS3Resources_603129(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListS3Resources_603128(path: JsonNode; query: JsonNode;
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
  var valid_603130 = query.getOrDefault("maxResults")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "maxResults", valid_603130
  var valid_603131 = query.getOrDefault("nextToken")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "nextToken", valid_603131
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
      "MacieService.ListS3Resources"))
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

proc call*(call_603141: Call_ListS3Resources_603127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_ListS3Resources_603127; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listS3Resources
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603143 = newJObject()
  var body_603144 = newJObject()
  add(query_603143, "maxResults", newJString(maxResults))
  add(query_603143, "nextToken", newJString(nextToken))
  if body != nil:
    body_603144 = body
  result = call_603142.call(nil, query_603143, nil, nil, body_603144)

var listS3Resources* = Call_ListS3Resources_603127(name: "listS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListS3Resources",
    validator: validate_ListS3Resources_603128, base: "/", url: url_ListS3Resources_603129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateS3Resources_603145 = ref object of OpenApiRestCall_602457
proc url_UpdateS3Resources_603147(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateS3Resources_603146(path: JsonNode; query: JsonNode;
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
  var valid_603148 = header.getOrDefault("X-Amz-Date")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Date", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Security-Token")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Security-Token", valid_603149
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603150 = header.getOrDefault("X-Amz-Target")
  valid_603150 = validateParameter(valid_603150, JString, required = true, default = newJString(
      "MacieService.UpdateS3Resources"))
  if valid_603150 != nil:
    section.add "X-Amz-Target", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Content-Sha256", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Algorithm")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Algorithm", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Signature")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Signature", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603157: Call_UpdateS3Resources_603145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_603157.validator(path, query, header, formData, body)
  let scheme = call_603157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603157.url(scheme.get, call_603157.host, call_603157.base,
                         call_603157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603157, url, valid)

proc call*(call_603158: Call_UpdateS3Resources_603145; body: JsonNode): Recallable =
  ## updateS3Resources
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ##   body: JObject (required)
  var body_603159 = newJObject()
  if body != nil:
    body_603159 = body
  result = call_603158.call(nil, nil, nil, nil, body_603159)

var updateS3Resources* = Call_UpdateS3Resources_603145(name: "updateS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.UpdateS3Resources",
    validator: validate_UpdateS3Resources_603146, base: "/",
    url: url_UpdateS3Resources_603147, schemes: {Scheme.Https, Scheme.Http})
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
