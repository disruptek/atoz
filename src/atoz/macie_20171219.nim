
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_AssociateMemberAccount_599696 = ref object of OpenApiRestCall_599359
proc url_AssociateMemberAccount_599698(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateMemberAccount_599697(path: JsonNode; query: JsonNode;
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
  var valid_599810 = header.getOrDefault("X-Amz-Date")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-Date", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Security-Token")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Security-Token", valid_599811
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599825 = header.getOrDefault("X-Amz-Target")
  valid_599825 = validateParameter(valid_599825, JString, required = true, default = newJString(
      "MacieService.AssociateMemberAccount"))
  if valid_599825 != nil:
    section.add "X-Amz-Target", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Content-Sha256", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Signature")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Signature", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-SignedHeaders", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Credential")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Credential", valid_599830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599854: Call_AssociateMemberAccount_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ## 
  let valid = call_599854.validator(path, query, header, formData, body)
  let scheme = call_599854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599854.url(scheme.get, call_599854.host, call_599854.base,
                         call_599854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599854, url, valid)

proc call*(call_599925: Call_AssociateMemberAccount_599696; body: JsonNode): Recallable =
  ## associateMemberAccount
  ## Associates a specified AWS account with Amazon Macie as a member account.
  ##   body: JObject (required)
  var body_599926 = newJObject()
  if body != nil:
    body_599926 = body
  result = call_599925.call(nil, nil, nil, nil, body_599926)

var associateMemberAccount* = Call_AssociateMemberAccount_599696(
    name: "associateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateMemberAccount",
    validator: validate_AssociateMemberAccount_599697, base: "/",
    url: url_AssociateMemberAccount_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateS3Resources_599965 = ref object of OpenApiRestCall_599359
proc url_AssociateS3Resources_599967(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateS3Resources_599966(path: JsonNode; query: JsonNode;
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
  var valid_599968 = header.getOrDefault("X-Amz-Date")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Date", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Security-Token")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Security-Token", valid_599969
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599970 = header.getOrDefault("X-Amz-Target")
  valid_599970 = validateParameter(valid_599970, JString, required = true, default = newJString(
      "MacieService.AssociateS3Resources"))
  if valid_599970 != nil:
    section.add "X-Amz-Target", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-Content-Sha256", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Algorithm")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Algorithm", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Signature")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Signature", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-SignedHeaders", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Credential")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Credential", valid_599975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599977: Call_AssociateS3Resources_599965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ## 
  let valid = call_599977.validator(path, query, header, formData, body)
  let scheme = call_599977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599977.url(scheme.get, call_599977.host, call_599977.base,
                         call_599977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599977, url, valid)

proc call*(call_599978: Call_AssociateS3Resources_599965; body: JsonNode): Recallable =
  ## associateS3Resources
  ## Associates specified S3 resources with Amazon Macie for monitoring and data classification. If memberAccountId isn't specified, the action associates specified S3 resources with Macie for the current master account. If memberAccountId is specified, the action associates specified S3 resources with Macie for the specified member account. 
  ##   body: JObject (required)
  var body_599979 = newJObject()
  if body != nil:
    body_599979 = body
  result = call_599978.call(nil, nil, nil, nil, body_599979)

var associateS3Resources* = Call_AssociateS3Resources_599965(
    name: "associateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.AssociateS3Resources",
    validator: validate_AssociateS3Resources_599966, base: "/",
    url: url_AssociateS3Resources_599967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMemberAccount_599980 = ref object of OpenApiRestCall_599359
proc url_DisassociateMemberAccount_599982(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMemberAccount_599981(path: JsonNode; query: JsonNode;
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
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599985 = header.getOrDefault("X-Amz-Target")
  valid_599985 = validateParameter(valid_599985, JString, required = true, default = newJString(
      "MacieService.DisassociateMemberAccount"))
  if valid_599985 != nil:
    section.add "X-Amz-Target", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Content-Sha256", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Algorithm")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Algorithm", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Signature")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Signature", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-SignedHeaders", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_DisassociateMemberAccount_599980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified member account from Amazon Macie.
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_DisassociateMemberAccount_599980; body: JsonNode): Recallable =
  ## disassociateMemberAccount
  ## Removes the specified member account from Amazon Macie.
  ##   body: JObject (required)
  var body_599994 = newJObject()
  if body != nil:
    body_599994 = body
  result = call_599993.call(nil, nil, nil, nil, body_599994)

