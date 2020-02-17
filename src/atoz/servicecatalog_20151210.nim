
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptPortfolioShare_610996 = ref object of OpenApiRestCall_610658
proc url_AcceptPortfolioShare_610998(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptPortfolioShare_610997(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AcceptPortfolioShare"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AcceptPortfolioShare_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts an offer to share the specified portfolio.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AcceptPortfolioShare_610996; body: JsonNode): Recallable =
  ## acceptPortfolioShare
  ## Accepts an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var acceptPortfolioShare* = Call_AcceptPortfolioShare_610996(
    name: "acceptPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare",
    validator: validate_AcceptPortfolioShare_610997, base: "/",
    url: url_AcceptPortfolioShare_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateBudgetWithResource_611265 = ref object of OpenApiRestCall_610658
proc url_AssociateBudgetWithResource_611267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateBudgetWithResource_611266(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateBudgetWithResource"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_AssociateBudgetWithResource_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified budget with the specified resource.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_AssociateBudgetWithResource_611265; body: JsonNode): Recallable =
  ## associateBudgetWithResource
  ## Associates the specified budget with the specified resource.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var associateBudgetWithResource* = Call_AssociateBudgetWithResource_611265(
    name: "associateBudgetWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource",
    validator: validate_AssociateBudgetWithResource_611266, base: "/",
    url: url_AssociateBudgetWithResource_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociatePrincipalWithPortfolio_611280 = ref object of OpenApiRestCall_610658
proc url_AssociatePrincipalWithPortfolio_611282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociatePrincipalWithPortfolio_611281(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_AssociatePrincipalWithPortfolio_611280;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates the specified principal ARN with the specified portfolio.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_AssociatePrincipalWithPortfolio_611280; body: JsonNode): Recallable =
  ## associatePrincipalWithPortfolio
  ## Associates the specified principal ARN with the specified portfolio.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var associatePrincipalWithPortfolio* = Call_AssociatePrincipalWithPortfolio_611280(
    name: "associatePrincipalWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio",
    validator: validate_AssociatePrincipalWithPortfolio_611281, base: "/",
    url: url_AssociatePrincipalWithPortfolio_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateProductWithPortfolio_611295 = ref object of OpenApiRestCall_610658
proc url_AssociateProductWithPortfolio_611297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateProductWithPortfolio_611296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateProductWithPortfolio"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_AssociateProductWithPortfolio_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified product with the specified portfolio.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_AssociateProductWithPortfolio_611295; body: JsonNode): Recallable =
  ## associateProductWithPortfolio
  ## Associates the specified product with the specified portfolio.
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var associateProductWithPortfolio* = Call_AssociateProductWithPortfolio_611295(
    name: "associateProductWithPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio",
    validator: validate_AssociateProductWithPortfolio_611296, base: "/",
    url: url_AssociateProductWithPortfolio_611297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateServiceActionWithProvisioningArtifact_611310 = ref object of OpenApiRestCall_610658
proc url_AssociateServiceActionWithProvisioningArtifact_611312(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateServiceActionWithProvisioningArtifact_611311(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString("AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_AssociateServiceActionWithProvisioningArtifact_611310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates a self-service action with a provisioning artifact.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_AssociateServiceActionWithProvisioningArtifact_611310;
          body: JsonNode): Recallable =
  ## associateServiceActionWithProvisioningArtifact
  ## Associates a self-service action with a provisioning artifact.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var associateServiceActionWithProvisioningArtifact* = Call_AssociateServiceActionWithProvisioningArtifact_611310(
    name: "associateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact",
    validator: validate_AssociateServiceActionWithProvisioningArtifact_611311,
    base: "/", url: url_AssociateServiceActionWithProvisioningArtifact_611312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTagOptionWithResource_611325 = ref object of OpenApiRestCall_610658
proc url_AssociateTagOptionWithResource_611327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTagOptionWithResource_611326(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.AssociateTagOptionWithResource"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_AssociateTagOptionWithResource_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associate the specified TagOption with the specified portfolio or product.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_AssociateTagOptionWithResource_611325; body: JsonNode): Recallable =
  ## associateTagOptionWithResource
  ## Associate the specified TagOption with the specified portfolio or product.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var associateTagOptionWithResource* = Call_AssociateTagOptionWithResource_611325(
    name: "associateTagOptionWithResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource",
    validator: validate_AssociateTagOptionWithResource_611326, base: "/",
    url: url_AssociateTagOptionWithResource_611327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateServiceActionWithProvisioningArtifact_611340 = ref object of OpenApiRestCall_610658
proc url_BatchAssociateServiceActionWithProvisioningArtifact_611342(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateServiceActionWithProvisioningArtifact_611341(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_BatchAssociateServiceActionWithProvisioningArtifact_611340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates multiple self-service actions with provisioning artifacts.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_BatchAssociateServiceActionWithProvisioningArtifact_611340;
          body: JsonNode): Recallable =
  ## batchAssociateServiceActionWithProvisioningArtifact
  ## Associates multiple self-service actions with provisioning artifacts.
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var batchAssociateServiceActionWithProvisioningArtifact* = Call_BatchAssociateServiceActionWithProvisioningArtifact_611340(
    name: "batchAssociateServiceActionWithProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact",
    validator: validate_BatchAssociateServiceActionWithProvisioningArtifact_611341,
    base: "/", url: url_BatchAssociateServiceActionWithProvisioningArtifact_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateServiceActionFromProvisioningArtifact_611355 = ref object of OpenApiRestCall_610658
proc url_BatchDisassociateServiceActionFromProvisioningArtifact_611357(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateServiceActionFromProvisioningArtifact_611356(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString("AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_BatchDisassociateServiceActionFromProvisioningArtifact_611355;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_BatchDisassociateServiceActionFromProvisioningArtifact_611355;
          body: JsonNode): Recallable =
  ## batchDisassociateServiceActionFromProvisioningArtifact
  ## Disassociates a batch of self-service actions from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var batchDisassociateServiceActionFromProvisioningArtifact* = Call_BatchDisassociateServiceActionFromProvisioningArtifact_611355(
    name: "batchDisassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact",
    validator: validate_BatchDisassociateServiceActionFromProvisioningArtifact_611356,
    base: "/", url: url_BatchDisassociateServiceActionFromProvisioningArtifact_611357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CopyProduct_611370 = ref object of OpenApiRestCall_610658
proc url_CopyProduct_611372(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CopyProduct_611371(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CopyProduct"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_CopyProduct_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_CopyProduct_611370; body: JsonNode): Recallable =
  ## copyProduct
  ## <p>Copies the specified source product to the specified target product or a new product.</p> <p>You can copy a product to the same account or another account. You can copy a product to the same region or another region.</p> <p>This operation is performed asynchronously. To track the progress of the operation, use <a>DescribeCopyProductStatus</a>.</p>
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var copyProduct* = Call_CopyProduct_611370(name: "copyProduct",
                                        meth: HttpMethod.HttpPost,
                                        host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct",
                                        validator: validate_CopyProduct_611371,
                                        base: "/", url: url_CopyProduct_611372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConstraint_611385 = ref object of OpenApiRestCall_610658
proc url_CreateConstraint_611387(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConstraint_611386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateConstraint"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_CreateConstraint_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a constraint.
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_CreateConstraint_611385; body: JsonNode): Recallable =
  ## createConstraint
  ## Creates a constraint.
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var createConstraint* = Call_CreateConstraint_611385(name: "createConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint",
    validator: validate_CreateConstraint_611386, base: "/",
    url: url_CreateConstraint_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolio_611400 = ref object of OpenApiRestCall_610658
proc url_CreatePortfolio_611402(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolio_611401(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolio"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_CreatePortfolio_611400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a portfolio.
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_CreatePortfolio_611400; body: JsonNode): Recallable =
  ## createPortfolio
  ## Creates a portfolio.
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var createPortfolio* = Call_CreatePortfolio_611400(name: "createPortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio",
    validator: validate_CreatePortfolio_611401, base: "/", url: url_CreatePortfolio_611402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePortfolioShare_611415 = ref object of OpenApiRestCall_610658
proc url_CreatePortfolioShare_611417(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePortfolioShare_611416(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreatePortfolioShare"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_CreatePortfolioShare_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_CreatePortfolioShare_611415; body: JsonNode): Recallable =
  ## createPortfolioShare
  ## Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the master account of an Organization. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var createPortfolioShare* = Call_CreatePortfolioShare_611415(
    name: "createPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare",
    validator: validate_CreatePortfolioShare_611416, base: "/",
    url: url_CreatePortfolioShare_611417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProduct_611430 = ref object of OpenApiRestCall_610658
proc url_CreateProduct_611432(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProduct_611431(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProduct"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CreateProduct_611430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a product.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CreateProduct_611430; body: JsonNode): Recallable =
  ## createProduct
  ## Creates a product.
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var createProduct* = Call_CreateProduct_611430(name: "createProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct",
    validator: validate_CreateProduct_611431, base: "/", url: url_CreateProduct_611432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisionedProductPlan_611445 = ref object of OpenApiRestCall_610658
proc url_CreateProvisionedProductPlan_611447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisionedProductPlan_611446(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisionedProductPlan"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_CreateProvisionedProductPlan_611445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_CreateProvisionedProductPlan_611445; body: JsonNode): Recallable =
  ## createProvisionedProductPlan
  ## <p>Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed.</p> <p>You can create one plan per provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILBLE or TAINTED.</p> <p>To view the resource changes in the change set, use <a>DescribeProvisionedProductPlan</a>. To create or modify the provisioned product, use <a>ExecuteProvisionedProductPlan</a>.</p>
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var createProvisionedProductPlan* = Call_CreateProvisionedProductPlan_611445(
    name: "createProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan",
    validator: validate_CreateProvisionedProductPlan_611446, base: "/",
    url: url_CreateProvisionedProductPlan_611447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProvisioningArtifact_611460 = ref object of OpenApiRestCall_610658
proc url_CreateProvisioningArtifact_611462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProvisioningArtifact_611461(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateProvisioningArtifact"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_CreateProvisioningArtifact_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_CreateProvisioningArtifact_611460; body: JsonNode): Recallable =
  ## createProvisioningArtifact
  ## <p>Creates a provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot create a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var createProvisioningArtifact* = Call_CreateProvisioningArtifact_611460(
    name: "createProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact",
    validator: validate_CreateProvisioningArtifact_611461, base: "/",
    url: url_CreateProvisioningArtifact_611462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateServiceAction_611475 = ref object of OpenApiRestCall_610658
proc url_CreateServiceAction_611477(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateServiceAction_611476(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611478 = header.getOrDefault("X-Amz-Target")
  valid_611478 = validateParameter(valid_611478, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateServiceAction"))
  if valid_611478 != nil:
    section.add "X-Amz-Target", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_CreateServiceAction_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a self-service action.
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_CreateServiceAction_611475; body: JsonNode): Recallable =
  ## createServiceAction
  ## Creates a self-service action.
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var createServiceAction* = Call_CreateServiceAction_611475(
    name: "createServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction",
    validator: validate_CreateServiceAction_611476, base: "/",
    url: url_CreateServiceAction_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTagOption_611490 = ref object of OpenApiRestCall_610658
proc url_CreateTagOption_611492(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTagOption_611491(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.CreateTagOption"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_CreateTagOption_611490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a TagOption.
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_CreateTagOption_611490; body: JsonNode): Recallable =
  ## createTagOption
  ## Creates a TagOption.
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var createTagOption* = Call_CreateTagOption_611490(name: "createTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption",
    validator: validate_CreateTagOption_611491, base: "/", url: url_CreateTagOption_611492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConstraint_611505 = ref object of OpenApiRestCall_610658
proc url_DeleteConstraint_611507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConstraint_611506(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611508 = header.getOrDefault("X-Amz-Target")
  valid_611508 = validateParameter(valid_611508, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteConstraint"))
  if valid_611508 != nil:
    section.add "X-Amz-Target", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_DeleteConstraint_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified constraint.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_DeleteConstraint_611505; body: JsonNode): Recallable =
  ## deleteConstraint
  ## Deletes the specified constraint.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var deleteConstraint* = Call_DeleteConstraint_611505(name: "deleteConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint",
    validator: validate_DeleteConstraint_611506, base: "/",
    url: url_DeleteConstraint_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolio_611520 = ref object of OpenApiRestCall_610658
proc url_DeletePortfolio_611522(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolio_611521(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611523 = header.getOrDefault("X-Amz-Target")
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolio"))
  if valid_611523 != nil:
    section.add "X-Amz-Target", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_DeletePortfolio_611520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_DeletePortfolio_611520; body: JsonNode): Recallable =
  ## deletePortfolio
  ## <p>Deletes the specified portfolio.</p> <p>You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts.</p>
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var deletePortfolio* = Call_DeletePortfolio_611520(name: "deletePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio",
    validator: validate_DeletePortfolio_611521, base: "/", url: url_DeletePortfolio_611522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePortfolioShare_611535 = ref object of OpenApiRestCall_610658
proc url_DeletePortfolioShare_611537(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePortfolioShare_611536(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611538 = header.getOrDefault("X-Amz-Target")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeletePortfolioShare"))
  if valid_611538 != nil:
    section.add "X-Amz-Target", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611547: Call_DeletePortfolioShare_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_DeletePortfolioShare_611535; body: JsonNode): Recallable =
  ## deletePortfolioShare
  ## Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the master account of an Organization.
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var deletePortfolioShare* = Call_DeletePortfolioShare_611535(
    name: "deletePortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare",
    validator: validate_DeletePortfolioShare_611536, base: "/",
    url: url_DeletePortfolioShare_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProduct_611550 = ref object of OpenApiRestCall_610658
proc url_DeleteProduct_611552(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProduct_611551(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611553 = header.getOrDefault("X-Amz-Target")
  valid_611553 = validateParameter(valid_611553, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProduct"))
  if valid_611553 != nil:
    section.add "X-Amz-Target", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Signature")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Signature", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Content-Sha256", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Date")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Date", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Credential")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Credential", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Security-Token")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Security-Token", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Algorithm")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Algorithm", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-SignedHeaders", valid_611560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611562: Call_DeleteProduct_611550; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_DeleteProduct_611550; body: JsonNode): Recallable =
  ## deleteProduct
  ## <p>Deletes the specified product.</p> <p>You cannot delete a product if it was shared with you or is associated with a portfolio.</p>
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var deleteProduct* = Call_DeleteProduct_611550(name: "deleteProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct",
    validator: validate_DeleteProduct_611551, base: "/", url: url_DeleteProduct_611552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedProductPlan_611565 = ref object of OpenApiRestCall_610658
proc url_DeleteProvisionedProductPlan_611567(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisionedProductPlan_611566(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611568 = header.getOrDefault("X-Amz-Target")
  valid_611568 = validateParameter(valid_611568, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisionedProductPlan"))
  if valid_611568 != nil:
    section.add "X-Amz-Target", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_DeleteProvisionedProductPlan_611565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified plan.
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_DeleteProvisionedProductPlan_611565; body: JsonNode): Recallable =
  ## deleteProvisionedProductPlan
  ## Deletes the specified plan.
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var deleteProvisionedProductPlan* = Call_DeleteProvisionedProductPlan_611565(
    name: "deleteProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan",
    validator: validate_DeleteProvisionedProductPlan_611566, base: "/",
    url: url_DeleteProvisionedProductPlan_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisioningArtifact_611580 = ref object of OpenApiRestCall_610658
proc url_DeleteProvisioningArtifact_611582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteProvisioningArtifact_611581(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611583 = header.getOrDefault("X-Amz-Target")
  valid_611583 = validateParameter(valid_611583, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteProvisioningArtifact"))
  if valid_611583 != nil:
    section.add "X-Amz-Target", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_DeleteProvisioningArtifact_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_DeleteProvisioningArtifact_611580; body: JsonNode): Recallable =
  ## deleteProvisioningArtifact
  ## <p>Deletes the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.</p>
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var deleteProvisioningArtifact* = Call_DeleteProvisioningArtifact_611580(
    name: "deleteProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact",
    validator: validate_DeleteProvisioningArtifact_611581, base: "/",
    url: url_DeleteProvisioningArtifact_611582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceAction_611595 = ref object of OpenApiRestCall_610658
proc url_DeleteServiceAction_611597(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServiceAction_611596(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611598 = header.getOrDefault("X-Amz-Target")
  valid_611598 = validateParameter(valid_611598, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteServiceAction"))
  if valid_611598 != nil:
    section.add "X-Amz-Target", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_DeleteServiceAction_611595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a self-service action.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_DeleteServiceAction_611595; body: JsonNode): Recallable =
  ## deleteServiceAction
  ## Deletes a self-service action.
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var deleteServiceAction* = Call_DeleteServiceAction_611595(
    name: "deleteServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction",
    validator: validate_DeleteServiceAction_611596, base: "/",
    url: url_DeleteServiceAction_611597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTagOption_611610 = ref object of OpenApiRestCall_610658
proc url_DeleteTagOption_611612(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTagOption_611611(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611613 = header.getOrDefault("X-Amz-Target")
  valid_611613 = validateParameter(valid_611613, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DeleteTagOption"))
  if valid_611613 != nil:
    section.add "X-Amz-Target", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_DeleteTagOption_611610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_DeleteTagOption_611610; body: JsonNode): Recallable =
  ## deleteTagOption
  ## <p>Deletes the specified TagOption.</p> <p>You cannot delete a TagOption if it is associated with a product or portfolio.</p>
  ##   body: JObject (required)
  var body_611624 = newJObject()
  if body != nil:
    body_611624 = body
  result = call_611623.call(nil, nil, nil, nil, body_611624)

var deleteTagOption* = Call_DeleteTagOption_611610(name: "deleteTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption",
    validator: validate_DeleteTagOption_611611, base: "/", url: url_DeleteTagOption_611612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConstraint_611625 = ref object of OpenApiRestCall_610658
proc url_DescribeConstraint_611627(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConstraint_611626(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611628 = header.getOrDefault("X-Amz-Target")
  valid_611628 = validateParameter(valid_611628, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeConstraint"))
  if valid_611628 != nil:
    section.add "X-Amz-Target", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611637: Call_DescribeConstraint_611625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified constraint.
  ## 
  let valid = call_611637.validator(path, query, header, formData, body)
  let scheme = call_611637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611637.url(scheme.get, call_611637.host, call_611637.base,
                         call_611637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611637, url, valid)

proc call*(call_611638: Call_DescribeConstraint_611625; body: JsonNode): Recallable =
  ## describeConstraint
  ## Gets information about the specified constraint.
  ##   body: JObject (required)
  var body_611639 = newJObject()
  if body != nil:
    body_611639 = body
  result = call_611638.call(nil, nil, nil, nil, body_611639)

var describeConstraint* = Call_DescribeConstraint_611625(
    name: "describeConstraint", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint",
    validator: validate_DescribeConstraint_611626, base: "/",
    url: url_DescribeConstraint_611627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyProductStatus_611640 = ref object of OpenApiRestCall_610658
proc url_DescribeCopyProductStatus_611642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCopyProductStatus_611641(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611643 = header.getOrDefault("X-Amz-Target")
  valid_611643 = validateParameter(valid_611643, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeCopyProductStatus"))
  if valid_611643 != nil:
    section.add "X-Amz-Target", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Signature")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Signature", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Content-Sha256", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Date")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Date", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Credential")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Credential", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Security-Token")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Security-Token", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Algorithm")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Algorithm", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-SignedHeaders", valid_611650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611652: Call_DescribeCopyProductStatus_611640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified copy product operation.
  ## 
  let valid = call_611652.validator(path, query, header, formData, body)
  let scheme = call_611652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611652.url(scheme.get, call_611652.host, call_611652.base,
                         call_611652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611652, url, valid)

proc call*(call_611653: Call_DescribeCopyProductStatus_611640; body: JsonNode): Recallable =
  ## describeCopyProductStatus
  ## Gets the status of the specified copy product operation.
  ##   body: JObject (required)
  var body_611654 = newJObject()
  if body != nil:
    body_611654 = body
  result = call_611653.call(nil, nil, nil, nil, body_611654)

var describeCopyProductStatus* = Call_DescribeCopyProductStatus_611640(
    name: "describeCopyProductStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus",
    validator: validate_DescribeCopyProductStatus_611641, base: "/",
    url: url_DescribeCopyProductStatus_611642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolio_611655 = ref object of OpenApiRestCall_610658
proc url_DescribePortfolio_611657(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolio_611656(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611658 = header.getOrDefault("X-Amz-Target")
  valid_611658 = validateParameter(valid_611658, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolio"))
  if valid_611658 != nil:
    section.add "X-Amz-Target", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Signature")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Signature", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Content-Sha256", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Date")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Date", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Credential")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Credential", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Security-Token")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Security-Token", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Algorithm")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Algorithm", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-SignedHeaders", valid_611665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_DescribePortfolio_611655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified portfolio.
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_DescribePortfolio_611655; body: JsonNode): Recallable =
  ## describePortfolio
  ## Gets information about the specified portfolio.
  ##   body: JObject (required)
  var body_611669 = newJObject()
  if body != nil:
    body_611669 = body
  result = call_611668.call(nil, nil, nil, nil, body_611669)

var describePortfolio* = Call_DescribePortfolio_611655(name: "describePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio",
    validator: validate_DescribePortfolio_611656, base: "/",
    url: url_DescribePortfolio_611657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePortfolioShareStatus_611670 = ref object of OpenApiRestCall_610658
proc url_DescribePortfolioShareStatus_611672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePortfolioShareStatus_611671(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611673 = header.getOrDefault("X-Amz-Target")
  valid_611673 = validateParameter(valid_611673, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribePortfolioShareStatus"))
  if valid_611673 != nil:
    section.add "X-Amz-Target", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Signature")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Signature", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Content-Sha256", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Date")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Date", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Credential")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Credential", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Security-Token")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Security-Token", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Algorithm")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Algorithm", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-SignedHeaders", valid_611680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611682: Call_DescribePortfolioShareStatus_611670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ## 
  let valid = call_611682.validator(path, query, header, formData, body)
  let scheme = call_611682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611682.url(scheme.get, call_611682.host, call_611682.base,
                         call_611682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611682, url, valid)

proc call*(call_611683: Call_DescribePortfolioShareStatus_611670; body: JsonNode): Recallable =
  ## describePortfolioShareStatus
  ## Gets the status of the specified portfolio share operation. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_611684 = newJObject()
  if body != nil:
    body_611684 = body
  result = call_611683.call(nil, nil, nil, nil, body_611684)

var describePortfolioShareStatus* = Call_DescribePortfolioShareStatus_611670(
    name: "describePortfolioShareStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus",
    validator: validate_DescribePortfolioShareStatus_611671, base: "/",
    url: url_DescribePortfolioShareStatus_611672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProduct_611685 = ref object of OpenApiRestCall_610658
proc url_DescribeProduct_611687(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProduct_611686(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611688 = header.getOrDefault("X-Amz-Target")
  valid_611688 = validateParameter(valid_611688, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProduct"))
  if valid_611688 != nil:
    section.add "X-Amz-Target", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Signature")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Signature", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Content-Sha256", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Date")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Date", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Credential")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Credential", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_DescribeProduct_611685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_DescribeProduct_611685; body: JsonNode): Recallable =
  ## describeProduct
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_611699 = newJObject()
  if body != nil:
    body_611699 = body
  result = call_611698.call(nil, nil, nil, nil, body_611699)

var describeProduct* = Call_DescribeProduct_611685(name: "describeProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct",
    validator: validate_DescribeProduct_611686, base: "/", url: url_DescribeProduct_611687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductAsAdmin_611700 = ref object of OpenApiRestCall_610658
proc url_DescribeProductAsAdmin_611702(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductAsAdmin_611701(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611703 = header.getOrDefault("X-Amz-Target")
  valid_611703 = validateParameter(valid_611703, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductAsAdmin"))
  if valid_611703 != nil:
    section.add "X-Amz-Target", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Signature")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Signature", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Content-Sha256", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Date")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Date", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Credential")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Credential", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Security-Token")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Security-Token", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Algorithm")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Algorithm", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-SignedHeaders", valid_611710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_DescribeProductAsAdmin_611700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product. This operation is run with administrator access.
  ## 
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_DescribeProductAsAdmin_611700; body: JsonNode): Recallable =
  ## describeProductAsAdmin
  ## Gets information about the specified product. This operation is run with administrator access.
  ##   body: JObject (required)
  var body_611714 = newJObject()
  if body != nil:
    body_611714 = body
  result = call_611713.call(nil, nil, nil, nil, body_611714)

var describeProductAsAdmin* = Call_DescribeProductAsAdmin_611700(
    name: "describeProductAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin",
    validator: validate_DescribeProductAsAdmin_611701, base: "/",
    url: url_DescribeProductAsAdmin_611702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProductView_611715 = ref object of OpenApiRestCall_610658
proc url_DescribeProductView_611717(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProductView_611716(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611718 = header.getOrDefault("X-Amz-Target")
  valid_611718 = validateParameter(valid_611718, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProductView"))
  if valid_611718 != nil:
    section.add "X-Amz-Target", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Security-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Security-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Algorithm")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Algorithm", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-SignedHeaders", valid_611725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611727: Call_DescribeProductView_611715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified product.
  ## 
  let valid = call_611727.validator(path, query, header, formData, body)
  let scheme = call_611727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611727.url(scheme.get, call_611727.host, call_611727.base,
                         call_611727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611727, url, valid)

proc call*(call_611728: Call_DescribeProductView_611715; body: JsonNode): Recallable =
  ## describeProductView
  ## Gets information about the specified product.
  ##   body: JObject (required)
  var body_611729 = newJObject()
  if body != nil:
    body_611729 = body
  result = call_611728.call(nil, nil, nil, nil, body_611729)

var describeProductView* = Call_DescribeProductView_611715(
    name: "describeProductView", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView",
    validator: validate_DescribeProductView_611716, base: "/",
    url: url_DescribeProductView_611717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProduct_611730 = ref object of OpenApiRestCall_610658
proc url_DescribeProvisionedProduct_611732(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProduct_611731(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611733 = header.getOrDefault("X-Amz-Target")
  valid_611733 = validateParameter(valid_611733, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProduct"))
  if valid_611733 != nil:
    section.add "X-Amz-Target", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Signature")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Signature", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Content-Sha256", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Date")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Date", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Credential")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Credential", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Security-Token")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Security-Token", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Algorithm")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Algorithm", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-SignedHeaders", valid_611740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611742: Call_DescribeProvisionedProduct_611730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioned product.
  ## 
  let valid = call_611742.validator(path, query, header, formData, body)
  let scheme = call_611742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611742.url(scheme.get, call_611742.host, call_611742.base,
                         call_611742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611742, url, valid)

proc call*(call_611743: Call_DescribeProvisionedProduct_611730; body: JsonNode): Recallable =
  ## describeProvisionedProduct
  ## Gets information about the specified provisioned product.
  ##   body: JObject (required)
  var body_611744 = newJObject()
  if body != nil:
    body_611744 = body
  result = call_611743.call(nil, nil, nil, nil, body_611744)

var describeProvisionedProduct* = Call_DescribeProvisionedProduct_611730(
    name: "describeProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct",
    validator: validate_DescribeProvisionedProduct_611731, base: "/",
    url: url_DescribeProvisionedProduct_611732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisionedProductPlan_611745 = ref object of OpenApiRestCall_610658
proc url_DescribeProvisionedProductPlan_611747(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisionedProductPlan_611746(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611748 = header.getOrDefault("X-Amz-Target")
  valid_611748 = validateParameter(valid_611748, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisionedProductPlan"))
  if valid_611748 != nil:
    section.add "X-Amz-Target", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Signature")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Signature", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Content-Sha256", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Date")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Date", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Credential")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Credential", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Security-Token")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Security-Token", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Algorithm")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Algorithm", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-SignedHeaders", valid_611755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611757: Call_DescribeProvisionedProductPlan_611745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the resource changes for the specified plan.
  ## 
  let valid = call_611757.validator(path, query, header, formData, body)
  let scheme = call_611757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611757.url(scheme.get, call_611757.host, call_611757.base,
                         call_611757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611757, url, valid)

proc call*(call_611758: Call_DescribeProvisionedProductPlan_611745; body: JsonNode): Recallable =
  ## describeProvisionedProductPlan
  ## Gets information about the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_611759 = newJObject()
  if body != nil:
    body_611759 = body
  result = call_611758.call(nil, nil, nil, nil, body_611759)

var describeProvisionedProductPlan* = Call_DescribeProvisionedProductPlan_611745(
    name: "describeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan",
    validator: validate_DescribeProvisionedProductPlan_611746, base: "/",
    url: url_DescribeProvisionedProductPlan_611747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningArtifact_611760 = ref object of OpenApiRestCall_610658
proc url_DescribeProvisioningArtifact_611762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningArtifact_611761(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611763 = header.getOrDefault("X-Amz-Target")
  valid_611763 = validateParameter(valid_611763, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningArtifact"))
  if valid_611763 != nil:
    section.add "X-Amz-Target", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611772: Call_DescribeProvisioningArtifact_611760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ## 
  let valid = call_611772.validator(path, query, header, formData, body)
  let scheme = call_611772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611772.url(scheme.get, call_611772.host, call_611772.base,
                         call_611772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611772, url, valid)

proc call*(call_611773: Call_DescribeProvisioningArtifact_611760; body: JsonNode): Recallable =
  ## describeProvisioningArtifact
  ## Gets information about the specified provisioning artifact (also known as a version) for the specified product.
  ##   body: JObject (required)
  var body_611774 = newJObject()
  if body != nil:
    body_611774 = body
  result = call_611773.call(nil, nil, nil, nil, body_611774)

var describeProvisioningArtifact* = Call_DescribeProvisioningArtifact_611760(
    name: "describeProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact",
    validator: validate_DescribeProvisioningArtifact_611761, base: "/",
    url: url_DescribeProvisioningArtifact_611762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProvisioningParameters_611775 = ref object of OpenApiRestCall_610658
proc url_DescribeProvisioningParameters_611777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProvisioningParameters_611776(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611778 = header.getOrDefault("X-Amz-Target")
  valid_611778 = validateParameter(valid_611778, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeProvisioningParameters"))
  if valid_611778 != nil:
    section.add "X-Amz-Target", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Signature")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Signature", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Content-Sha256", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Date")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Date", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Credential")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Credential", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Security-Token")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Security-Token", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Algorithm")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Algorithm", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-SignedHeaders", valid_611785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611787: Call_DescribeProvisioningParameters_611775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ## 
  let valid = call_611787.validator(path, query, header, formData, body)
  let scheme = call_611787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611787.url(scheme.get, call_611787.host, call_611787.base,
                         call_611787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611787, url, valid)

proc call*(call_611788: Call_DescribeProvisioningParameters_611775; body: JsonNode): Recallable =
  ## describeProvisioningParameters
  ## <p>Gets information about the configuration required to provision the specified product using the specified provisioning artifact.</p> <p>If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to <a>ProvisionProduct</a>, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>". Tag the provisioned product with the value <code>sc-tagoption-conflict-portfolioId-productId</code>.</p>
  ##   body: JObject (required)
  var body_611789 = newJObject()
  if body != nil:
    body_611789 = body
  result = call_611788.call(nil, nil, nil, nil, body_611789)

var describeProvisioningParameters* = Call_DescribeProvisioningParameters_611775(
    name: "describeProvisioningParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters",
    validator: validate_DescribeProvisioningParameters_611776, base: "/",
    url: url_DescribeProvisioningParameters_611777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecord_611790 = ref object of OpenApiRestCall_610658
proc url_DescribeRecord_611792(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRecord_611791(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611793 = header.getOrDefault("X-Amz-Target")
  valid_611793 = validateParameter(valid_611793, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeRecord"))
  if valid_611793 != nil:
    section.add "X-Amz-Target", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Signature")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Signature", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Content-Sha256", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Date")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Date", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Credential")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Credential", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Security-Token")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Security-Token", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Algorithm")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Algorithm", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-SignedHeaders", valid_611800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611802: Call_DescribeRecord_611790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ## 
  let valid = call_611802.validator(path, query, header, formData, body)
  let scheme = call_611802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611802.url(scheme.get, call_611802.host, call_611802.base,
                         call_611802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611802, url, valid)

proc call*(call_611803: Call_DescribeRecord_611790; body: JsonNode): Recallable =
  ## describeRecord
  ## <p>Gets information about the specified request operation.</p> <p>Use this operation after calling a request operation (for example, <a>ProvisionProduct</a>, <a>TerminateProvisionedProduct</a>, or <a>UpdateProvisionedProduct</a>). </p> <note> <p>If a provisioned product was transferred to a new owner using <a>UpdateProvisionedProductProperties</a>, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use <a>ListRecordHistory</a> to see the product's history from when he was the owner.</p> </note>
  ##   body: JObject (required)
  var body_611804 = newJObject()
  if body != nil:
    body_611804 = body
  result = call_611803.call(nil, nil, nil, nil, body_611804)

var describeRecord* = Call_DescribeRecord_611790(name: "describeRecord",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord",
    validator: validate_DescribeRecord_611791, base: "/", url: url_DescribeRecord_611792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceAction_611805 = ref object of OpenApiRestCall_610658
proc url_DescribeServiceAction_611807(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceAction_611806(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611808 = header.getOrDefault("X-Amz-Target")
  valid_611808 = validateParameter(valid_611808, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceAction"))
  if valid_611808 != nil:
    section.add "X-Amz-Target", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Signature")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Signature", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Content-Sha256", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Date")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Date", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Credential")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Credential", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Security-Token")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Security-Token", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Algorithm")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Algorithm", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-SignedHeaders", valid_611815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_DescribeServiceAction_611805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a self-service action.
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_DescribeServiceAction_611805; body: JsonNode): Recallable =
  ## describeServiceAction
  ## Describes a self-service action.
  ##   body: JObject (required)
  var body_611819 = newJObject()
  if body != nil:
    body_611819 = body
  result = call_611818.call(nil, nil, nil, nil, body_611819)

var describeServiceAction* = Call_DescribeServiceAction_611805(
    name: "describeServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction",
    validator: validate_DescribeServiceAction_611806, base: "/",
    url: url_DescribeServiceAction_611807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServiceActionExecutionParameters_611820 = ref object of OpenApiRestCall_610658
proc url_DescribeServiceActionExecutionParameters_611822(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServiceActionExecutionParameters_611821(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_611823 = header.getOrDefault("X-Amz-Target")
  valid_611823 = validateParameter(valid_611823, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"))
  if valid_611823 != nil:
    section.add "X-Amz-Target", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Signature")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Signature", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Content-Sha256", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Date")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Date", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Credential")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Credential", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Security-Token")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Security-Token", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Algorithm")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Algorithm", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-SignedHeaders", valid_611830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611832: Call_DescribeServiceActionExecutionParameters_611820;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_611832.validator(path, query, header, formData, body)
  let scheme = call_611832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611832.url(scheme.get, call_611832.host, call_611832.base,
                         call_611832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611832, url, valid)

proc call*(call_611833: Call_DescribeServiceActionExecutionParameters_611820;
          body: JsonNode): Recallable =
  ## describeServiceActionExecutionParameters
  ##   body: JObject (required)
  var body_611834 = newJObject()
  if body != nil:
    body_611834 = body
  result = call_611833.call(nil, nil, nil, nil, body_611834)

var describeServiceActionExecutionParameters* = Call_DescribeServiceActionExecutionParameters_611820(
    name: "describeServiceActionExecutionParameters", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters",
    validator: validate_DescribeServiceActionExecutionParameters_611821,
    base: "/", url: url_DescribeServiceActionExecutionParameters_611822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTagOption_611835 = ref object of OpenApiRestCall_610658
proc url_DescribeTagOption_611837(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTagOption_611836(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611838 = header.getOrDefault("X-Amz-Target")
  valid_611838 = validateParameter(valid_611838, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DescribeTagOption"))
  if valid_611838 != nil:
    section.add "X-Amz-Target", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Signature")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Signature", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Content-Sha256", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Date")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Date", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Credential")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Credential", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Security-Token")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Security-Token", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Algorithm")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Algorithm", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-SignedHeaders", valid_611845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_DescribeTagOption_611835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified TagOption.
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_DescribeTagOption_611835; body: JsonNode): Recallable =
  ## describeTagOption
  ## Gets information about the specified TagOption.
  ##   body: JObject (required)
  var body_611849 = newJObject()
  if body != nil:
    body_611849 = body
  result = call_611848.call(nil, nil, nil, nil, body_611849)

var describeTagOption* = Call_DescribeTagOption_611835(name: "describeTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption",
    validator: validate_DescribeTagOption_611836, base: "/",
    url: url_DescribeTagOption_611837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableAWSOrganizationsAccess_611850 = ref object of OpenApiRestCall_610658
proc url_DisableAWSOrganizationsAccess_611852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableAWSOrganizationsAccess_611851(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611853 = header.getOrDefault("X-Amz-Target")
  valid_611853 = validateParameter(valid_611853, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"))
  if valid_611853 != nil:
    section.add "X-Amz-Target", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_DisableAWSOrganizationsAccess_611850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_DisableAWSOrganizationsAccess_611850; body: JsonNode): Recallable =
  ## disableAWSOrganizationsAccess
  ## Disable portfolio sharing through AWS Organizations feature. This feature will not delete your current shares but it will prevent you from creating new shares throughout your organization. Current shares will not be in sync with your organization structure if it changes after calling this API. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_611864 = newJObject()
  if body != nil:
    body_611864 = body
  result = call_611863.call(nil, nil, nil, nil, body_611864)

var disableAWSOrganizationsAccess* = Call_DisableAWSOrganizationsAccess_611850(
    name: "disableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess",
    validator: validate_DisableAWSOrganizationsAccess_611851, base: "/",
    url: url_DisableAWSOrganizationsAccess_611852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateBudgetFromResource_611865 = ref object of OpenApiRestCall_610658
proc url_DisassociateBudgetFromResource_611867(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateBudgetFromResource_611866(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611868 = header.getOrDefault("X-Amz-Target")
  valid_611868 = validateParameter(valid_611868, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateBudgetFromResource"))
  if valid_611868 != nil:
    section.add "X-Amz-Target", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Signature")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Signature", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Content-Sha256", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Date")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Date", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Credential")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Credential", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Security-Token")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Security-Token", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Algorithm")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Algorithm", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-SignedHeaders", valid_611875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611877: Call_DisassociateBudgetFromResource_611865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified budget from the specified resource.
  ## 
  let valid = call_611877.validator(path, query, header, formData, body)
  let scheme = call_611877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611877.url(scheme.get, call_611877.host, call_611877.base,
                         call_611877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611877, url, valid)

proc call*(call_611878: Call_DisassociateBudgetFromResource_611865; body: JsonNode): Recallable =
  ## disassociateBudgetFromResource
  ## Disassociates the specified budget from the specified resource.
  ##   body: JObject (required)
  var body_611879 = newJObject()
  if body != nil:
    body_611879 = body
  result = call_611878.call(nil, nil, nil, nil, body_611879)

var disassociateBudgetFromResource* = Call_DisassociateBudgetFromResource_611865(
    name: "disassociateBudgetFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource",
    validator: validate_DisassociateBudgetFromResource_611866, base: "/",
    url: url_DisassociateBudgetFromResource_611867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociatePrincipalFromPortfolio_611880 = ref object of OpenApiRestCall_610658
proc url_DisassociatePrincipalFromPortfolio_611882(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociatePrincipalFromPortfolio_611881(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611883 = header.getOrDefault("X-Amz-Target")
  valid_611883 = validateParameter(valid_611883, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"))
  if valid_611883 != nil:
    section.add "X-Amz-Target", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Signature")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Signature", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Content-Sha256", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Date")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Date", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Credential")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Credential", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Security-Token")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Security-Token", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Algorithm")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Algorithm", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-SignedHeaders", valid_611890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611892: Call_DisassociatePrincipalFromPortfolio_611880;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ## 
  let valid = call_611892.validator(path, query, header, formData, body)
  let scheme = call_611892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611892.url(scheme.get, call_611892.host, call_611892.base,
                         call_611892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611892, url, valid)

proc call*(call_611893: Call_DisassociatePrincipalFromPortfolio_611880;
          body: JsonNode): Recallable =
  ## disassociatePrincipalFromPortfolio
  ## Disassociates a previously associated principal ARN from a specified portfolio.
  ##   body: JObject (required)
  var body_611894 = newJObject()
  if body != nil:
    body_611894 = body
  result = call_611893.call(nil, nil, nil, nil, body_611894)

var disassociatePrincipalFromPortfolio* = Call_DisassociatePrincipalFromPortfolio_611880(
    name: "disassociatePrincipalFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio",
    validator: validate_DisassociatePrincipalFromPortfolio_611881, base: "/",
    url: url_DisassociatePrincipalFromPortfolio_611882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateProductFromPortfolio_611895 = ref object of OpenApiRestCall_610658
proc url_DisassociateProductFromPortfolio_611897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateProductFromPortfolio_611896(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611898 = header.getOrDefault("X-Amz-Target")
  valid_611898 = validateParameter(valid_611898, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateProductFromPortfolio"))
  if valid_611898 != nil:
    section.add "X-Amz-Target", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611907: Call_DisassociateProductFromPortfolio_611895;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified product from the specified portfolio. 
  ## 
  let valid = call_611907.validator(path, query, header, formData, body)
  let scheme = call_611907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611907.url(scheme.get, call_611907.host, call_611907.base,
                         call_611907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611907, url, valid)

proc call*(call_611908: Call_DisassociateProductFromPortfolio_611895;
          body: JsonNode): Recallable =
  ## disassociateProductFromPortfolio
  ## Disassociates the specified product from the specified portfolio. 
  ##   body: JObject (required)
  var body_611909 = newJObject()
  if body != nil:
    body_611909 = body
  result = call_611908.call(nil, nil, nil, nil, body_611909)

var disassociateProductFromPortfolio* = Call_DisassociateProductFromPortfolio_611895(
    name: "disassociateProductFromPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio",
    validator: validate_DisassociateProductFromPortfolio_611896, base: "/",
    url: url_DisassociateProductFromPortfolio_611897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateServiceActionFromProvisioningArtifact_611910 = ref object of OpenApiRestCall_610658
proc url_DisassociateServiceActionFromProvisioningArtifact_611912(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateServiceActionFromProvisioningArtifact_611911(
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611913 = header.getOrDefault("X-Amz-Target")
  valid_611913 = validateParameter(valid_611913, JString, required = true, default = newJString("AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"))
  if valid_611913 != nil:
    section.add "X-Amz-Target", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Signature")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Signature", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Content-Sha256", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Date")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Date", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Credential")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Credential", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Security-Token")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Security-Token", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Algorithm")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Algorithm", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-SignedHeaders", valid_611920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611922: Call_DisassociateServiceActionFromProvisioningArtifact_611910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ## 
  let valid = call_611922.validator(path, query, header, formData, body)
  let scheme = call_611922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611922.url(scheme.get, call_611922.host, call_611922.base,
                         call_611922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611922, url, valid)

proc call*(call_611923: Call_DisassociateServiceActionFromProvisioningArtifact_611910;
          body: JsonNode): Recallable =
  ## disassociateServiceActionFromProvisioningArtifact
  ## Disassociates the specified self-service action association from the specified provisioning artifact.
  ##   body: JObject (required)
  var body_611924 = newJObject()
  if body != nil:
    body_611924 = body
  result = call_611923.call(nil, nil, nil, nil, body_611924)

var disassociateServiceActionFromProvisioningArtifact* = Call_DisassociateServiceActionFromProvisioningArtifact_611910(
    name: "disassociateServiceActionFromProvisioningArtifact",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact",
    validator: validate_DisassociateServiceActionFromProvisioningArtifact_611911,
    base: "/", url: url_DisassociateServiceActionFromProvisioningArtifact_611912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTagOptionFromResource_611925 = ref object of OpenApiRestCall_610658
proc url_DisassociateTagOptionFromResource_611927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTagOptionFromResource_611926(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611928 = header.getOrDefault("X-Amz-Target")
  valid_611928 = validateParameter(valid_611928, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.DisassociateTagOptionFromResource"))
  if valid_611928 != nil:
    section.add "X-Amz-Target", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Signature")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Signature", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Content-Sha256", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Date")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Date", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Credential")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Credential", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Security-Token")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Security-Token", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Algorithm")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Algorithm", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-SignedHeaders", valid_611935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611937: Call_DisassociateTagOptionFromResource_611925;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates the specified TagOption from the specified resource.
  ## 
  let valid = call_611937.validator(path, query, header, formData, body)
  let scheme = call_611937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611937.url(scheme.get, call_611937.host, call_611937.base,
                         call_611937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611937, url, valid)

proc call*(call_611938: Call_DisassociateTagOptionFromResource_611925;
          body: JsonNode): Recallable =
  ## disassociateTagOptionFromResource
  ## Disassociates the specified TagOption from the specified resource.
  ##   body: JObject (required)
  var body_611939 = newJObject()
  if body != nil:
    body_611939 = body
  result = call_611938.call(nil, nil, nil, nil, body_611939)

var disassociateTagOptionFromResource* = Call_DisassociateTagOptionFromResource_611925(
    name: "disassociateTagOptionFromResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource",
    validator: validate_DisassociateTagOptionFromResource_611926, base: "/",
    url: url_DisassociateTagOptionFromResource_611927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableAWSOrganizationsAccess_611940 = ref object of OpenApiRestCall_610658
proc url_EnableAWSOrganizationsAccess_611942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableAWSOrganizationsAccess_611941(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611943 = header.getOrDefault("X-Amz-Target")
  valid_611943 = validateParameter(valid_611943, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"))
  if valid_611943 != nil:
    section.add "X-Amz-Target", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Signature")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Signature", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Content-Sha256", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Date")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Date", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Credential")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Credential", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Security-Token")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Security-Token", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Algorithm")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Algorithm", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-SignedHeaders", valid_611950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611952: Call_EnableAWSOrganizationsAccess_611940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ## 
  let valid = call_611952.validator(path, query, header, formData, body)
  let scheme = call_611952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611952.url(scheme.get, call_611952.host, call_611952.base,
                         call_611952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611952, url, valid)

proc call*(call_611953: Call_EnableAWSOrganizationsAccess_611940; body: JsonNode): Recallable =
  ## enableAWSOrganizationsAccess
  ## <p>Enable portfolio sharing feature through AWS Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the master account in the organization.</p> <p>By calling this API Service Catalog will make a call to organizations:EnableAWSServiceAccess on your behalf so that your shares can be in sync with any changes in your AWS Organizations structure.</p>
  ##   body: JObject (required)
  var body_611954 = newJObject()
  if body != nil:
    body_611954 = body
  result = call_611953.call(nil, nil, nil, nil, body_611954)

var enableAWSOrganizationsAccess* = Call_EnableAWSOrganizationsAccess_611940(
    name: "enableAWSOrganizationsAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess",
    validator: validate_EnableAWSOrganizationsAccess_611941, base: "/",
    url: url_EnableAWSOrganizationsAccess_611942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductPlan_611955 = ref object of OpenApiRestCall_610658
proc url_ExecuteProvisionedProductPlan_611957(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductPlan_611956(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611958 = header.getOrDefault("X-Amz-Target")
  valid_611958 = validateParameter(valid_611958, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"))
  if valid_611958 != nil:
    section.add "X-Amz-Target", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611967: Call_ExecuteProvisionedProductPlan_611955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ## 
  let valid = call_611967.validator(path, query, header, formData, body)
  let scheme = call_611967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611967.url(scheme.get, call_611967.host, call_611967.base,
                         call_611967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611967, url, valid)

proc call*(call_611968: Call_ExecuteProvisionedProductPlan_611955; body: JsonNode): Recallable =
  ## executeProvisionedProductPlan
  ## Provisions or modifies a product based on the resource changes for the specified plan.
  ##   body: JObject (required)
  var body_611969 = newJObject()
  if body != nil:
    body_611969 = body
  result = call_611968.call(nil, nil, nil, nil, body_611969)

var executeProvisionedProductPlan* = Call_ExecuteProvisionedProductPlan_611955(
    name: "executeProvisionedProductPlan", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan",
    validator: validate_ExecuteProvisionedProductPlan_611956, base: "/",
    url: url_ExecuteProvisionedProductPlan_611957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExecuteProvisionedProductServiceAction_611970 = ref object of OpenApiRestCall_610658
proc url_ExecuteProvisionedProductServiceAction_611972(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExecuteProvisionedProductServiceAction_611971(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611973 = header.getOrDefault("X-Amz-Target")
  valid_611973 = validateParameter(valid_611973, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"))
  if valid_611973 != nil:
    section.add "X-Amz-Target", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Signature")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Signature", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Content-Sha256", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Date")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Date", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Credential")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Credential", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Security-Token")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Security-Token", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Algorithm")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Algorithm", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-SignedHeaders", valid_611980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611982: Call_ExecuteProvisionedProductServiceAction_611970;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Executes a self-service action against a provisioned product.
  ## 
  let valid = call_611982.validator(path, query, header, formData, body)
  let scheme = call_611982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611982.url(scheme.get, call_611982.host, call_611982.base,
                         call_611982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611982, url, valid)

proc call*(call_611983: Call_ExecuteProvisionedProductServiceAction_611970;
          body: JsonNode): Recallable =
  ## executeProvisionedProductServiceAction
  ## Executes a self-service action against a provisioned product.
  ##   body: JObject (required)
  var body_611984 = newJObject()
  if body != nil:
    body_611984 = body
  result = call_611983.call(nil, nil, nil, nil, body_611984)

var executeProvisionedProductServiceAction* = Call_ExecuteProvisionedProductServiceAction_611970(
    name: "executeProvisionedProductServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction",
    validator: validate_ExecuteProvisionedProductServiceAction_611971, base: "/",
    url: url_ExecuteProvisionedProductServiceAction_611972,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAWSOrganizationsAccessStatus_611985 = ref object of OpenApiRestCall_610658
proc url_GetAWSOrganizationsAccessStatus_611987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAWSOrganizationsAccessStatus_611986(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611988 = header.getOrDefault("X-Amz-Target")
  valid_611988 = validateParameter(valid_611988, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"))
  if valid_611988 != nil:
    section.add "X-Amz-Target", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Signature")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Signature", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Content-Sha256", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Date")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Date", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Credential")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Credential", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Security-Token")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Security-Token", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Algorithm")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Algorithm", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-SignedHeaders", valid_611995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_GetAWSOrganizationsAccessStatus_611985;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_GetAWSOrganizationsAccessStatus_611985; body: JsonNode): Recallable =
  ## getAWSOrganizationsAccessStatus
  ## Get the Access Status for AWS Organization portfolio share feature. This API can only be called by the master account in the organization.
  ##   body: JObject (required)
  var body_611999 = newJObject()
  if body != nil:
    body_611999 = body
  result = call_611998.call(nil, nil, nil, nil, body_611999)

var getAWSOrganizationsAccessStatus* = Call_GetAWSOrganizationsAccessStatus_611985(
    name: "getAWSOrganizationsAccessStatus", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus",
    validator: validate_GetAWSOrganizationsAccessStatus_611986, base: "/",
    url: url_GetAWSOrganizationsAccessStatus_611987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAcceptedPortfolioShares_612000 = ref object of OpenApiRestCall_610658
proc url_ListAcceptedPortfolioShares_612002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAcceptedPortfolioShares_612001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612003 = query.getOrDefault("PageToken")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "PageToken", valid_612003
  var valid_612004 = query.getOrDefault("PageSize")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "PageSize", valid_612004
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
  var valid_612005 = header.getOrDefault("X-Amz-Target")
  valid_612005 = validateParameter(valid_612005, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListAcceptedPortfolioShares"))
  if valid_612005 != nil:
    section.add "X-Amz-Target", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Signature")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Signature", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Content-Sha256", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Date")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Date", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Credential")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Credential", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Security-Token")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Security-Token", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Algorithm")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Algorithm", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-SignedHeaders", valid_612012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612014: Call_ListAcceptedPortfolioShares_612000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios for which sharing was accepted by this account.
  ## 
  let valid = call_612014.validator(path, query, header, formData, body)
  let scheme = call_612014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612014.url(scheme.get, call_612014.host, call_612014.base,
                         call_612014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612014, url, valid)

proc call*(call_612015: Call_ListAcceptedPortfolioShares_612000; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listAcceptedPortfolioShares
  ## Lists all portfolios for which sharing was accepted by this account.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612016 = newJObject()
  var body_612017 = newJObject()
  add(query_612016, "PageToken", newJString(PageToken))
  add(query_612016, "PageSize", newJString(PageSize))
  if body != nil:
    body_612017 = body
  result = call_612015.call(nil, query_612016, nil, nil, body_612017)

var listAcceptedPortfolioShares* = Call_ListAcceptedPortfolioShares_612000(
    name: "listAcceptedPortfolioShares", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares",
    validator: validate_ListAcceptedPortfolioShares_612001, base: "/",
    url: url_ListAcceptedPortfolioShares_612002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBudgetsForResource_612019 = ref object of OpenApiRestCall_610658
proc url_ListBudgetsForResource_612021(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBudgetsForResource_612020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the budgets associated to the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612022 = query.getOrDefault("PageToken")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "PageToken", valid_612022
  var valid_612023 = query.getOrDefault("PageSize")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "PageSize", valid_612023
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
  var valid_612024 = header.getOrDefault("X-Amz-Target")
  valid_612024 = validateParameter(valid_612024, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListBudgetsForResource"))
  if valid_612024 != nil:
    section.add "X-Amz-Target", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Signature")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Signature", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Content-Sha256", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Date")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Date", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Credential")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Credential", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Security-Token")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Security-Token", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Algorithm")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Algorithm", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-SignedHeaders", valid_612031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612033: Call_ListBudgetsForResource_612019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the budgets associated to the specified resource.
  ## 
  let valid = call_612033.validator(path, query, header, formData, body)
  let scheme = call_612033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612033.url(scheme.get, call_612033.host, call_612033.base,
                         call_612033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612033, url, valid)

proc call*(call_612034: Call_ListBudgetsForResource_612019; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listBudgetsForResource
  ## Lists all the budgets associated to the specified resource.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612035 = newJObject()
  var body_612036 = newJObject()
  add(query_612035, "PageToken", newJString(PageToken))
  add(query_612035, "PageSize", newJString(PageSize))
  if body != nil:
    body_612036 = body
  result = call_612034.call(nil, query_612035, nil, nil, body_612036)

var listBudgetsForResource* = Call_ListBudgetsForResource_612019(
    name: "listBudgetsForResource", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource",
    validator: validate_ListBudgetsForResource_612020, base: "/",
    url: url_ListBudgetsForResource_612021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConstraintsForPortfolio_612037 = ref object of OpenApiRestCall_610658
proc url_ListConstraintsForPortfolio_612039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConstraintsForPortfolio_612038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612040 = query.getOrDefault("PageToken")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "PageToken", valid_612040
  var valid_612041 = query.getOrDefault("PageSize")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "PageSize", valid_612041
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
  var valid_612042 = header.getOrDefault("X-Amz-Target")
  valid_612042 = validateParameter(valid_612042, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListConstraintsForPortfolio"))
  if valid_612042 != nil:
    section.add "X-Amz-Target", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Signature")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Signature", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-Content-Sha256", valid_612044
  var valid_612045 = header.getOrDefault("X-Amz-Date")
  valid_612045 = validateParameter(valid_612045, JString, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "X-Amz-Date", valid_612045
  var valid_612046 = header.getOrDefault("X-Amz-Credential")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "X-Amz-Credential", valid_612046
  var valid_612047 = header.getOrDefault("X-Amz-Security-Token")
  valid_612047 = validateParameter(valid_612047, JString, required = false,
                                 default = nil)
  if valid_612047 != nil:
    section.add "X-Amz-Security-Token", valid_612047
  var valid_612048 = header.getOrDefault("X-Amz-Algorithm")
  valid_612048 = validateParameter(valid_612048, JString, required = false,
                                 default = nil)
  if valid_612048 != nil:
    section.add "X-Amz-Algorithm", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-SignedHeaders", valid_612049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612051: Call_ListConstraintsForPortfolio_612037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the constraints for the specified portfolio and product.
  ## 
  let valid = call_612051.validator(path, query, header, formData, body)
  let scheme = call_612051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612051.url(scheme.get, call_612051.host, call_612051.base,
                         call_612051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612051, url, valid)

proc call*(call_612052: Call_ListConstraintsForPortfolio_612037; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listConstraintsForPortfolio
  ## Lists the constraints for the specified portfolio and product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612053 = newJObject()
  var body_612054 = newJObject()
  add(query_612053, "PageToken", newJString(PageToken))
  add(query_612053, "PageSize", newJString(PageSize))
  if body != nil:
    body_612054 = body
  result = call_612052.call(nil, query_612053, nil, nil, body_612054)

var listConstraintsForPortfolio* = Call_ListConstraintsForPortfolio_612037(
    name: "listConstraintsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio",
    validator: validate_ListConstraintsForPortfolio_612038, base: "/",
    url: url_ListConstraintsForPortfolio_612039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLaunchPaths_612055 = ref object of OpenApiRestCall_610658
proc url_ListLaunchPaths_612057(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLaunchPaths_612056(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612058 = query.getOrDefault("PageToken")
  valid_612058 = validateParameter(valid_612058, JString, required = false,
                                 default = nil)
  if valid_612058 != nil:
    section.add "PageToken", valid_612058
  var valid_612059 = query.getOrDefault("PageSize")
  valid_612059 = validateParameter(valid_612059, JString, required = false,
                                 default = nil)
  if valid_612059 != nil:
    section.add "PageSize", valid_612059
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
  var valid_612060 = header.getOrDefault("X-Amz-Target")
  valid_612060 = validateParameter(valid_612060, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListLaunchPaths"))
  if valid_612060 != nil:
    section.add "X-Amz-Target", valid_612060
  var valid_612061 = header.getOrDefault("X-Amz-Signature")
  valid_612061 = validateParameter(valid_612061, JString, required = false,
                                 default = nil)
  if valid_612061 != nil:
    section.add "X-Amz-Signature", valid_612061
  var valid_612062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612062 = validateParameter(valid_612062, JString, required = false,
                                 default = nil)
  if valid_612062 != nil:
    section.add "X-Amz-Content-Sha256", valid_612062
  var valid_612063 = header.getOrDefault("X-Amz-Date")
  valid_612063 = validateParameter(valid_612063, JString, required = false,
                                 default = nil)
  if valid_612063 != nil:
    section.add "X-Amz-Date", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Credential")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Credential", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Security-Token")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Security-Token", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Algorithm")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Algorithm", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-SignedHeaders", valid_612067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612069: Call_ListLaunchPaths_612055; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ## 
  let valid = call_612069.validator(path, query, header, formData, body)
  let scheme = call_612069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612069.url(scheme.get, call_612069.host, call_612069.base,
                         call_612069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612069, url, valid)

proc call*(call_612070: Call_ListLaunchPaths_612055; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listLaunchPaths
  ## Lists the paths to the specified product. A path is how the user has access to a specified product, and is necessary when provisioning a product. A path also determines the constraints put on the product.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612071 = newJObject()
  var body_612072 = newJObject()
  add(query_612071, "PageToken", newJString(PageToken))
  add(query_612071, "PageSize", newJString(PageSize))
  if body != nil:
    body_612072 = body
  result = call_612070.call(nil, query_612071, nil, nil, body_612072)

var listLaunchPaths* = Call_ListLaunchPaths_612055(name: "listLaunchPaths",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths",
    validator: validate_ListLaunchPaths_612056, base: "/", url: url_ListLaunchPaths_612057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOrganizationPortfolioAccess_612073 = ref object of OpenApiRestCall_610658
proc url_ListOrganizationPortfolioAccess_612075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOrganizationPortfolioAccess_612074(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612076 = query.getOrDefault("PageToken")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "PageToken", valid_612076
  var valid_612077 = query.getOrDefault("PageSize")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "PageSize", valid_612077
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
  var valid_612078 = header.getOrDefault("X-Amz-Target")
  valid_612078 = validateParameter(valid_612078, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"))
  if valid_612078 != nil:
    section.add "X-Amz-Target", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Signature")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Signature", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Content-Sha256", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-Date")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-Date", valid_612081
  var valid_612082 = header.getOrDefault("X-Amz-Credential")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "X-Amz-Credential", valid_612082
  var valid_612083 = header.getOrDefault("X-Amz-Security-Token")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "X-Amz-Security-Token", valid_612083
  var valid_612084 = header.getOrDefault("X-Amz-Algorithm")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "X-Amz-Algorithm", valid_612084
  var valid_612085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-SignedHeaders", valid_612085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612087: Call_ListOrganizationPortfolioAccess_612073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ## 
  let valid = call_612087.validator(path, query, header, formData, body)
  let scheme = call_612087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612087.url(scheme.get, call_612087.host, call_612087.base,
                         call_612087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612087, url, valid)

proc call*(call_612088: Call_ListOrganizationPortfolioAccess_612073;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listOrganizationPortfolioAccess
  ## Lists the organization nodes that have access to the specified portfolio. This API can only be called by the master account in the organization.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612089 = newJObject()
  var body_612090 = newJObject()
  add(query_612089, "PageToken", newJString(PageToken))
  add(query_612089, "PageSize", newJString(PageSize))
  if body != nil:
    body_612090 = body
  result = call_612088.call(nil, query_612089, nil, nil, body_612090)

var listOrganizationPortfolioAccess* = Call_ListOrganizationPortfolioAccess_612073(
    name: "listOrganizationPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess",
    validator: validate_ListOrganizationPortfolioAccess_612074, base: "/",
    url: url_ListOrganizationPortfolioAccess_612075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolioAccess_612091 = ref object of OpenApiRestCall_610658
proc url_ListPortfolioAccess_612093(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolioAccess_612092(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612094 = header.getOrDefault("X-Amz-Target")
  valid_612094 = validateParameter(valid_612094, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolioAccess"))
  if valid_612094 != nil:
    section.add "X-Amz-Target", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Signature")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Signature", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Content-Sha256", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Date")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Date", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Credential")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Credential", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Security-Token")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Security-Token", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-Algorithm")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-Algorithm", valid_612100
  var valid_612101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612101 = validateParameter(valid_612101, JString, required = false,
                                 default = nil)
  if valid_612101 != nil:
    section.add "X-Amz-SignedHeaders", valid_612101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612103: Call_ListPortfolioAccess_612091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account IDs that have access to the specified portfolio.
  ## 
  let valid = call_612103.validator(path, query, header, formData, body)
  let scheme = call_612103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612103.url(scheme.get, call_612103.host, call_612103.base,
                         call_612103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612103, url, valid)

proc call*(call_612104: Call_ListPortfolioAccess_612091; body: JsonNode): Recallable =
  ## listPortfolioAccess
  ## Lists the account IDs that have access to the specified portfolio.
  ##   body: JObject (required)
  var body_612105 = newJObject()
  if body != nil:
    body_612105 = body
  result = call_612104.call(nil, nil, nil, nil, body_612105)

var listPortfolioAccess* = Call_ListPortfolioAccess_612091(
    name: "listPortfolioAccess", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess",
    validator: validate_ListPortfolioAccess_612092, base: "/",
    url: url_ListPortfolioAccess_612093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfolios_612106 = ref object of OpenApiRestCall_610658
proc url_ListPortfolios_612108(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfolios_612107(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all portfolios in the catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612109 = query.getOrDefault("PageToken")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "PageToken", valid_612109
  var valid_612110 = query.getOrDefault("PageSize")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "PageSize", valid_612110
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
  var valid_612111 = header.getOrDefault("X-Amz-Target")
  valid_612111 = validateParameter(valid_612111, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfolios"))
  if valid_612111 != nil:
    section.add "X-Amz-Target", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Signature")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Signature", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Content-Sha256", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Date")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Date", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Credential")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Credential", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Security-Token")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Security-Token", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Algorithm")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Algorithm", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-SignedHeaders", valid_612118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612120: Call_ListPortfolios_612106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios in the catalog.
  ## 
  let valid = call_612120.validator(path, query, header, formData, body)
  let scheme = call_612120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612120.url(scheme.get, call_612120.host, call_612120.base,
                         call_612120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612120, url, valid)

proc call*(call_612121: Call_ListPortfolios_612106; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfolios
  ## Lists all portfolios in the catalog.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612122 = newJObject()
  var body_612123 = newJObject()
  add(query_612122, "PageToken", newJString(PageToken))
  add(query_612122, "PageSize", newJString(PageSize))
  if body != nil:
    body_612123 = body
  result = call_612121.call(nil, query_612122, nil, nil, body_612123)

var listPortfolios* = Call_ListPortfolios_612106(name: "listPortfolios",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios",
    validator: validate_ListPortfolios_612107, base: "/", url: url_ListPortfolios_612108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPortfoliosForProduct_612124 = ref object of OpenApiRestCall_610658
proc url_ListPortfoliosForProduct_612126(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPortfoliosForProduct_612125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612127 = query.getOrDefault("PageToken")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "PageToken", valid_612127
  var valid_612128 = query.getOrDefault("PageSize")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "PageSize", valid_612128
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
  var valid_612129 = header.getOrDefault("X-Amz-Target")
  valid_612129 = validateParameter(valid_612129, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPortfoliosForProduct"))
  if valid_612129 != nil:
    section.add "X-Amz-Target", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Signature")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Signature", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Content-Sha256", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Date")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Date", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Credential")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Credential", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Security-Token")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Security-Token", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Algorithm")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Algorithm", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-SignedHeaders", valid_612136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612138: Call_ListPortfoliosForProduct_612124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all portfolios that the specified product is associated with.
  ## 
  let valid = call_612138.validator(path, query, header, formData, body)
  let scheme = call_612138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612138.url(scheme.get, call_612138.host, call_612138.base,
                         call_612138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612138, url, valid)

proc call*(call_612139: Call_ListPortfoliosForProduct_612124; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPortfoliosForProduct
  ## Lists all portfolios that the specified product is associated with.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612140 = newJObject()
  var body_612141 = newJObject()
  add(query_612140, "PageToken", newJString(PageToken))
  add(query_612140, "PageSize", newJString(PageSize))
  if body != nil:
    body_612141 = body
  result = call_612139.call(nil, query_612140, nil, nil, body_612141)

var listPortfoliosForProduct* = Call_ListPortfoliosForProduct_612124(
    name: "listPortfoliosForProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct",
    validator: validate_ListPortfoliosForProduct_612125, base: "/",
    url: url_ListPortfoliosForProduct_612126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPrincipalsForPortfolio_612142 = ref object of OpenApiRestCall_610658
proc url_ListPrincipalsForPortfolio_612144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPrincipalsForPortfolio_612143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612145 = query.getOrDefault("PageToken")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "PageToken", valid_612145
  var valid_612146 = query.getOrDefault("PageSize")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "PageSize", valid_612146
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
  var valid_612147 = header.getOrDefault("X-Amz-Target")
  valid_612147 = validateParameter(valid_612147, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListPrincipalsForPortfolio"))
  if valid_612147 != nil:
    section.add "X-Amz-Target", valid_612147
  var valid_612148 = header.getOrDefault("X-Amz-Signature")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "X-Amz-Signature", valid_612148
  var valid_612149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Content-Sha256", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Date")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Date", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Credential")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Credential", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Security-Token")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Security-Token", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Algorithm")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Algorithm", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-SignedHeaders", valid_612154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612156: Call_ListPrincipalsForPortfolio_612142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all principal ARNs associated with the specified portfolio.
  ## 
  let valid = call_612156.validator(path, query, header, formData, body)
  let scheme = call_612156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612156.url(scheme.get, call_612156.host, call_612156.base,
                         call_612156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612156, url, valid)

proc call*(call_612157: Call_ListPrincipalsForPortfolio_612142; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listPrincipalsForPortfolio
  ## Lists all principal ARNs associated with the specified portfolio.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612158 = newJObject()
  var body_612159 = newJObject()
  add(query_612158, "PageToken", newJString(PageToken))
  add(query_612158, "PageSize", newJString(PageSize))
  if body != nil:
    body_612159 = body
  result = call_612157.call(nil, query_612158, nil, nil, body_612159)

var listPrincipalsForPortfolio* = Call_ListPrincipalsForPortfolio_612142(
    name: "listPrincipalsForPortfolio", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio",
    validator: validate_ListPrincipalsForPortfolio_612143, base: "/",
    url: url_ListPrincipalsForPortfolio_612144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedProductPlans_612160 = ref object of OpenApiRestCall_610658
proc url_ListProvisionedProductPlans_612162(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisionedProductPlans_612161(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612163 = header.getOrDefault("X-Amz-Target")
  valid_612163 = validateParameter(valid_612163, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisionedProductPlans"))
  if valid_612163 != nil:
    section.add "X-Amz-Target", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Signature")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Signature", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Content-Sha256", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Date")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Date", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Credential")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Credential", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-Security-Token")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-Security-Token", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Algorithm")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Algorithm", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-SignedHeaders", valid_612170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612172: Call_ListProvisionedProductPlans_612160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ## 
  let valid = call_612172.validator(path, query, header, formData, body)
  let scheme = call_612172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612172.url(scheme.get, call_612172.host, call_612172.base,
                         call_612172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612172, url, valid)

proc call*(call_612173: Call_ListProvisionedProductPlans_612160; body: JsonNode): Recallable =
  ## listProvisionedProductPlans
  ## Lists the plans for the specified provisioned product or all plans to which the user has access.
  ##   body: JObject (required)
  var body_612174 = newJObject()
  if body != nil:
    body_612174 = body
  result = call_612173.call(nil, nil, nil, nil, body_612174)

var listProvisionedProductPlans* = Call_ListProvisionedProductPlans_612160(
    name: "listProvisionedProductPlans", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans",
    validator: validate_ListProvisionedProductPlans_612161, base: "/",
    url: url_ListProvisionedProductPlans_612162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifacts_612175 = ref object of OpenApiRestCall_610658
proc url_ListProvisioningArtifacts_612177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifacts_612176(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612178 = header.getOrDefault("X-Amz-Target")
  valid_612178 = validateParameter(valid_612178, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifacts"))
  if valid_612178 != nil:
    section.add "X-Amz-Target", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Signature")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Signature", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Content-Sha256", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Date")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Date", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Credential")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Credential", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-Security-Token")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-Security-Token", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Algorithm")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Algorithm", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-SignedHeaders", valid_612185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612187: Call_ListProvisioningArtifacts_612175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ## 
  let valid = call_612187.validator(path, query, header, formData, body)
  let scheme = call_612187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612187.url(scheme.get, call_612187.host, call_612187.base,
                         call_612187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612187, url, valid)

proc call*(call_612188: Call_ListProvisioningArtifacts_612175; body: JsonNode): Recallable =
  ## listProvisioningArtifacts
  ## Lists all provisioning artifacts (also known as versions) for the specified product.
  ##   body: JObject (required)
  var body_612189 = newJObject()
  if body != nil:
    body_612189 = body
  result = call_612188.call(nil, nil, nil, nil, body_612189)

var listProvisioningArtifacts* = Call_ListProvisioningArtifacts_612175(
    name: "listProvisioningArtifacts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts",
    validator: validate_ListProvisioningArtifacts_612176, base: "/",
    url: url_ListProvisioningArtifacts_612177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisioningArtifactsForServiceAction_612190 = ref object of OpenApiRestCall_610658
proc url_ListProvisioningArtifactsForServiceAction_612192(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProvisioningArtifactsForServiceAction_612191(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612193 = query.getOrDefault("PageToken")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "PageToken", valid_612193
  var valid_612194 = query.getOrDefault("PageSize")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "PageSize", valid_612194
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
  var valid_612195 = header.getOrDefault("X-Amz-Target")
  valid_612195 = validateParameter(valid_612195, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"))
  if valid_612195 != nil:
    section.add "X-Amz-Target", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-Signature")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-Signature", valid_612196
  var valid_612197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612197 = validateParameter(valid_612197, JString, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "X-Amz-Content-Sha256", valid_612197
  var valid_612198 = header.getOrDefault("X-Amz-Date")
  valid_612198 = validateParameter(valid_612198, JString, required = false,
                                 default = nil)
  if valid_612198 != nil:
    section.add "X-Amz-Date", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Credential")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Credential", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Security-Token")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Security-Token", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Algorithm")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Algorithm", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-SignedHeaders", valid_612202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612204: Call_ListProvisioningArtifactsForServiceAction_612190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ## 
  let valid = call_612204.validator(path, query, header, formData, body)
  let scheme = call_612204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612204.url(scheme.get, call_612204.host, call_612204.base,
                         call_612204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612204, url, valid)

proc call*(call_612205: Call_ListProvisioningArtifactsForServiceAction_612190;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listProvisioningArtifactsForServiceAction
  ## Lists all provisioning artifacts (also known as versions) for the specified self-service action.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612206 = newJObject()
  var body_612207 = newJObject()
  add(query_612206, "PageToken", newJString(PageToken))
  add(query_612206, "PageSize", newJString(PageSize))
  if body != nil:
    body_612207 = body
  result = call_612205.call(nil, query_612206, nil, nil, body_612207)

var listProvisioningArtifactsForServiceAction* = Call_ListProvisioningArtifactsForServiceAction_612190(
    name: "listProvisioningArtifactsForServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction",
    validator: validate_ListProvisioningArtifactsForServiceAction_612191,
    base: "/", url: url_ListProvisioningArtifactsForServiceAction_612192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecordHistory_612208 = ref object of OpenApiRestCall_610658
proc url_ListRecordHistory_612210(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRecordHistory_612209(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612211 = header.getOrDefault("X-Amz-Target")
  valid_612211 = validateParameter(valid_612211, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListRecordHistory"))
  if valid_612211 != nil:
    section.add "X-Amz-Target", valid_612211
  var valid_612212 = header.getOrDefault("X-Amz-Signature")
  valid_612212 = validateParameter(valid_612212, JString, required = false,
                                 default = nil)
  if valid_612212 != nil:
    section.add "X-Amz-Signature", valid_612212
  var valid_612213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612213 = validateParameter(valid_612213, JString, required = false,
                                 default = nil)
  if valid_612213 != nil:
    section.add "X-Amz-Content-Sha256", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Date")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Date", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Credential")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Credential", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Security-Token")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Security-Token", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Algorithm")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Algorithm", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-SignedHeaders", valid_612218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612220: Call_ListRecordHistory_612208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified requests or all performed requests.
  ## 
  let valid = call_612220.validator(path, query, header, formData, body)
  let scheme = call_612220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612220.url(scheme.get, call_612220.host, call_612220.base,
                         call_612220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612220, url, valid)

proc call*(call_612221: Call_ListRecordHistory_612208; body: JsonNode): Recallable =
  ## listRecordHistory
  ## Lists the specified requests or all performed requests.
  ##   body: JObject (required)
  var body_612222 = newJObject()
  if body != nil:
    body_612222 = body
  result = call_612221.call(nil, nil, nil, nil, body_612222)

var listRecordHistory* = Call_ListRecordHistory_612208(name: "listRecordHistory",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory",
    validator: validate_ListRecordHistory_612209, base: "/",
    url: url_ListRecordHistory_612210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForTagOption_612223 = ref object of OpenApiRestCall_610658
proc url_ListResourcesForTagOption_612225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForTagOption_612224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the resources associated with the specified TagOption.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612226 = query.getOrDefault("PageToken")
  valid_612226 = validateParameter(valid_612226, JString, required = false,
                                 default = nil)
  if valid_612226 != nil:
    section.add "PageToken", valid_612226
  var valid_612227 = query.getOrDefault("PageSize")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "PageSize", valid_612227
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
  var valid_612228 = header.getOrDefault("X-Amz-Target")
  valid_612228 = validateParameter(valid_612228, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListResourcesForTagOption"))
  if valid_612228 != nil:
    section.add "X-Amz-Target", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Signature")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Signature", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Content-Sha256", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Date")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Date", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Credential")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Credential", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Security-Token")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Security-Token", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-Algorithm")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Algorithm", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-SignedHeaders", valid_612235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612237: Call_ListResourcesForTagOption_612223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the resources associated with the specified TagOption.
  ## 
  let valid = call_612237.validator(path, query, header, formData, body)
  let scheme = call_612237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612237.url(scheme.get, call_612237.host, call_612237.base,
                         call_612237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612237, url, valid)

proc call*(call_612238: Call_ListResourcesForTagOption_612223; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listResourcesForTagOption
  ## Lists the resources associated with the specified TagOption.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612239 = newJObject()
  var body_612240 = newJObject()
  add(query_612239, "PageToken", newJString(PageToken))
  add(query_612239, "PageSize", newJString(PageSize))
  if body != nil:
    body_612240 = body
  result = call_612238.call(nil, query_612239, nil, nil, body_612240)

var listResourcesForTagOption* = Call_ListResourcesForTagOption_612223(
    name: "listResourcesForTagOption", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption",
    validator: validate_ListResourcesForTagOption_612224, base: "/",
    url: url_ListResourcesForTagOption_612225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActions_612241 = ref object of OpenApiRestCall_610658
proc url_ListServiceActions_612243(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActions_612242(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists all self-service actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612244 = query.getOrDefault("PageToken")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "PageToken", valid_612244
  var valid_612245 = query.getOrDefault("PageSize")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "PageSize", valid_612245
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
  var valid_612246 = header.getOrDefault("X-Amz-Target")
  valid_612246 = validateParameter(valid_612246, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActions"))
  if valid_612246 != nil:
    section.add "X-Amz-Target", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Signature")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Signature", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Content-Sha256", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-Date")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Date", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-Credential")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-Credential", valid_612250
  var valid_612251 = header.getOrDefault("X-Amz-Security-Token")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "X-Amz-Security-Token", valid_612251
  var valid_612252 = header.getOrDefault("X-Amz-Algorithm")
  valid_612252 = validateParameter(valid_612252, JString, required = false,
                                 default = nil)
  if valid_612252 != nil:
    section.add "X-Amz-Algorithm", valid_612252
  var valid_612253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "X-Amz-SignedHeaders", valid_612253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612255: Call_ListServiceActions_612241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all self-service actions.
  ## 
  let valid = call_612255.validator(path, query, header, formData, body)
  let scheme = call_612255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612255.url(scheme.get, call_612255.host, call_612255.base,
                         call_612255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612255, url, valid)

proc call*(call_612256: Call_ListServiceActions_612241; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActions
  ## Lists all self-service actions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612257 = newJObject()
  var body_612258 = newJObject()
  add(query_612257, "PageToken", newJString(PageToken))
  add(query_612257, "PageSize", newJString(PageSize))
  if body != nil:
    body_612258 = body
  result = call_612256.call(nil, query_612257, nil, nil, body_612258)

var listServiceActions* = Call_ListServiceActions_612241(
    name: "listServiceActions", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions",
    validator: validate_ListServiceActions_612242, base: "/",
    url: url_ListServiceActions_612243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServiceActionsForProvisioningArtifact_612259 = ref object of OpenApiRestCall_610658
proc url_ListServiceActionsForProvisioningArtifact_612261(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServiceActionsForProvisioningArtifact_612260(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612262 = query.getOrDefault("PageToken")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "PageToken", valid_612262
  var valid_612263 = query.getOrDefault("PageSize")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "PageSize", valid_612263
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
  var valid_612264 = header.getOrDefault("X-Amz-Target")
  valid_612264 = validateParameter(valid_612264, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"))
  if valid_612264 != nil:
    section.add "X-Amz-Target", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Signature")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Signature", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-Content-Sha256", valid_612266
  var valid_612267 = header.getOrDefault("X-Amz-Date")
  valid_612267 = validateParameter(valid_612267, JString, required = false,
                                 default = nil)
  if valid_612267 != nil:
    section.add "X-Amz-Date", valid_612267
  var valid_612268 = header.getOrDefault("X-Amz-Credential")
  valid_612268 = validateParameter(valid_612268, JString, required = false,
                                 default = nil)
  if valid_612268 != nil:
    section.add "X-Amz-Credential", valid_612268
  var valid_612269 = header.getOrDefault("X-Amz-Security-Token")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Security-Token", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Algorithm")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Algorithm", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-SignedHeaders", valid_612271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612273: Call_ListServiceActionsForProvisioningArtifact_612259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ## 
  let valid = call_612273.validator(path, query, header, formData, body)
  let scheme = call_612273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612273.url(scheme.get, call_612273.host, call_612273.base,
                         call_612273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612273, url, valid)

proc call*(call_612274: Call_ListServiceActionsForProvisioningArtifact_612259;
          body: JsonNode; PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listServiceActionsForProvisioningArtifact
  ## Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612275 = newJObject()
  var body_612276 = newJObject()
  add(query_612275, "PageToken", newJString(PageToken))
  add(query_612275, "PageSize", newJString(PageSize))
  if body != nil:
    body_612276 = body
  result = call_612274.call(nil, query_612275, nil, nil, body_612276)

var listServiceActionsForProvisioningArtifact* = Call_ListServiceActionsForProvisioningArtifact_612259(
    name: "listServiceActionsForProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact",
    validator: validate_ListServiceActionsForProvisioningArtifact_612260,
    base: "/", url: url_ListServiceActionsForProvisioningArtifact_612261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStackInstancesForProvisionedProduct_612277 = ref object of OpenApiRestCall_610658
proc url_ListStackInstancesForProvisionedProduct_612279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStackInstancesForProvisionedProduct_612278(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612280 = header.getOrDefault("X-Amz-Target")
  valid_612280 = validateParameter(valid_612280, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"))
  if valid_612280 != nil:
    section.add "X-Amz-Target", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-Signature")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-Signature", valid_612281
  var valid_612282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Content-Sha256", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Date")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Date", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Credential")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Credential", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-Security-Token")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-Security-Token", valid_612285
  var valid_612286 = header.getOrDefault("X-Amz-Algorithm")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "X-Amz-Algorithm", valid_612286
  var valid_612287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "X-Amz-SignedHeaders", valid_612287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612289: Call_ListStackInstancesForProvisionedProduct_612277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ## 
  let valid = call_612289.validator(path, query, header, formData, body)
  let scheme = call_612289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612289.url(scheme.get, call_612289.host, call_612289.base,
                         call_612289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612289, url, valid)

proc call*(call_612290: Call_ListStackInstancesForProvisionedProduct_612277;
          body: JsonNode): Recallable =
  ## listStackInstancesForProvisionedProduct
  ## Returns summary information about stack instances that are associated with the specified <code>CFN_STACKSET</code> type provisioned product. You can filter for stack instances that are associated with a specific AWS account name or region. 
  ##   body: JObject (required)
  var body_612291 = newJObject()
  if body != nil:
    body_612291 = body
  result = call_612290.call(nil, nil, nil, nil, body_612291)

var listStackInstancesForProvisionedProduct* = Call_ListStackInstancesForProvisionedProduct_612277(
    name: "listStackInstancesForProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct",
    validator: validate_ListStackInstancesForProvisionedProduct_612278, base: "/",
    url: url_ListStackInstancesForProvisionedProduct_612279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagOptions_612292 = ref object of OpenApiRestCall_610658
proc url_ListTagOptions_612294(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagOptions_612293(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612295 = query.getOrDefault("PageToken")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "PageToken", valid_612295
  var valid_612296 = query.getOrDefault("PageSize")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "PageSize", valid_612296
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
  var valid_612297 = header.getOrDefault("X-Amz-Target")
  valid_612297 = validateParameter(valid_612297, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ListTagOptions"))
  if valid_612297 != nil:
    section.add "X-Amz-Target", valid_612297
  var valid_612298 = header.getOrDefault("X-Amz-Signature")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-Signature", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Content-Sha256", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Date")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Date", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Credential")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Credential", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Security-Token")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Security-Token", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Algorithm")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Algorithm", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-SignedHeaders", valid_612304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612306: Call_ListTagOptions_612292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the specified TagOptions or all TagOptions.
  ## 
  let valid = call_612306.validator(path, query, header, formData, body)
  let scheme = call_612306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612306.url(scheme.get, call_612306.host, call_612306.base,
                         call_612306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612306, url, valid)

proc call*(call_612307: Call_ListTagOptions_612292; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## listTagOptions
  ## Lists the specified TagOptions or all TagOptions.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612308 = newJObject()
  var body_612309 = newJObject()
  add(query_612308, "PageToken", newJString(PageToken))
  add(query_612308, "PageSize", newJString(PageSize))
  if body != nil:
    body_612309 = body
  result = call_612307.call(nil, query_612308, nil, nil, body_612309)

var listTagOptions* = Call_ListTagOptions_612292(name: "listTagOptions",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions",
    validator: validate_ListTagOptions_612293, base: "/", url: url_ListTagOptions_612294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ProvisionProduct_612310 = ref object of OpenApiRestCall_610658
proc url_ProvisionProduct_612312(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ProvisionProduct_612311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612313 = header.getOrDefault("X-Amz-Target")
  valid_612313 = validateParameter(valid_612313, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ProvisionProduct"))
  if valid_612313 != nil:
    section.add "X-Amz-Target", valid_612313
  var valid_612314 = header.getOrDefault("X-Amz-Signature")
  valid_612314 = validateParameter(valid_612314, JString, required = false,
                                 default = nil)
  if valid_612314 != nil:
    section.add "X-Amz-Signature", valid_612314
  var valid_612315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "X-Amz-Content-Sha256", valid_612315
  var valid_612316 = header.getOrDefault("X-Amz-Date")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Date", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Credential")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Credential", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Security-Token")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Security-Token", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Algorithm")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Algorithm", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-SignedHeaders", valid_612320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612322: Call_ProvisionProduct_612310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ## 
  let valid = call_612322.validator(path, query, header, formData, body)
  let scheme = call_612322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612322.url(scheme.get, call_612322.host, call_612322.base,
                         call_612322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612322, url, valid)

proc call*(call_612323: Call_ProvisionProduct_612310; body: JsonNode): Recallable =
  ## provisionProduct
  ## <p>Provisions the specified product.</p> <p>A provisioned product is a resourced instance of a product. For example, provisioning a product based on a CloudFormation template launches a CloudFormation stack and its underlying resources. You can check the status of this request using <a>DescribeRecord</a>.</p> <p>If the request contains a tag key with an empty list of values, there is a tag conflict for that key. Do not include conflicted keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[<i>N</i>]:<i>Value</i>".</p>
  ##   body: JObject (required)
  var body_612324 = newJObject()
  if body != nil:
    body_612324 = body
  result = call_612323.call(nil, nil, nil, nil, body_612324)

var provisionProduct* = Call_ProvisionProduct_612310(name: "provisionProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct",
    validator: validate_ProvisionProduct_612311, base: "/",
    url: url_ProvisionProduct_612312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectPortfolioShare_612325 = ref object of OpenApiRestCall_610658
proc url_RejectPortfolioShare_612327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RejectPortfolioShare_612326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612328 = header.getOrDefault("X-Amz-Target")
  valid_612328 = validateParameter(valid_612328, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.RejectPortfolioShare"))
  if valid_612328 != nil:
    section.add "X-Amz-Target", valid_612328
  var valid_612329 = header.getOrDefault("X-Amz-Signature")
  valid_612329 = validateParameter(valid_612329, JString, required = false,
                                 default = nil)
  if valid_612329 != nil:
    section.add "X-Amz-Signature", valid_612329
  var valid_612330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612330 = validateParameter(valid_612330, JString, required = false,
                                 default = nil)
  if valid_612330 != nil:
    section.add "X-Amz-Content-Sha256", valid_612330
  var valid_612331 = header.getOrDefault("X-Amz-Date")
  valid_612331 = validateParameter(valid_612331, JString, required = false,
                                 default = nil)
  if valid_612331 != nil:
    section.add "X-Amz-Date", valid_612331
  var valid_612332 = header.getOrDefault("X-Amz-Credential")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Credential", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Security-Token")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Security-Token", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Algorithm")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Algorithm", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-SignedHeaders", valid_612335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612337: Call_RejectPortfolioShare_612325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects an offer to share the specified portfolio.
  ## 
  let valid = call_612337.validator(path, query, header, formData, body)
  let scheme = call_612337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612337.url(scheme.get, call_612337.host, call_612337.base,
                         call_612337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612337, url, valid)

proc call*(call_612338: Call_RejectPortfolioShare_612325; body: JsonNode): Recallable =
  ## rejectPortfolioShare
  ## Rejects an offer to share the specified portfolio.
  ##   body: JObject (required)
  var body_612339 = newJObject()
  if body != nil:
    body_612339 = body
  result = call_612338.call(nil, nil, nil, nil, body_612339)

var rejectPortfolioShare* = Call_RejectPortfolioShare_612325(
    name: "rejectPortfolioShare", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare",
    validator: validate_RejectPortfolioShare_612326, base: "/",
    url: url_RejectPortfolioShare_612327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ScanProvisionedProducts_612340 = ref object of OpenApiRestCall_610658
proc url_ScanProvisionedProducts_612342(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ScanProvisionedProducts_612341(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612343 = header.getOrDefault("X-Amz-Target")
  valid_612343 = validateParameter(valid_612343, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.ScanProvisionedProducts"))
  if valid_612343 != nil:
    section.add "X-Amz-Target", valid_612343
  var valid_612344 = header.getOrDefault("X-Amz-Signature")
  valid_612344 = validateParameter(valid_612344, JString, required = false,
                                 default = nil)
  if valid_612344 != nil:
    section.add "X-Amz-Signature", valid_612344
  var valid_612345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612345 = validateParameter(valid_612345, JString, required = false,
                                 default = nil)
  if valid_612345 != nil:
    section.add "X-Amz-Content-Sha256", valid_612345
  var valid_612346 = header.getOrDefault("X-Amz-Date")
  valid_612346 = validateParameter(valid_612346, JString, required = false,
                                 default = nil)
  if valid_612346 != nil:
    section.add "X-Amz-Date", valid_612346
  var valid_612347 = header.getOrDefault("X-Amz-Credential")
  valid_612347 = validateParameter(valid_612347, JString, required = false,
                                 default = nil)
  if valid_612347 != nil:
    section.add "X-Amz-Credential", valid_612347
  var valid_612348 = header.getOrDefault("X-Amz-Security-Token")
  valid_612348 = validateParameter(valid_612348, JString, required = false,
                                 default = nil)
  if valid_612348 != nil:
    section.add "X-Amz-Security-Token", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Algorithm")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Algorithm", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-SignedHeaders", valid_612350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612352: Call_ScanProvisionedProducts_612340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ## 
  let valid = call_612352.validator(path, query, header, formData, body)
  let scheme = call_612352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612352.url(scheme.get, call_612352.host, call_612352.base,
                         call_612352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612352, url, valid)

proc call*(call_612353: Call_ScanProvisionedProducts_612340; body: JsonNode): Recallable =
  ## scanProvisionedProducts
  ## <p>Lists the provisioned products that are available (not terminated).</p> <p>To use additional filtering, see <a>SearchProvisionedProducts</a>.</p>
  ##   body: JObject (required)
  var body_612354 = newJObject()
  if body != nil:
    body_612354 = body
  result = call_612353.call(nil, nil, nil, nil, body_612354)

var scanProvisionedProducts* = Call_ScanProvisionedProducts_612340(
    name: "scanProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts",
    validator: validate_ScanProvisionedProducts_612341, base: "/",
    url: url_ScanProvisionedProducts_612342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProducts_612355 = ref object of OpenApiRestCall_610658
proc url_SearchProducts_612357(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProducts_612356(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about the products to which the caller has access.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612358 = query.getOrDefault("PageToken")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "PageToken", valid_612358
  var valid_612359 = query.getOrDefault("PageSize")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "PageSize", valid_612359
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
  var valid_612360 = header.getOrDefault("X-Amz-Target")
  valid_612360 = validateParameter(valid_612360, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProducts"))
  if valid_612360 != nil:
    section.add "X-Amz-Target", valid_612360
  var valid_612361 = header.getOrDefault("X-Amz-Signature")
  valid_612361 = validateParameter(valid_612361, JString, required = false,
                                 default = nil)
  if valid_612361 != nil:
    section.add "X-Amz-Signature", valid_612361
  var valid_612362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612362 = validateParameter(valid_612362, JString, required = false,
                                 default = nil)
  if valid_612362 != nil:
    section.add "X-Amz-Content-Sha256", valid_612362
  var valid_612363 = header.getOrDefault("X-Amz-Date")
  valid_612363 = validateParameter(valid_612363, JString, required = false,
                                 default = nil)
  if valid_612363 != nil:
    section.add "X-Amz-Date", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Credential")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Credential", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Security-Token")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Security-Token", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Algorithm")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Algorithm", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-SignedHeaders", valid_612367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612369: Call_SearchProducts_612355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products to which the caller has access.
  ## 
  let valid = call_612369.validator(path, query, header, formData, body)
  let scheme = call_612369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612369.url(scheme.get, call_612369.host, call_612369.base,
                         call_612369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612369, url, valid)

proc call*(call_612370: Call_SearchProducts_612355; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProducts
  ## Gets information about the products to which the caller has access.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612371 = newJObject()
  var body_612372 = newJObject()
  add(query_612371, "PageToken", newJString(PageToken))
  add(query_612371, "PageSize", newJString(PageSize))
  if body != nil:
    body_612372 = body
  result = call_612370.call(nil, query_612371, nil, nil, body_612372)

var searchProducts* = Call_SearchProducts_612355(name: "searchProducts",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts",
    validator: validate_SearchProducts_612356, base: "/", url: url_SearchProducts_612357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProductsAsAdmin_612373 = ref object of OpenApiRestCall_610658
proc url_SearchProductsAsAdmin_612375(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProductsAsAdmin_612374(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612376 = query.getOrDefault("PageToken")
  valid_612376 = validateParameter(valid_612376, JString, required = false,
                                 default = nil)
  if valid_612376 != nil:
    section.add "PageToken", valid_612376
  var valid_612377 = query.getOrDefault("PageSize")
  valid_612377 = validateParameter(valid_612377, JString, required = false,
                                 default = nil)
  if valid_612377 != nil:
    section.add "PageSize", valid_612377
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
  var valid_612378 = header.getOrDefault("X-Amz-Target")
  valid_612378 = validateParameter(valid_612378, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProductsAsAdmin"))
  if valid_612378 != nil:
    section.add "X-Amz-Target", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Signature")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Signature", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Content-Sha256", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Date")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Date", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-Credential")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-Credential", valid_612382
  var valid_612383 = header.getOrDefault("X-Amz-Security-Token")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-Security-Token", valid_612383
  var valid_612384 = header.getOrDefault("X-Amz-Algorithm")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-Algorithm", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-SignedHeaders", valid_612385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612387: Call_SearchProductsAsAdmin_612373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the products for the specified portfolio or all products.
  ## 
  let valid = call_612387.validator(path, query, header, formData, body)
  let scheme = call_612387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612387.url(scheme.get, call_612387.host, call_612387.base,
                         call_612387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612387, url, valid)

proc call*(call_612388: Call_SearchProductsAsAdmin_612373; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProductsAsAdmin
  ## Gets information about the products for the specified portfolio or all products.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612389 = newJObject()
  var body_612390 = newJObject()
  add(query_612389, "PageToken", newJString(PageToken))
  add(query_612389, "PageSize", newJString(PageSize))
  if body != nil:
    body_612390 = body
  result = call_612388.call(nil, query_612389, nil, nil, body_612390)

var searchProductsAsAdmin* = Call_SearchProductsAsAdmin_612373(
    name: "searchProductsAsAdmin", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin",
    validator: validate_SearchProductsAsAdmin_612374, base: "/",
    url: url_SearchProductsAsAdmin_612375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchProvisionedProducts_612391 = ref object of OpenApiRestCall_610658
proc url_SearchProvisionedProducts_612393(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SearchProvisionedProducts_612392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageToken: JString
  ##            : Pagination token
  ##   PageSize: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_612394 = query.getOrDefault("PageToken")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "PageToken", valid_612394
  var valid_612395 = query.getOrDefault("PageSize")
  valid_612395 = validateParameter(valid_612395, JString, required = false,
                                 default = nil)
  if valid_612395 != nil:
    section.add "PageSize", valid_612395
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
  var valid_612396 = header.getOrDefault("X-Amz-Target")
  valid_612396 = validateParameter(valid_612396, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.SearchProvisionedProducts"))
  if valid_612396 != nil:
    section.add "X-Amz-Target", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-Signature")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-Signature", valid_612397
  var valid_612398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612398 = validateParameter(valid_612398, JString, required = false,
                                 default = nil)
  if valid_612398 != nil:
    section.add "X-Amz-Content-Sha256", valid_612398
  var valid_612399 = header.getOrDefault("X-Amz-Date")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-Date", valid_612399
  var valid_612400 = header.getOrDefault("X-Amz-Credential")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "X-Amz-Credential", valid_612400
  var valid_612401 = header.getOrDefault("X-Amz-Security-Token")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "X-Amz-Security-Token", valid_612401
  var valid_612402 = header.getOrDefault("X-Amz-Algorithm")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Algorithm", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-SignedHeaders", valid_612403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612405: Call_SearchProvisionedProducts_612391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the provisioned products that meet the specified criteria.
  ## 
  let valid = call_612405.validator(path, query, header, formData, body)
  let scheme = call_612405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612405.url(scheme.get, call_612405.host, call_612405.base,
                         call_612405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612405, url, valid)

proc call*(call_612406: Call_SearchProvisionedProducts_612391; body: JsonNode;
          PageToken: string = ""; PageSize: string = ""): Recallable =
  ## searchProvisionedProducts
  ## Gets information about the provisioned products that meet the specified criteria.
  ##   PageToken: string
  ##            : Pagination token
  ##   PageSize: string
  ##           : Pagination limit
  ##   body: JObject (required)
  var query_612407 = newJObject()
  var body_612408 = newJObject()
  add(query_612407, "PageToken", newJString(PageToken))
  add(query_612407, "PageSize", newJString(PageSize))
  if body != nil:
    body_612408 = body
  result = call_612406.call(nil, query_612407, nil, nil, body_612408)

var searchProvisionedProducts* = Call_SearchProvisionedProducts_612391(
    name: "searchProvisionedProducts", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts",
    validator: validate_SearchProvisionedProducts_612392, base: "/",
    url: url_SearchProvisionedProducts_612393,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateProvisionedProduct_612409 = ref object of OpenApiRestCall_610658
proc url_TerminateProvisionedProduct_612411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateProvisionedProduct_612410(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612412 = header.getOrDefault("X-Amz-Target")
  valid_612412 = validateParameter(valid_612412, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.TerminateProvisionedProduct"))
  if valid_612412 != nil:
    section.add "X-Amz-Target", valid_612412
  var valid_612413 = header.getOrDefault("X-Amz-Signature")
  valid_612413 = validateParameter(valid_612413, JString, required = false,
                                 default = nil)
  if valid_612413 != nil:
    section.add "X-Amz-Signature", valid_612413
  var valid_612414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612414 = validateParameter(valid_612414, JString, required = false,
                                 default = nil)
  if valid_612414 != nil:
    section.add "X-Amz-Content-Sha256", valid_612414
  var valid_612415 = header.getOrDefault("X-Amz-Date")
  valid_612415 = validateParameter(valid_612415, JString, required = false,
                                 default = nil)
  if valid_612415 != nil:
    section.add "X-Amz-Date", valid_612415
  var valid_612416 = header.getOrDefault("X-Amz-Credential")
  valid_612416 = validateParameter(valid_612416, JString, required = false,
                                 default = nil)
  if valid_612416 != nil:
    section.add "X-Amz-Credential", valid_612416
  var valid_612417 = header.getOrDefault("X-Amz-Security-Token")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Security-Token", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Algorithm")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Algorithm", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-SignedHeaders", valid_612419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612421: Call_TerminateProvisionedProduct_612409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_612421.validator(path, query, header, formData, body)
  let scheme = call_612421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612421.url(scheme.get, call_612421.host, call_612421.base,
                         call_612421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612421, url, valid)

proc call*(call_612422: Call_TerminateProvisionedProduct_612409; body: JsonNode): Recallable =
  ## terminateProvisionedProduct
  ## <p>Terminates the specified provisioned product.</p> <p>This operation does not delete any records associated with the provisioned product.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_612423 = newJObject()
  if body != nil:
    body_612423 = body
  result = call_612422.call(nil, nil, nil, nil, body_612423)

var terminateProvisionedProduct* = Call_TerminateProvisionedProduct_612409(
    name: "terminateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct",
    validator: validate_TerminateProvisionedProduct_612410, base: "/",
    url: url_TerminateProvisionedProduct_612411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConstraint_612424 = ref object of OpenApiRestCall_610658
proc url_UpdateConstraint_612426(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateConstraint_612425(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612427 = header.getOrDefault("X-Amz-Target")
  valid_612427 = validateParameter(valid_612427, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateConstraint"))
  if valid_612427 != nil:
    section.add "X-Amz-Target", valid_612427
  var valid_612428 = header.getOrDefault("X-Amz-Signature")
  valid_612428 = validateParameter(valid_612428, JString, required = false,
                                 default = nil)
  if valid_612428 != nil:
    section.add "X-Amz-Signature", valid_612428
  var valid_612429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612429 = validateParameter(valid_612429, JString, required = false,
                                 default = nil)
  if valid_612429 != nil:
    section.add "X-Amz-Content-Sha256", valid_612429
  var valid_612430 = header.getOrDefault("X-Amz-Date")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "X-Amz-Date", valid_612430
  var valid_612431 = header.getOrDefault("X-Amz-Credential")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "X-Amz-Credential", valid_612431
  var valid_612432 = header.getOrDefault("X-Amz-Security-Token")
  valid_612432 = validateParameter(valid_612432, JString, required = false,
                                 default = nil)
  if valid_612432 != nil:
    section.add "X-Amz-Security-Token", valid_612432
  var valid_612433 = header.getOrDefault("X-Amz-Algorithm")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "X-Amz-Algorithm", valid_612433
  var valid_612434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "X-Amz-SignedHeaders", valid_612434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612436: Call_UpdateConstraint_612424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified constraint.
  ## 
  let valid = call_612436.validator(path, query, header, formData, body)
  let scheme = call_612436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612436.url(scheme.get, call_612436.host, call_612436.base,
                         call_612436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612436, url, valid)

proc call*(call_612437: Call_UpdateConstraint_612424; body: JsonNode): Recallable =
  ## updateConstraint
  ## Updates the specified constraint.
  ##   body: JObject (required)
  var body_612438 = newJObject()
  if body != nil:
    body_612438 = body
  result = call_612437.call(nil, nil, nil, nil, body_612438)

var updateConstraint* = Call_UpdateConstraint_612424(name: "updateConstraint",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint",
    validator: validate_UpdateConstraint_612425, base: "/",
    url: url_UpdateConstraint_612426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePortfolio_612439 = ref object of OpenApiRestCall_610658
proc url_UpdatePortfolio_612441(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePortfolio_612440(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612442 = header.getOrDefault("X-Amz-Target")
  valid_612442 = validateParameter(valid_612442, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdatePortfolio"))
  if valid_612442 != nil:
    section.add "X-Amz-Target", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-Signature")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-Signature", valid_612443
  var valid_612444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612444 = validateParameter(valid_612444, JString, required = false,
                                 default = nil)
  if valid_612444 != nil:
    section.add "X-Amz-Content-Sha256", valid_612444
  var valid_612445 = header.getOrDefault("X-Amz-Date")
  valid_612445 = validateParameter(valid_612445, JString, required = false,
                                 default = nil)
  if valid_612445 != nil:
    section.add "X-Amz-Date", valid_612445
  var valid_612446 = header.getOrDefault("X-Amz-Credential")
  valid_612446 = validateParameter(valid_612446, JString, required = false,
                                 default = nil)
  if valid_612446 != nil:
    section.add "X-Amz-Credential", valid_612446
  var valid_612447 = header.getOrDefault("X-Amz-Security-Token")
  valid_612447 = validateParameter(valid_612447, JString, required = false,
                                 default = nil)
  if valid_612447 != nil:
    section.add "X-Amz-Security-Token", valid_612447
  var valid_612448 = header.getOrDefault("X-Amz-Algorithm")
  valid_612448 = validateParameter(valid_612448, JString, required = false,
                                 default = nil)
  if valid_612448 != nil:
    section.add "X-Amz-Algorithm", valid_612448
  var valid_612449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "X-Amz-SignedHeaders", valid_612449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612451: Call_UpdatePortfolio_612439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ## 
  let valid = call_612451.validator(path, query, header, formData, body)
  let scheme = call_612451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612451.url(scheme.get, call_612451.host, call_612451.base,
                         call_612451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612451, url, valid)

proc call*(call_612452: Call_UpdatePortfolio_612439; body: JsonNode): Recallable =
  ## updatePortfolio
  ## <p>Updates the specified portfolio.</p> <p>You cannot update a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_612453 = newJObject()
  if body != nil:
    body_612453 = body
  result = call_612452.call(nil, nil, nil, nil, body_612453)

var updatePortfolio* = Call_UpdatePortfolio_612439(name: "updatePortfolio",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio",
    validator: validate_UpdatePortfolio_612440, base: "/", url: url_UpdatePortfolio_612441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProduct_612454 = ref object of OpenApiRestCall_610658
proc url_UpdateProduct_612456(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProduct_612455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612457 = header.getOrDefault("X-Amz-Target")
  valid_612457 = validateParameter(valid_612457, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProduct"))
  if valid_612457 != nil:
    section.add "X-Amz-Target", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-Signature")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-Signature", valid_612458
  var valid_612459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612459 = validateParameter(valid_612459, JString, required = false,
                                 default = nil)
  if valid_612459 != nil:
    section.add "X-Amz-Content-Sha256", valid_612459
  var valid_612460 = header.getOrDefault("X-Amz-Date")
  valid_612460 = validateParameter(valid_612460, JString, required = false,
                                 default = nil)
  if valid_612460 != nil:
    section.add "X-Amz-Date", valid_612460
  var valid_612461 = header.getOrDefault("X-Amz-Credential")
  valid_612461 = validateParameter(valid_612461, JString, required = false,
                                 default = nil)
  if valid_612461 != nil:
    section.add "X-Amz-Credential", valid_612461
  var valid_612462 = header.getOrDefault("X-Amz-Security-Token")
  valid_612462 = validateParameter(valid_612462, JString, required = false,
                                 default = nil)
  if valid_612462 != nil:
    section.add "X-Amz-Security-Token", valid_612462
  var valid_612463 = header.getOrDefault("X-Amz-Algorithm")
  valid_612463 = validateParameter(valid_612463, JString, required = false,
                                 default = nil)
  if valid_612463 != nil:
    section.add "X-Amz-Algorithm", valid_612463
  var valid_612464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612464 = validateParameter(valid_612464, JString, required = false,
                                 default = nil)
  if valid_612464 != nil:
    section.add "X-Amz-SignedHeaders", valid_612464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612466: Call_UpdateProduct_612454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified product.
  ## 
  let valid = call_612466.validator(path, query, header, formData, body)
  let scheme = call_612466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612466.url(scheme.get, call_612466.host, call_612466.base,
                         call_612466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612466, url, valid)

proc call*(call_612467: Call_UpdateProduct_612454; body: JsonNode): Recallable =
  ## updateProduct
  ## Updates the specified product.
  ##   body: JObject (required)
  var body_612468 = newJObject()
  if body != nil:
    body_612468 = body
  result = call_612467.call(nil, nil, nil, nil, body_612468)

var updateProduct* = Call_UpdateProduct_612454(name: "updateProduct",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct",
    validator: validate_UpdateProduct_612455, base: "/", url: url_UpdateProduct_612456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProduct_612469 = ref object of OpenApiRestCall_610658
proc url_UpdateProvisionedProduct_612471(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProduct_612470(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612472 = header.getOrDefault("X-Amz-Target")
  valid_612472 = validateParameter(valid_612472, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProduct"))
  if valid_612472 != nil:
    section.add "X-Amz-Target", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Signature")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Signature", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Content-Sha256", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Date")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Date", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Credential")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Credential", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-Security-Token")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-Security-Token", valid_612477
  var valid_612478 = header.getOrDefault("X-Amz-Algorithm")
  valid_612478 = validateParameter(valid_612478, JString, required = false,
                                 default = nil)
  if valid_612478 != nil:
    section.add "X-Amz-Algorithm", valid_612478
  var valid_612479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612479 = validateParameter(valid_612479, JString, required = false,
                                 default = nil)
  if valid_612479 != nil:
    section.add "X-Amz-SignedHeaders", valid_612479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612481: Call_UpdateProvisionedProduct_612469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ## 
  let valid = call_612481.validator(path, query, header, formData, body)
  let scheme = call_612481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612481.url(scheme.get, call_612481.host, call_612481.base,
                         call_612481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612481, url, valid)

proc call*(call_612482: Call_UpdateProvisionedProduct_612469; body: JsonNode): Recallable =
  ## updateProvisionedProduct
  ## <p>Requests updates to the configuration of the specified provisioned product.</p> <p>If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely.</p> <p>You can check the status of this request using <a>DescribeRecord</a>.</p>
  ##   body: JObject (required)
  var body_612483 = newJObject()
  if body != nil:
    body_612483 = body
  result = call_612482.call(nil, nil, nil, nil, body_612483)

var updateProvisionedProduct* = Call_UpdateProvisionedProduct_612469(
    name: "updateProvisionedProduct", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct",
    validator: validate_UpdateProvisionedProduct_612470, base: "/",
    url: url_UpdateProvisionedProduct_612471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisionedProductProperties_612484 = ref object of OpenApiRestCall_610658
proc url_UpdateProvisionedProductProperties_612486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisionedProductProperties_612485(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612487 = header.getOrDefault("X-Amz-Target")
  valid_612487 = validateParameter(valid_612487, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisionedProductProperties"))
  if valid_612487 != nil:
    section.add "X-Amz-Target", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Signature")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Signature", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Content-Sha256", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Date")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Date", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Credential")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Credential", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Security-Token")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Security-Token", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-Algorithm")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-Algorithm", valid_612493
  var valid_612494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "X-Amz-SignedHeaders", valid_612494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612496: Call_UpdateProvisionedProductProperties_612484;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Requests updates to the properties of the specified provisioned product.
  ## 
  let valid = call_612496.validator(path, query, header, formData, body)
  let scheme = call_612496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612496.url(scheme.get, call_612496.host, call_612496.base,
                         call_612496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612496, url, valid)

proc call*(call_612497: Call_UpdateProvisionedProductProperties_612484;
          body: JsonNode): Recallable =
  ## updateProvisionedProductProperties
  ## Requests updates to the properties of the specified provisioned product.
  ##   body: JObject (required)
  var body_612498 = newJObject()
  if body != nil:
    body_612498 = body
  result = call_612497.call(nil, nil, nil, nil, body_612498)

var updateProvisionedProductProperties* = Call_UpdateProvisionedProductProperties_612484(
    name: "updateProvisionedProductProperties", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties",
    validator: validate_UpdateProvisionedProductProperties_612485, base: "/",
    url: url_UpdateProvisionedProductProperties_612486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProvisioningArtifact_612499 = ref object of OpenApiRestCall_610658
proc url_UpdateProvisioningArtifact_612501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateProvisioningArtifact_612500(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612502 = header.getOrDefault("X-Amz-Target")
  valid_612502 = validateParameter(valid_612502, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateProvisioningArtifact"))
  if valid_612502 != nil:
    section.add "X-Amz-Target", valid_612502
  var valid_612503 = header.getOrDefault("X-Amz-Signature")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "X-Amz-Signature", valid_612503
  var valid_612504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612504 = validateParameter(valid_612504, JString, required = false,
                                 default = nil)
  if valid_612504 != nil:
    section.add "X-Amz-Content-Sha256", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Date")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Date", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-Credential")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Credential", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Security-Token")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Security-Token", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Algorithm")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Algorithm", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-SignedHeaders", valid_612509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612511: Call_UpdateProvisioningArtifact_612499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ## 
  let valid = call_612511.validator(path, query, header, formData, body)
  let scheme = call_612511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612511.url(scheme.get, call_612511.host, call_612511.base,
                         call_612511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612511, url, valid)

proc call*(call_612512: Call_UpdateProvisioningArtifact_612499; body: JsonNode): Recallable =
  ## updateProvisioningArtifact
  ## <p>Updates the specified provisioning artifact (also known as a version) for the specified product.</p> <p>You cannot update a provisioning artifact for a product that was shared with you.</p>
  ##   body: JObject (required)
  var body_612513 = newJObject()
  if body != nil:
    body_612513 = body
  result = call_612512.call(nil, nil, nil, nil, body_612513)

var updateProvisioningArtifact* = Call_UpdateProvisioningArtifact_612499(
    name: "updateProvisioningArtifact", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com", route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact",
    validator: validate_UpdateProvisioningArtifact_612500, base: "/",
    url: url_UpdateProvisioningArtifact_612501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceAction_612514 = ref object of OpenApiRestCall_610658
proc url_UpdateServiceAction_612516(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceAction_612515(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612517 = header.getOrDefault("X-Amz-Target")
  valid_612517 = validateParameter(valid_612517, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateServiceAction"))
  if valid_612517 != nil:
    section.add "X-Amz-Target", valid_612517
  var valid_612518 = header.getOrDefault("X-Amz-Signature")
  valid_612518 = validateParameter(valid_612518, JString, required = false,
                                 default = nil)
  if valid_612518 != nil:
    section.add "X-Amz-Signature", valid_612518
  var valid_612519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612519 = validateParameter(valid_612519, JString, required = false,
                                 default = nil)
  if valid_612519 != nil:
    section.add "X-Amz-Content-Sha256", valid_612519
  var valid_612520 = header.getOrDefault("X-Amz-Date")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "X-Amz-Date", valid_612520
  var valid_612521 = header.getOrDefault("X-Amz-Credential")
  valid_612521 = validateParameter(valid_612521, JString, required = false,
                                 default = nil)
  if valid_612521 != nil:
    section.add "X-Amz-Credential", valid_612521
  var valid_612522 = header.getOrDefault("X-Amz-Security-Token")
  valid_612522 = validateParameter(valid_612522, JString, required = false,
                                 default = nil)
  if valid_612522 != nil:
    section.add "X-Amz-Security-Token", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Algorithm")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Algorithm", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-SignedHeaders", valid_612524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612526: Call_UpdateServiceAction_612514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a self-service action.
  ## 
  let valid = call_612526.validator(path, query, header, formData, body)
  let scheme = call_612526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612526.url(scheme.get, call_612526.host, call_612526.base,
                         call_612526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612526, url, valid)

proc call*(call_612527: Call_UpdateServiceAction_612514; body: JsonNode): Recallable =
  ## updateServiceAction
  ## Updates a self-service action.
  ##   body: JObject (required)
  var body_612528 = newJObject()
  if body != nil:
    body_612528 = body
  result = call_612527.call(nil, nil, nil, nil, body_612528)

var updateServiceAction* = Call_UpdateServiceAction_612514(
    name: "updateServiceAction", meth: HttpMethod.HttpPost,
    host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction",
    validator: validate_UpdateServiceAction_612515, base: "/",
    url: url_UpdateServiceAction_612516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTagOption_612529 = ref object of OpenApiRestCall_610658
proc url_UpdateTagOption_612531(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTagOption_612530(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612532 = header.getOrDefault("X-Amz-Target")
  valid_612532 = validateParameter(valid_612532, JString, required = true, default = newJString(
      "AWS242ServiceCatalogService.UpdateTagOption"))
  if valid_612532 != nil:
    section.add "X-Amz-Target", valid_612532
  var valid_612533 = header.getOrDefault("X-Amz-Signature")
  valid_612533 = validateParameter(valid_612533, JString, required = false,
                                 default = nil)
  if valid_612533 != nil:
    section.add "X-Amz-Signature", valid_612533
  var valid_612534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612534 = validateParameter(valid_612534, JString, required = false,
                                 default = nil)
  if valid_612534 != nil:
    section.add "X-Amz-Content-Sha256", valid_612534
  var valid_612535 = header.getOrDefault("X-Amz-Date")
  valid_612535 = validateParameter(valid_612535, JString, required = false,
                                 default = nil)
  if valid_612535 != nil:
    section.add "X-Amz-Date", valid_612535
  var valid_612536 = header.getOrDefault("X-Amz-Credential")
  valid_612536 = validateParameter(valid_612536, JString, required = false,
                                 default = nil)
  if valid_612536 != nil:
    section.add "X-Amz-Credential", valid_612536
  var valid_612537 = header.getOrDefault("X-Amz-Security-Token")
  valid_612537 = validateParameter(valid_612537, JString, required = false,
                                 default = nil)
  if valid_612537 != nil:
    section.add "X-Amz-Security-Token", valid_612537
  var valid_612538 = header.getOrDefault("X-Amz-Algorithm")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "X-Amz-Algorithm", valid_612538
  var valid_612539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "X-Amz-SignedHeaders", valid_612539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612541: Call_UpdateTagOption_612529; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified TagOption.
  ## 
  let valid = call_612541.validator(path, query, header, formData, body)
  let scheme = call_612541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612541.url(scheme.get, call_612541.host, call_612541.base,
                         call_612541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612541, url, valid)

proc call*(call_612542: Call_UpdateTagOption_612529; body: JsonNode): Recallable =
  ## updateTagOption
  ## Updates the specified TagOption.
  ##   body: JObject (required)
  var body_612543 = newJObject()
  if body != nil:
    body_612543 = body
  result = call_612542.call(nil, nil, nil, nil, body_612543)

var updateTagOption* = Call_UpdateTagOption_612529(name: "updateTagOption",
    meth: HttpMethod.HttpPost, host: "servicecatalog.amazonaws.com",
    route: "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption",
    validator: validate_UpdateTagOption_612530, base: "/", url: url_UpdateTagOption_612531,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
