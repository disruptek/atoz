
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Service Catalog
## version: 2015-12-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Service Catalog</fullname> <p> <a href="https://aws.amazon.com/servicecatalog/">AWS Service Catalog</a> enables organizations to create and manage catalogs of IT services that are approved for use on AWS. To get the most out of this documentation, you should be familiar with the terminology discussed in <a href="http://docs.aws.amazon.com/servicecatalog/latest/adminguide/what-is_concepts.html">AWS Service Catalog Concepts</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/servicecatalog/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "servicecatalog.ap-northeast-1.amazonaws.com", "ap-southeast-1": "servicecatalog.ap-southeast-1.amazonaws.com", "us-west-2": "servicecatalog.us-west-2.amazonaws.com", "eu-west-2": "servicecatalog.eu-west-2.amazonaws.com", "ap-northeast-3": "servicecatalog.ap-northeast-3.amazonaws.com", "eu-central-1": "servicecatalog.eu-central-1.amazonaws.com", "us-east-2": "servicecatalog.us-east-2.amazonaws.com", "us-east-1": "servicecatalog.us-east-1.amazonaws.com", "cn-northwest-1": "servicecatalog.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "servicecatalog.ap-south-1.amazonaws.com", "eu-north-1": "servicecatalog.eu-north-1.amazonaws.com", "ap-northeast-2": "servicecatalog.ap-northeast-2.amazonaws.com", "us-west-1": "servicecatalog.us-west-1.amazonaws.com", "us-gov-east-1": "servicecatalog.us-gov-east-1.amazonaws.com", "eu-west-3": "servicecatalog.eu-west-3.amazonaws.com", "cn-north-1": "servicecatalog.cn-north-1.amazonaws.com.cn", "sa-east-1": "servicecatalog.sa-east-1.amazonaws.com", "eu-west-1": "servicecatalog.eu-west-1.amazonaws.com", "us-gov-west-1": "servicecatalog.us-gov-west-1.amazonaws.com", "ap-southeast-2": "servicecatalog.ap-southeast-2.amazonaws.com", "ca-central-1": "servicecatalog.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "servicecatalog.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "servicecatalog.ap-southeast-1.amazonaws.com",
      "us-west-2": "servicecatalog.us-west-2.amazonaws.com",
      "eu-west-2": "servicecatalog.eu-west-2.amazonaws.com",
      "ap-northeast-3": "servicecatalog.ap-northeast-3.amazonaws.com",
      "eu-central-1": "servicecatalog.eu-central-1.amazonaws.com",
      "us-east-2": "servicecatalog.us-east-2.amazonaws.com",
      "us-east-1": "servicecatalog.us-east-1.amazonaws.com",
      "cn-northwest-1": "servicecatalog.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "servicecatalog.ap-south-1.amazonaws.com",
      "eu-north-1": "servicecatalog.eu-north-1.amazonaws.com",
      "ap-northeast-2": "servicecatalog.ap-northeast-2.amazonaws.com",
      "us-west-1": "servicecatalog.us-west-1.amazonaws.com",
      "us-gov-east-1": "servicecatalog.us-gov-east-1.amazonaws.com",
      "eu-west-3": "servicecatalog.eu-west-3.amazonaws.com",
      "cn-north-1": "servicecatalog.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "servicecatalog.sa-east-1.amazonaws.com",
      "eu-west-1": "servicecatalog.eu-west-1.amazonaws.com",
      "us-gov-west-1": "servicecatalog.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "servicecatalog.ap-southeast-2.amazonaws.com",
      "ca-central-1": "servicecatalog.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "servicecatalog"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptPortfolioShare_593774 = ref object of OpenApiRestCall_593437
