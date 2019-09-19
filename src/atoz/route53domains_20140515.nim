
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53 Domains
## version: 2014-05-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Route 53 API actions let you register domain names and perform related operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53domains/
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "route53domains.ap-northeast-1.amazonaws.com", "ap-southeast-1": "route53domains.ap-southeast-1.amazonaws.com", "us-west-2": "route53domains.us-west-2.amazonaws.com", "eu-west-2": "route53domains.eu-west-2.amazonaws.com", "ap-northeast-3": "route53domains.ap-northeast-3.amazonaws.com", "eu-central-1": "route53domains.eu-central-1.amazonaws.com", "us-east-2": "route53domains.us-east-2.amazonaws.com", "us-east-1": "route53domains.us-east-1.amazonaws.com", "cn-northwest-1": "route53domains.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "route53domains.ap-south-1.amazonaws.com", "eu-north-1": "route53domains.eu-north-1.amazonaws.com", "ap-northeast-2": "route53domains.ap-northeast-2.amazonaws.com", "us-west-1": "route53domains.us-west-1.amazonaws.com", "us-gov-east-1": "route53domains.us-gov-east-1.amazonaws.com", "eu-west-3": "route53domains.eu-west-3.amazonaws.com", "cn-north-1": "route53domains.cn-north-1.amazonaws.com.cn", "sa-east-1": "route53domains.sa-east-1.amazonaws.com", "eu-west-1": "route53domains.eu-west-1.amazonaws.com", "us-gov-west-1": "route53domains.us-gov-west-1.amazonaws.com", "ap-southeast-2": "route53domains.ap-southeast-2.amazonaws.com", "ca-central-1": "route53domains.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "route53domains.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "route53domains.ap-southeast-1.amazonaws.com",
      "us-west-2": "route53domains.us-west-2.amazonaws.com",
      "eu-west-2": "route53domains.eu-west-2.amazonaws.com",
      "ap-northeast-3": "route53domains.ap-northeast-3.amazonaws.com",
      "eu-central-1": "route53domains.eu-central-1.amazonaws.com",
      "us-east-2": "route53domains.us-east-2.amazonaws.com",
      "us-east-1": "route53domains.us-east-1.amazonaws.com",
      "cn-northwest-1": "route53domains.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "route53domains.ap-south-1.amazonaws.com",
      "eu-north-1": "route53domains.eu-north-1.amazonaws.com",
      "ap-northeast-2": "route53domains.ap-northeast-2.amazonaws.com",
      "us-west-1": "route53domains.us-west-1.amazonaws.com",
      "us-gov-east-1": "route53domains.us-gov-east-1.amazonaws.com",
      "eu-west-3": "route53domains.eu-west-3.amazonaws.com",
      "cn-north-1": "route53domains.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "route53domains.sa-east-1.amazonaws.com",
      "eu-west-1": "route53domains.eu-west-1.amazonaws.com",
      "us-gov-west-1": "route53domains.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "route53domains.ap-southeast-2.amazonaws.com",
      "ca-central-1": "route53domains.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "route53domains"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CheckDomainAvailability_772933 = ref object of OpenApiRestCall_772597