var disassociateMemberAccount* = Call_DisassociateMemberAccount_599980(
    name: "disassociateMemberAccount", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateMemberAccount",
    validator: validate_DisassociateMemberAccount_599981, base: "/",
    url: url_DisassociateMemberAccount_599982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateS3Resources_599995 = ref object of OpenApiRestCall_599359
proc url_DisassociateS3Resources_599997(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateS3Resources_599996(path: JsonNode; query: JsonNode;
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
  var valid_599998 = header.getOrDefault("X-Amz-Date")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Date", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Security-Token")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Security-Token", valid_599999
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600000 = header.getOrDefault("X-Amz-Target")
  valid_600000 = validateParameter(valid_600000, JString, required = true, default = newJString(
      "MacieService.DisassociateS3Resources"))
  if valid_600000 != nil:
    section.add "X-Amz-Target", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Content-Sha256", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Algorithm")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Algorithm", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Signature")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Signature", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-SignedHeaders", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600007: Call_DisassociateS3Resources_599995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ## 
  let valid = call_600007.validator(path, query, header, formData, body)
  let scheme = call_600007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600007.url(scheme.get, call_600007.host, call_600007.base,
                         call_600007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600007, url, valid)

proc call*(call_600008: Call_DisassociateS3Resources_599995; body: JsonNode): Recallable =
  ## disassociateS3Resources
  ## Removes specified S3 resources from being monitored by Amazon Macie. If memberAccountId isn't specified, the action removes specified S3 resources from Macie for the current master account. If memberAccountId is specified, the action removes specified S3 resources from Macie for the specified member account.
  ##   body: JObject (required)
  var body_600009 = newJObject()
  if body != nil:
    body_600009 = body
  result = call_600008.call(nil, nil, nil, nil, body_600009)

