
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
  Call_CheckDomainAvailability_602770 = ref object of OpenApiRestCall_602433
proc url_CheckDomainAvailability_602772(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CheckDomainAvailability_602771(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.CheckDomainAvailability"))
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

proc call*(call_602928: Call_CheckDomainAvailability_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_CheckDomainAvailability_602770; body: JsonNode): Recallable =
  ## checkDomainAvailability
  ## This operation checks the availability of one domain name. Note that if the availability status of a domain is pending, you must submit another request to determine the availability of the domain name.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var checkDomainAvailability* = Call_CheckDomainAvailability_602770(
    name: "checkDomainAvailability", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.CheckDomainAvailability",
    validator: validate_CheckDomainAvailability_602771, base: "/",
    url: url_CheckDomainAvailability_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CheckDomainTransferability_603039 = ref object of OpenApiRestCall_602433
proc url_CheckDomainTransferability_603041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CheckDomainTransferability_603040(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.CheckDomainTransferability"))
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

proc call*(call_603051: Call_CheckDomainTransferability_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks whether a domain name can be transferred to Amazon Route 53. 
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CheckDomainTransferability_603039; body: JsonNode): Recallable =
  ## checkDomainTransferability
  ## Checks whether a domain name can be transferred to Amazon Route 53. 
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var checkDomainTransferability* = Call_CheckDomainTransferability_603039(
    name: "checkDomainTransferability", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.CheckDomainTransferability",
    validator: validate_CheckDomainTransferability_603040, base: "/",
    url: url_CheckDomainTransferability_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagsForDomain_603054 = ref object of OpenApiRestCall_602433
proc url_DeleteTagsForDomain_603056(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTagsForDomain_603055(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.DeleteTagsForDomain"))
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

proc call*(call_603066: Call_DeleteTagsForDomain_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation deletes the specified tags for a domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_DeleteTagsForDomain_603054; body: JsonNode): Recallable =
  ## deleteTagsForDomain
  ## <p>This operation deletes the specified tags for a domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var deleteTagsForDomain* = Call_DeleteTagsForDomain_603054(
    name: "deleteTagsForDomain", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DeleteTagsForDomain",
    validator: validate_DeleteTagsForDomain_603055, base: "/",
    url: url_DeleteTagsForDomain_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDomainAutoRenew_603069 = ref object of OpenApiRestCall_602433
proc url_DisableDomainAutoRenew_603071(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDomainAutoRenew_603070(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.DisableDomainAutoRenew"))
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

proc call*(call_603081: Call_DisableDomainAutoRenew_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation disables automatic renewal of domain registration for the specified domain.
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_DisableDomainAutoRenew_603069; body: JsonNode): Recallable =
  ## disableDomainAutoRenew
  ## This operation disables automatic renewal of domain registration for the specified domain.
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var disableDomainAutoRenew* = Call_DisableDomainAutoRenew_603069(
    name: "disableDomainAutoRenew", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DisableDomainAutoRenew",
    validator: validate_DisableDomainAutoRenew_603070, base: "/",
    url: url_DisableDomainAutoRenew_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableDomainTransferLock_603084 = ref object of OpenApiRestCall_602433
proc url_DisableDomainTransferLock_603086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableDomainTransferLock_603085(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.DisableDomainTransferLock"))
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

proc call*(call_603096: Call_DisableDomainTransferLock_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_DisableDomainTransferLock_603084; body: JsonNode): Recallable =
  ## disableDomainTransferLock
  ## This operation removes the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to allow domain transfers. We recommend you refrain from performing this action unless you intend to transfer the domain to a different registrar. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var disableDomainTransferLock* = Call_DisableDomainTransferLock_603084(
    name: "disableDomainTransferLock", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.DisableDomainTransferLock",
    validator: validate_DisableDomainTransferLock_603085, base: "/",
    url: url_DisableDomainTransferLock_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDomainAutoRenew_603099 = ref object of OpenApiRestCall_602433
proc url_EnableDomainAutoRenew_603101(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDomainAutoRenew_603100(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.EnableDomainAutoRenew"))
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

proc call*(call_603111: Call_EnableDomainAutoRenew_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your AWS account.</p> <p>The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see <a href="http://wiki.gandi.net/en/domains/renew#renewal_restoration_and_deletion_times">"Renewal, restoration, and deletion times"</a> on the website for our registrar associate, Gandi. Amazon Route 53 requires that you renew before the end of the renewal period that is listed on the Gandi website so we can complete processing before the deadline.</p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_EnableDomainAutoRenew_603099; body: JsonNode): Recallable =
  ## enableDomainAutoRenew
  ## <p>This operation configures Amazon Route 53 to automatically renew the specified domain before the domain registration expires. The cost of renewing your domain registration is billed to your AWS account.</p> <p>The period during which you can renew a domain name varies by TLD. For a list of TLDs and their renewal policies, see <a href="http://wiki.gandi.net/en/domains/renew#renewal_restoration_and_deletion_times">"Renewal, restoration, and deletion times"</a> on the website for our registrar associate, Gandi. Amazon Route 53 requires that you renew before the end of the renewal period that is listed on the Gandi website so we can complete processing before the deadline.</p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var enableDomainAutoRenew* = Call_EnableDomainAutoRenew_603099(
    name: "enableDomainAutoRenew", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.EnableDomainAutoRenew",
    validator: validate_EnableDomainAutoRenew_603100, base: "/",
    url: url_EnableDomainAutoRenew_603101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableDomainTransferLock_603114 = ref object of OpenApiRestCall_602433
proc url_EnableDomainTransferLock_603116(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableDomainTransferLock_603115(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.EnableDomainTransferLock"))
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

proc call*(call_603126: Call_EnableDomainTransferLock_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation sets the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_EnableDomainTransferLock_603114; body: JsonNode): Recallable =
  ## enableDomainTransferLock
  ## This operation sets the transfer lock on the domain (specifically the <code>clientTransferProhibited</code> status) to prevent domain transfers. Successful submission returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var enableDomainTransferLock* = Call_EnableDomainTransferLock_603114(
    name: "enableDomainTransferLock", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.EnableDomainTransferLock",
    validator: validate_EnableDomainTransferLock_603115, base: "/",
    url: url_EnableDomainTransferLock_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContactReachabilityStatus_603129 = ref object of OpenApiRestCall_602433
proc url_GetContactReachabilityStatus_603131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetContactReachabilityStatus_603130(path: JsonNode; query: JsonNode;
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
      "Route53Domains_v20140515.GetContactReachabilityStatus"))
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

proc call*(call_603141: Call_GetContactReachabilityStatus_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded.</p> <p>If you want us to resend the email, use the <code>ResendContactReachabilityEmail</code> operation.</p>
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_GetContactReachabilityStatus_603129; body: JsonNode): Recallable =
  ## getContactReachabilityStatus
  ## <p>For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation returns information about whether the registrant contact has responded.</p> <p>If you want us to resend the email, use the <code>ResendContactReachabilityEmail</code> operation.</p>
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var getContactReachabilityStatus* = Call_GetContactReachabilityStatus_603129(
    name: "getContactReachabilityStatus", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.GetContactReachabilityStatus",
    validator: validate_GetContactReachabilityStatus_603130, base: "/",
    url: url_GetContactReachabilityStatus_603131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDetail_603144 = ref object of OpenApiRestCall_602433
proc url_GetDomainDetail_603146(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainDetail_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetDomainDetail"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_GetDomainDetail_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns detailed information about a specified domain that is associated with the current AWS account. Contact information for the domain is also returned as part of the output.
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_GetDomainDetail_603144; body: JsonNode): Recallable =
  ## getDomainDetail
  ## This operation returns detailed information about a specified domain that is associated with the current AWS account. Contact information for the domain is also returned as part of the output.
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var getDomainDetail* = Call_GetDomainDetail_603144(name: "getDomainDetail",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetDomainDetail",
    validator: validate_GetDomainDetail_603145, base: "/", url: url_GetDomainDetail_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainSuggestions_603159 = ref object of OpenApiRestCall_602433
proc url_GetDomainSuggestions_603161(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDomainSuggestions_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetDomainSuggestions"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_GetDomainSuggestions_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The GetDomainSuggestions operation returns a list of suggested domain names given a string, which can either be a domain name or simply a word or phrase (without spaces).
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_GetDomainSuggestions_603159; body: JsonNode): Recallable =
  ## getDomainSuggestions
  ## The GetDomainSuggestions operation returns a list of suggested domain names given a string, which can either be a domain name or simply a word or phrase (without spaces).
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var getDomainSuggestions* = Call_GetDomainSuggestions_603159(
    name: "getDomainSuggestions", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetDomainSuggestions",
    validator: validate_GetDomainSuggestions_603160, base: "/",
    url: url_GetDomainSuggestions_603161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOperationDetail_603174 = ref object of OpenApiRestCall_602433
proc url_GetOperationDetail_603176(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOperationDetail_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "Route53Domains_v20140515.GetOperationDetail"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_GetOperationDetail_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the current status of an operation that is not completed.
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_GetOperationDetail_603174; body: JsonNode): Recallable =
  ## getOperationDetail
  ## This operation returns the current status of an operation that is not completed.
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var getOperationDetail* = Call_GetOperationDetail_603174(
    name: "getOperationDetail", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.GetOperationDetail",
    validator: validate_GetOperationDetail_603175, base: "/",
    url: url_GetOperationDetail_603176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_603189 = ref object of OpenApiRestCall_602433
proc url_ListDomains_603191(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDomains_603190(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603192 = query.getOrDefault("Marker")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "Marker", valid_603192
  var valid_603193 = query.getOrDefault("MaxItems")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "MaxItems", valid_603193
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
  var valid_603194 = header.getOrDefault("X-Amz-Date")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Date", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Security-Token")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Security-Token", valid_603195
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603196 = header.getOrDefault("X-Amz-Target")
  valid_603196 = validateParameter(valid_603196, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListDomains"))
  if valid_603196 != nil:
    section.add "X-Amz-Target", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Content-Sha256", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Algorithm")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Algorithm", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Signature")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Signature", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-SignedHeaders", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603203: Call_ListDomains_603189; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns all the domain names registered with Amazon Route 53 for the current AWS account.
  ## 
  let valid = call_603203.validator(path, query, header, formData, body)
  let scheme = call_603203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603203.url(scheme.get, call_603203.host, call_603203.base,
                         call_603203.route, valid.getOrDefault("path"))
  result = hook(call_603203, url, valid)

proc call*(call_603204: Call_ListDomains_603189; body: JsonNode; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDomains
  ## This operation returns all the domain names registered with Amazon Route 53 for the current AWS account.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603205 = newJObject()
  var body_603206 = newJObject()
  add(query_603205, "Marker", newJString(Marker))
  if body != nil:
    body_603206 = body
  add(query_603205, "MaxItems", newJString(MaxItems))
  result = call_603204.call(nil, query_603205, nil, nil, body_603206)

var listDomains* = Call_ListDomains_603189(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ListDomains",
                                        validator: validate_ListDomains_603190,
                                        base: "/", url: url_ListDomains_603191,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOperations_603208 = ref object of OpenApiRestCall_602433
proc url_ListOperations_603210(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOperations_603209(path: JsonNode; query: JsonNode;
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
  var valid_603211 = query.getOrDefault("Marker")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "Marker", valid_603211
  var valid_603212 = query.getOrDefault("MaxItems")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "MaxItems", valid_603212
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
  var valid_603213 = header.getOrDefault("X-Amz-Date")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Date", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Security-Token")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Security-Token", valid_603214
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603215 = header.getOrDefault("X-Amz-Target")
  valid_603215 = validateParameter(valid_603215, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListOperations"))
  if valid_603215 != nil:
    section.add "X-Amz-Target", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Algorithm")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Algorithm", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Signature")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Signature", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_ListOperations_603208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the operation IDs of operations that are not yet complete.
  ## 
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_ListOperations_603208; body: JsonNode;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listOperations
  ## This operation returns the operation IDs of operations that are not yet complete.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603224 = newJObject()
  var body_603225 = newJObject()
  add(query_603224, "Marker", newJString(Marker))
  if body != nil:
    body_603225 = body
  add(query_603224, "MaxItems", newJString(MaxItems))
  result = call_603223.call(nil, query_603224, nil, nil, body_603225)

var listOperations* = Call_ListOperations_603208(name: "listOperations",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.ListOperations",
    validator: validate_ListOperations_603209, base: "/", url: url_ListOperations_603210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForDomain_603226 = ref object of OpenApiRestCall_602433
proc url_ListTagsForDomain_603228(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForDomain_603227(path: JsonNode; query: JsonNode;
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
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603231 = header.getOrDefault("X-Amz-Target")
  valid_603231 = validateParameter(valid_603231, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ListTagsForDomain"))
  if valid_603231 != nil:
    section.add "X-Amz-Target", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_ListTagsForDomain_603226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation returns all of the tags that are associated with the specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"))
  result = hook(call_603238, url, valid)

proc call*(call_603239: Call_ListTagsForDomain_603226; body: JsonNode): Recallable =
  ## listTagsForDomain
  ## <p>This operation returns all of the tags that are associated with the specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_603240 = newJObject()
  if body != nil:
    body_603240 = body
  result = call_603239.call(nil, nil, nil, nil, body_603240)

var listTagsForDomain* = Call_ListTagsForDomain_603226(name: "listTagsForDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.ListTagsForDomain",
    validator: validate_ListTagsForDomain_603227, base: "/",
    url: url_ListTagsForDomain_603228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDomain_603241 = ref object of OpenApiRestCall_602433
proc url_RegisterDomain_603243(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterDomain_603242(path: JsonNode; query: JsonNode;
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
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603246 = header.getOrDefault("X-Amz-Target")
  valid_603246 = validateParameter(valid_603246, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RegisterDomain"))
  if valid_603246 != nil:
    section.add "X-Amz-Target", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Content-Sha256", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-SignedHeaders", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Credential")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Credential", valid_603251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_RegisterDomain_603241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters.</p> <p>When you register a domain, Amazon Route 53 does the following:</p> <ul> <li> <p>Creates a Amazon Route 53 hosted zone that has the same name as the domain. Amazon Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers.</p> </li> <li> <p>Enables autorenew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration.</p> </li> <li> <p>Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the registrant, admin, and tech contacts.</p> </li> <li> <p>If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email.</p> </li> <li> <p>Charges your AWS account an amount based on the top-level domain. For more information, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> </li> </ul>
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_RegisterDomain_603241; body: JsonNode): Recallable =
  ## registerDomain
  ## <p>This operation registers a domain. Domains are registered either by Amazon Registrar (for .com, .net, and .org domains) or by our registrar associate, Gandi (for all other domains). For some top-level domains (TLDs), this operation requires extra parameters.</p> <p>When you register a domain, Amazon Route 53 does the following:</p> <ul> <li> <p>Creates a Amazon Route 53 hosted zone that has the same name as the domain. Amazon Route 53 assigns four name servers to your hosted zone and automatically updates your domain registration with the names of these name servers.</p> </li> <li> <p>Enables autorenew, so your domain registration will renew automatically each year. We'll notify you in advance of the renewal date so you can choose whether to renew the registration.</p> </li> <li> <p>Optionally enables privacy protection, so WHOIS queries return contact information either for Amazon Registrar (for .com, .net, and .org domains) or for our registrar associate, Gandi (for all other TLDs). If you don't enable privacy protection, WHOIS queries return the information that you entered for the registrant, admin, and tech contacts.</p> </li> <li> <p>If registration is successful, returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant is notified by email.</p> </li> <li> <p>Charges your AWS account an amount based on the top-level domain. For more information, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603255 = newJObject()
  if body != nil:
    body_603255 = body
  result = call_603254.call(nil, nil, nil, nil, body_603255)

var registerDomain* = Call_RegisterDomain_603241(name: "registerDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.RegisterDomain",
    validator: validate_RegisterDomain_603242, base: "/", url: url_RegisterDomain_603243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenewDomain_603256 = ref object of OpenApiRestCall_602433
proc url_RenewDomain_603258(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RenewDomain_603257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603261 = header.getOrDefault("X-Amz-Target")
  valid_603261 = validateParameter(valid_603261, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RenewDomain"))
  if valid_603261 != nil:
    section.add "X-Amz-Target", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Content-Sha256", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Algorithm")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Algorithm", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Signature")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Signature", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-SignedHeaders", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Credential")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Credential", valid_603266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603268: Call_RenewDomain_603256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your AWS account.</p> <p>We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html">Renewing Registration for a Domain</a> in the Amazon Route 53 Developer Guide.</p>
  ## 
  let valid = call_603268.validator(path, query, header, formData, body)
  let scheme = call_603268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603268.url(scheme.get, call_603268.host, call_603268.base,
                         call_603268.route, valid.getOrDefault("path"))
  result = hook(call_603268, url, valid)

proc call*(call_603269: Call_RenewDomain_603256; body: JsonNode): Recallable =
  ## renewDomain
  ## <p>This operation renews a domain for the specified number of years. The cost of renewing your domain is billed to your AWS account.</p> <p>We recommend that you renew your domain several weeks before the expiration date. Some TLD registries delete domains before the expiration date if you haven't renewed far enough in advance. For more information about renewing domain registration, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-renew.html">Renewing Registration for a Domain</a> in the Amazon Route 53 Developer Guide.</p>
  ##   body: JObject (required)
  var body_603270 = newJObject()
  if body != nil:
    body_603270 = body
  result = call_603269.call(nil, nil, nil, nil, body_603270)

var renewDomain* = Call_RenewDomain_603256(name: "renewDomain",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.RenewDomain",
                                        validator: validate_RenewDomain_603257,
                                        base: "/", url: url_RenewDomain_603258,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResendContactReachabilityEmail_603271 = ref object of OpenApiRestCall_602433
proc url_ResendContactReachabilityEmail_603273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResendContactReachabilityEmail_603272(path: JsonNode;
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
  var valid_603274 = header.getOrDefault("X-Amz-Date")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Date", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Security-Token")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Security-Token", valid_603275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603276 = header.getOrDefault("X-Amz-Target")
  valid_603276 = validateParameter(valid_603276, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ResendContactReachabilityEmail"))
  if valid_603276 != nil:
    section.add "X-Amz-Target", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Content-Sha256", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_ResendContactReachabilityEmail_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_ResendContactReachabilityEmail_603271; body: JsonNode): Recallable =
  ## resendContactReachabilityEmail
  ## For operations that require confirmation that the email address for the registrant contact is valid, such as registering a new domain, this operation resends the confirmation email to the current email address for the registrant contact.
  ##   body: JObject (required)
  var body_603285 = newJObject()
  if body != nil:
    body_603285 = body
  result = call_603284.call(nil, nil, nil, nil, body_603285)

var resendContactReachabilityEmail* = Call_ResendContactReachabilityEmail_603271(
    name: "resendContactReachabilityEmail", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ResendContactReachabilityEmail",
    validator: validate_ResendContactReachabilityEmail_603272, base: "/",
    url: url_ResendContactReachabilityEmail_603273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RetrieveDomainAuthCode_603286 = ref object of OpenApiRestCall_602433
proc url_RetrieveDomainAuthCode_603288(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RetrieveDomainAuthCode_603287(path: JsonNode; query: JsonNode;
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
  var valid_603289 = header.getOrDefault("X-Amz-Date")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Date", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Security-Token")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Security-Token", valid_603290
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603291 = header.getOrDefault("X-Amz-Target")
  valid_603291 = validateParameter(valid_603291, JString, required = true, default = newJString(
      "Route53Domains_v20140515.RetrieveDomainAuthCode"))
  if valid_603291 != nil:
    section.add "X-Amz-Target", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Content-Sha256", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Signature")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Signature", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Credential")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Credential", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_RetrieveDomainAuthCode_603286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the AuthCode for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_RetrieveDomainAuthCode_603286; body: JsonNode): Recallable =
  ## retrieveDomainAuthCode
  ## This operation returns the AuthCode for the domain. To transfer a domain to another registrar, you provide this value to the new registrar.
  ##   body: JObject (required)
  var body_603300 = newJObject()
  if body != nil:
    body_603300 = body
  result = call_603299.call(nil, nil, nil, nil, body_603300)

var retrieveDomainAuthCode* = Call_RetrieveDomainAuthCode_603286(
    name: "retrieveDomainAuthCode", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.RetrieveDomainAuthCode",
    validator: validate_RetrieveDomainAuthCode_603287, base: "/",
    url: url_RetrieveDomainAuthCode_603288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TransferDomain_603301 = ref object of OpenApiRestCall_602433
proc url_TransferDomain_603303(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TransferDomain_603302(path: JsonNode; query: JsonNode;
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
  var valid_603304 = header.getOrDefault("X-Amz-Date")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Date", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Security-Token")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Security-Token", valid_603305
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603306 = header.getOrDefault("X-Amz-Target")
  valid_603306 = validateParameter(valid_603306, JString, required = true, default = newJString(
      "Route53Domains_v20140515.TransferDomain"))
  if valid_603306 != nil:
    section.add "X-Amz-Target", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Content-Sha256", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Algorithm")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Algorithm", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Signature")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Signature", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-SignedHeaders", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Credential")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Credential", valid_603311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603313: Call_TransferDomain_603301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs).</p> <p>For transfer requirements, a detailed procedure, and information about viewing the status of a domain transfer, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html">Transferring Registration for a Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you consider transferring your DNS service to Amazon Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time.</p> <important> <p>If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable.</p> </important> <p>If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_603313.validator(path, query, header, formData, body)
  let scheme = call_603313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603313.url(scheme.get, call_603313.host, call_603313.base,
                         call_603313.route, valid.getOrDefault("path"))
  result = hook(call_603313, url, valid)

proc call*(call_603314: Call_TransferDomain_603301; body: JsonNode): Recallable =
  ## transferDomain
  ## <p>This operation transfers a domain from another registrar to Amazon Route 53. When the transfer is complete, the domain is registered either with Amazon Registrar (for .com, .net, and .org domains) or with our registrar associate, Gandi (for all other TLDs).</p> <p>For transfer requirements, a detailed procedure, and information about viewing the status of a domain transfer, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html">Transferring Registration for a Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If the registrar for your domain is also the DNS service provider for the domain, we highly recommend that you consider transferring your DNS service to Amazon Route 53 or to another DNS service provider before you transfer your registration. Some registrars provide free DNS service when you purchase a domain registration. When you transfer the registration, the previous registrar will not renew your domain registration and could end your DNS service at any time.</p> <important> <p>If the registrar for your domain is also the DNS service provider for the domain and you don't transfer DNS service to another provider, your website, email, and the web applications associated with the domain might become unavailable.</p> </important> <p>If the transfer is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the transfer doesn't complete successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_603315 = newJObject()
  if body != nil:
    body_603315 = body
  result = call_603314.call(nil, nil, nil, nil, body_603315)

var transferDomain* = Call_TransferDomain_603301(name: "transferDomain",
    meth: HttpMethod.HttpPost, host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.TransferDomain",
    validator: validate_TransferDomain_603302, base: "/", url: url_TransferDomain_603303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainContact_603316 = ref object of OpenApiRestCall_602433
proc url_UpdateDomainContact_603318(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainContact_603317(path: JsonNode; query: JsonNode;
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
  var valid_603319 = header.getOrDefault("X-Amz-Date")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Date", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Security-Token")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Security-Token", valid_603320
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603321 = header.getOrDefault("X-Amz-Target")
  valid_603321 = validateParameter(valid_603321, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainContact"))
  if valid_603321 != nil:
    section.add "X-Amz-Target", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Content-Sha256", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Signature")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Signature", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-SignedHeaders", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Credential")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Credential", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603328: Call_UpdateDomainContact_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical.</p> <p>If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_603328.validator(path, query, header, formData, body)
  let scheme = call_603328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603328.url(scheme.get, call_603328.host, call_603328.base,
                         call_603328.route, valid.getOrDefault("path"))
  result = hook(call_603328, url, valid)

proc call*(call_603329: Call_UpdateDomainContact_603316; body: JsonNode): Recallable =
  ## updateDomainContact
  ## <p>This operation updates the contact information for a particular domain. You must specify information for at least one contact: registrant, administrator, or technical.</p> <p>If the update is successful, this method returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_603330 = newJObject()
  if body != nil:
    body_603330 = body
  result = call_603329.call(nil, nil, nil, nil, body_603330)

var updateDomainContact* = Call_UpdateDomainContact_603316(
    name: "updateDomainContact", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainContact",
    validator: validate_UpdateDomainContact_603317, base: "/",
    url: url_UpdateDomainContact_603318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainContactPrivacy_603331 = ref object of OpenApiRestCall_602433
proc url_UpdateDomainContactPrivacy_603333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainContactPrivacy_603332(path: JsonNode; query: JsonNode;
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
  var valid_603334 = header.getOrDefault("X-Amz-Date")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Date", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Security-Token")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Security-Token", valid_603335
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603336 = header.getOrDefault("X-Amz-Target")
  valid_603336 = validateParameter(valid_603336, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainContactPrivacy"))
  if valid_603336 != nil:
    section.add "X-Amz-Target", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_UpdateDomainContactPrivacy_603331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi.</p> <p>This operation affects only the contact information for the specified contact type (registrant, administrator, or tech). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with <a>GetOperationDetail</a> to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"))
  result = hook(call_603343, url, valid)

proc call*(call_603344: Call_UpdateDomainContactPrivacy_603331; body: JsonNode): Recallable =
  ## updateDomainContactPrivacy
  ## <p>This operation updates the specified domain contact's privacy setting. When privacy protection is enabled, contact information such as email address is replaced either with contact information for Amazon Registrar (for .com, .net, and .org domains) or with contact information for our registrar associate, Gandi.</p> <p>This operation affects only the contact information for the specified contact type (registrant, administrator, or tech). If the request succeeds, Amazon Route 53 returns an operation ID that you can use with <a>GetOperationDetail</a> to track the progress and completion of the action. If the request doesn't complete successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_603345 = newJObject()
  if body != nil:
    body_603345 = body
  result = call_603344.call(nil, nil, nil, nil, body_603345)

var updateDomainContactPrivacy* = Call_UpdateDomainContactPrivacy_603331(
    name: "updateDomainContactPrivacy", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainContactPrivacy",
    validator: validate_UpdateDomainContactPrivacy_603332, base: "/",
    url: url_UpdateDomainContactPrivacy_603333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomainNameservers_603346 = ref object of OpenApiRestCall_602433
proc url_UpdateDomainNameservers_603348(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDomainNameservers_603347(path: JsonNode; query: JsonNode;
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603351 = header.getOrDefault("X-Amz-Target")
  valid_603351 = validateParameter(valid_603351, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateDomainNameservers"))
  if valid_603351 != nil:
    section.add "X-Amz-Target", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Content-Sha256", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Signature")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Signature", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-SignedHeaders", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Credential")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Credential", valid_603356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603358: Call_UpdateDomainNameservers_603346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain.</p> <p>If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ## 
  let valid = call_603358.validator(path, query, header, formData, body)
  let scheme = call_603358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603358.url(scheme.get, call_603358.host, call_603358.base,
                         call_603358.route, valid.getOrDefault("path"))
  result = hook(call_603358, url, valid)

proc call*(call_603359: Call_UpdateDomainNameservers_603346; body: JsonNode): Recallable =
  ## updateDomainNameservers
  ## <p>This operation replaces the current set of name servers for the domain with the specified set of name servers. If you use Amazon Route 53 as your DNS service, specify the four name servers in the delegation set for the hosted zone for the domain.</p> <p>If successful, this operation returns an operation ID that you can use to track the progress and completion of the action. If the request is not completed successfully, the domain registrant will be notified by email.</p>
  ##   body: JObject (required)
  var body_603360 = newJObject()
  if body != nil:
    body_603360 = body
  result = call_603359.call(nil, nil, nil, nil, body_603360)

var updateDomainNameservers* = Call_UpdateDomainNameservers_603346(
    name: "updateDomainNameservers", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateDomainNameservers",
    validator: validate_UpdateDomainNameservers_603347, base: "/",
    url: url_UpdateDomainNameservers_603348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagsForDomain_603361 = ref object of OpenApiRestCall_602433
proc url_UpdateTagsForDomain_603363(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTagsForDomain_603362(path: JsonNode; query: JsonNode;
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603366 = header.getOrDefault("X-Amz-Target")
  valid_603366 = validateParameter(valid_603366, JString, required = true, default = newJString(
      "Route53Domains_v20140515.UpdateTagsForDomain"))
  if valid_603366 != nil:
    section.add "X-Amz-Target", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Content-Sha256", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Signature")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Signature", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-SignedHeaders", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Credential")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Credential", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_UpdateTagsForDomain_603361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This operation adds or updates tags for a specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"))
  result = hook(call_603373, url, valid)

proc call*(call_603374: Call_UpdateTagsForDomain_603361; body: JsonNode): Recallable =
  ## updateTagsForDomain
  ## <p>This operation adds or updates tags for a specified domain.</p> <p>All tag operations are eventually consistent; subsequent operations might not immediately represent all issued operations.</p>
  ##   body: JObject (required)
  var body_603375 = newJObject()
  if body != nil:
    body_603375 = body
  result = call_603374.call(nil, nil, nil, nil, body_603375)

var updateTagsForDomain* = Call_UpdateTagsForDomain_603361(
    name: "updateTagsForDomain", meth: HttpMethod.HttpPost,
    host: "route53domains.amazonaws.com",
    route: "/#X-Amz-Target=Route53Domains_v20140515.UpdateTagsForDomain",
    validator: validate_UpdateTagsForDomain_603362, base: "/",
    url: url_UpdateTagsForDomain_603363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ViewBilling_603376 = ref object of OpenApiRestCall_602433
proc url_ViewBilling_603378(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ViewBilling_603377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603379 = header.getOrDefault("X-Amz-Date")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Date", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603381 = header.getOrDefault("X-Amz-Target")
  valid_603381 = validateParameter(valid_603381, JString, required = true, default = newJString(
      "Route53Domains_v20140515.ViewBilling"))
  if valid_603381 != nil:
    section.add "X-Amz-Target", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Content-Sha256", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Algorithm")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Algorithm", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Signature")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Signature", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-SignedHeaders", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Credential")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Credential", valid_603386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603388: Call_ViewBilling_603376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the domain-related billing records for the current AWS account for a specified period
  ## 
  let valid = call_603388.validator(path, query, header, formData, body)
  let scheme = call_603388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603388.url(scheme.get, call_603388.host, call_603388.base,
                         call_603388.route, valid.getOrDefault("path"))
  result = hook(call_603388, url, valid)

proc call*(call_603389: Call_ViewBilling_603376; body: JsonNode): Recallable =
  ## viewBilling
  ## Returns all the domain-related billing records for the current AWS account for a specified period
  ##   body: JObject (required)
  var body_603390 = newJObject()
  if body != nil:
    body_603390 = body
  result = call_603389.call(nil, nil, nil, nil, body_603390)

var viewBilling* = Call_ViewBilling_603376(name: "viewBilling",
                                        meth: HttpMethod.HttpPost,
                                        host: "route53domains.amazonaws.com", route: "/#X-Amz-Target=Route53Domains_v20140515.ViewBilling",
                                        validator: validate_ViewBilling_603377,
                                        base: "/", url: url_ViewBilling_603378,
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