proc url_CheckDomainAvailability_772935(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CheckDomainAvailability_772934(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "Route53Domains_v20140515.CheckDomainAvailability"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_CheckDomainAvailability_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_CheckDomainAvailability_772933; body: JsonNode): Recallable =
  ## checkDomainAvailability
  ## This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var checkDomainAvailability* = Call_CheckDomainAvailability_772933(
    name: "checkDomainAvailability", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.CheckDomainAvailability",
    validator: validate_CheckDomainAvailability_772934, base: "/",
    url: url_CheckDomainAvailability_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CheckDomainTransferability_773202 = ref object of OpenApiRestCall_772597
proc url_CheckDomainTransferability_773204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CheckDomainTransferability_773203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Checks whether a domain name can be transferred to Amazon Route 53. 
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "Route53Domains_v20140515.CheckDomainTransferability"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_CheckDomainTransferability_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks whether a domain name can be transferred to Amazon Route 53. 
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_CheckDomainTransferability_773202; body: JsonNode): Recallable =
  ## checkDomainTransferability
  ## Checks whether a domain name can be transferred to Amazon Route 53. 
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var checkDomainTransferability* = Call_CheckDomainTransferability_773202(
    name: "checkDomainTransferability", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.CheckDomainTransferability",
    validator: validate_CheckDomainTransferability_773203, base: "/",
    url: url_CheckDomainTransferability_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagsForDomain_773217 = ref object of OpenApiRestCall_772597
proc url_DeleteTagsForDomain_773219(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTagsForDomain_773218(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>This operation deletes the specified tags for a domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "Route53Domains_v20140515.DeleteTagsForDomain"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_DeleteTagsForDomain_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes the specified tags for a domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_DeleteTagsForDomain_773217; body: JsonNode): Recallable =
  ## deleteTagsForDomain
  ## <p>This operation deletes the specified tags for a domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var deleteTagsForDomain* = Call_DeleteTagsForDomain_773217(
    name: "deleteTagsForDomain", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DeleteTagsForDomain",
    validator: validate_DeleteTagsForDomain_773218, base: "/",
    url: url_DeleteTagsForDomain_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDomainAutoRenew_773232 = ref object of OpenApiRestCall_772597
proc url_DisableDomainAutoRenew_773234(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDomainAutoRenew_773233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation disables automatic renewal of domain registration for the specified domain.
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "Route53Domains_v20140515.DisableDomainAutoRenew"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_DisableDomainAutoRenew_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation disables automatic renewal of domain registration for the specified domain.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_DisableDomainAutoRenew_773232; body: JsonNode): Recallable =
  ## disableDomainAutoRenew
  ## This operation disables automatic renewal of domain registration for the specified domain.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var disableDomainAutoRenew* = Call_DisableDomainAutoRenew_773232(
    name: "disableDomainAutoRenew", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DisableDomainAutoRenew",
    validator: validate_DisableDomainAutoRenew_773233, base: "/",
    url: url_DisableDomainAutoRenew_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDomainTransferLock_773247 = ref object of OpenApiRestCall_772597
proc url_DisableDomainTransferLock_773249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDomainTransferLock_773248(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation removes the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "Route53Domains_v20140515.DisableDomainTransferLock"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_DisableDomainTransferLock_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_DisableDomainTransferLock_773247; body: JsonNode): Recallable =
  ## disableDomainTransferLock
  ## This operation removes the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var disableDomainTransferLock* = Call_DisableDomainTransferLock_773247(
    name: "disableDomainTransferLock", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DisableDomainTransferLock",
    validator: validate_DisableDomainTransferLock_773248, base: "/",
    url: url_DisableDomainTransferLock_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDomainAutoRenew_773262 = ref object of OpenApiRestCall_772597
proc url_EnableDomainAutoRenew_773264(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDomainAutoRenew_773263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your AWS account.</p> <p>The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see <a href="http://wiki.gandi.net/en/domains/renew#renewal_restoration_and_deletion_times">"Renewal, restoration, and deletion times"</a> on the website for our registrar associate, Gandi. Amazon Route 53 requires that you renew before the end of the renewal period that is listed on the Gandi website so we can complete processing before the deadline.</p>
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "Route53Domains_v20140515.EnableDomainAutoRenew"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_EnableDomainAutoRenew_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your AWS account.</p> <p>The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see <a href="http://wiki.gandi.net/en/domains/renew#renewal_restoration_and_deletion_times">"Renewal, restoration, and deletion times"</a> on the website for our registrar associate, Gandi. Amazon Route 53 requires that you renew before the end of the renewal period that is listed on the Gandi website so we can complete processing before the deadline.</p>
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_EnableDomainAutoRenew_773262; body: JsonNode): Recallable =
  ## enableDomainAutoRenew
  ## <p>This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your AWS account.</p> <p>The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see <a href="http://wiki.gandi.net/en/domains/renew#renewal_restoration_and_deletion_times">"Renewal, restoration, and deletion times"</a> on the website for our registrar associate, Gandi. Amazon Route 53 requires that you renew before the end of the renewal period that is listed on the Gandi website so we can complete processing before the deadline.</p>
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var enableDomainAutoRenew* = Call_EnableDomainAutoRenew_773262(
    name: "enableDomainAutoRenew", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.EnableDomainAutoRenew",
    validator: validate_EnableDomainAutoRenew_773263, base: "/",
    url: url_EnableDomainAutoRenew_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDomainTransferLock_773277 = ref object of OpenApiRestCall_772597
proc url_EnableDomainTransferLock_773279(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDomainTransferLock_773278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation sets the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "Route53Domains_v20140515.EnableDomainTransferLock"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_EnableDomainTransferLock_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation sets the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_EnableDomainTransferLock_773277; body: JsonNode): Recallable =
  ## enableDomainTransferLock
  ## This operation sets the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var enableDomainTransferLock* = Call_EnableDomainTransferLock_773277(
    name: "enableDomainTransferLock", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.EnableDomainTransferLock",
    validator: validate_EnableDomainTransferLock_773278, base: "/",
    url: url_EnableDomainTransferLock_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactReachabilityStatus_773292 = ref object of OpenApiRestCall_772597
proc url_GetContactReachabilityStatus_773294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetContactReachabilityStatus_773293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded.</p> <p>If you want us to resend the email, use the <code>ResendContactReachabilityEmail</code> operation.</p>
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetContactReachabilityStatus"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_GetContactReachabilityStatus_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded.</p> <p>If you want us to resend the email, use the <code>ResendContactReachabilityEmail</code> operation.</p>
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_GetContactReachabilityStatus_773292; body: JsonNode): Recallable =
  ## getContactReachabilityStatus
  ## <p>For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded.</p> <p>If you want us to resend the email, use the <code>ResendContactReachabilityEmail</code> operation.</p>
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var getContactReachabilityStatus* = Call_GetContactReachabilityStatus_773292(
    name: "getContactReachabilityStatus", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.GetContactReachabilityStatus",
    validator: validate_GetContactReachabilityStatus_773293, base: "/",
    url: url_GetContactReachabilityStatus_773294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDetail_773307 = ref object of OpenApiRestCall_772597
proc url_GetDomainDetail_773309(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainDetail_773308(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## This operation returns detailed information about a specified domain that is associated with the current AWS account. Contact information for the domain is also returned as part of the output.
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetDomainDetail"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_GetDomainDetail_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns detailed information about a specified domain that is associated with the current AWS account. Contact information for the domain is also returned as part of the output.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_GetDomainDetail_773307; body: JsonNode): Recallable =
  ## getDomainDetail
  ## This operation returns detailed information about a specified domain that is associated with the current AWS account. Contact information for the domain is also returned as part of the output.
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var getDomainDetail* = Call_GetDomainDetail_773307(name: "getDomainDetail",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetDomainDetail",
    validator: validate_GetDomainDetail_773308, base: "/", url: url_GetDomainDetail_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainSuggestions_773322 = ref object of OpenApiRestCall_772597
proc url_GetDomainSuggestions_773324(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainSuggestions_773323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## The GetDomainSuggestions operation returns a list of suggested domain names given a string, which can either be a domain name or simply a word or phrase (without spaces).
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetDomainSuggestions"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_GetDomainSuggestions_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The GetDomainSuggestions operation returns a list of suggested domain names given a string, which can either be a domain name or simply a word or phrase (without spaces).
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_GetDomainSuggestions_773322; body: JsonNode): Recallable =
  ## getDomainSuggestions
  ## The GetDomainSuggestions operation returns a list of suggested domain names given a string, which can either be a domain name or simply a word or phrase (without spaces).
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var getDomainSuggestions* = Call_GetDomainSuggestions_773322(
    name: "getDomainSuggestions", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetDomainSuggestions",
    validator: validate_GetDomainSuggestions_773323, base: "/",
    url: url_GetDomainSuggestions_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationDetail_773337 = ref object of OpenApiRestCall_772597
proc url_GetOperationDetail_773339(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOperationDetail_773338(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## This operation returns the current status of an operation that is not completed.
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetOperationDetail"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_GetOperationDetail_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the current status of an operation that is not completed.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_GetOperationDetail_773337; body: JsonNode): Recallable =
  ## getOperationDetail
  ## This operation returns the current status of an operation that is not completed.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var getOperationDetail* = Call_GetOperationDetail_773337(
    name: "getOperationDetail", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetOperationDetail",
    validator: validate_GetOperationDetail_773338, base: "/",
    url: url_GetOperationDetail_773339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_773352 = ref object of OpenApiRestCall_772597
proc url_ListDomains_773354(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDomains_773353(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns all the domain names registered with Amazon Route 53 for the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773355 = query.getOrDefault("Marker")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "Marker", valid_773355
  var valid_773356 = query.getOrDefault("MaxItems")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "MaxItems", valid_773356
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
  var valid_773357 = header.getOrDefault("X-Amz-Date")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Date", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Security-Token")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Security-Token", valid_773358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773359 = header.getOrDefault("X-Amz-Target")
  valid_773359 = validateParameter(valid_773359, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListDomains"))
  if valid_773359 != nil:
    section.add "X-Amz-Target", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Content-Sha256", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Algorithm")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Algorithm", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Signature")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Signature", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-SignedHeaders", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Credential")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Credential", valid_773364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773366: Call_ListDomains_773352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns all the domain names registered with Amazon Route 53 for the current AWS account.
  ## 
  let valid = call_773366.validator(path, query, header, formData, body)
  let scheme = call_773366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773366.url(scheme.get, call_773366.host, call_773366.base,
                         call_773366.route, valid.getOrDefault("path"))
  result = hook(call_773366, url, valid)

proc call*(call_773367: Call_ListDomains_773352; body: JsonNode; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDomains
  ## This operation returns all the domain names registered with Amazon Route 53 for the current AWS account.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_773368 = newJObject()
  var body_773369 = newJObject()
  add(query_773368, "Marker", newJString(Marker))
  if body != nil:
    body_773369 = body
  add(query_773368, "MaxItems", newJString(MaxItems))
  result = call_773367.call(nil, query_773368, nil, nil, body_773369)

var listDomains* = Call_ListDomains_773352(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ListDomains",
                                        validator: validate_ListDomains_773353,
                                        base: "/", url: url_ListDomains_773354,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOperations_773371 = ref object of OpenApiRestCall_772597
proc url_ListOperations_773373(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOperations_773372(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation returns the operation IDs of operations that are not yet complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_773374 = query.getOrDefault("Marker")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "Marker", valid_773374
  var valid_773375 = query.getOrDefault("MaxItems")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "MaxItems", valid_773375
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
  var valid_773376 = header.getOrDefault("X-Amz-Date")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Date", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Security-Token")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Security-Token", valid_773377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773378 = header.getOrDefault("X-Amz-Target")
  valid_773378 = validateParameter(valid_773378, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListOperations"))
  if valid_773378 != nil:
    section.add "X-Amz-Target", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Content-Sha256", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Algorithm")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Algorithm", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Signature")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Signature", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-SignedHeaders", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Credential")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Credential", valid_773383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_ListOperations_773371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the operation IDs of operations that are not yet complete.
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_ListOperations_773371; body: JsonNode;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listOperations
  ## This operation returns the operation IDs of operations that are not yet complete.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_773387 = newJObject()
  var body_773388 = newJObject()
  add(query_773387, "Marker", newJString(Marker))
  if body != nil:
    body_773388 = body
  add(query_773387, "MaxItems", newJString(MaxItems))
  result = call_773386.call(nil, query_773387, nil, nil, body_773388)

var listOperations* = Call_ListOperations_773371(name: "listOperations",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.ListOperations",
    validator: validate_ListOperations_773372, base: "/", url: url_ListOperations_773373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForDomain_773389 = ref object of OpenApiRestCall_772597
proc url_ListTagsForDomain_773391(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForDomain_773390(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>This operation returns all of the tags that are associated with the specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
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
  var valid_773392 = header.getOrDefault("X-Amz-Date")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Date", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Security-Token")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Security-Token", valid_773393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773394 = header.getOrDefault("X-Amz-Target")
  valid_773394 = validateParameter(valid_773394, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListTagsForDomain"))
  if valid_773394 != nil:
    section.add "X-Amz-Target", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Content-Sha256", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Algorithm")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Algorithm", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Signature")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Signature", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-SignedHeaders", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Credential")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Credential", valid_773399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773401: Call_ListTagsForDomain_773389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns all of the tags that are associated with the specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_773401.validator(path, query, header, formData, body)
  let scheme = call_773401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773401.url(scheme.get, call_773401.host, call_773401.base,
                         call_773401.route, valid.getOrDefault("path"))
  result = hook(call_773401, url, valid)

proc call*(call_773402: Call_ListTagsForDomain_773389; body: JsonNode): Recallable =
  ## listTagsForDomain
  ## <p>This operation returns all of the tags that are associated with the specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_773403 = newJObject()
  if body != nil:
    body_773403 = body
  result = call_773402.call(nil, nil, nil, nil, body_773403)

var listTagsForDomain* = Call_ListTagsForDomain_773389(name: "listTagsForDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.ListTagsForDomain",
    validator: validate_ListTagsForDomain_773390, base: "/",
    url: url_ListTagsForDomain_773391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDomain_773404 = ref object of OpenApiRestCall_772597
proc url_RegisterDomain_773406(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterDomain_773405(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters.</p> <p>When you register a domain, Amazon Route 53 does the following:</p> <ul> <li> <p>Creates a Amazon Route 53 hosted zone that has the same name as the domain. Amazon Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers.</p> </li> <li> <p>Enables autorenew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration.</p> </li> <li> <p>Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the registrant, admin, and tech contacts.</p> </li> <li> <p>If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email.</p> </li> <li> <p>Charges your AWS account an amount based on the top-level domain. For more information, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> </li> </ul>
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
  var valid_773407 = header.getOrDefault("X-Amz-Date")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Date", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Security-Token")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Security-Token", valid_773408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773409 = header.getOrDefault("X-Amz-Target")
  valid_773409 = validateParameter(valid_773409, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RegisterDomain"))
  if valid_773409 != nil:
    section.add "X-Amz-Target", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Content-Sha256", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Algorithm")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Algorithm", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Signature")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Signature", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-SignedHeaders", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Credential")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Credential", valid_773414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773416: Call_RegisterDomain_773404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters.</p> <p>When you register a domain, Amazon Route 53 does the following:</p> <ul> <li> <p>Creates a Amazon Route 53 hosted zone that has the same name as the domain. Amazon Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers.</p> </li> <li> <p>Enables autorenew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration.</p> </li> <li> <p>Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the registrant, admin, and tech contacts.</p> </li> <li> <p>If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email.</p> </li> <li> <p>Charges your AWS account an amount based on the top-level domain. For more information, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> </li> </ul>
  ## 
  let valid = call_773416.validator(path, query, header, formData, body)
  let scheme = call_773416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773416.url(scheme.get, call_773416.host, call_773416.base,
                         call_773416.route, valid.getOrDefault("path"))
  result = hook(call_773416, url, valid)

proc call*(call_773417: Call_RegisterDomain_773404; body: JsonNode): Recallable =
  ## registerDomain
  ## <p>This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters.</p> <p>When you register a domain, Amazon Route 53 does the following:</p> <ul> <li> <p>Creates a Amazon Route 53 hosted zone that has the same name as the domain. Amazon Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers.</p> </li> <li> <p>Enables autorenew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration.</p> </li> <li> <p>Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the registrant, admin, and tech contacts.</p> </li> <li> <p>If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email.</p> </li> <li> <p>Charges your AWS account an amount based on the top-level domain. For more information, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773418 = newJObject()
  if body != nil:
    body_773418 = body
  result = call_773417.call(nil, nil, nil, nil, body_773418)

var registerDomain* = Call_RegisterDomain_773404(name: "registerDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.RegisterDomain",
    validator: validate_RegisterDomain_773405, base: "/", url: url_RegisterDomain_773406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewDomain_773419 = ref object of OpenApiRestCall_772597
proc url_RenewDomain_773421(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RenewDomain_773420(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your AWS account.</p> <p>We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html">Renewing Registration for a Domain</a> in the Amazon Route 53 Developer Guide.</p>
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
  var valid_773422 = header.getOrDefault("X-Amz-Date")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Date", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Security-Token")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Security-Token", valid_773423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773424 = header.getOrDefault("X-Amz-Target")
  valid_773424 = validateParameter(valid_773424, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RenewDomain"))
  if valid_773424 != nil:
    section.add "X-Amz-Target", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Content-Sha256", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Algorithm")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Algorithm", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Signature")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Signature", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-SignedHeaders", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Credential")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Credential", valid_773429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773431: Call_RenewDomain_773419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your AWS account.</p> <p>We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html">Renewing Registration for a Domain</a> in the Amazon Route 53 Developer Guide.</p>
  ## 
  let valid = call_773431.validator(path, query, header, formData, body)
  let scheme = call_773431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773431.url(scheme.get, call_773431.host, call_773431.base,
                         call_773431.route, valid.getOrDefault("path"))
  result = hook(call_773431, url, valid)

proc call*(call_773432: Call_RenewDomain_773419; body: JsonNode): Recallable =
  ## renewDomain
  ## <p>This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your AWS account.</p> <p>We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html">Renewing Registration for a Domain</a> in the Amazon Route 53 Developer Guide.</p>
  ##   body: JObject (required)
  var body_773433 = newJObject()
  if body != nil:
    body_773433 = body
  result = call_773432.call(nil, nil, nil, nil, body_773433)

var renewDomain* = Call_RenewDomain_773419(name: "renewDomain",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.RenewDomain",
                                        validator: validate_RenewDomain_773420,
                                        base: "/", url: url_RenewDomain_773421,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendContactReachabilityEmail_773434 = ref object of OpenApiRestCall_772597
proc url_ResendContactReachabilityEmail_773436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResendContactReachabilityEmail_773435(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
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
  var valid_773437 = header.getOrDefault("X-Amz-Date")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-Date", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Security-Token")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Security-Token", valid_773438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773439 = header.getOrDefault("X-Amz-Target")
  valid_773439 = validateParameter(valid_773439, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ResendContactReachabilityEmail"))
  if valid_773439 != nil:
    section.add "X-Amz-Target", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Content-Sha256", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Algorithm")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Algorithm", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Signature")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Signature", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-SignedHeaders", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Credential")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Credential", valid_773444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773446: Call_ResendContactReachabilityEmail_773434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
  ## 
  let valid = call_773446.validator(path, query, header, formData, body)
  let scheme = call_773446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773446.url(scheme.get, call_773446.host, call_773446.base,
                         call_773446.route, valid.getOrDefault("path"))
  result = hook(call_773446, url, valid)

proc call*(call_773447: Call_ResendContactReachabilityEmail_773434; body: JsonNode): Recallable =
  ## resendContactReachabilityEmail
  ## For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
  ##   body: JObject (required)
  var body_773448 = newJObject()
  if body != nil:
    body_773448 = body
  result = call_773447.call(nil, nil, nil, nil, body_773448)

var resendContactReachabilityEmail* = Call_ResendContactReachabilityEmail_773434(
    name: "resendContactReachabilityEmail", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ResendContactReachabilityEmail",
    validator: validate_ResendContactReachabilityEmail_773435, base: "/",
    url: url_ResendContactReachabilityEmail_773436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveDomainAuthCode_773449 = ref object of OpenApiRestCall_772597
proc url_RetrieveDomainAuthCode_773451(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RetrieveDomainAuthCode_773450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the AuthCode for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
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
  var valid_773452 = header.getOrDefault("X-Amz-Date")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Date", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Security-Token")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Security-Token", valid_773453
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773454 = header.getOrDefault("X-Amz-Target")
  valid_773454 = validateParameter(valid_773454, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RetrieveDomainAuthCode"))
  if valid_773454 != nil:
    section.add "X-Amz-Target", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Content-Sha256", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Algorithm")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Algorithm", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Signature")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Signature", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-SignedHeaders", valid_773458
  var valid_773459 = header.getOrDefault("X-Amz-Credential")
  valid_773459 = validateParameter(valid_773459, JString, required = false,
                                 default = nil)
  if valid_773459 != nil:
    section.add "X-Amz-Credential", valid_773459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773461: Call_RetrieveDomainAuthCode_773449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the AuthCode for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
  ## 
  let valid = call_773461.validator(path, query, header, formData, body)
  let scheme = call_773461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773461.url(scheme.get, call_773461.host, call_773461.base,
                         call_773461.route, valid.getOrDefault("path"))
  result = hook(call_773461, url, valid)

proc call*(call_773462: Call_RetrieveDomainAuthCode_773449; body: JsonNode): Recallable =
  ## retrieveDomainAuthCode
  ## This operation returns the AuthCode for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
  ##   body: JObject (required)
  var body_773463 = newJObject()
  if body != nil:
    body_773463 = body
  result = call_773462.call(nil, nil, nil, nil, body_773463)

var retrieveDomainAuthCode* = Call_RetrieveDomainAuthCode_773449(
    name: "retrieveDomainAuthCode", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.RetrieveDomainAuthCode",
    validator: validate_RetrieveDomainAuthCode_773450, base: "/",
    url: url_RetrieveDomainAuthCode_773451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransferDomain_773464 = ref object of OpenApiRestCall_772597
proc url_TransferDomain_773466(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TransferDomain_773465(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>This operation transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs).</p> <p>For transfer requirements, a detailed procedure, and information about viewing the status of a domain transfer, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html">Transferring Registration for a Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you consider transferring your DNS service to Amazon Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time.</p> <important> <p>If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable.</p> </important> <p>If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.</p>
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
  var valid_773467 = header.getOrDefault("X-Amz-Date")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Date", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Security-Token")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Security-Token", valid_773468
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773469 = header.getOrDefault("X-Amz-Target")
  valid_773469 = validateParameter(valid_773469, JString, required = true, default = newJString(
      "Route53Domains_v20140515.TransferDomain"))
  if valid_773469 != nil:
    section.add "X-Amz-Target", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-Content-Sha256", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Algorithm")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Algorithm", valid_773471
  var valid_773472 = header.getOrDefault("X-Amz-Signature")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Signature", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-SignedHeaders", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Credential")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Credential", valid_773474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773476: Call_TransferDomain_773464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs).</p> <p>For transfer requirements, a detailed procedure, and information about viewing the status of a domain transfer, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html">Transferring Registration for a Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you consider transferring your DNS service to Amazon Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time.</p> <important> <p>If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable.</p> </important> <p>If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_773476.validator(path, query, header, formData, body)
  let scheme = call_773476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773476.url(scheme.get, call_773476.host, call_773476.base,
                         call_773476.route, valid.getOrDefault("path"))
  result = hook(call_773476, url, valid)

proc call*(call_773477: Call_TransferDomain_773464; body: JsonNode): Recallable =
  ## transferDomain
  ## <p>This operation transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs).</p> <p>For transfer requirements, a detailed procedure, and information about viewing the status of a domain transfer, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html">Transferring Registration for a Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you consider transferring your DNS service to Amazon Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time.</p> <important> <p>If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable.</p> </important> <p>If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_773478 = newJObject()
  if body != nil:
    body_773478 = body
  result = call_773477.call(nil, nil, nil, nil, body_773478)

var transferDomain* = Call_TransferDomain_773464(name: "transferDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.TransferDomain",
    validator: validate_TransferDomain_773465, base: "/", url: url_TransferDomain_773466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainContact_773479 = ref object of OpenApiRestCall_772597
proc url_UpdateDomainContact_773481(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainContact_773480(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical.</p> <p>If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
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
  var valid_773482 = header.getOrDefault("X-Amz-Date")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Date", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Security-Token")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Security-Token", valid_773483
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773484 = header.getOrDefault("X-Amz-Target")
  valid_773484 = validateParameter(valid_773484, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainContact"))
  if valid_773484 != nil:
    section.add "X-Amz-Target", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Content-Sha256", valid_773485
  var valid_773486 = header.getOrDefault("X-Amz-Algorithm")
  valid_773486 = validateParameter(valid_773486, JString, required = false,
                                 default = nil)
  if valid_773486 != nil:
    section.add "X-Amz-Algorithm", valid_773486
  var valid_773487 = header.getOrDefault("X-Amz-Signature")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Signature", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-SignedHeaders", valid_773488
  var valid_773489 = header.getOrDefault("X-Amz-Credential")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "X-Amz-Credential", valid_773489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773491: Call_UpdateDomainContact_773479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical.</p> <p>If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_773491.validator(path, query, header, formData, body)
  let scheme = call_773491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773491.url(scheme.get, call_773491.host, call_773491.base,
                         call_773491.route, valid.getOrDefault("path"))
  result = hook(call_773491, url, valid)

proc call*(call_773492: Call_UpdateDomainContact_773479; body: JsonNode): Recallable =
  ## updateDomainContact
  ## <p>This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical.</p> <p>If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_773493 = newJObject()
  if body != nil:
    body_773493 = body
  result = call_773492.call(nil, nil, nil, nil, body_773493)

var updateDomainContact* = Call_UpdateDomainContact_773479(
    name: "updateDomainContact", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainContact",
    validator: validate_UpdateDomainContact_773480, base: "/",
    url: url_UpdateDomainContact_773481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainContactPrivacy_773494 = ref object of OpenApiRestCall_772597
proc url_UpdateDomainContactPrivacy_773496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainContactPrivacy_773495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi.</p> <p>This operation affects only the contact information for the specified contact type (registrant, administrator, or tech). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with <a>GetOperationDetail</a> to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email.</p>
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
  var valid_773497 = header.getOrDefault("X-Amz-Date")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Date", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-Security-Token")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-Security-Token", valid_773498
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773499 = header.getOrDefault("X-Amz-Target")
  valid_773499 = validateParameter(valid_773499, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainContactPrivacy"))
  if valid_773499 != nil:
    section.add "X-Amz-Target", valid_773499
  var valid_773500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "X-Amz-Content-Sha256", valid_773500
  var valid_773501 = header.getOrDefault("X-Amz-Algorithm")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "X-Amz-Algorithm", valid_773501
  var valid_773502 = header.getOrDefault("X-Amz-Signature")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Signature", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-SignedHeaders", valid_773503
  var valid_773504 = header.getOrDefault("X-Amz-Credential")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Credential", valid_773504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773506: Call_UpdateDomainContactPrivacy_773494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi.</p> <p>This operation affects only the contact information for the specified contact type (registrant, administrator, or tech). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with <a>GetOperationDetail</a> to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_773506.validator(path, query, header, formData, body)
  let scheme = call_773506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773506.url(scheme.get, call_773506.host, call_773506.base,
                         call_773506.route, valid.getOrDefault("path"))
  result = hook(call_773506, url, valid)

proc call*(call_773507: Call_UpdateDomainContactPrivacy_773494; body: JsonNode): Recallable =
  ## updateDomainContactPrivacy
  ## <p>This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi.</p> <p>This operation affects only the contact information for the specified contact type (registrant, administrator, or tech). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with <a>GetOperationDetail</a> to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_773508 = newJObject()
  if body != nil:
    body_773508 = body
  result = call_773507.call(nil, nil, nil, nil, body_773508)

var updateDomainContactPrivacy* = Call_UpdateDomainContactPrivacy_773494(
    name: "updateDomainContactPrivacy", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainContactPrivacy",
    validator: validate_UpdateDomainContactPrivacy_773495, base: "/",
    url: url_UpdateDomainContactPrivacy_773496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainNameservers_773509 = ref object of OpenApiRestCall_772597
proc url_UpdateDomainNameservers_773511(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainNameservers_773510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain.</p> <p>If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
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
  var valid_773512 = header.getOrDefault("X-Amz-Date")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Date", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Security-Token")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Security-Token", valid_773513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773514 = header.getOrDefault("X-Amz-Target")
  valid_773514 = validateParameter(valid_773514, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainNameservers"))
  if valid_773514 != nil:
    section.add "X-Amz-Target", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Content-Sha256", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Algorithm")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Algorithm", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-Signature")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Signature", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-SignedHeaders", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Credential")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Credential", valid_773519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773521: Call_UpdateDomainNameservers_773509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain.</p> <p>If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_773521.validator(path, query, header, formData, body)
  let scheme = call_773521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773521.url(scheme.get, call_773521.host, call_773521.base,
                         call_773521.route, valid.getOrDefault("path"))
  result = hook(call_773521, url, valid)

proc call*(call_773522: Call_UpdateDomainNameservers_773509; body: JsonNode): Recallable =
  ## updateDomainNameservers
  ## <p>This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain.</p> <p>If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_773523 = newJObject()
  if body != nil:
    body_773523 = body
  result = call_773522.call(nil, nil, nil, nil, body_773523)

var updateDomainNameservers* = Call_UpdateDomainNameservers_773509(
    name: "updateDomainNameservers", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainNameservers",
    validator: validate_UpdateDomainNameservers_773510, base: "/",
    url: url_UpdateDomainNameservers_773511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagsForDomain_773524 = ref object of OpenApiRestCall_772597
proc url_UpdateTagsForDomain_773526(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTagsForDomain_773525(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>This operation adds or updates tags for a specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
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
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773529 = header.getOrDefault("X-Amz-Target")
  valid_773529 = validateParameter(valid_773529, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateTagsForDomain"))
  if valid_773529 != nil:
    section.add "X-Amz-Target", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Content-Sha256", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Algorithm")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Algorithm", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-Signature")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Signature", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-SignedHeaders", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Credential")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Credential", valid_773534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773536: Call_UpdateTagsForDomain_773524; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation adds or updates tags for a specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_773536.validator(path, query, header, formData, body)
  let scheme = call_773536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773536.url(scheme.get, call_773536.host, call_773536.base,
                         call_773536.route, valid.getOrDefault("path"))
  result = hook(call_773536, url, valid)

proc call*(call_773537: Call_UpdateTagsForDomain_773524; body: JsonNode): Recallable =
  ## updateTagsForDomain
  ## <p>This operation adds or updates tags for a specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_773538 = newJObject()
  if body != nil:
    body_773538 = body
  result = call_773537.call(nil, nil, nil, nil, body_773538)

var updateTagsForDomain* = Call_UpdateTagsForDomain_773524(
    name: "updateTagsForDomain", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateTagsForDomain",
    validator: validate_UpdateTagsForDomain_773525, base: "/",
    url: url_UpdateTagsForDomain_773526, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ViewBilling_773539 = ref object of OpenApiRestCall_772597
proc url_ViewBilling_773541(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ViewBilling_773540(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all the domain-related billing records for the current AWS account for a specified period
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
  var valid_773542 = header.getOrDefault("X-Amz-Date")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "X-Amz-Date", valid_773542
  var valid_773543 = header.getOrDefault("X-Amz-Security-Token")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "X-Amz-Security-Token", valid_773543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773544 = header.getOrDefault("X-Amz-Target")
  valid_773544 = validateParameter(valid_773544, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ViewBilling"))
  if valid_773544 != nil:
    section.add "X-Amz-Target", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Content-Sha256", valid_773545
  var valid_773546 = header.getOrDefault("X-Amz-Algorithm")
  valid_773546 = validateParameter(valid_773546, JString, required = false,
                                 default = nil)
  if valid_773546 != nil:
    section.add "X-Amz-Algorithm", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Signature")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Signature", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-SignedHeaders", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Credential")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Credential", valid_773549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773551: Call_ViewBilling_773539; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the domain-related billing records for the current AWS account for a specified period
  ## 
  let valid = call_773551.validator(path, query, header, formData, body)
  let scheme = call_773551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773551.url(scheme.get, call_773551.host, call_773551.base,
                         call_773551.route, valid.getOrDefault("path"))
  result = hook(call_773551, url, valid)

proc call*(call_773552: Call_ViewBilling_773539; body: JsonNode): Recallable =
  ## viewBilling
  ## Returns all the domain-related billing records for the current AWS account for a specified period
  ##   body: JObject (required)
  var body_773553 = newJObject()
  if body != nil:
    body_773553 = body
  result = call_773552.call(nil, nil, nil, nil, body_773553)

var viewBilling* = Call_ViewBilling_773539(name: "viewBilling",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ViewBilling",
                                        validator: validate_ViewBilling_773540,
                                        base: "/", url: url_ViewBilling_773541,
                                        schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