proc url_AcceptPortfolioShare_593776(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptPortfolioShare_593775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Accepts an offer to share the specified portfolio.
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AcceptPortfolioShare_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AcceptPortfolioShare_593774; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_593774(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_593775, base: "/",
    url: url_AcceptPortfolioShare_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_594043 = ref object of OpenApiRestCall_593437
proc url_AssociateBudgetWithResource_594045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateBudgetWithResource_594044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified budget with the specified resource.
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_AssociateBudgetWithResource_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_AssociateBudgetWithResource_594043; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_594043(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_594044, base: "/",
    url: url_AssociateBudgetWithResource_594045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_594058 = ref object of OpenApiRestCall_593437
proc url_AssociatePrincipalWithPortfolio_594060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_594059(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified principal ARN with the specified portfolio.
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_AssociatePrincipalWithPortfolio_594058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_AssociatePrincipalWithPortfolio_594058; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_594058(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_594059, base: "/",
    url: url_AssociatePrincipalWithPortfolio_594060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_594073 = ref object of OpenApiRestCall_593437
proc url_AssociateProductWithPortfolio_594075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateProductWithPortfolio_594074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified product with the specified portfolio.
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_AssociateProductWithPortfolio_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_AssociateProductWithPortfolio_594073; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_594073(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_594074, base: "/",
    url: url_AssociateProductWithPortfolio_594075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_594088 = ref object of OpenApiRestCall_593437
proc url_AssociateServiceActionWithProvisioningArtifact_594090(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_594089(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Associates a self-service action with a provisioning artifact.
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_AssociateServiceActionWithProvisioningArtifact_594088;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_AssociateServiceActionWithProvisioningArtifact_594088;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_594088(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_594089,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_594090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_594103 = ref object of OpenApiRestCall_593437
proc url_AssociateTagOptionWithResource_594105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateTagOptionWithResource_594104(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associate the specified TagOption with the specified portfolio or product.
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_AssociateTagOptionWithResource_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_AssociateTagOptionWithResource_594103; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_594103(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_594104, base: "/",
    url: url_AssociateTagOptionWithResource_594105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_594118 = ref object of OpenApiRestCall_593437
proc url_BatchAssociateServiceActionWithProvisioningArtifact_594120(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_594119(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Associates multiple self-service actions with provisioning artifacts.
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_BatchAssociateServiceActionWithProvisioningArtifact_594118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_BatchAssociateServiceActionWithProvisioningArtifact_594118;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_594118(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_594119,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_594133 = ref object of OpenApiRestCall_593437
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_594135(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_594134(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_BatchDisassociateServiceActionFromProvisioningArtifact_594133;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_BatchDisassociateServiceActionFromProvisioningArtifact_594133;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_594133(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_594134,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_594135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_594148 = ref object of OpenApiRestCall_593437
proc url_CopyProduct_594150(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CopyProduct_594149(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CopyProduct_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CopyProduct_594148; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var copyProduct* = Call_CopyProduct_594148(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_594149,
                                        base: "/", url: url_CopyProduct_594150,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_594163 = ref object of OpenApiRestCall_593437
proc url_CreateConstraint_594165(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConstraint_594164(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a constraint.
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_CreateConstraint_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_CreateConstraint_594163; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var createConstraint* = Call_CreateConstraint_594163(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_594164, base: "/",
    url: url_CreateConstraint_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_594178 = ref object of OpenApiRestCall_593437
proc url_CreatePortfolio_594180(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePortfolio_594179(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a portfolio.
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_CreatePortfolio_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_CreatePortfolio_594178; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var createPortfolio* = Call_CreatePortfolio_594178(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_594179, base: "/", url: url_CreatePortfolio_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_594193 = ref object of OpenApiRestCall_593437
proc url_CreatePortfolioShare_594195(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePortfolioShare_594194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_CreatePortfolioShare_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_CreatePortfolioShare_594193; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var createPortfolioShare* = Call_CreatePortfolioShare_594193(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_594194, base: "/",
    url: url_CreatePortfolioShare_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_594208 = ref object of OpenApiRestCall_593437
proc url_CreateProduct_594210(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProduct_594209(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a product.
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_CreateProduct_594208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_CreateProduct_594208; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var createProduct* = Call_CreateProduct_594208(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_594209, base: "/", url: url_CreateProduct_594210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_594223 = ref object of OpenApiRestCall_593437
proc url_CreateProvisionedProductPlan_594225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProvisionedProductPlan_594224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_CreateProvisionedProductPlan_594223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_CreateProvisionedProductPlan_594223; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_594223(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_594224, base: "/",
    url: url_CreateProvisionedProductPlan_594225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_594238 = ref object of OpenApiRestCall_593437
proc url_CreateProvisioningArtifact_594240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateProvisioningArtifact_594239(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
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
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_CreateProvisioningArtifact_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_CreateProvisioningArtifact_594238; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_594238(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_594239, base: "/",
    url: url_CreateProvisioningArtifact_594240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_594253 = ref object of OpenApiRestCall_593437
proc url_CreateServiceAction_594255(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateServiceAction_594254(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a self-service action.
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
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_CreateServiceAction_594253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_CreateServiceAction_594253; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var createServiceAction* = Call_CreateServiceAction_594253(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_594254, base: "/",
    url: url_CreateServiceAction_594255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_594268 = ref object of OpenApiRestCall_593437
proc url_CreateTagOption_594270(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTagOption_594269(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a TagOption.
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_CreateTagOption_594268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_CreateTagOption_594268; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var createTagOption* = Call_CreateTagOption_594268(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_594269, base: "/", url: url_CreateTagOption_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_594283 = ref object of OpenApiRestCall_593437
proc url_DeleteConstraint_594285(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConstraint_594284(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the specified constraint.
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_DeleteConstraint_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_DeleteConstraint_594283; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var deleteConstraint* = Call_DeleteConstraint_594283(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_594284, base: "/",
    url: url_DeleteConstraint_594285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_594298 = ref object of OpenApiRestCall_593437
proc url_DeletePortfolio_594300(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePortfolio_594299(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
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
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeletePortfolio_594298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeletePortfolio_594298; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var deletePortfolio* = Call_DeletePortfolio_594298(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_594299, base: "/", url: url_DeletePortfolio_594300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_594313 = ref object of OpenApiRestCall_593437
proc url_DeletePortfolioShare_594315(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePortfolioShare_594314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
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
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_DeletePortfolioShare_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_DeletePortfolioShare_594313; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var deletePortfolioShare* = Call_DeletePortfolioShare_594313(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_594314, base: "/",
    url: url_DeletePortfolioShare_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_594328 = ref object of OpenApiRestCall_593437
proc url_DeleteProduct_594330(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProduct_594329(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
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
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_DeleteProduct_594328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_DeleteProduct_594328; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var deleteProduct* = Call_DeleteProduct_594328(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_594329, base: "/", url: url_DeleteProduct_594330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_594343 = ref object of OpenApiRestCall_593437
proc url_DeleteProvisionedProductPlan_594345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProvisionedProductPlan_594344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified plan.
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
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_DeleteProvisionedProductPlan_594343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_DeleteProvisionedProductPlan_594343; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_594357 = newJObject()
  if body != nil:
    body_594357 = body
  result = call_594356.call(nil, nil, nil, nil, body_594357)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_594343(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_594344, base: "/",
    url: url_DeleteProvisionedProductPlan_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_594358 = ref object of OpenApiRestCall_593437
proc url_DeleteProvisioningArtifact_594360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteProvisioningArtifact_594359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
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
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_DeleteProvisioningArtifact_594358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_DeleteProvisioningArtifact_594358; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_594372 = newJObject()
  if body != nil:
    body_594372 = body
  result = call_594371.call(nil, nil, nil, nil, body_594372)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_594358(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_594359, base: "/",
    url: url_DeleteProvisioningArtifact_594360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_594373 = ref object of OpenApiRestCall_593437
proc url_DeleteServiceAction_594375(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteServiceAction_594374(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a self-service action.
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
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_DeleteServiceAction_594373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_DeleteServiceAction_594373; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var deleteServiceAction* = Call_DeleteServiceAction_594373(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_594374, base: "/",
    url: url_DeleteServiceAction_594375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_594388 = ref object of OpenApiRestCall_593437
proc url_DeleteTagOption_594390(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTagOption_594389(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
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
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Security-Token")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Security-Token", valid_594392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594393 = header.getOrDefault("X-Amz-Target")
  valid_594393 = validateParameter(valid_594393, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_594393 != nil:
    section.add "X-Amz-Target", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594400: Call_DeleteTagOption_594388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_594400.validator(path, query, header, formData, body)
  let scheme = call_594400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594400.url(scheme.get, call_594400.host, call_594400.base,
                         call_594400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594400, url, valid)

proc call*(call_594401: Call_DeleteTagOption_594388; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_594402 = newJObject()
  if body != nil:
    body_594402 = body
  result = call_594401.call(nil, nil, nil, nil, body_594402)

var deleteTagOption* = Call_DeleteTagOption_594388(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_594389, base: "/", url: url_DeleteTagOption_594390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_594403 = ref object of OpenApiRestCall_593437
proc url_DescribeConstraint_594405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConstraint_594404(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the specified constraint.
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
  var valid_594406 = header.getOrDefault("X-Amz-Date")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Date", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594408 = header.getOrDefault("X-Amz-Target")
  valid_594408 = validateParameter(valid_594408, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_594408 != nil:
    section.add "X-Amz-Target", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Algorithm")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Algorithm", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Credential")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Credential", valid_594413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594415: Call_DescribeConstraint_594403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_594415.validator(path, query, header, formData, body)
  let scheme = call_594415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594415.url(scheme.get, call_594415.host, call_594415.base,
                         call_594415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594415, url, valid)

proc call*(call_594416: Call_DescribeConstraint_594403; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_594417 = newJObject()
  if body != nil:
    body_594417 = body
  result = call_594416.call(nil, nil, nil, nil, body_594417)

var describeConstraint* = Call_DescribeConstraint_594403(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_594404, base: "/",
    url: url_DescribeConstraint_594405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_594418 = ref object of OpenApiRestCall_593437
proc url_DescribeCopyProductStatus_594420(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCopyProductStatus_594419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the status of the specified copy product operation.
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
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Security-Token")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Security-Token", valid_594422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594423 = header.getOrDefault("X-Amz-Target")
  valid_594423 = validateParameter(valid_594423, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_594423 != nil:
    section.add "X-Amz-Target", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Algorithm")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Algorithm", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Credential")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Credential", valid_594428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594430: Call_DescribeCopyProductStatus_594418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_594430.validator(path, query, header, formData, body)
  let scheme = call_594430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594430.url(scheme.get, call_594430.host, call_594430.base,
                         call_594430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594430, url, valid)

proc call*(call_594431: Call_DescribeCopyProductStatus_594418; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_594432 = newJObject()
  if body != nil:
    body_594432 = body
  result = call_594431.call(nil, nil, nil, nil, body_594432)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_594418(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_594419, base: "/",
    url: url_DescribeCopyProductStatus_594420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_594433 = ref object of OpenApiRestCall_593437
proc url_DescribePortfolio_594435(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePortfolio_594434(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets information about the specified portfolio.
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
  var valid_594436 = header.getOrDefault("X-Amz-Date")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Date", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Security-Token")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Security-Token", valid_594437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594438 = header.getOrDefault("X-Amz-Target")
  valid_594438 = validateParameter(valid_594438, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_594438 != nil:
    section.add "X-Amz-Target", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_DescribePortfolio_594433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_DescribePortfolio_594433; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_594447 = newJObject()
  if body != nil:
    body_594447 = body
  result = call_594446.call(nil, nil, nil, nil, body_594447)

var describePortfolio* = Call_DescribePortfolio_594433(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_594434, base: "/",
    url: url_DescribePortfolio_594435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_594448 = ref object of OpenApiRestCall_593437
proc url_DescribePortfolioShareStatus_594450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePortfolioShareStatus_594449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
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
  var valid_594451 = header.getOrDefault("X-Amz-Date")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Date", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Security-Token")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Security-Token", valid_594452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594453 = header.getOrDefault("X-Amz-Target")
  valid_594453 = validateParameter(valid_594453, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_594453 != nil:
    section.add "X-Amz-Target", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Content-Sha256", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Signature")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Signature", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_DescribePortfolioShareStatus_594448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_DescribePortfolioShareStatus_594448; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_594462 = newJObject()
  if body != nil:
    body_594462 = body
  result = call_594461.call(nil, nil, nil, nil, body_594462)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_594448(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_594449, base: "/",
    url: url_DescribePortfolioShareStatus_594450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_594463 = ref object of OpenApiRestCall_593437
proc url_DescribeProduct_594465(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProduct_594464(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets information about the specified product.
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
  var valid_594466 = header.getOrDefault("X-Amz-Date")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Date", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594468 = header.getOrDefault("X-Amz-Target")
  valid_594468 = validateParameter(valid_594468, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_594468 != nil:
    section.add "X-Amz-Target", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-SignedHeaders", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_DescribeProduct_594463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_DescribeProduct_594463; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_594477 = newJObject()
  if body != nil:
    body_594477 = body
  result = call_594476.call(nil, nil, nil, nil, body_594477)

var describeProduct* = Call_DescribeProduct_594463(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_594464, base: "/", url: url_DescribeProduct_594465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_594478 = ref object of OpenApiRestCall_593437
proc url_DescribeProductAsAdmin_594480(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProductAsAdmin_594479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the specified product. This operation is run with administrator access.
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
  var valid_594481 = header.getOrDefault("X-Amz-Date")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Date", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Security-Token")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Security-Token", valid_594482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594483 = header.getOrDefault("X-Amz-Target")
  valid_594483 = validateParameter(valid_594483, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_594483 != nil:
    section.add "X-Amz-Target", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Content-Sha256", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Algorithm")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Algorithm", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Signature")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Signature", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-SignedHeaders", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Credential")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Credential", valid_594488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_DescribeProductAsAdmin_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_DescribeProductAsAdmin_594478; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_594492 = newJObject()
  if body != nil:
    body_594492 = body
  result = call_594491.call(nil, nil, nil, nil, body_594492)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_594478(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_594479, base: "/",
    url: url_DescribeProductAsAdmin_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_594493 = ref object of OpenApiRestCall_593437
proc url_DescribeProductView_594495(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProductView_594494(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the specified product.
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
  var valid_594496 = header.getOrDefault("X-Amz-Date")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Date", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Security-Token")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Security-Token", valid_594497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594498 = header.getOrDefault("X-Amz-Target")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_594498 != nil:
    section.add "X-Amz-Target", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Algorithm")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Algorithm", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Credential")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Credential", valid_594503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594505: Call_DescribeProductView_594493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_594505.validator(path, query, header, formData, body)
  let scheme = call_594505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594505.url(scheme.get, call_594505.host, call_594505.base,
                         call_594505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594505, url, valid)

proc call*(call_594506: Call_DescribeProductView_594493; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_594507 = newJObject()
  if body != nil:
    body_594507 = body
  result = call_594506.call(nil, nil, nil, nil, body_594507)

var describeProductView* = Call_DescribeProductView_594493(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_594494, base: "/",
    url: url_DescribeProductView_594495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_594508 = ref object of OpenApiRestCall_593437
proc url_DescribeProvisionedProduct_594510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisionedProduct_594509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the specified provisioned product.
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
  var valid_594511 = header.getOrDefault("X-Amz-Date")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Date", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Security-Token")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Security-Token", valid_594512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594513 = header.getOrDefault("X-Amz-Target")
  valid_594513 = validateParameter(valid_594513, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_594513 != nil:
    section.add "X-Amz-Target", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Content-Sha256", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Algorithm")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Algorithm", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-SignedHeaders", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Credential")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Credential", valid_594518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594520: Call_DescribeProvisionedProduct_594508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_594520.validator(path, query, header, formData, body)
  let scheme = call_594520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594520.url(scheme.get, call_594520.host, call_594520.base,
                         call_594520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594520, url, valid)

proc call*(call_594521: Call_DescribeProvisionedProduct_594508; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_594522 = newJObject()
  if body != nil:
    body_594522 = body
  result = call_594521.call(nil, nil, nil, nil, body_594522)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_594508(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_594509, base: "/",
    url: url_DescribeProvisionedProduct_594510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_594523 = ref object of OpenApiRestCall_593437
proc url_DescribeProvisionedProductPlan_594525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisionedProductPlan_594524(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource changes for the specified plan.
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
  var valid_594526 = header.getOrDefault("X-Amz-Date")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Date", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Security-Token")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Security-Token", valid_594527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594528 = header.getOrDefault("X-Amz-Target")
  valid_594528 = validateParameter(valid_594528, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_594528 != nil:
    section.add "X-Amz-Target", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Content-Sha256", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Algorithm")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Algorithm", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-SignedHeaders", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Credential")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Credential", valid_594533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594535: Call_DescribeProvisionedProductPlan_594523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_594535.validator(path, query, header, formData, body)
  let scheme = call_594535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594535.url(scheme.get, call_594535.host, call_594535.base,
                         call_594535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594535, url, valid)

proc call*(call_594536: Call_DescribeProvisionedProductPlan_594523; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_594537 = newJObject()
  if body != nil:
    body_594537 = body
  result = call_594536.call(nil, nil, nil, nil, body_594537)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_594523(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_594524, base: "/",
    url: url_DescribeProvisionedProductPlan_594525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_594538 = ref object of OpenApiRestCall_593437
proc url_DescribeProvisioningArtifact_594540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisioningArtifact_594539(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
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
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Security-Token")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Security-Token", valid_594542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594543 = header.getOrDefault("X-Amz-Target")
  valid_594543 = validateParameter(valid_594543, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_594543 != nil:
    section.add "X-Amz-Target", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Content-Sha256", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Algorithm")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Algorithm", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-SignedHeaders", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_DescribeProvisioningArtifact_594538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_DescribeProvisioningArtifact_594538; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_594552 = newJObject()
  if body != nil:
    body_594552 = body
  result = call_594551.call(nil, nil, nil, nil, body_594552)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_594538(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_594539, base: "/",
    url: url_DescribeProvisioningArtifact_594540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_594553 = ref object of OpenApiRestCall_593437
proc url_DescribeProvisioningParameters_594555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeProvisioningParameters_594554(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
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
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594558 = header.getOrDefault("X-Amz-Target")
  valid_594558 = validateParameter(valid_594558, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_594558 != nil:
    section.add "X-Amz-Target", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Content-Sha256", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Algorithm")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Algorithm", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-SignedHeaders", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594565: Call_DescribeProvisioningParameters_594553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_594565.validator(path, query, header, formData, body)
  let scheme = call_594565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594565.url(scheme.get, call_594565.host, call_594565.base,
                         call_594565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594565, url, valid)

proc call*(call_594566: Call_DescribeProvisioningParameters_594553; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_594567 = newJObject()
  if body != nil:
    body_594567 = body
  result = call_594566.call(nil, nil, nil, nil, body_594567)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_594553(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_594554, base: "/",
    url: url_DescribeProvisioningParameters_594555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_594568 = ref object of OpenApiRestCall_593437
proc url_DescribeRecord_594570(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRecord_594569(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
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
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594573 = header.getOrDefault("X-Amz-Target")
  valid_594573 = validateParameter(valid_594573, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_594573 != nil:
    section.add "X-Amz-Target", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Content-Sha256", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Algorithm")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Algorithm", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-SignedHeaders", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Credential")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Credential", valid_594578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_DescribeRecord_594568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_DescribeRecord_594568; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_594582 = newJObject()
  if body != nil:
    body_594582 = body
  result = call_594581.call(nil, nil, nil, nil, body_594582)

var describeRecord* = Call_DescribeRecord_594568(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_594569, base: "/", url: url_DescribeRecord_594570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_594583 = ref object of OpenApiRestCall_593437
proc url_DescribeServiceAction_594585(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServiceAction_594584(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a self-service action.
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
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594588 = header.getOrDefault("X-Amz-Target")
  valid_594588 = validateParameter(valid_594588, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_594588 != nil:
    section.add "X-Amz-Target", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Content-Sha256", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-SignedHeaders", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Credential")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Credential", valid_594593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_DescribeServiceAction_594583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_DescribeServiceAction_594583; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_594597 = newJObject()
  if body != nil:
    body_594597 = body
  result = call_594596.call(nil, nil, nil, nil, body_594597)

var describeServiceAction* = Call_DescribeServiceAction_594583(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_594584, base: "/",
    url: url_DescribeServiceAction_594585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_594598 = ref object of OpenApiRestCall_593437
proc url_DescribeServiceActionExecutionParameters_594600(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_594599(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Security-Token")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Security-Token", valid_594602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594603 = header.getOrDefault("X-Amz-Target")
  valid_594603 = validateParameter(valid_594603, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_594603 != nil:
    section.add "X-Amz-Target", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Content-Sha256", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-SignedHeaders", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Credential")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Credential", valid_594608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_DescribeServiceActionExecutionParameters_594598;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_DescribeServiceActionExecutionParameters_594598;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_594612 = newJObject()
  if body != nil:
    body_594612 = body
  result = call_594611.call(nil, nil, nil, nil, body_594612)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_594598(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_594599,
    base: "/", url: url_DescribeServiceActionExecutionParameters_594600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_594613 = ref object of OpenApiRestCall_593437
proc url_DescribeTagOption_594615(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTagOption_594614(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Gets information about the specified TagOption.
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
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Security-Token")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Security-Token", valid_594617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594618 = header.getOrDefault("X-Amz-Target")
  valid_594618 = validateParameter(valid_594618, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_594618 != nil:
    section.add "X-Amz-Target", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Content-Sha256", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Algorithm")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Algorithm", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-SignedHeaders", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Credential")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Credential", valid_594623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_DescribeTagOption_594613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_DescribeTagOption_594613; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_594627 = newJObject()
  if body != nil:
    body_594627 = body
  result = call_594626.call(nil, nil, nil, nil, body_594627)

var describeTagOption* = Call_DescribeTagOption_594613(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_594614, base: "/",
    url: url_DescribeTagOption_594615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_594628 = ref object of OpenApiRestCall_593437
proc url_DisableAWSOrganizationsAccess_594630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisableAWSOrganizationsAccess_594629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
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
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Security-Token")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Security-Token", valid_594632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594633 = header.getOrDefault("X-Amz-Target")
  valid_594633 = validateParameter(valid_594633, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_594633 != nil:
    section.add "X-Amz-Target", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Content-Sha256", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Algorithm")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Algorithm", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Signature")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Signature", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-SignedHeaders", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Credential")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Credential", valid_594638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_DisableAWSOrganizationsAccess_594628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_DisableAWSOrganizationsAccess_594628; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_594642 = newJObject()
  if body != nil:
    body_594642 = body
  result = call_594641.call(nil, nil, nil, nil, body_594642)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_594628(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_594629, base: "/",
    url: url_DisableAWSOrganizationsAccess_594630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_594643 = ref object of OpenApiRestCall_593437
proc url_DisassociateBudgetFromResource_594645(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateBudgetFromResource_594644(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified budget from the specified resource.
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
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Security-Token")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Security-Token", valid_594647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594648 = header.getOrDefault("X-Amz-Target")
  valid_594648 = validateParameter(valid_594648, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_594648 != nil:
    section.add "X-Amz-Target", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-SignedHeaders", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Credential")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Credential", valid_594653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_DisassociateBudgetFromResource_594643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_DisassociateBudgetFromResource_594643; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_594657 = newJObject()
  if body != nil:
    body_594657 = body
  result = call_594656.call(nil, nil, nil, nil, body_594657)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_594643(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_594644, base: "/",
    url: url_DisassociateBudgetFromResource_594645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_594658 = ref object of OpenApiRestCall_593437
proc url_DisassociatePrincipalFromPortfolio_594660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_594659(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
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
  var valid_594661 = header.getOrDefault("X-Amz-Date")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Date", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594663 = header.getOrDefault("X-Amz-Target")
  valid_594663 = validateParameter(valid_594663, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_594663 != nil:
    section.add "X-Amz-Target", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-SignedHeaders", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Credential")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Credential", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594670: Call_DisassociatePrincipalFromPortfolio_594658;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_594670.validator(path, query, header, formData, body)
  let scheme = call_594670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594670.url(scheme.get, call_594670.host, call_594670.base,
                         call_594670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594670, url, valid)

proc call*(call_594671: Call_DisassociatePrincipalFromPortfolio_594658;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_594672 = newJObject()
  if body != nil:
    body_594672 = body
  result = call_594671.call(nil, nil, nil, nil, body_594672)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_594658(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_594659, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_594660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_594673 = ref object of OpenApiRestCall_593437
proc url_DisassociateProductFromPortfolio_594675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateProductFromPortfolio_594674(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified product from the specified portfolio. 
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
  var valid_594676 = header.getOrDefault("X-Amz-Date")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Date", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Security-Token")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Security-Token", valid_594677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594678 = header.getOrDefault("X-Amz-Target")
  valid_594678 = validateParameter(valid_594678, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_594678 != nil:
    section.add "X-Amz-Target", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594685: Call_DisassociateProductFromPortfolio_594673;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_594685.validator(path, query, header, formData, body)
  let scheme = call_594685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594685.url(scheme.get, call_594685.host, call_594685.base,
                         call_594685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594685, url, valid)

proc call*(call_594686: Call_DisassociateProductFromPortfolio_594673;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_594687 = newJObject()
  if body != nil:
    body_594687 = body
  result = call_594686.call(nil, nil, nil, nil, body_594687)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_594673(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_594674, base: "/",
    url: url_DisassociateProductFromPortfolio_594675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_594688 = ref object of OpenApiRestCall_593437
proc url_DisassociateServiceActionFromProvisioningArtifact_594690(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_594689(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
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
  var valid_594691 = header.getOrDefault("X-Amz-Date")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Date", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Security-Token")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Security-Token", valid_594692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594693 = header.getOrDefault("X-Amz-Target")
  valid_594693 = validateParameter(valid_594693, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_594693 != nil:
    section.add "X-Amz-Target", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Content-Sha256", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Algorithm")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Algorithm", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Signature")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Signature", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-SignedHeaders", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Credential")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Credential", valid_594698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_DisassociateServiceActionFromProvisioningArtifact_594688;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_DisassociateServiceActionFromProvisioningArtifact_594688;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_594702 = newJObject()
  if body != nil:
    body_594702 = body
  result = call_594701.call(nil, nil, nil, nil, body_594702)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_594688(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_594689,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_594690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_594703 = ref object of OpenApiRestCall_593437
proc url_DisassociateTagOptionFromResource_594705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateTagOptionFromResource_594704(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the specified TagOption from the specified resource.
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
  var valid_594706 = header.getOrDefault("X-Amz-Date")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Date", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Security-Token")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Security-Token", valid_594707
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594708 = header.getOrDefault("X-Amz-Target")
  valid_594708 = validateParameter(valid_594708, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_594708 != nil:
    section.add "X-Amz-Target", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Content-Sha256", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Algorithm")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Algorithm", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Signature")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Signature", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-SignedHeaders", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Credential")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Credential", valid_594713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594715: Call_DisassociateTagOptionFromResource_594703;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_594715.validator(path, query, header, formData, body)
  let scheme = call_594715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594715.url(scheme.get, call_594715.host, call_594715.base,
                         call_594715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594715, url, valid)

proc call*(call_594716: Call_DisassociateTagOptionFromResource_594703;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_594717 = newJObject()
  if body != nil:
    body_594717 = body
  result = call_594716.call(nil, nil, nil, nil, body_594717)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_594703(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_594704, base: "/",
    url: url_DisassociateTagOptionFromResource_594705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_594718 = ref object of OpenApiRestCall_593437
proc url_EnableAWSOrganizationsAccess_594720(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_EnableAWSOrganizationsAccess_594719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
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
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Security-Token")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Security-Token", valid_594722
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594723 = header.getOrDefault("X-Amz-Target")
  valid_594723 = validateParameter(valid_594723, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_594723 != nil:
    section.add "X-Amz-Target", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Content-Sha256", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Algorithm")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Algorithm", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Signature")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Signature", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-SignedHeaders", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Credential")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Credential", valid_594728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594730: Call_EnableAWSOrganizationsAccess_594718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_594730.validator(path, query, header, formData, body)
  let scheme = call_594730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594730.url(scheme.get, call_594730.host, call_594730.base,
                         call_594730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594730, url, valid)

proc call*(call_594731: Call_EnableAWSOrganizationsAccess_594718; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_594732 = newJObject()
  if body != nil:
    body_594732 = body
  result = call_594731.call(nil, nil, nil, nil, body_594732)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_594718(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_594719, base: "/",
    url: url_EnableAWSOrganizationsAccess_594720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_594733 = ref object of OpenApiRestCall_593437
proc url_ExecuteProvisionedProductPlan_594735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteProvisionedProductPlan_594734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
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
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594738 = header.getOrDefault("X-Amz-Target")
  valid_594738 = validateParameter(valid_594738, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_594738 != nil:
    section.add "X-Amz-Target", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Content-Sha256", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Algorithm")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Algorithm", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Signature")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Signature", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-SignedHeaders", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Credential")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Credential", valid_594743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594745: Call_ExecuteProvisionedProductPlan_594733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_594745.validator(path, query, header, formData, body)
  let scheme = call_594745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594745.url(scheme.get, call_594745.host, call_594745.base,
                         call_594745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594745, url, valid)

proc call*(call_594746: Call_ExecuteProvisionedProductPlan_594733; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_594747 = newJObject()
  if body != nil:
    body_594747 = body
  result = call_594746.call(nil, nil, nil, nil, body_594747)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_594733(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_594734, base: "/",
    url: url_ExecuteProvisionedProductPlan_594735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_594748 = ref object of OpenApiRestCall_593437
proc url_ExecuteProvisionedProductServiceAction_594750(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_594749(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Executes a self-service action against a provisioned product.
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
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594753 = header.getOrDefault("X-Amz-Target")
  valid_594753 = validateParameter(valid_594753, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_594753 != nil:
    section.add "X-Amz-Target", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Content-Sha256", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Algorithm")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Algorithm", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Signature")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Signature", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-SignedHeaders", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Credential")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Credential", valid_594758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594760: Call_ExecuteProvisionedProductServiceAction_594748;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_594760.validator(path, query, header, formData, body)
  let scheme = call_594760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594760.url(scheme.get, call_594760.host, call_594760.base,
                         call_594760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594760, url, valid)

proc call*(call_594761: Call_ExecuteProvisionedProductServiceAction_594748;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_594762 = newJObject()
  if body != nil:
    body_594762 = body
  result = call_594761.call(nil, nil, nil, nil, body_594762)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_594748(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_594749, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_594750,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_594763 = ref object of OpenApiRestCall_593437
proc url_GetAWSOrganizationsAccessStatus_594765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_594764(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
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
  var valid_594766 = header.getOrDefault("X-Amz-Date")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Date", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Security-Token")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Security-Token", valid_594767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594768 = header.getOrDefault("X-Amz-Target")
  valid_594768 = validateParameter(valid_594768, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_594768 != nil:
    section.add "X-Amz-Target", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Content-Sha256", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Algorithm")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Algorithm", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Signature")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Signature", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-SignedHeaders", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Credential")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Credential", valid_594773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594775: Call_GetAWSOrganizationsAccessStatus_594763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_594775.validator(path, query, header, formData, body)
  let scheme = call_594775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594775.url(scheme.get, call_594775.host, call_594775.base,
                         call_594775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594775, url, valid)

proc call*(call_594776: Call_GetAWSOrganizationsAccessStatus_594763; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_594777 = newJObject()
  if body != nil:
    body_594777 = body
  result = call_594776.call(nil, nil, nil, nil, body_594777)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_594763(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_594764, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_594765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_594778 = ref object of OpenApiRestCall_593437
proc url_ListAcceptedPortfolioShares_594780(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAcceptedPortfolioShares_594779(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594781 = query.getOrDefault("PageSize")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "PageSize", valid_594781
  var valid_594782 = query.getOrDefault("PageToken")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "PageToken", valid_594782
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
  var valid_594783 = header.getOrDefault("X-Amz-Date")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-Date", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Security-Token")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Security-Token", valid_594784
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594785 = header.getOrDefault("X-Amz-Target")
  valid_594785 = validateParameter(valid_594785, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_594785 != nil:
    section.add "X-Amz-Target", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Content-Sha256", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-Algorithm")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-Algorithm", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-Signature")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Signature", valid_594788
  var valid_594789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "X-Amz-SignedHeaders", valid_594789
  var valid_594790 = header.getOrDefault("X-Amz-Credential")
  valid_594790 = validateParameter(valid_594790, JString, required = false,
                                 default = nil)
  if valid_594790 != nil:
    section.add "X-Amz-Credential", valid_594790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594792: Call_ListAcceptedPortfolioShares_594778; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_594792.validator(path, query, header, formData, body)
  let scheme = call_594792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594792.url(scheme.get, call_594792.host, call_594792.base,
                         call_594792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594792, url, valid)

proc call*(call_594793: Call_ListAcceptedPortfolioShares_594778; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594794 = newJObject()
  var body_594795 = newJObject()
  add(query_594794, "PageSize", newJString(PageSize))
  add(query_594794, "PageToken", newJString(PageToken))
  if body != nil:
    body_594795 = body
  result = call_594793.call(nil, query_594794, nil, nil, body_594795)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_594778(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_594779, base: "/",
    url: url_ListAcceptedPortfolioShares_594780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_594797 = ref object of OpenApiRestCall_593437
proc url_ListBudgetsForResource_594799(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBudgetsForResource_594798(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the budgets associated to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594800 = query.getOrDefault("PageSize")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "PageSize", valid_594800
  var valid_594801 = query.getOrDefault("PageToken")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "PageToken", valid_594801
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
  var valid_594802 = header.getOrDefault("X-Amz-Date")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-Date", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Security-Token")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Security-Token", valid_594803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594804 = header.getOrDefault("X-Amz-Target")
  valid_594804 = validateParameter(valid_594804, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_594804 != nil:
    section.add "X-Amz-Target", valid_594804
  var valid_594805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594805 = validateParameter(valid_594805, JString, required = false,
                                 default = nil)
  if valid_594805 != nil:
    section.add "X-Amz-Content-Sha256", valid_594805
  var valid_594806 = header.getOrDefault("X-Amz-Algorithm")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Algorithm", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Signature")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Signature", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-SignedHeaders", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Credential")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Credential", valid_594809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594811: Call_ListBudgetsForResource_594797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_594811.validator(path, query, header, formData, body)
  let scheme = call_594811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594811.url(scheme.get, call_594811.host, call_594811.base,
                         call_594811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594811, url, valid)

proc call*(call_594812: Call_ListBudgetsForResource_594797; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594813 = newJObject()
  var body_594814 = newJObject()
  add(query_594813, "PageSize", newJString(PageSize))
  add(query_594813, "PageToken", newJString(PageToken))
  if body != nil:
    body_594814 = body
  result = call_594812.call(nil, query_594813, nil, nil, body_594814)

var listBudgetsForResource* = Call_ListBudgetsForResource_594797(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_594798, base: "/",
    url: url_ListBudgetsForResource_594799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_594815 = ref object of OpenApiRestCall_593437
proc url_ListConstraintsForPortfolio_594817(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConstraintsForPortfolio_594816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594818 = query.getOrDefault("PageSize")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "PageSize", valid_594818
  var valid_594819 = query.getOrDefault("PageToken")
  valid_594819 = validateParameter(valid_594819, JString, required = false,
                                 default = nil)
  if valid_594819 != nil:
    section.add "PageToken", valid_594819
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
  var valid_594820 = header.getOrDefault("X-Amz-Date")
  valid_594820 = validateParameter(valid_594820, JString, required = false,
                                 default = nil)
  if valid_594820 != nil:
    section.add "X-Amz-Date", valid_594820
  var valid_594821 = header.getOrDefault("X-Amz-Security-Token")
  valid_594821 = validateParameter(valid_594821, JString, required = false,
                                 default = nil)
  if valid_594821 != nil:
    section.add "X-Amz-Security-Token", valid_594821
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594822 = header.getOrDefault("X-Amz-Target")
  valid_594822 = validateParameter(valid_594822, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_594822 != nil:
    section.add "X-Amz-Target", valid_594822
  var valid_594823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "X-Amz-Content-Sha256", valid_594823
  var valid_594824 = header.getOrDefault("X-Amz-Algorithm")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "X-Amz-Algorithm", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Signature")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Signature", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-SignedHeaders", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Credential")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Credential", valid_594827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594829: Call_ListConstraintsForPortfolio_594815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_594829.validator(path, query, header, formData, body)
  let scheme = call_594829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594829.url(scheme.get, call_594829.host, call_594829.base,
                         call_594829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594829, url, valid)

proc call*(call_594830: Call_ListConstraintsForPortfolio_594815; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594831 = newJObject()
  var body_594832 = newJObject()
  add(query_594831, "PageSize", newJString(PageSize))
  add(query_594831, "PageToken", newJString(PageToken))
  if body != nil:
    body_594832 = body
  result = call_594830.call(nil, query_594831, nil, nil, body_594832)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_594815(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_594816, base: "/",
    url: url_ListConstraintsForPortfolio_594817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_594833 = ref object of OpenApiRestCall_593437
proc url_ListLaunchPaths_594835(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLaunchPaths_594834(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594836 = query.getOrDefault("PageSize")
  valid_594836 = validateParameter(valid_594836, JString, required = false,
                                 default = nil)
  if valid_594836 != nil:
    section.add "PageSize", valid_594836
  var valid_594837 = query.getOrDefault("PageToken")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "PageToken", valid_594837
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
  var valid_594838 = header.getOrDefault("X-Amz-Date")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Date", valid_594838
  var valid_594839 = header.getOrDefault("X-Amz-Security-Token")
  valid_594839 = validateParameter(valid_594839, JString, required = false,
                                 default = nil)
  if valid_594839 != nil:
    section.add "X-Amz-Security-Token", valid_594839
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594840 = header.getOrDefault("X-Amz-Target")
  valid_594840 = validateParameter(valid_594840, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_594840 != nil:
    section.add "X-Amz-Target", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Content-Sha256", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Algorithm")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Algorithm", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-Signature")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Signature", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-SignedHeaders", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Credential")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Credential", valid_594845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594847: Call_ListLaunchPaths_594833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_594847.validator(path, query, header, formData, body)
  let scheme = call_594847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594847.url(scheme.get, call_594847.host, call_594847.base,
                         call_594847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594847, url, valid)

proc call*(call_594848: Call_ListLaunchPaths_594833; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594849 = newJObject()
  var body_594850 = newJObject()
  add(query_594849, "PageSize", newJString(PageSize))
  add(query_594849, "PageToken", newJString(PageToken))
  if body != nil:
    body_594850 = body
  result = call_594848.call(nil, query_594849, nil, nil, body_594850)

var listLaunchPaths* = Call_ListLaunchPaths_594833(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_594834, base: "/", url: url_ListLaunchPaths_594835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_594851 = ref object of OpenApiRestCall_593437
proc url_ListOrganizationPortfolioAccess_594853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOrganizationPortfolioAccess_594852(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594854 = query.getOrDefault("PageSize")
  valid_594854 = validateParameter(valid_594854, JString, required = false,
                                 default = nil)
  if valid_594854 != nil:
    section.add "PageSize", valid_594854
  var valid_594855 = query.getOrDefault("PageToken")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "PageToken", valid_594855
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
  var valid_594856 = header.getOrDefault("X-Amz-Date")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Date", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594858 = header.getOrDefault("X-Amz-Target")
  valid_594858 = validateParameter(valid_594858, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_594858 != nil:
    section.add "X-Amz-Target", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Content-Sha256", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Algorithm")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Algorithm", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Signature")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Signature", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-SignedHeaders", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Credential")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Credential", valid_594863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594865: Call_ListOrganizationPortfolioAccess_594851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_594865.validator(path, query, header, formData, body)
  let scheme = call_594865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594865.url(scheme.get, call_594865.host, call_594865.base,
                         call_594865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594865, url, valid)

proc call*(call_594866: Call_ListOrganizationPortfolioAccess_594851;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594867 = newJObject()
  var body_594868 = newJObject()
  add(query_594867, "PageSize", newJString(PageSize))
  add(query_594867, "PageToken", newJString(PageToken))
  if body != nil:
    body_594868 = body
  result = call_594866.call(nil, query_594867, nil, nil, body_594868)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_594851(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_594852, base: "/",
    url: url_ListOrganizationPortfolioAccess_594853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_594869 = ref object of OpenApiRestCall_593437
proc url_ListPortfolioAccess_594871(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfolioAccess_594870(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the account IDs that have access to the specified portfolio.
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
  var valid_594872 = header.getOrDefault("X-Amz-Date")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Date", valid_594872
  var valid_594873 = header.getOrDefault("X-Amz-Security-Token")
  valid_594873 = validateParameter(valid_594873, JString, required = false,
                                 default = nil)
  if valid_594873 != nil:
    section.add "X-Amz-Security-Token", valid_594873
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594874 = header.getOrDefault("X-Amz-Target")
  valid_594874 = validateParameter(valid_594874, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_594874 != nil:
    section.add "X-Amz-Target", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Content-Sha256", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Algorithm")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Algorithm", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-Signature")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-Signature", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-SignedHeaders", valid_594878
  var valid_594879 = header.getOrDefault("X-Amz-Credential")
  valid_594879 = validateParameter(valid_594879, JString, required = false,
                                 default = nil)
  if valid_594879 != nil:
    section.add "X-Amz-Credential", valid_594879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594881: Call_ListPortfolioAccess_594869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_594881.validator(path, query, header, formData, body)
  let scheme = call_594881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594881.url(scheme.get, call_594881.host, call_594881.base,
                         call_594881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594881, url, valid)

proc call*(call_594882: Call_ListPortfolioAccess_594869; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_594883 = newJObject()
  if body != nil:
    body_594883 = body
  result = call_594882.call(nil, nil, nil, nil, body_594883)

var listPortfolioAccess* = Call_ListPortfolioAccess_594869(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_594870, base: "/",
    url: url_ListPortfolioAccess_594871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_594884 = ref object of OpenApiRestCall_593437
proc url_ListPortfolios_594886(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfolios_594885(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all portfolios in the catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594887 = query.getOrDefault("PageSize")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "PageSize", valid_594887
  var valid_594888 = query.getOrDefault("PageToken")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "PageToken", valid_594888
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
  var valid_594889 = header.getOrDefault("X-Amz-Date")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Date", valid_594889
  var valid_594890 = header.getOrDefault("X-Amz-Security-Token")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Security-Token", valid_594890
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594891 = header.getOrDefault("X-Amz-Target")
  valid_594891 = validateParameter(valid_594891, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_594891 != nil:
    section.add "X-Amz-Target", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-Content-Sha256", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Algorithm")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Algorithm", valid_594893
  var valid_594894 = header.getOrDefault("X-Amz-Signature")
  valid_594894 = validateParameter(valid_594894, JString, required = false,
                                 default = nil)
  if valid_594894 != nil:
    section.add "X-Amz-Signature", valid_594894
  var valid_594895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594895 = validateParameter(valid_594895, JString, required = false,
                                 default = nil)
  if valid_594895 != nil:
    section.add "X-Amz-SignedHeaders", valid_594895
  var valid_594896 = header.getOrDefault("X-Amz-Credential")
  valid_594896 = validateParameter(valid_594896, JString, required = false,
                                 default = nil)
  if valid_594896 != nil:
    section.add "X-Amz-Credential", valid_594896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594898: Call_ListPortfolios_594884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_594898.validator(path, query, header, formData, body)
  let scheme = call_594898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594898.url(scheme.get, call_594898.host, call_594898.base,
                         call_594898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594898, url, valid)

proc call*(call_594899: Call_ListPortfolios_594884; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594900 = newJObject()
  var body_594901 = newJObject()
  add(query_594900, "PageSize", newJString(PageSize))
  add(query_594900, "PageToken", newJString(PageToken))
  if body != nil:
    body_594901 = body
  result = call_594899.call(nil, query_594900, nil, nil, body_594901)

var listPortfolios* = Call_ListPortfolios_594884(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_594885, base: "/", url: url_ListPortfolios_594886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_594902 = ref object of OpenApiRestCall_593437
proc url_ListPortfoliosForProduct_594904(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPortfoliosForProduct_594903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594905 = query.getOrDefault("PageSize")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "PageSize", valid_594905
  var valid_594906 = query.getOrDefault("PageToken")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "PageToken", valid_594906
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
  var valid_594907 = header.getOrDefault("X-Amz-Date")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Date", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Security-Token")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Security-Token", valid_594908
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594909 = header.getOrDefault("X-Amz-Target")
  valid_594909 = validateParameter(valid_594909, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_594909 != nil:
    section.add "X-Amz-Target", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Content-Sha256", valid_594910
  var valid_594911 = header.getOrDefault("X-Amz-Algorithm")
  valid_594911 = validateParameter(valid_594911, JString, required = false,
                                 default = nil)
  if valid_594911 != nil:
    section.add "X-Amz-Algorithm", valid_594911
  var valid_594912 = header.getOrDefault("X-Amz-Signature")
  valid_594912 = validateParameter(valid_594912, JString, required = false,
                                 default = nil)
  if valid_594912 != nil:
    section.add "X-Amz-Signature", valid_594912
  var valid_594913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594913 = validateParameter(valid_594913, JString, required = false,
                                 default = nil)
  if valid_594913 != nil:
    section.add "X-Amz-SignedHeaders", valid_594913
  var valid_594914 = header.getOrDefault("X-Amz-Credential")
  valid_594914 = validateParameter(valid_594914, JString, required = false,
                                 default = nil)
  if valid_594914 != nil:
    section.add "X-Amz-Credential", valid_594914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594916: Call_ListPortfoliosForProduct_594902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_594916.validator(path, query, header, formData, body)
  let scheme = call_594916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594916.url(scheme.get, call_594916.host, call_594916.base,
                         call_594916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594916, url, valid)

proc call*(call_594917: Call_ListPortfoliosForProduct_594902; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594918 = newJObject()
  var body_594919 = newJObject()
  add(query_594918, "PageSize", newJString(PageSize))
  add(query_594918, "PageToken", newJString(PageToken))
  if body != nil:
    body_594919 = body
  result = call_594917.call(nil, query_594918, nil, nil, body_594919)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_594902(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_594903, base: "/",
    url: url_ListPortfoliosForProduct_594904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_594920 = ref object of OpenApiRestCall_593437
proc url_ListPrincipalsForPortfolio_594922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPrincipalsForPortfolio_594921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594923 = query.getOrDefault("PageSize")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "PageSize", valid_594923
  var valid_594924 = query.getOrDefault("PageToken")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "PageToken", valid_594924
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
  var valid_594925 = header.getOrDefault("X-Amz-Date")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Date", valid_594925
  var valid_594926 = header.getOrDefault("X-Amz-Security-Token")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = nil)
  if valid_594926 != nil:
    section.add "X-Amz-Security-Token", valid_594926
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594927 = header.getOrDefault("X-Amz-Target")
  valid_594927 = validateParameter(valid_594927, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_594927 != nil:
    section.add "X-Amz-Target", valid_594927
  var valid_594928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "X-Amz-Content-Sha256", valid_594928
  var valid_594929 = header.getOrDefault("X-Amz-Algorithm")
  valid_594929 = validateParameter(valid_594929, JString, required = false,
                                 default = nil)
  if valid_594929 != nil:
    section.add "X-Amz-Algorithm", valid_594929
  var valid_594930 = header.getOrDefault("X-Amz-Signature")
  valid_594930 = validateParameter(valid_594930, JString, required = false,
                                 default = nil)
  if valid_594930 != nil:
    section.add "X-Amz-Signature", valid_594930
  var valid_594931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-SignedHeaders", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-Credential")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-Credential", valid_594932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594934: Call_ListPrincipalsForPortfolio_594920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_594934.validator(path, query, header, formData, body)
  let scheme = call_594934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594934.url(scheme.get, call_594934.host, call_594934.base,
                         call_594934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594934, url, valid)

proc call*(call_594935: Call_ListPrincipalsForPortfolio_594920; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594936 = newJObject()
  var body_594937 = newJObject()
  add(query_594936, "PageSize", newJString(PageSize))
  add(query_594936, "PageToken", newJString(PageToken))
  if body != nil:
    body_594937 = body
  result = call_594935.call(nil, query_594936, nil, nil, body_594937)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_594920(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_594921, base: "/",
    url: url_ListPrincipalsForPortfolio_594922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_594938 = ref object of OpenApiRestCall_593437
proc url_ListProvisionedProductPlans_594940(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisionedProductPlans_594939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
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
  var valid_594941 = header.getOrDefault("X-Amz-Date")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Date", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Security-Token")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Security-Token", valid_594942
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594943 = header.getOrDefault("X-Amz-Target")
  valid_594943 = validateParameter(valid_594943, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_594943 != nil:
    section.add "X-Amz-Target", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Content-Sha256", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-Algorithm")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-Algorithm", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-Signature")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Signature", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-SignedHeaders", valid_594947
  var valid_594948 = header.getOrDefault("X-Amz-Credential")
  valid_594948 = validateParameter(valid_594948, JString, required = false,
                                 default = nil)
  if valid_594948 != nil:
    section.add "X-Amz-Credential", valid_594948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594950: Call_ListProvisionedProductPlans_594938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_594950.validator(path, query, header, formData, body)
  let scheme = call_594950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594950.url(scheme.get, call_594950.host, call_594950.base,
                         call_594950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594950, url, valid)

proc call*(call_594951: Call_ListProvisionedProductPlans_594938; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_594952 = newJObject()
  if body != nil:
    body_594952 = body
  result = call_594951.call(nil, nil, nil, nil, body_594952)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_594938(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_594939, base: "/",
    url: url_ListProvisionedProductPlans_594940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_594953 = ref object of OpenApiRestCall_593437
proc url_ListProvisioningArtifacts_594955(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisioningArtifacts_594954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
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
  var valid_594956 = header.getOrDefault("X-Amz-Date")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Date", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Security-Token")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Security-Token", valid_594957
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594958 = header.getOrDefault("X-Amz-Target")
  valid_594958 = validateParameter(valid_594958, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_594958 != nil:
    section.add "X-Amz-Target", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Content-Sha256", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-Algorithm")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-Algorithm", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Signature")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Signature", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-SignedHeaders", valid_594962
  var valid_594963 = header.getOrDefault("X-Amz-Credential")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "X-Amz-Credential", valid_594963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594965: Call_ListProvisioningArtifacts_594953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_594965.validator(path, query, header, formData, body)
  let scheme = call_594965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594965.url(scheme.get, call_594965.host, call_594965.base,
                         call_594965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594965, url, valid)

proc call*(call_594966: Call_ListProvisioningArtifacts_594953; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_594967 = newJObject()
  if body != nil:
    body_594967 = body
  result = call_594966.call(nil, nil, nil, nil, body_594967)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_594953(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_594954, base: "/",
    url: url_ListProvisioningArtifacts_594955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_594968 = ref object of OpenApiRestCall_593437
proc url_ListProvisioningArtifactsForServiceAction_594970(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_594969(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594971 = query.getOrDefault("PageSize")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "PageSize", valid_594971
  var valid_594972 = query.getOrDefault("PageToken")
  valid_594972 = validateParameter(valid_594972, JString, required = false,
                                 default = nil)
  if valid_594972 != nil:
    section.add "PageToken", valid_594972
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
  var valid_594973 = header.getOrDefault("X-Amz-Date")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "X-Amz-Date", valid_594973
  var valid_594974 = header.getOrDefault("X-Amz-Security-Token")
  valid_594974 = validateParameter(valid_594974, JString, required = false,
                                 default = nil)
  if valid_594974 != nil:
    section.add "X-Amz-Security-Token", valid_594974
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594975 = header.getOrDefault("X-Amz-Target")
  valid_594975 = validateParameter(valid_594975, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_594975 != nil:
    section.add "X-Amz-Target", valid_594975
  var valid_594976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Content-Sha256", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Algorithm")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Algorithm", valid_594977
  var valid_594978 = header.getOrDefault("X-Amz-Signature")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "X-Amz-Signature", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-SignedHeaders", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-Credential")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-Credential", valid_594980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594982: Call_ListProvisioningArtifactsForServiceAction_594968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_594982.validator(path, query, header, formData, body)
  let scheme = call_594982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594982.url(scheme.get, call_594982.host, call_594982.base,
                         call_594982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594982, url, valid)

proc call*(call_594983: Call_ListProvisioningArtifactsForServiceAction_594968;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594984 = newJObject()
  var body_594985 = newJObject()
  add(query_594984, "PageSize", newJString(PageSize))
  add(query_594984, "PageToken", newJString(PageToken))
  if body != nil:
    body_594985 = body
  result = call_594983.call(nil, query_594984, nil, nil, body_594985)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_594968(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_594969,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_594970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_594986 = ref object of OpenApiRestCall_593437
proc url_ListRecordHistory_594988(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRecordHistory_594987(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the specified requests or all performed requests.
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
  var valid_594989 = header.getOrDefault("X-Amz-Date")
  valid_594989 = validateParameter(valid_594989, JString, required = false,
                                 default = nil)
  if valid_594989 != nil:
    section.add "X-Amz-Date", valid_594989
  var valid_594990 = header.getOrDefault("X-Amz-Security-Token")
  valid_594990 = validateParameter(valid_594990, JString, required = false,
                                 default = nil)
  if valid_594990 != nil:
    section.add "X-Amz-Security-Token", valid_594990
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594991 = header.getOrDefault("X-Amz-Target")
  valid_594991 = validateParameter(valid_594991, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_594991 != nil:
    section.add "X-Amz-Target", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Content-Sha256", valid_594992
  var valid_594993 = header.getOrDefault("X-Amz-Algorithm")
  valid_594993 = validateParameter(valid_594993, JString, required = false,
                                 default = nil)
  if valid_594993 != nil:
    section.add "X-Amz-Algorithm", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Signature")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Signature", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-SignedHeaders", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Credential")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Credential", valid_594996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594998: Call_ListRecordHistory_594986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_594998.validator(path, query, header, formData, body)
  let scheme = call_594998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594998.url(scheme.get, call_594998.host, call_594998.base,
                         call_594998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594998, url, valid)

proc call*(call_594999: Call_ListRecordHistory_594986; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_595000 = newJObject()
  if body != nil:
    body_595000 = body
  result = call_594999.call(nil, nil, nil, nil, body_595000)

var listRecordHistory* = Call_ListRecordHistory_594986(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_594987, base: "/",
    url: url_ListRecordHistory_594988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_595001 = ref object of OpenApiRestCall_593437
proc url_ListResourcesForTagOption_595003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourcesForTagOption_595002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources associated with the specified TagOption.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595004 = query.getOrDefault("PageSize")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "PageSize", valid_595004
  var valid_595005 = query.getOrDefault("PageToken")
  valid_595005 = validateParameter(valid_595005, JString, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "PageToken", valid_595005
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
  var valid_595006 = header.getOrDefault("X-Amz-Date")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Date", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Security-Token")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Security-Token", valid_595007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595008 = header.getOrDefault("X-Amz-Target")
  valid_595008 = validateParameter(valid_595008, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_595008 != nil:
    section.add "X-Amz-Target", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Content-Sha256", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Algorithm")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Algorithm", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Signature")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Signature", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-SignedHeaders", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Credential")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Credential", valid_595013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595015: Call_ListResourcesForTagOption_595001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_595015.validator(path, query, header, formData, body)
  let scheme = call_595015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595015.url(scheme.get, call_595015.host, call_595015.base,
                         call_595015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595015, url, valid)

proc call*(call_595016: Call_ListResourcesForTagOption_595001; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595017 = newJObject()
  var body_595018 = newJObject()
  add(query_595017, "PageSize", newJString(PageSize))
  add(query_595017, "PageToken", newJString(PageToken))
  if body != nil:
    body_595018 = body
  result = call_595016.call(nil, query_595017, nil, nil, body_595018)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_595001(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_595002, base: "/",
    url: url_ListResourcesForTagOption_595003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_595019 = ref object of OpenApiRestCall_593437
proc url_ListServiceActions_595021(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServiceActions_595020(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all self-service actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595022 = query.getOrDefault("PageSize")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "PageSize", valid_595022
  var valid_595023 = query.getOrDefault("PageToken")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "PageToken", valid_595023
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
  var valid_595024 = header.getOrDefault("X-Amz-Date")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Date", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Security-Token")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Security-Token", valid_595025
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595026 = header.getOrDefault("X-Amz-Target")
  valid_595026 = validateParameter(valid_595026, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_595026 != nil:
    section.add "X-Amz-Target", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-Content-Sha256", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-Algorithm")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Algorithm", valid_595028
  var valid_595029 = header.getOrDefault("X-Amz-Signature")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "X-Amz-Signature", valid_595029
  var valid_595030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "X-Amz-SignedHeaders", valid_595030
  var valid_595031 = header.getOrDefault("X-Amz-Credential")
  valid_595031 = validateParameter(valid_595031, JString, required = false,
                                 default = nil)
  if valid_595031 != nil:
    section.add "X-Amz-Credential", valid_595031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595033: Call_ListServiceActions_595019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_595033.validator(path, query, header, formData, body)
  let scheme = call_595033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595033.url(scheme.get, call_595033.host, call_595033.base,
                         call_595033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595033, url, valid)

proc call*(call_595034: Call_ListServiceActions_595019; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595035 = newJObject()
  var body_595036 = newJObject()
  add(query_595035, "PageSize", newJString(PageSize))
  add(query_595035, "PageToken", newJString(PageToken))
  if body != nil:
    body_595036 = body
  result = call_595034.call(nil, query_595035, nil, nil, body_595036)

var listServiceActions* = Call_ListServiceActions_595019(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_595020, base: "/",
    url: url_ListServiceActions_595021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_595037 = ref object of OpenApiRestCall_593437
proc url_ListServiceActionsForProvisioningArtifact_595039(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_595038(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595040 = query.getOrDefault("PageSize")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "PageSize", valid_595040
  var valid_595041 = query.getOrDefault("PageToken")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "PageToken", valid_595041
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
  var valid_595042 = header.getOrDefault("X-Amz-Date")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "X-Amz-Date", valid_595042
  var valid_595043 = header.getOrDefault("X-Amz-Security-Token")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-Security-Token", valid_595043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595044 = header.getOrDefault("X-Amz-Target")
  valid_595044 = validateParameter(valid_595044, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_595044 != nil:
    section.add "X-Amz-Target", valid_595044
  var valid_595045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595045 = validateParameter(valid_595045, JString, required = false,
                                 default = nil)
  if valid_595045 != nil:
    section.add "X-Amz-Content-Sha256", valid_595045
  var valid_595046 = header.getOrDefault("X-Amz-Algorithm")
  valid_595046 = validateParameter(valid_595046, JString, required = false,
                                 default = nil)
  if valid_595046 != nil:
    section.add "X-Amz-Algorithm", valid_595046
  var valid_595047 = header.getOrDefault("X-Amz-Signature")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Signature", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-SignedHeaders", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Credential")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Credential", valid_595049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595051: Call_ListServiceActionsForProvisioningArtifact_595037;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_595051.validator(path, query, header, formData, body)
  let scheme = call_595051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595051.url(scheme.get, call_595051.host, call_595051.base,
                         call_595051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595051, url, valid)

proc call*(call_595052: Call_ListServiceActionsForProvisioningArtifact_595037;
          body: JsonNode; PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595053 = newJObject()
  var body_595054 = newJObject()
  add(query_595053, "PageSize", newJString(PageSize))
  add(query_595053, "PageToken", newJString(PageToken))
  if body != nil:
    body_595054 = body
  result = call_595052.call(nil, query_595053, nil, nil, body_595054)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_595037(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_595038,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_595039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_595055 = ref object of OpenApiRestCall_593437
proc url_ListStackInstancesForProvisionedProduct_595057(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_595056(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
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
  var valid_595058 = header.getOrDefault("X-Amz-Date")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "X-Amz-Date", valid_595058
  var valid_595059 = header.getOrDefault("X-Amz-Security-Token")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "X-Amz-Security-Token", valid_595059
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595060 = header.getOrDefault("X-Amz-Target")
  valid_595060 = validateParameter(valid_595060, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_595060 != nil:
    section.add "X-Amz-Target", valid_595060
  var valid_595061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "X-Amz-Content-Sha256", valid_595061
  var valid_595062 = header.getOrDefault("X-Amz-Algorithm")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "X-Amz-Algorithm", valid_595062
  var valid_595063 = header.getOrDefault("X-Amz-Signature")
  valid_595063 = validateParameter(valid_595063, JString, required = false,
                                 default = nil)
  if valid_595063 != nil:
    section.add "X-Amz-Signature", valid_595063
  var valid_595064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "X-Amz-SignedHeaders", valid_595064
  var valid_595065 = header.getOrDefault("X-Amz-Credential")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "X-Amz-Credential", valid_595065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595067: Call_ListStackInstancesForProvisionedProduct_595055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_595067.validator(path, query, header, formData, body)
  let scheme = call_595067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595067.url(scheme.get, call_595067.host, call_595067.base,
                         call_595067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595067, url, valid)

proc call*(call_595068: Call_ListStackInstancesForProvisionedProduct_595055;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_595069 = newJObject()
  if body != nil:
    body_595069 = body
  result = call_595068.call(nil, nil, nil, nil, body_595069)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_595055(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_595056, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_595057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_595070 = ref object of OpenApiRestCall_593437
proc url_ListTagOptions_595072(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagOptions_595071(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595073 = query.getOrDefault("PageSize")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "PageSize", valid_595073
  var valid_595074 = query.getOrDefault("PageToken")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "PageToken", valid_595074
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
  var valid_595075 = header.getOrDefault("X-Amz-Date")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "X-Amz-Date", valid_595075
  var valid_595076 = header.getOrDefault("X-Amz-Security-Token")
  valid_595076 = validateParameter(valid_595076, JString, required = false,
                                 default = nil)
  if valid_595076 != nil:
    section.add "X-Amz-Security-Token", valid_595076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595077 = header.getOrDefault("X-Amz-Target")
  valid_595077 = validateParameter(valid_595077, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_595077 != nil:
    section.add "X-Amz-Target", valid_595077
  var valid_595078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595078 = validateParameter(valid_595078, JString, required = false,
                                 default = nil)
  if valid_595078 != nil:
    section.add "X-Amz-Content-Sha256", valid_595078
  var valid_595079 = header.getOrDefault("X-Amz-Algorithm")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Algorithm", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Signature")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Signature", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-SignedHeaders", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Credential")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Credential", valid_595082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595084: Call_ListTagOptions_595070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_595084.validator(path, query, header, formData, body)
  let scheme = call_595084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595084.url(scheme.get, call_595084.host, call_595084.base,
                         call_595084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595084, url, valid)

proc call*(call_595085: Call_ListTagOptions_595070; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595086 = newJObject()
  var body_595087 = newJObject()
  add(query_595086, "PageSize", newJString(PageSize))
  add(query_595086, "PageToken", newJString(PageToken))
  if body != nil:
    body_595087 = body
  result = call_595085.call(nil, query_595086, nil, nil, body_595087)

var listTagOptions* = Call_ListTagOptions_595070(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_595071, base: "/", url: url_ListTagOptions_595072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_595088 = ref object of OpenApiRestCall_593437
proc url_ProvisionProduct_595090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ProvisionProduct_595089(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
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
  var valid_595091 = header.getOrDefault("X-Amz-Date")
  valid_595091 = validateParameter(valid_595091, JString, required = false,
                                 default = nil)
  if valid_595091 != nil:
    section.add "X-Amz-Date", valid_595091
  var valid_595092 = header.getOrDefault("X-Amz-Security-Token")
  valid_595092 = validateParameter(valid_595092, JString, required = false,
                                 default = nil)
  if valid_595092 != nil:
    section.add "X-Amz-Security-Token", valid_595092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595093 = header.getOrDefault("X-Amz-Target")
  valid_595093 = validateParameter(valid_595093, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_595093 != nil:
    section.add "X-Amz-Target", valid_595093
  var valid_595094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-Content-Sha256", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Algorithm")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Algorithm", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Signature")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Signature", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-SignedHeaders", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Credential")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Credential", valid_595098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595100: Call_ProvisionProduct_595088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_595100.validator(path, query, header, formData, body)
  let scheme = call_595100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595100.url(scheme.get, call_595100.host, call_595100.base,
                         call_595100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595100, url, valid)

proc call*(call_595101: Call_ProvisionProduct_595088; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_595102 = newJObject()
  if body != nil:
    body_595102 = body
  result = call_595101.call(nil, nil, nil, nil, body_595102)

var provisionProduct* = Call_ProvisionProduct_595088(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_595089, base: "/",
    url: url_ProvisionProduct_595090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_595103 = ref object of OpenApiRestCall_593437
proc url_RejectPortfolioShare_595105(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RejectPortfolioShare_595104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rejects an offer to share the specified portfolio.
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
  var valid_595106 = header.getOrDefault("X-Amz-Date")
  valid_595106 = validateParameter(valid_595106, JString, required = false,
                                 default = nil)
  if valid_595106 != nil:
    section.add "X-Amz-Date", valid_595106
  var valid_595107 = header.getOrDefault("X-Amz-Security-Token")
  valid_595107 = validateParameter(valid_595107, JString, required = false,
                                 default = nil)
  if valid_595107 != nil:
    section.add "X-Amz-Security-Token", valid_595107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595108 = header.getOrDefault("X-Amz-Target")
  valid_595108 = validateParameter(valid_595108, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_595108 != nil:
    section.add "X-Amz-Target", valid_595108
  var valid_595109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595109 = validateParameter(valid_595109, JString, required = false,
                                 default = nil)
  if valid_595109 != nil:
    section.add "X-Amz-Content-Sha256", valid_595109
  var valid_595110 = header.getOrDefault("X-Amz-Algorithm")
  valid_595110 = validateParameter(valid_595110, JString, required = false,
                                 default = nil)
  if valid_595110 != nil:
    section.add "X-Amz-Algorithm", valid_595110
  var valid_595111 = header.getOrDefault("X-Amz-Signature")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Signature", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-SignedHeaders", valid_595112
  var valid_595113 = header.getOrDefault("X-Amz-Credential")
  valid_595113 = validateParameter(valid_595113, JString, required = false,
                                 default = nil)
  if valid_595113 != nil:
    section.add "X-Amz-Credential", valid_595113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595115: Call_RejectPortfolioShare_595103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_595115.validator(path, query, header, formData, body)
  let scheme = call_595115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595115.url(scheme.get, call_595115.host, call_595115.base,
                         call_595115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595115, url, valid)

proc call*(call_595116: Call_RejectPortfolioShare_595103; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_595117 = newJObject()
  if body != nil:
    body_595117 = body
  result = call_595116.call(nil, nil, nil, nil, body_595117)

var rejectPortfolioShare* = Call_RejectPortfolioShare_595103(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_595104, base: "/",
    url: url_RejectPortfolioShare_595105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_595118 = ref object of OpenApiRestCall_593437
proc url_ScanProvisionedProducts_595120(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ScanProvisionedProducts_595119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
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
  var valid_595121 = header.getOrDefault("X-Amz-Date")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-Date", valid_595121
  var valid_595122 = header.getOrDefault("X-Amz-Security-Token")
  valid_595122 = validateParameter(valid_595122, JString, required = false,
                                 default = nil)
  if valid_595122 != nil:
    section.add "X-Amz-Security-Token", valid_595122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595123 = header.getOrDefault("X-Amz-Target")
  valid_595123 = validateParameter(valid_595123, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_595123 != nil:
    section.add "X-Amz-Target", valid_595123
  var valid_595124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595124 = validateParameter(valid_595124, JString, required = false,
                                 default = nil)
  if valid_595124 != nil:
    section.add "X-Amz-Content-Sha256", valid_595124
  var valid_595125 = header.getOrDefault("X-Amz-Algorithm")
  valid_595125 = validateParameter(valid_595125, JString, required = false,
                                 default = nil)
  if valid_595125 != nil:
    section.add "X-Amz-Algorithm", valid_595125
  var valid_595126 = header.getOrDefault("X-Amz-Signature")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Signature", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-SignedHeaders", valid_595127
  var valid_595128 = header.getOrDefault("X-Amz-Credential")
  valid_595128 = validateParameter(valid_595128, JString, required = false,
                                 default = nil)
  if valid_595128 != nil:
    section.add "X-Amz-Credential", valid_595128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595130: Call_ScanProvisionedProducts_595118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_595130.validator(path, query, header, formData, body)
  let scheme = call_595130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595130.url(scheme.get, call_595130.host, call_595130.base,
                         call_595130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595130, url, valid)

proc call*(call_595131: Call_ScanProvisionedProducts_595118; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_595132 = newJObject()
  if body != nil:
    body_595132 = body
  result = call_595131.call(nil, nil, nil, nil, body_595132)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_595118(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_595119, base: "/",
    url: url_ScanProvisionedProducts_595120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_595133 = ref object of OpenApiRestCall_593437
proc url_SearchProducts_595135(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProducts_595134(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about the products to which the caller has access.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595136 = query.getOrDefault("PageSize")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "PageSize", valid_595136
  var valid_595137 = query.getOrDefault("PageToken")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "PageToken", valid_595137
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
  var valid_595138 = header.getOrDefault("X-Amz-Date")
  valid_595138 = validateParameter(valid_595138, JString, required = false,
                                 default = nil)
  if valid_595138 != nil:
    section.add "X-Amz-Date", valid_595138
  var valid_595139 = header.getOrDefault("X-Amz-Security-Token")
  valid_595139 = validateParameter(valid_595139, JString, required = false,
                                 default = nil)
  if valid_595139 != nil:
    section.add "X-Amz-Security-Token", valid_595139
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595140 = header.getOrDefault("X-Amz-Target")
  valid_595140 = validateParameter(valid_595140, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_595140 != nil:
    section.add "X-Amz-Target", valid_595140
  var valid_595141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Content-Sha256", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Algorithm")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Algorithm", valid_595142
  var valid_595143 = header.getOrDefault("X-Amz-Signature")
  valid_595143 = validateParameter(valid_595143, JString, required = false,
                                 default = nil)
  if valid_595143 != nil:
    section.add "X-Amz-Signature", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-SignedHeaders", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Credential")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Credential", valid_595145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595147: Call_SearchProducts_595133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_595147.validator(path, query, header, formData, body)
  let scheme = call_595147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595147.url(scheme.get, call_595147.host, call_595147.base,
                         call_595147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595147, url, valid)

proc call*(call_595148: Call_SearchProducts_595133; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595149 = newJObject()
  var body_595150 = newJObject()
  add(query_595149, "PageSize", newJString(PageSize))
  add(query_595149, "PageToken", newJString(PageToken))
  if body != nil:
    body_595150 = body
  result = call_595148.call(nil, query_595149, nil, nil, body_595150)

var searchProducts* = Call_SearchProducts_595133(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_595134, base: "/", url: url_SearchProducts_595135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_595151 = ref object of OpenApiRestCall_593437
proc url_SearchProductsAsAdmin_595153(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProductsAsAdmin_595152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595154 = query.getOrDefault("PageSize")
  valid_595154 = validateParameter(valid_595154, JString, required = false,
                                 default = nil)
  if valid_595154 != nil:
    section.add "PageSize", valid_595154
  var valid_595155 = query.getOrDefault("PageToken")
  valid_595155 = validateParameter(valid_595155, JString, required = false,
                                 default = nil)
  if valid_595155 != nil:
    section.add "PageToken", valid_595155
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
  var valid_595156 = header.getOrDefault("X-Amz-Date")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Date", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Security-Token")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Security-Token", valid_595157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595158 = header.getOrDefault("X-Amz-Target")
  valid_595158 = validateParameter(valid_595158, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_595158 != nil:
    section.add "X-Amz-Target", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Content-Sha256", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Algorithm")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Algorithm", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Signature")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Signature", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-SignedHeaders", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Credential")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Credential", valid_595163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595165: Call_SearchProductsAsAdmin_595151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_595165.validator(path, query, header, formData, body)
  let scheme = call_595165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595165.url(scheme.get, call_595165.host, call_595165.base,
                         call_595165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595165, url, valid)

proc call*(call_595166: Call_SearchProductsAsAdmin_595151; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595167 = newJObject()
  var body_595168 = newJObject()
  add(query_595167, "PageSize", newJString(PageSize))
  add(query_595167, "PageToken", newJString(PageToken))
  if body != nil:
    body_595168 = body
  result = call_595166.call(nil, query_595167, nil, nil, body_595168)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_595151(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_595152, base: "/",
    url: url_SearchProductsAsAdmin_595153, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_595169 = ref object of OpenApiRestCall_593437
proc url_SearchProvisionedProducts_595171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchProvisionedProducts_595170(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JString
  ##           : Pagination limit
  ##   PageToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_595172 = query.getOrDefault("PageSize")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "PageSize", valid_595172
  var valid_595173 = query.getOrDefault("PageToken")
  valid_595173 = validateParameter(valid_595173, JString, required = false,
                                 default = nil)
  if valid_595173 != nil:
    section.add "PageToken", valid_595173
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
  var valid_595174 = header.getOrDefault("X-Amz-Date")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Date", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Security-Token")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Security-Token", valid_595175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595176 = header.getOrDefault("X-Amz-Target")
  valid_595176 = validateParameter(valid_595176, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_595176 != nil:
    section.add "X-Amz-Target", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-Content-Sha256", valid_595177
  var valid_595178 = header.getOrDefault("X-Amz-Algorithm")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "X-Amz-Algorithm", valid_595178
  var valid_595179 = header.getOrDefault("X-Amz-Signature")
  valid_595179 = validateParameter(valid_595179, JString, required = false,
                                 default = nil)
  if valid_595179 != nil:
    section.add "X-Amz-Signature", valid_595179
  var valid_595180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "X-Amz-SignedHeaders", valid_595180
  var valid_595181 = header.getOrDefault("X-Amz-Credential")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "X-Amz-Credential", valid_595181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595183: Call_SearchProvisionedProducts_595169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_595183.validator(path, query, header, formData, body)
  let scheme = call_595183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595183.url(scheme.get, call_595183.host, call_595183.base,
                         call_595183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595183, url, valid)

proc call*(call_595184: Call_SearchProvisionedProducts_595169; body: JsonNode;
          PageSize: string = ""; PageToken: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageSize: string
  ##           : Pagination limit
  ##   PageToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_595185 = newJObject()
  var body_595186 = newJObject()
  add(query_595185, "PageSize", newJString(PageSize))
  add(query_595185, "PageToken", newJString(PageToken))
  if body != nil:
    body_595186 = body
  result = call_595184.call(nil, query_595185, nil, nil, body_595186)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_595169(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_595170, base: "/",
    url: url_SearchProvisionedProducts_595171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_595187 = ref object of OpenApiRestCall_593437
proc url_TerminateProvisionedProduct_595189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateProvisionedProduct_595188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
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
  var valid_595190 = header.getOrDefault("X-Amz-Date")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Date", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Security-Token")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Security-Token", valid_595191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595192 = header.getOrDefault("X-Amz-Target")
  valid_595192 = validateParameter(valid_595192, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_595192 != nil:
    section.add "X-Amz-Target", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-Content-Sha256", valid_595193
  var valid_595194 = header.getOrDefault("X-Amz-Algorithm")
  valid_595194 = validateParameter(valid_595194, JString, required = false,
                                 default = nil)
  if valid_595194 != nil:
    section.add "X-Amz-Algorithm", valid_595194
  var valid_595195 = header.getOrDefault("X-Amz-Signature")
  valid_595195 = validateParameter(valid_595195, JString, required = false,
                                 default = nil)
  if valid_595195 != nil:
    section.add "X-Amz-Signature", valid_595195
  var valid_595196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "X-Amz-SignedHeaders", valid_595196
  var valid_595197 = header.getOrDefault("X-Amz-Credential")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "X-Amz-Credential", valid_595197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595199: Call_TerminateProvisionedProduct_595187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_595199.validator(path, query, header, formData, body)
  let scheme = call_595199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595199.url(scheme.get, call_595199.host, call_595199.base,
                         call_595199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595199, url, valid)

proc call*(call_595200: Call_TerminateProvisionedProduct_595187; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_595201 = newJObject()
  if body != nil:
    body_595201 = body
  result = call_595200.call(nil, nil, nil, nil, body_595201)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_595187(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_595188, base: "/",
    url: url_TerminateProvisionedProduct_595189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_595202 = ref object of OpenApiRestCall_593437
proc url_UpdateConstraint_595204(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateConstraint_595203(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates the specified constraint.
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
  var valid_595205 = header.getOrDefault("X-Amz-Date")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Date", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Security-Token")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Security-Token", valid_595206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595207 = header.getOrDefault("X-Amz-Target")
  valid_595207 = validateParameter(valid_595207, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_595207 != nil:
    section.add "X-Amz-Target", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Content-Sha256", valid_595208
  var valid_595209 = header.getOrDefault("X-Amz-Algorithm")
  valid_595209 = validateParameter(valid_595209, JString, required = false,
                                 default = nil)
  if valid_595209 != nil:
    section.add "X-Amz-Algorithm", valid_595209
  var valid_595210 = header.getOrDefault("X-Amz-Signature")
  valid_595210 = validateParameter(valid_595210, JString, required = false,
                                 default = nil)
  if valid_595210 != nil:
    section.add "X-Amz-Signature", valid_595210
  var valid_595211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595211 = validateParameter(valid_595211, JString, required = false,
                                 default = nil)
  if valid_595211 != nil:
    section.add "X-Amz-SignedHeaders", valid_595211
  var valid_595212 = header.getOrDefault("X-Amz-Credential")
  valid_595212 = validateParameter(valid_595212, JString, required = false,
                                 default = nil)
  if valid_595212 != nil:
    section.add "X-Amz-Credential", valid_595212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595214: Call_UpdateConstraint_595202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_595214.validator(path, query, header, formData, body)
  let scheme = call_595214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595214.url(scheme.get, call_595214.host, call_595214.base,
                         call_595214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595214, url, valid)

proc call*(call_595215: Call_UpdateConstraint_595202; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_595216 = newJObject()
  if body != nil:
    body_595216 = body
  result = call_595215.call(nil, nil, nil, nil, body_595216)

var updateConstraint* = Call_UpdateConstraint_595202(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_595203, base: "/",
    url: url_UpdateConstraint_595204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_595217 = ref object of OpenApiRestCall_593437
proc url_UpdatePortfolio_595219(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePortfolio_595218(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
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
  var valid_595220 = header.getOrDefault("X-Amz-Date")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-Date", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Security-Token")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Security-Token", valid_595221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595222 = header.getOrDefault("X-Amz-Target")
  valid_595222 = validateParameter(valid_595222, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_595222 != nil:
    section.add "X-Amz-Target", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-Content-Sha256", valid_595223
  var valid_595224 = header.getOrDefault("X-Amz-Algorithm")
  valid_595224 = validateParameter(valid_595224, JString, required = false,
                                 default = nil)
  if valid_595224 != nil:
    section.add "X-Amz-Algorithm", valid_595224
  var valid_595225 = header.getOrDefault("X-Amz-Signature")
  valid_595225 = validateParameter(valid_595225, JString, required = false,
                                 default = nil)
  if valid_595225 != nil:
    section.add "X-Amz-Signature", valid_595225
  var valid_595226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595226 = validateParameter(valid_595226, JString, required = false,
                                 default = nil)
  if valid_595226 != nil:
    section.add "X-Amz-SignedHeaders", valid_595226
  var valid_595227 = header.getOrDefault("X-Amz-Credential")
  valid_595227 = validateParameter(valid_595227, JString, required = false,
                                 default = nil)
  if valid_595227 != nil:
    section.add "X-Amz-Credential", valid_595227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595229: Call_UpdatePortfolio_595217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_595229.validator(path, query, header, formData, body)
  let scheme = call_595229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595229.url(scheme.get, call_595229.host, call_595229.base,
                         call_595229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595229, url, valid)

proc call*(call_595230: Call_UpdatePortfolio_595217; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_595231 = newJObject()
  if body != nil:
    body_595231 = body
  result = call_595230.call(nil, nil, nil, nil, body_595231)

var updatePortfolio* = Call_UpdatePortfolio_595217(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_595218, base: "/", url: url_UpdatePortfolio_595219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_595232 = ref object of OpenApiRestCall_593437
proc url_UpdateProduct_595234(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProduct_595233(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified product.
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
  var valid_595235 = header.getOrDefault("X-Amz-Date")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-Date", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Security-Token")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Security-Token", valid_595236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595237 = header.getOrDefault("X-Amz-Target")
  valid_595237 = validateParameter(valid_595237, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_595237 != nil:
    section.add "X-Amz-Target", valid_595237
  var valid_595238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595238 = validateParameter(valid_595238, JString, required = false,
                                 default = nil)
  if valid_595238 != nil:
    section.add "X-Amz-Content-Sha256", valid_595238
  var valid_595239 = header.getOrDefault("X-Amz-Algorithm")
  valid_595239 = validateParameter(valid_595239, JString, required = false,
                                 default = nil)
  if valid_595239 != nil:
    section.add "X-Amz-Algorithm", valid_595239
  var valid_595240 = header.getOrDefault("X-Amz-Signature")
  valid_595240 = validateParameter(valid_595240, JString, required = false,
                                 default = nil)
  if valid_595240 != nil:
    section.add "X-Amz-Signature", valid_595240
  var valid_595241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595241 = validateParameter(valid_595241, JString, required = false,
                                 default = nil)
  if valid_595241 != nil:
    section.add "X-Amz-SignedHeaders", valid_595241
  var valid_595242 = header.getOrDefault("X-Amz-Credential")
  valid_595242 = validateParameter(valid_595242, JString, required = false,
                                 default = nil)
  if valid_595242 != nil:
    section.add "X-Amz-Credential", valid_595242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595244: Call_UpdateProduct_595232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_595244.validator(path, query, header, formData, body)
  let scheme = call_595244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595244.url(scheme.get, call_595244.host, call_595244.base,
                         call_595244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595244, url, valid)

proc call*(call_595245: Call_UpdateProduct_595232; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_595246 = newJObject()
  if body != nil:
    body_595246 = body
  result = call_595245.call(nil, nil, nil, nil, body_595246)

var updateProduct* = Call_UpdateProduct_595232(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_595233, base: "/", url: url_UpdateProduct_595234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_595247 = ref object of OpenApiRestCall_593437
proc url_UpdateProvisionedProduct_595249(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisionedProduct_595248(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
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
  var valid_595250 = header.getOrDefault("X-Amz-Date")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Date", valid_595250
  var valid_595251 = header.getOrDefault("X-Amz-Security-Token")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Security-Token", valid_595251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595252 = header.getOrDefault("X-Amz-Target")
  valid_595252 = validateParameter(valid_595252, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_595252 != nil:
    section.add "X-Amz-Target", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Content-Sha256", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-Algorithm")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-Algorithm", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Signature")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Signature", valid_595255
  var valid_595256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595256 = validateParameter(valid_595256, JString, required = false,
                                 default = nil)
  if valid_595256 != nil:
    section.add "X-Amz-SignedHeaders", valid_595256
  var valid_595257 = header.getOrDefault("X-Amz-Credential")
  valid_595257 = validateParameter(valid_595257, JString, required = false,
                                 default = nil)
  if valid_595257 != nil:
    section.add "X-Amz-Credential", valid_595257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595259: Call_UpdateProvisionedProduct_595247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_595259.validator(path, query, header, formData, body)
  let scheme = call_595259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595259.url(scheme.get, call_595259.host, call_595259.base,
                         call_595259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595259, url, valid)

proc call*(call_595260: Call_UpdateProvisionedProduct_595247; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_595261 = newJObject()
  if body != nil:
    body_595261 = body
  result = call_595260.call(nil, nil, nil, nil, body_595261)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_595247(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_595248, base: "/",
    url: url_UpdateProvisionedProduct_595249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_595262 = ref object of OpenApiRestCall_593437
proc url_UpdateProvisionedProductProperties_595264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisionedProductProperties_595263(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Requests updates to the properties of the specified provisioned product.
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
  var valid_595265 = header.getOrDefault("X-Amz-Date")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "X-Amz-Date", valid_595265
  var valid_595266 = header.getOrDefault("X-Amz-Security-Token")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "X-Amz-Security-Token", valid_595266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595267 = header.getOrDefault("X-Amz-Target")
  valid_595267 = validateParameter(valid_595267, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_595267 != nil:
    section.add "X-Amz-Target", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-Content-Sha256", valid_595268
  var valid_595269 = header.getOrDefault("X-Amz-Algorithm")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-Algorithm", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Signature")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Signature", valid_595270
  var valid_595271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "X-Amz-SignedHeaders", valid_595271
  var valid_595272 = header.getOrDefault("X-Amz-Credential")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "X-Amz-Credential", valid_595272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595274: Call_UpdateProvisionedProductProperties_595262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_595274.validator(path, query, header, formData, body)
  let scheme = call_595274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595274.url(scheme.get, call_595274.host, call_595274.base,
                         call_595274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595274, url, valid)

proc call*(call_595275: Call_UpdateProvisionedProductProperties_595262;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_595276 = newJObject()
  if body != nil:
    body_595276 = body
  result = call_595275.call(nil, nil, nil, nil, body_595276)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_595262(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_595263, base: "/",
    url: url_UpdateProvisionedProductProperties_595264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_595277 = ref object of OpenApiRestCall_593437
proc url_UpdateProvisioningArtifact_595279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateProvisioningArtifact_595278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
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
  var valid_595280 = header.getOrDefault("X-Amz-Date")
  valid_595280 = validateParameter(valid_595280, JString, required = false,
                                 default = nil)
  if valid_595280 != nil:
    section.add "X-Amz-Date", valid_595280
  var valid_595281 = header.getOrDefault("X-Amz-Security-Token")
  valid_595281 = validateParameter(valid_595281, JString, required = false,
                                 default = nil)
  if valid_595281 != nil:
    section.add "X-Amz-Security-Token", valid_595281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595282 = header.getOrDefault("X-Amz-Target")
  valid_595282 = validateParameter(valid_595282, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_595282 != nil:
    section.add "X-Amz-Target", valid_595282
  var valid_595283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "X-Amz-Content-Sha256", valid_595283
  var valid_595284 = header.getOrDefault("X-Amz-Algorithm")
  valid_595284 = validateParameter(valid_595284, JString, required = false,
                                 default = nil)
  if valid_595284 != nil:
    section.add "X-Amz-Algorithm", valid_595284
  var valid_595285 = header.getOrDefault("X-Amz-Signature")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Signature", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-SignedHeaders", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Credential")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Credential", valid_595287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595289: Call_UpdateProvisioningArtifact_595277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_595289.validator(path, query, header, formData, body)
  let scheme = call_595289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595289.url(scheme.get, call_595289.host, call_595289.base,
                         call_595289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595289, url, valid)

proc call*(call_595290: Call_UpdateProvisioningArtifact_595277; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_595291 = newJObject()
  if body != nil:
    body_595291 = body
  result = call_595290.call(nil, nil, nil, nil, body_595291)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_595277(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_595278, base: "/",
    url: url_UpdateProvisioningArtifact_595279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_595292 = ref object of OpenApiRestCall_593437
proc url_UpdateServiceAction_595294(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateServiceAction_595293(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates a self-service action.
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
  var valid_595295 = header.getOrDefault("X-Amz-Date")
  valid_595295 = validateParameter(valid_595295, JString, required = false,
                                 default = nil)
  if valid_595295 != nil:
    section.add "X-Amz-Date", valid_595295
  var valid_595296 = header.getOrDefault("X-Amz-Security-Token")
  valid_595296 = validateParameter(valid_595296, JString, required = false,
                                 default = nil)
  if valid_595296 != nil:
    section.add "X-Amz-Security-Token", valid_595296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595297 = header.getOrDefault("X-Amz-Target")
  valid_595297 = validateParameter(valid_595297, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_595297 != nil:
    section.add "X-Amz-Target", valid_595297
  var valid_595298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595298 = validateParameter(valid_595298, JString, required = false,
                                 default = nil)
  if valid_595298 != nil:
    section.add "X-Amz-Content-Sha256", valid_595298
  var valid_595299 = header.getOrDefault("X-Amz-Algorithm")
  valid_595299 = validateParameter(valid_595299, JString, required = false,
                                 default = nil)
  if valid_595299 != nil:
    section.add "X-Amz-Algorithm", valid_595299
  var valid_595300 = header.getOrDefault("X-Amz-Signature")
  valid_595300 = validateParameter(valid_595300, JString, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "X-Amz-Signature", valid_595300
  var valid_595301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "X-Amz-SignedHeaders", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Credential")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Credential", valid_595302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595304: Call_UpdateServiceAction_595292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_595304.validator(path, query, header, formData, body)
  let scheme = call_595304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595304.url(scheme.get, call_595304.host, call_595304.base,
                         call_595304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595304, url, valid)

proc call*(call_595305: Call_UpdateServiceAction_595292; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_595306 = newJObject()
  if body != nil:
    body_595306 = body
  result = call_595305.call(nil, nil, nil, nil, body_595306)

var updateServiceAction* = Call_UpdateServiceAction_595292(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_595293, base: "/",
    url: url_UpdateServiceAction_595294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_595307 = ref object of OpenApiRestCall_593437
proc url_UpdateTagOption_595309(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTagOption_595308(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the specified TagOption.
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
  var valid_595310 = header.getOrDefault("X-Amz-Date")
  valid_595310 = validateParameter(valid_595310, JString, required = false,
                                 default = nil)
  if valid_595310 != nil:
    section.add "X-Amz-Date", valid_595310
  var valid_595311 = header.getOrDefault("X-Amz-Security-Token")
  valid_595311 = validateParameter(valid_595311, JString, required = false,
                                 default = nil)
  if valid_595311 != nil:
    section.add "X-Amz-Security-Token", valid_595311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595312 = header.getOrDefault("X-Amz-Target")
  valid_595312 = validateParameter(valid_595312, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_595312 != nil:
    section.add "X-Amz-Target", valid_595312
  var valid_595313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595313 = validateParameter(valid_595313, JString, required = false,
                                 default = nil)
  if valid_595313 != nil:
    section.add "X-Amz-Content-Sha256", valid_595313
  var valid_595314 = header.getOrDefault("X-Amz-Algorithm")
  valid_595314 = validateParameter(valid_595314, JString, required = false,
                                 default = nil)
  if valid_595314 != nil:
    section.add "X-Amz-Algorithm", valid_595314
  var valid_595315 = header.getOrDefault("X-Amz-Signature")
  valid_595315 = validateParameter(valid_595315, JString, required = false,
                                 default = nil)
  if valid_595315 != nil:
    section.add "X-Amz-Signature", valid_595315
  var valid_595316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595316 = validateParameter(valid_595316, JString, required = false,
                                 default = nil)
  if valid_595316 != nil:
    section.add "X-Amz-SignedHeaders", valid_595316
  var valid_595317 = header.getOrDefault("X-Amz-Credential")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "X-Amz-Credential", valid_595317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595319: Call_UpdateTagOption_595307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_595319.validator(path, query, header, formData, body)
  let scheme = call_595319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595319.url(scheme.get, call_595319.host, call_595319.base,
                         call_595319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595319, url, valid)

proc call*(call_595320: Call_UpdateTagOption_595307; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_595321 = newJObject()
  if body != nil:
    body_595321 = body
  result = call_595320.call(nil, nil, nil, nil, body_595321)

var updateTagOption* = Call_UpdateTagOption_595307(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_595308, base: "/", url: url_UpdateTagOption_595309,
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