var disassociateS3Resources* = Call_DisassociateS3Resources_599995(
    name: "disassociateS3Resources", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.DisassociateS3Resources",
    validator: validate_DisassociateS3Resources_599996, base: "/",
    url: url_DisassociateS3Resources_599997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMemberAccounts_600010 = ref object of OpenApiRestCall_599359
proc url_ListMemberAccounts_600012(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMemberAccounts_600011(path: JsonNode; query: JsonNode;
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
  var valid_600013 = query.getOrDefault("maxResults")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "maxResults", valid_600013
  var valid_600014 = query.getOrDefault("nextToken")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "nextToken", valid_600014
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
  var valid_600015 = header.getOrDefault("X-Amz-Date")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Date", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Security-Token")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Security-Token", valid_600016
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600017 = header.getOrDefault("X-Amz-Target")
  valid_600017 = validateParameter(valid_600017, JString, required = true, default = newJString(
      "MacieService.ListMemberAccounts"))
  if valid_600017 != nil:
    section.add "X-Amz-Target", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600024: Call_ListMemberAccounts_600010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ## 
  let valid = call_600024.validator(path, query, header, formData, body)
  let scheme = call_600024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600024.url(scheme.get, call_600024.host, call_600024.base,
                         call_600024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600024, url, valid)

proc call*(call_600025: Call_ListMemberAccounts_600010; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listMemberAccounts
  ## Lists all Amazon Macie member accounts for the current Amazon Macie master account.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600026 = newJObject()
  var body_600027 = newJObject()
  add(query_600026, "maxResults", newJString(maxResults))
  add(query_600026, "nextToken", newJString(nextToken))
  if body != nil:
    body_600027 = body
  result = call_600025.call(nil, query_600026, nil, nil, body_600027)

var listMemberAccounts* = Call_ListMemberAccounts_600010(
    name: "listMemberAccounts", meth: HttpMethod.HttpPost,
    host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListMemberAccounts",
    validator: validate_ListMemberAccounts_600011, base: "/",
    url: url_ListMemberAccounts_600012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListS3Resources_600029 = ref object of OpenApiRestCall_599359
proc url_ListS3Resources_600031(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListS3Resources_600030(path: JsonNode; query: JsonNode;
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
  var valid_600032 = query.getOrDefault("maxResults")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "maxResults", valid_600032
  var valid_600033 = query.getOrDefault("nextToken")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "nextToken", valid_600033
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
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Security-Token")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Security-Token", valid_600035
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600036 = header.getOrDefault("X-Amz-Target")
  valid_600036 = validateParameter(valid_600036, JString, required = true, default = newJString(
      "MacieService.ListS3Resources"))
  if valid_600036 != nil:
    section.add "X-Amz-Target", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Content-Sha256", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Algorithm")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Algorithm", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Signature")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Signature", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-SignedHeaders", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Credential")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Credential", valid_600041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600043: Call_ListS3Resources_600029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_600043.validator(path, query, header, formData, body)
  let scheme = call_600043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600043.url(scheme.get, call_600043.host, call_600043.base,
                         call_600043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600043, url, valid)

proc call*(call_600044: Call_ListS3Resources_600029; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listS3Resources
  ## Lists all the S3 resources associated with Amazon Macie. If memberAccountId isn't specified, the action lists the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action lists the S3 resources associated with Amazon Macie for the specified member account. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600045 = newJObject()
  var body_600046 = newJObject()
  add(query_600045, "maxResults", newJString(maxResults))
  add(query_600045, "nextToken", newJString(nextToken))
  if body != nil:
    body_600046 = body
  result = call_600044.call(nil, query_600045, nil, nil, body_600046)

var listS3Resources* = Call_ListS3Resources_600029(name: "listS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.ListS3Resources",
    validator: validate_ListS3Resources_600030, base: "/", url: url_ListS3Resources_600031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateS3Resources_600047 = ref object of OpenApiRestCall_599359
proc url_UpdateS3Resources_600049(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateS3Resources_600048(path: JsonNode; query: JsonNode;
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
  var valid_600050 = header.getOrDefault("X-Amz-Date")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Date", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Security-Token")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Security-Token", valid_600051
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600052 = header.getOrDefault("X-Amz-Target")
  valid_600052 = validateParameter(valid_600052, JString, required = true, default = newJString(
      "MacieService.UpdateS3Resources"))
  if valid_600052 != nil:
    section.add "X-Amz-Target", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Content-Sha256", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Algorithm")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Algorithm", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Signature")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Signature", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-SignedHeaders", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Credential")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Credential", valid_600057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600059: Call_UpdateS3Resources_600047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ## 
  let valid = call_600059.validator(path, query, header, formData, body)
  let scheme = call_600059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600059.url(scheme.get, call_600059.host, call_600059.base,
                         call_600059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600059, url, valid)

proc call*(call_600060: Call_UpdateS3Resources_600047; body: JsonNode): Recallable =
  ## updateS3Resources
  ## Updates the classification types for the specified S3 resources. If memberAccountId isn't specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the current master account. If memberAccountId is specified, the action updates the classification types of the S3 resources associated with Amazon Macie for the specified member account. 
  ##   body: JObject (required)
  var body_600061 = newJObject()
  if body != nil:
    body_600061 = body
  result = call_600060.call(nil, nil, nil, nil, body_600061)

var updateS3Resources* = Call_UpdateS3Resources_600047(name: "updateS3Resources",
    meth: HttpMethod.HttpPost, host: "macie.amazonaws.com",
    route: "/#X-Amz-Target=MacieService.UpdateS3Resources",
    validator: validate_UpdateS3Resources_600048, base: "/",
    url: url_UpdateS3Resources_600049, schemes: {Scheme.Https, Scheme.Http})
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
